// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CompliancePassport
 * @author AGL Team
 * @notice 合规护照合约 — 集成 ERC-8126 风险评分与 ERC-8226 合规状态
 * @dev 合规证明可导出/可验证，支持可移植的合规状态
 *
 * 架构层级: L3 — Compliance Layer
 * 标准依赖:
 *   - ERC-8126 (Agent Verification / Risk Score, Finalized)
 *   - ERC-8226 (Regulated Agent Mandate / Compliance, our AGL)
 *   - ERC-8004 (Agent Identity)
 *
 * 核心功能:
 *   1. 集成 ERC-8126 的 0-100 风险评分体系
 *   2. 集成 ERC-8226 的合规委托状态
 *   3. 合规证明可导出为可验证凭证
 *   4. 支持多验证者评分聚合
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

/// @notice ERC-8126 风险评分接口 (兼容标准)
interface IERC8126RiskScore {
    function getLatestRiskScore(uint256 agentId)
        external
        view
        returns (uint8 score, uint256 updatedAt, address scorer);
}

/// @notice ERC-8226 合规委托接口 (兼容标准)
interface IERC8226Compliance {
    function getActivePrincipal(uint256 agentId)
        external
        view
        returns (address principal, uint256 mandateExpiry);

    function isCompliant(uint256 agentId) external view returns (bool);
}

