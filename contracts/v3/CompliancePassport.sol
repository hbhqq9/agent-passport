// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CompliancePassport V3
 * @author AGL Team
 * @notice 合规护照合约 — 集成 ERC-8126 风险评分与 ERC-8226 合规状态
 * @dev 合规证明可导出/可验证，支持可移植的合规状态
 *
 * V3 安全修复:
 *   - [CRITICAL] 修复 EIP-712 Nonce 读写错位 (同 AgentPassport)
 *     TYPEHASH 增加 signer 字段, nonce 统一从 signer 读取/写入
 *   - [HIGH] 修复 issueCertificateBySignature 允许伪造 riskScore
 *     不再接受外部传入的 riskScore，改为从链上已有记录读取
 *   - [HIGH] 修复 verifyComplianceProof 永久失效
 *     将 scorerCount 从硬编码 0 改为动态查询实际活跃评分者数量
 *     函数可见性从 pure 改为 view
 */

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// ========== 外部接口 ==========

interface IAgentRegistryForCompliance {
    function isRegisteredAgent(address wallet) external view returns (bool);
    function getAgentByWallet(address wallet) external view returns (uint256);
    function getAgentWallet(uint256 agentId) external view returns (address);
}

interface IERC8126RiskScore {
    function getLatestRiskScore(uint256 agentId)
        external view returns (uint8 score, uint256 updatedAt, address scorer);
}

interface IERC8226Compliance {
    function getActivePrincipal(uint256 agentId)
        external view returns (address principal, uint256 mandateExpiry);
    function isCompliant(uint256 agentId) external view returns (bool);
}

contract CompliancePassport is EIP712, AccessControl {
    using ECDSA for bytes32;

    // ========== 角色 ==========
    bytes32 public constant SCORER_ROLE = keccak256("SCORER_ROLE");
    bytes32 public constant COMPLIANCE_ORACLE_ROLE = keccak256("COMPLIANCE_ORACLE_ROLE");

    // ========== EIP-712 类型 ==========
    // [V3 FIX] 增加 signer 字段，将 nonce 与 signer 绑定
    bytes32 private constant COMPLIANCE_CERT_TYPEHASH = keccak256(
        "ComplianceCertificate(address signer,uint256 agentId,uint8 complianceLevel,bytes32 evidenceHash,uint256 validUntil,uint256 nonce)"
    );

    bytes32 private constant RISK_SCORE_TYPEHASH = keccak256(
        "RiskScore(address signer,uint256 agentId,uint8 score,uint256 validUntil,bytes32 evidenceHash,uint256 nonce)"
    );

    // ========== 数据结构 ==========

    struct RiskScoreRecord {
        uint8 score;
        address scorer;
        uint256 scoredAt;
        uint256 validUntil;
        bytes32 evidenceHash;
        string scorerURI;
        bool revoked;
    }

    enum ComplianceCheck {
        IDENTITY_VERIFIED,
        WALLET_CLEAN,
        BEHAVIOR_NORMAL,
        CODE_VERIFIED,
        MANDATE_VALID,
        KYC_CLEARED
    }

    struct ComplianceRecord {
        ComplianceCheck checkType;
        bool passed;
        address verifier;
        uint256 verifiedAt;
        uint256 validUntil;
        bytes32 evidenceHash;
        string details;
    }

    struct ComplianceCertificate {
        uint256 certId;
        uint256 agentId;
        uint8 riskScore;
        uint8 complianceLevel;
        bytes32 evidenceHash;
        uint256 validUntil;
        uint256 issuedAt;
        address issuer;
        bool revoked;
    }

    struct MandateStatus {
        uint256 agentId;
        address principal;
        uint256 mandateExpiry;
        uint256 financialCap;
        bytes32 scopeHash;
        bool frozen;
        uint256 lastVerified;
    }

    struct ComplianceSummary {
        uint256 agentId;
        uint8 compositeRiskScore;
        uint8 complianceLevel;
        uint256 validChecks;
        uint256 totalChecks;
        bool hasActiveMandate;
        bool hasValidCertificate;
        uint256 lastUpdated;
    }

    // ========== 状态变量 ==========

    IAgentRegistryForCompliance public immutable agentRegistry;
    IERC8126RiskScore public erc8126Oracle;
    IERC8226Compliance public erc8226Oracle;

    uint256 private _nextCertId;

    mapping(uint256 => RiskScoreRecord[]) internal _riskScores;
    mapping(uint256 => mapping(ComplianceCheck => ComplianceRecord[])) internal _complianceRecords;
    mapping(uint256 => ComplianceCertificate) internal _certificates;
    mapping(uint256 => uint256[]) internal _agentCertificates;
    mapping(uint256 => MandateStatus) internal _mandates;

    /// @notice 签名 nonce — [V3] 统一按 signer 索引
    mapping(address => uint256) public scorerNonces;

    // ========== 事件 ==========

    event RiskScoreRecorded(
        uint256 indexed agentId,
        uint8 score,
        address indexed scorer,
        uint256 validUntil,
        bytes32 evidenceHash
    );

    event ComplianceCheckPassed(
        uint256 indexed agentId,
        ComplianceCheck indexed checkType,
        address indexed verifier,
        uint256 validUntil
    );

    event CertificateIssued(
        uint256 indexed certId,
        uint256 indexed agentId,
        uint8 riskScore,
        uint8 complianceLevel,
        uint256 validUntil
    );

    event CertificateRevoked(
        uint256 indexed certId,
        string reason
    );

    event MandateRecorded(
        uint256 indexed agentId,
        address indexed principal,
        uint256 mandateExpiry,
        uint256 financialCap
    );

    event MandateFrozen(
        uint256 indexed agentId,
        string reason
    );

    event OracleUpdated(
        string oracleName,
        address indexed oracleAddress
    );

    // ========== 构造函数 ==========

    constructor(address _agentRegistry)
        EIP712("AGLCompliancePassport", "1")
    {
        require(_agentRegistry != address(0), "CompliancePassport: zero registry");
        agentRegistry = IAgentRegistryForCompliance(_agentRegistry);
        _nextCertId = 1;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SCORER_ROLE, msg.sender);
        _grantRole(COMPLIANCE_ORACLE_ROLE, msg.sender);
    }

    // ========== ERC-8126 风险评分集成 ==========

    function recordRiskScore(
        uint256 agentId,
        uint8 score,
        uint256 validUntil,
        bytes32 evidenceHash,
        string calldata scorerURI
    ) external onlyRole(SCORER_ROLE) {
        require(score <= 100, "CompliancePassport: score out of range");
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");
        _requireAgentExists(agentId);

        _riskScores[agentId].push(RiskScoreRecord({
            score: score,
            scorer: msg.sender,
            scoredAt: block.timestamp,
            validUntil: validUntil,
            evidenceHash: evidenceHash,
            scorerURI: scorerURI,
            revoked: false
        }));

        emit RiskScoreRecorded(agentId, score, msg.sender, validUntil, evidenceHash);
    }

    /**
     * @notice 通过签名记录风险评分 (链下签名 + 链上提交)
     * @dev [V3 FIX] 修复 nonce 读写错位:
     *      - 新增 signer 和 nonce 参数
     *      - RISK_SCORE_TYPEHASH 增加 signer 字段
     *      - nonce 统一从 signer 读取/写入
     * @param signer 评分者 (签名者) 地址 — [V3 新增]
     * @param nonce 当前 nonce 值 — [V3 新增]
     */
    function recordRiskScoreBySignature(
        uint256 agentId,
        uint8 score,
        uint256 validUntil,
        bytes32 evidenceHash,
        uint256 deadline,
        bytes calldata signature,
        address signer,       // [V3] 签名者地址
        uint256 nonce         // [V3] 签名者当前 nonce
    ) external {
        require(score <= 100, "CompliancePassport: score out of range");
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");
        require(block.timestamp <= deadline, "CompliancePassport: expired");
        _requireAgentExists(agentId);

        // [V3 FIX] nonce 从 signer 读取，与签名绑定
        require(nonce == scorerNonces[signer], "CompliancePassport: invalid nonce");

        bytes32 structHash = keccak256(abi.encode(
            RISK_SCORE_TYPEHASH,
            signer,           // [V3] signer 纳入签名数据
            agentId,
            score,
            validUntil,
            evidenceHash,
            nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address recoveredSigner = hash.recover(signature);

        require(recoveredSigner == signer, "CompliancePassport: signer mismatch");
        require(hasRole(SCORER_ROLE, recoveredSigner), "CompliancePassport: not scorer");

        // [V3 FIX] nonce 写入 signer (读写一致)
        scorerNonces[signer] = nonce + 1;

        _riskScores[agentId].push(RiskScoreRecord({
            score: score,
            scorer: signer,
            scoredAt: block.timestamp,
            validUntil: validUntil,
            evidenceHash: evidenceHash,
            scorerURI: "",
            revoked: false
        }));

        emit RiskScoreRecorded(agentId, score, signer, validUntil, evidenceHash);
    }

    function getLatestRiskScore(uint256 agentId)
        external view
        returns (uint8 score, uint256 updatedAt, address scorer)
    {
        RiskScoreRecord[] storage records = _riskScores[agentId];
        if (records.length == 0) return (255, 0, address(0));

        for (uint256 i = records.length; i > 0; i--) {
            RiskScoreRecord storage r = records[i - 1];
            if (!r.revoked && (r.validUntil == 0 || block.timestamp <= r.validUntil)) {
                return (r.score, r.scoredAt, r.scorer);
            }
        }
        return (255, 0, address(0));
    }

    function getCompositeRiskScore(uint256 agentId)
        external view
        returns (uint8 compositeScore, uint256 scorerCount)
    {
        RiskScoreRecord[] storage records = _riskScores[agentId];
        uint256 totalScore = 0;
        uint256 count = 0;

        for (uint256 i = 0; i < records.length; i++) {
            if (!records[i].revoked &&
                (records[i].validUntil == 0 || block.timestamp <= records[i].validUntil)) {
                totalScore += records[i].score;
                count++;
            }
        }

        if (count == 0) return (255, 0);
        return (uint8(totalScore / count), count);
    }

    // ========== 合规检查 ==========

    function recordComplianceCheck(
        uint256 agentId,
        ComplianceCheck checkType,
        uint256 validUntil,
        bytes32 evidenceHash,
        string calldata details
    ) external onlyRole(COMPLIANCE_ORACLE_ROLE) {
        _requireAgentExists(agentId);
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");

        _complianceRecords[agentId][checkType].push(ComplianceRecord({
            checkType: checkType,
            passed: true,
            verifier: msg.sender,
            verifiedAt: block.timestamp,
            validUntil: validUntil,
            evidenceHash: evidenceHash,
            details: details
        }));

        emit ComplianceCheckPassed(agentId, checkType, msg.sender, validUntil);
    }

    function isComplianceCheckPassed(uint256 agentId, ComplianceCheck checkType)
        external view returns (bool)
    {
        ComplianceRecord[] storage records = _complianceRecords[agentId][checkType];
        for (uint256 i = records.length; i > 0; i--) {
            ComplianceRecord storage r = records[i - 1];
            if (r.passed && (r.validUntil == 0 || block.timestamp <= r.validUntil)) {
                return true;
            }
        }
        return false;
    }

    // ========== ERC-8226 委托状态集成 ==========

    function recordMandate(
        uint256 agentId,
        address principal,
        uint256 mandateExpiry,
        uint256 financialCap,
        bytes32 scopeHash
    ) external onlyRole(COMPLIANCE_ORACLE_ROLE) {
        _requireAgentExists(agentId);
        require(principal != address(0), "CompliancePassport: zero principal");
        require(mandateExpiry > block.timestamp, "CompliancePassport: expired mandate");

        _mandates[agentId] = MandateStatus({
            agentId: agentId,
            principal: principal,
            mandateExpiry: mandateExpiry,
            financialCap: financialCap,
            scopeHash: scopeHash,
            frozen: false,
            lastVerified: block.timestamp
        });

        emit MandateRecorded(agentId, principal, mandateExpiry, financialCap);
    }

    function freezeMandate(uint256 agentId, string calldata reason)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MandateStatus storage mandate = _mandates[agentId];
        require(mandate.agentId != 0, "CompliancePassport: no mandate");
        require(!mandate.frozen, "CompliancePassport: already frozen");

        mandate.frozen = true;
        emit MandateFrozen(agentId, reason);
    }

    function isMandateValid(uint256 agentId) external view returns (bool) {
        MandateStatus storage m = _mandates[agentId];
        if (m.agentId == 0) return false;
        if (m.frozen) return false;
        if (block.timestamp > m.mandateExpiry) return false;
        return true;
    }

    function getMandateStatus(uint256 agentId) external view returns (MandateStatus memory) {
        return _mandates[agentId];
    }

    // ========== 合规证书 ==========

    function issueCertificate(
        uint256 agentId,
        uint8 complianceLevel,
        bytes32 evidenceHash,
        uint256 validUntil
    ) external onlyRole(SCORER_ROLE) returns (uint256 certId) {
        _requireAgentExists(agentId);
        require(complianceLevel <= 5, "CompliancePassport: level out of range");
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");

        (uint8 compositeScore,) = this.getCompositeRiskScore(agentId);

        certId = _nextCertId++;
        _certificates[certId] = ComplianceCertificate({
            certId: certId,
            agentId: agentId,
            riskScore: compositeScore,
            complianceLevel: complianceLevel,
            evidenceHash: evidenceHash,
            validUntil: validUntil,
            issuedAt: block.timestamp,
            issuer: msg.sender,
            revoked: false
        });

        _agentCertificates[agentId].push(certId);

        emit CertificateIssued(certId, agentId, compositeScore, complianceLevel, validUntil);
    }

    /**
     * @notice 通过签名签发证书 (链下签发)
     * @dev [V3 FIX] 修复两个漏洞:
     *      1. nonce 读写错位 (同 AgentPassport)
     *      2. 不再接受外部 riskScore 参数，改为从链上已有评分记录读取
     *         防止签名路径绕过实际风险评估直接设置 riskScore=0
     *      - 新增 signer 和 nonce 参数
     *      - 移除 riskScore 参数 (改为链上读取)
     *      - COMPLIANCE_CERT_TYPEHASH 增加 signer 字段, 移除 riskScore
     * @param signer 评分者 (签名者) 地址 — [V3 新增]
     * @param nonce 当前 nonce 值 — [V3 新增]
     */
    function issueCertificateBySignature(
        uint256 agentId,
        // [V3 FIX] 移除 riskScore 参数 — 从链上读取真实评分
        uint8 complianceLevel,
        bytes32 evidenceHash,
        uint256 validUntil,
        uint256 deadline,
        bytes calldata signature,
        address signer,       // [V3] 签名者地址
        uint256 nonce         // [V3] 签名者当前 nonce
    ) external returns (uint256 certId) {
        _requireAgentExists(agentId);
        require(block.timestamp <= deadline, "CompliancePassport: expired");

        // [V3 FIX] nonce 从 signer 读取
        require(nonce == scorerNonces[signer], "CompliancePassport: invalid nonce");

        bytes32 structHash = keccak256(abi.encode(
            COMPLIANCE_CERT_TYPEHASH,
            signer,               // [V3] signer 纳入签名数据
            agentId,
            complianceLevel,
            evidenceHash,
            validUntil,
            nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address recoveredSigner = hash.recover(signature);

        require(recoveredSigner == signer, "CompliancePassport: signer mismatch");
        require(hasRole(SCORER_ROLE, recoveredSigner), "CompliancePassport: not scorer");

        // [V3 FIX] nonce 写入 signer (读写一致)
        scorerNonces[signer] = nonce + 1;

        // [V3 FIX] 从链上已有记录读取真实 riskScore，不再使用外部传入值
        (uint8 actualRiskScore,) = this.getCompositeRiskScore(agentId);

        certId = _nextCertId++;
        _certificates[certId] = ComplianceCertificate({
            certId: certId,
            agentId: agentId,
            riskScore: actualRiskScore,   // [V3 FIX] 使用链上真实评分
            complianceLevel: complianceLevel,
            evidenceHash: evidenceHash,
            validUntil: validUntil,
            issuedAt: block.timestamp,
            issuer: signer,
            revoked: false
        });

        _agentCertificates[agentId].push(certId);

        emit CertificateIssued(certId, agentId, actualRiskScore, complianceLevel, validUntil);
    }

    function revokeCertificate(uint256 certId, string calldata reason) external {
        ComplianceCertificate storage cert = _certificates[certId];
        require(cert.certId != 0, "CompliancePassport: cert not found");
        require(
            msg.sender == cert.issuer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CompliancePassport: unauthorized"
        );
        require(!cert.revoked, "CompliancePassport: already revoked");

        cert.revoked = true;
        emit CertificateRevoked(certId, reason);
    }

    // ========== 合规证明导出/验证 ==========

    function exportComplianceProof(uint256 agentId)
        external view
        returns (
            ComplianceSummary memory summary,
            bytes32 proofHash
        )
    {
        (uint8 compositeScore, uint256 scorerCount) = this.getCompositeRiskScore(agentId);

        uint256 validChecks = 0;
        uint256 totalChecks = uint256(type(ComplianceCheck).max) + 1;
        for (uint256 i = 0; i < totalChecks; i++) {
            ComplianceCheck ct = ComplianceCheck(i);
            ComplianceRecord[] storage records = _complianceRecords[agentId][ct];
            for (uint256 j = records.length; j > 0; j--) {
                if (records[j-1].passed &&
                    (records[j-1].validUntil == 0 || block.timestamp <= records[j-1].validUntil)) {
                    validChecks++;
                    break;
                }
            }
        }

        MandateStatus storage m = _mandates[agentId];
        bool hasActiveMandate = m.agentId != 0 && !m.frozen &&
                                block.timestamp <= m.mandateExpiry;

        uint256[] memory certIds = _agentCertificates[agentId];
        bool hasValidCert = false;
        for (uint256 i = certIds.length; i > 0; i--) {
            ComplianceCertificate storage c = _certificates[certIds[i-1]];
            if (!c.revoked && block.timestamp <= c.validUntil) {
                hasValidCert = true;
                break;
            }
        }

        uint8 level = _calculateComplianceLevel(
            compositeScore, validChecks, totalChecks, hasActiveMandate, hasValidCert
        );

        summary = ComplianceSummary({
            agentId: agentId,
            compositeRiskScore: compositeScore,
            complianceLevel: level,
            validChecks: validChecks,
            totalChecks: totalChecks,
            hasActiveMandate: hasActiveMandate,
            hasValidCertificate: hasValidCert,
            lastUpdated: block.timestamp
        });

        // [V3 FIX] proofHash 中包含动态 scorerCount (与 verifyComplianceProof 一致)
        proofHash = keccak256(abi.encode(
            summary,
            scorerCount,
            block.chainid,
            address(this)
        ));

        return (summary, proofHash);
    }

    /**
     * @notice 链下验证合规证明 (静态函数)
     * @dev [V3 FIX] 修复 verifyComplianceProof 永久失效漏洞:
     *      - 函数从 pure 改为 view (需要读取链上状态)
     *      - scorerCount 从硬编码 0 改为动态查询实际活跃评分者数量
     *      - 生成的 proofHash 与 exportComplianceProof 一致
     */
    function verifyComplianceProof(
        ComplianceSummary calldata summary,
        uint256 chainId,
        address passportContract,
        bytes32 expectedHash
    ) external view returns (bool) {
        // [V3 FIX] 动态查询实际活跃评分者数量，不再硬编码为 0
        uint256 scorerCount = _getActiveScorerCount(summary.agentId);

        bytes32 computedHash = keccak256(abi.encode(
            summary,
            scorerCount,    // [V3 FIX] 使用动态值替代硬编码 0
            chainId,
            passportContract
        ));
        return computedHash == expectedHash;
    }

    function meetsComplianceRequirement(
        uint256 agentId,
        uint8 maxRiskScore,
        ComplianceCheck[] calldata requiredChecks
    ) external view returns (bool) {
        (uint8 compositeScore,) = this.getCompositeRiskScore(agentId);
        if (compositeScore > maxRiskScore) return false;

        for (uint256 i = 0; i < requiredChecks.length; i++) {
            ComplianceRecord[] storage records = _complianceRecords[agentId][requiredChecks[i]];
            bool passed = false;
            for (uint256 j = records.length; j > 0; j--) {
                if (records[j-1].passed &&
                    (records[j-1].validUntil == 0 || block.timestamp <= records[j-1].validUntil)) {
                    passed = true;
                    break;
                }
            }
            if (!passed) return false;
        }

        return true;
    }

    // ========== 外部 Oracle 设置 ==========

    function setERC8126Oracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc8126Oracle = IERC8126RiskScore(oracle);
        emit OracleUpdated("ERC8126", oracle);
    }

    function setERC8226Oracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc8226Oracle = IERC8226Compliance(oracle);
        emit OracleUpdated("ERC8226", oracle);
    }

    // ========== 查询函数 ==========

    function getRiskScoreHistory(uint256 agentId)
        external view returns (RiskScoreRecord[] memory)
    {
        return _riskScores[agentId];
    }

    function getComplianceRecords(uint256 agentId, ComplianceCheck checkType)
        external view returns (ComplianceRecord[] memory)
    {
        return _complianceRecords[agentId][checkType];
    }

    function getCertificate(uint256 certId)
        external view returns (ComplianceCertificate memory)
    {
        return _certificates[certId];
    }

    function getAgentCertificateIds(uint256 agentId)
        external view returns (uint256[] memory)
    {
        return _agentCertificates[agentId];
    }

    function isValidCertificate(uint256 certId) external view returns (bool) {
        ComplianceCertificate storage c = _certificates[certId];
        if (c.certId == 0) return false;
        if (c.revoked) return false;
        if (block.timestamp > c.validUntil) return false;
        return true;
    }

    // ========== 管理函数 ==========

    function addScorer(address scorer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SCORER_ROLE, scorer);
    }

    function addComplianceOracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(COMPLIANCE_ORACLE_ROLE, oracle);
    }

    // ========== 内部函数 ==========

    function _requireAgentExists(uint256 agentId) internal view {
        address wallet = agentRegistry.getAgentWallet(agentId);
        require(wallet != address(0), "CompliancePassport: agent not found");
    }

    /**
     * @notice [V3 新增] 获取 Agent 的活跃评分者数量
     * @dev 用于 verifyComplianceProof 中动态计算 scorerCount
     *      统计逻辑与 getCompositeRiskScore 一致: 未撤销且未过期的评分记录数
     */
    function _getActiveScorerCount(uint256 agentId) internal view returns (uint256 count) {
        RiskScoreRecord[] storage records = _riskScores[agentId];
        for (uint256 i = 0; i < records.length; i++) {
            if (!records[i].revoked &&
                (records[i].validUntil == 0 || block.timestamp <= records[i].validUntil)) {
                count++;
            }
        }
    }

    function _calculateComplianceLevel(
        uint8 riskScore,
        uint256 validChecks,
        uint256 totalChecks,
        bool hasMandate,
        bool hasCert
    ) internal pure returns (uint8) {
        uint256 score = 0;

        if (riskScore <= 20) score += 30;
        else if (riskScore <= 40) score += 20;
        else if (riskScore <= 60) score += 10;

        if (totalChecks > 0) {
            score += (validChecks * 30) / totalChecks;
        }

        if (hasMandate) score += 20;
        if (hasCert) score += 20;

        if (score >= 90) return 5;
        if (score >= 70) return 4;
        if (score >= 50) return 3;
        if (score >= 30) return 2;
        if (score >= 10) return 1;
        return 0;
    }

    // ========== ERC-165 ==========

    function supportsInterface(bytes4 interfaceId)
        public view override(AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