contract CompliancePassport is EIP712, AccessControl {
    using ECDSA for bytes32;

    // ========== 角色 ==========
    bytes32 public constant SCORER_ROLE = keccak256("SCORER_ROLE");
    bytes32 public constant COMPLIANCE_ORACLE_ROLE = keccak256("COMPLIANCE_ORACLE_ROLE");

    // ========== EIP-712 类型 ==========
    bytes32 private constant COMPLIANCE_CERT_TYPEHASH = keccak256(
        "ComplianceCertificate(uint256 agentId,uint8 riskScore,uint8 complianceLevel,bytes32 evidenceHash,uint256 validUntil,uint256 nonce)"
    );

    // ========== 数据结构 ==========

    /// @notice 风险评分记录
    struct RiskScoreRecord {
        uint8 score;                  // 0-100, 0=最安全, 100=最高风险
        address scorer;               // 评分者
        uint256 scoredAt;             // 评分时间
        uint256 validUntil;           // 有效期
        bytes32 evidenceHash;         // 评分证据哈希 (ZK proof hash / audit data hash)
        string scorerURI;             // 评分者信息 URI
        bool revoked;
    }

    /// @notice 合规检查项
    enum ComplianceCheck {
        IDENTITY_VERIFIED,     // 身份已验证
        WALLET_CLEAN,          // 钱包无黑名单/制裁记录
        BEHAVIOR_NORMAL,       // 行为模式正常 (非 bot)
        CODE_VERIFIED,         // 智能合约代码已审计
        MANDATE_VALID,         // ERC-8226 委托有效
        KYC_CLEARED            // KYC 已通过
    }

    /// @notice 合规状态记录
    struct ComplianceRecord {
        ComplianceCheck checkType;
        bool passed;
        address verifier;
        uint256 verifiedAt;
        uint256 validUntil;
        bytes32 evidenceHash;
        string details;          // 附加说明
    }

    /// @notice 合规证书 (可导出凭证)
    struct ComplianceCertificate {
        uint256 certId;
        uint256 agentId;
        uint8 riskScore;           // 综合风险评分
        uint8 complianceLevel;     // 合规等级 (0-5)
        bytes32 evidenceHash;      // 完整证据包哈希
        uint256 validUntil;
        uint256 issuedAt;
        address issuer;
        bool revoked;
    }

    /// @notice ERC-8226 委托状态
    struct MandateStatus {
        uint256 agentId;
        address principal;          // 委托人 (经 KYC 验证)
        uint256 mandateExpiry;
        uint256 financialCap;       // 财务上限
        bytes32 scopeHash;          // 授权范围哈希
        bool frozen;                // 是否被冻结
        uint256 lastVerified;
    }

    /// @notice Agent 合规摘要
    struct ComplianceSummary {
        uint256 agentId;
        uint8 compositeRiskScore;   // 综合风险评分 (多评分者聚合)
        uint8 complianceLevel;      // 合规等级
        uint256 validChecks;        // 通过的检查项数
        uint256 totalChecks;        // 总检查项数
        bool hasActiveMandate;      // 是否有有效委托
        bool hasValidCertificate;   // 是否有有效证书
        uint256 lastUpdated;
    }

    // ========== 状态变量 ==========

    IAgentRegistryForCompliance public immutable agentRegistry;
    IERC8126RiskScore public erc8126Oracle;       // 外部 ERC-8126 评分源 (可选)
    IERC8226Compliance public erc8226Oracle;      // 外部 ERC-8226 合规源 (可选)

    uint256 private _nextCertId;

    /// @notice agentId => 风险评分记录列表
    mapping(uint256 => RiskScoreRecord[]) internal _riskScores;

    /// @notice agentId => ComplianceCheck => 记录列表
    mapping(uint256 => mapping(ComplianceCheck => ComplianceRecord[])) internal _complianceRecords;

    /// @notice certId => 合规证书
    mapping(uint256 => ComplianceCertificate) internal _certificates;

    /// @notice agentId => 证书 ID 列表
    mapping(uint256 => uint256[]) internal _agentCertificates;

    /// @notice agentId => 委托状态
    mapping(uint256 => MandateStatus) internal _mandates;

    /// @notice 签名 nonce
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

    /**
     * @notice 记录风险评分 (SCORER_ROLE)
     * @dev 实现 ERC-8126 兼容的评分体系: 0=最安全, 100=最高风险
     * @param agentId Agent ID
     * @param score 风险评分 (0-100)
     * @param validUntil 有效期
     * @param evidenceHash 证据哈希 (ZK proof hash / 审计数据哈希)
     * @param scorerURI 评分者信息
     */
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
     */
    function recordRiskScoreBySignature(
        uint256 agentId,
        uint8 score,
        uint256 validUntil,
        bytes32 evidenceHash,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(score <= 100, "CompliancePassport: score out of range");
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");
        require(block.timestamp <= deadline, "CompliancePassport: expired");
        _requireAgentExists(agentId);

        uint256 nonce = scorerNonces[msg.sender];
        bytes32 structHash = keccak256(abi.encode(
            keccak256("RiskScore(uint256 agentId,uint8 score,uint256 validUntil,bytes32 evidenceHash,uint256 nonce)"),
            agentId, score, validUntil, evidenceHash, nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);

        require(hasRole(SCORER_ROLE, signer), "CompliancePassport: not scorer");
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

    /**
     * @notice 获取 Agent 最新风险评分 (ERC-8126 兼容)
     */
    function getLatestRiskScore(uint256 agentId)
        external
        view
        returns (uint8 score, uint256 updatedAt, address scorer)
    {
        RiskScoreRecord[] storage records = _riskScores[agentId];
        if (records.length == 0) return (255, 0, address(0));

        // 从后往前找最新有效评分
        for (uint256 i = records.length; i > 0; i--) {
            RiskScoreRecord storage r = records[i - 1];
            if (!r.revoked && (r.validUntil == 0 || block.timestamp <= r.validUntil)) {
                return (r.score, r.scoredAt, r.scorer);
            }
        }
        return (255, 0, address(0));
    }

    /**
     * @notice 获取综合风险评分 (多评分者加权平均)
     */
    function getCompositeRiskScore(uint256 agentId)
        external
        view
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

    /**
     * @notice 记录合规检查通过
     */
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

    /**
     * @notice 检查某项合规是否通过
     */
    function isComplianceCheckPassed(uint256 agentId, ComplianceCheck checkType)
        external
        view
        returns (bool)
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

    /**
     * @notice 记录 ERC-8226 委托状态
     * @dev 与 AGL 合约的合规委托集成
     */
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

    /**
     * @notice 冻结委托 (监管触发)
     */
    function freezeMandate(uint256 agentId, string calldata reason)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MandateStatus storage mandate = _mandates[agentId];
        require(mandate.agentId != 0, "CompliancePassport: no mandate");
        require(!mandate.frozen, "CompliancePassport: already frozen");

        mandate.frozen = true;
        emit MandateFrozen(agentId, reason);
    }

    /**
     * @notice 检查委托是否有效
     */
    function isMandateValid(uint256 agentId) external view returns (bool) {
        MandateStatus storage m = _mandates[agentId];
        if (m.agentId == 0) return false;
        if (m.frozen) return false;
        if (block.timestamp > m.mandateExpiry) return false;
        return true;
    }

    /**
     * @notice 获取委托状态
     */
    function getMandateStatus(uint256 agentId) external view returns (MandateStatus memory) {
        return _mandates[agentId];
    }

    // ========== 合规证书 (可导出凭证) ==========

    /**
     * @notice 签发合规证书
     * @dev 基于当前所有评分和检查结果生成综合证书
     */
    function issueCertificate(
        uint256 agentId,
        uint8 complianceLevel,
        bytes32 evidenceHash,
        uint256 validUntil
    ) external onlyRole(SCORER_ROLE) returns (uint256 certId) {
        _requireAgentExists(agentId);
        require(complianceLevel <= 5, "CompliancePassport: level out of range");
        require(validUntil > block.timestamp, "CompliancePassport: invalid validity");

        // 获取当前综合评分
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
     */
    function issueCertificateBySignature(
        uint256 agentId,
        uint8 riskScore,
        uint8 complianceLevel,
        bytes32 evidenceHash,
        uint256 validUntil,
        uint256 deadline,
        bytes calldata signature
    ) external returns (uint256 certId) {
        _requireAgentExists(agentId);
        require(block.timestamp <= deadline, "CompliancePassport: expired");

        uint256 nonce = scorerNonces[msg.sender];
        bytes32 structHash = keccak256(abi.encode(
            COMPLIANCE_CERT_TYPEHASH,
            agentId, riskScore, complianceLevel, evidenceHash, validUntil, nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);

        require(hasRole(SCORER_ROLE, signer), "CompliancePassport: not scorer");
        scorerNonces[signer] = nonce + 1;

        certId = _nextCertId++;
        _certificates[certId] = ComplianceCertificate({
            certId: certId,
            agentId: agentId,
            riskScore: riskScore,
            complianceLevel: complianceLevel,
            evidenceHash: evidenceHash,
            validUntil: validUntil,
            issuedAt: block.timestamp,
            issuer: signer,
            revoked: false
        });

        _agentCertificates[agentId].push(certId);

        emit CertificateIssued(certId, agentId, riskScore, complianceLevel, validUntil);
    }

    /**
     * @notice 撤销证书
     */
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

    /**
     * @notice 导出完整合规证明包
     * @dev 生成可供任何第三方验证的合规数据摘要
     */
    function exportComplianceProof(uint256 agentId)
        external
        view
        returns (
            ComplianceSummary memory summary,
            bytes32 proofHash
        )
    {
        // 综合评分
        (uint8 compositeScore, uint256 scorerCount) = this.getCompositeRiskScore(agentId);

        // 统计合规检查
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

        // 委托状态
        MandateStatus storage m = _mandates[agentId];
        bool hasActiveMandate = m.agentId != 0 && !m.frozen &&
                                block.timestamp <= m.mandateExpiry;

        // 最新证书
        uint256[] memory certIds = _agentCertificates[agentId];
        bool hasValidCert = false;
        for (uint256 i = certIds.length; i > 0; i--) {
            ComplianceCertificate storage c = _certificates[certIds[i-1]];
            if (!c.revoked && block.timestamp <= c.validUntil) {
                hasValidCert = true;
                break;
            }
        }

        // 计算合规等级
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

        // 生成证明哈希
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
     * @dev 供第三方 DApp 验证合规证明的完整性
     */
    function verifyComplianceProof(
        ComplianceSummary calldata summary,
        uint256 chainId,
        address passportContract,
        bytes32 expectedHash
    ) external pure returns (bool) {
        bytes32 computedHash = keccak256(abi.encode(
            summary,
            0,  // scorerCount placeholder
            chainId,
            passportContract
        ));
        return computedHash == expectedHash;
    }

    /**
     * @notice 检查 Agent 是否满足最低合规要求
     * @param agentId Agent ID
     * @param maxRiskScore 最大可接受风险评分
     * @param requiredChecks 必须通过的合规检查类型
     */
    function meetsComplianceRequirement(
        uint256 agentId,
        uint8 maxRiskScore,
        ComplianceCheck[] calldata requiredChecks
    ) external view returns (bool) {
        // 检查风险评分
        (uint8 compositeScore,) = this.getCompositeRiskScore(agentId);
        if (compositeScore > maxRiskScore) return false;

        // 检查必须的合规检查
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

    /**
     * @notice 设置 ERC-8126 外部评分 Oracle
     */
    function setERC8126Oracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc8126Oracle = IERC8126RiskScore(oracle);
        emit OracleUpdated("ERC8126", oracle);
    }

    /**
     * @notice 设置 ERC-8226 外部合规 Oracle
     */
    function setERC8226Oracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc8226Oracle = IERC8226Compliance(oracle);
        emit OracleUpdated("ERC8226", oracle);
    }

    // ========== 查询函数 ==========

    function getRiskScoreHistory(uint256 agentId)
        external
        view
        returns (RiskScoreRecord[] memory)
    {
        return _riskScores[agentId];
    }

    function getComplianceRecords(uint256 agentId, ComplianceCheck checkType)
        external
        view
        returns (ComplianceRecord[] memory)
    {
        return _complianceRecords[agentId][checkType];
    }

    function getCertificate(uint256 certId)
        external
        view
        returns (ComplianceCertificate memory)
    {
        return _certificates[certId];
    }

    function getAgentCertificateIds(uint256 agentId)
        external
        view
        returns (uint256[] memory)
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

    function _calculateComplianceLevel(
        uint8 riskScore,
        uint256 validChecks,
        uint256 totalChecks,
        bool hasMandate,
        bool hasCert
    ) internal pure returns (uint8) {
        uint256 score = 0;

        // 风险评分贡献 (0-30 分)
        if (riskScore <= 20) score += 30;
        else if (riskScore <= 40) score += 20;
        else if (riskScore <= 60) score += 10;

        // 合规检查贡献 (0-30 分)
        if (totalChecks > 0) {
            score += (validChecks * 30) / totalChecks;
        }

        // 委托贡献 (0-20 分)
        if (hasMandate) score += 20;

        // 证书贡献 (0-20 分)
        if (hasCert) score += 20;

        // 映射到 0-5 等级
        if (score >= 90) return 5;   // Fully Compliant
        if (score >= 70) return 4;   // Mostly Compliant
        if (score >= 50) return 3;   // Partially Compliant
        if (score >= 30) return 2;   // Minimally Compliant
        if (score >= 10) return 1;   // Non-Compliant
        return 0;                     // Unverified
    }

    // ========== ERC-165 ==========

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
