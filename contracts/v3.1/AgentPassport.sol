// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AgentPassport V3
 * @author AGL Team
 * @notice Agent 护照合约 — 存储 Agent 身份属性与验证者签发的 attestation
 * @dev 集成 ERC-8196 认证钱包、ERC-8004 身份解析
 *
 * 架构层级: L2 — Identity Attributes & Attestations
 * 标准依赖: ERC-8196 (Authenticated Wallet), ERC-8004 (Identity)
 *
 * V3.1 安全修复:
 *   - [MEDIUM] _requireAgentActive 增加 Agent active 状态检查
 *
 * V3 安全修复 (继承):
 *   - [CRITICAL] 修复 EIP-712 Nonce 读写错位漏洞
 *     原代码: nonce 从 msg.sender 读取、写入 signer → 同一签名可被不同提交者无限重放
 *     修复: ATTESTATION_TYPEHASH 增加 signer 字段，nonce 统一从 signer 读取/写入
 *     新增参数: signer (验证者地址), nonce (当前 nonce)
 */

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAgentRegistry {
    function isRegisteredAgent(address wallet) external view returns (bool);
    function getAgentByWallet(address wallet) external view returns (uint256);
    function getAgentWallet(uint256 agentId) external view returns (address);
    // [V3.1 FIX] 新增: 获取 Agent 信息以检查 active 状态
    function getAgentInfo(uint256 agentId) external view returns (
        address owner, address agentWallet, string memory agentURI,
        uint256 registeredAt, bool active
    );
}

contract AgentPassport is EIP712, AccessControl {
    using ECDSA for bytes32;

    // ========== 角色 ==========
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // ========== EIP-712 类型 ==========
    // [V3 FIX] 增加 signer 字段，将 nonce 与 signer 绑定
    bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
        "Attestation(address signer,uint256 agentId,uint8 attributeType,bytes32 attributeHash,uint256 validUntil,uint256 nonce)"
    );

    // ========== 数据结构 ==========

    enum AttributeType {
        AGENT_TYPE,       // 0:通用, 1:交易, 2:社交, 3:数据, 4:开发
        CAPABILITY,
        COMPLIANCE,
        VERIFICATION,
        CUSTOM
    }

    struct AgentAttribute {
        AttributeType attrType;
        bytes32 attrHash;
        string rawValue;
        uint256 issuedAt;
        uint256 validUntil;
        address issuer;
        bool revoked;
    }

    struct Attestation {
        uint256 attestationId;
        uint256 agentId;
        address verifier;
        AttributeType attributeType;
        bytes32 attributeHash;
        string schemaURI;
        uint256 validUntil;
        uint256 issuedAt;
        bool revoked;
    }

    struct AgentPolicy {
        bytes32 policyHash;
        uint256 agentId;
        address owner;
        address agent;
        uint256 validUntil;
        uint8 minVerificationScore;
        bool isActive;
    }

    // ========== 状态变量 ==========

    IAgentRegistry public immutable agentRegistry;
    uint256 private _nextAttestationId;

    mapping(uint256 => AgentAttribute[]) internal _attributes;
    mapping(uint256 => Attestation) internal _attestations;
    mapping(uint256 => uint256[]) internal _agentAttestations;
    mapping(uint256 => bytes32[]) internal _agentPolicies;
    mapping(bytes32 => AgentPolicy) internal _policies;

    /// @notice 验证者 nonce (防重放)
    mapping(address => uint256) public verifierNonce;

    // ========== 事件 ==========

    event AttributeSet(
        uint256 indexed agentId,
        AttributeType indexed attrType,
        bytes32 attrHash,
        string rawValue,
        uint256 validUntil
    );

    event AttestationIssued(
        uint256 indexed attestationId,
        uint256 indexed agentId,
        address indexed verifier,
        AttributeType attributeType,
        bytes32 attributeHash,
        uint256 validUntil
    );

    event AttestationRevoked(
        uint256 indexed attestationId,
        string reason
    );

    event PolicyRegistered(
        bytes32 indexed policyHash,
        uint256 indexed agentId,
        address owner,
        address agent,
        uint256 validUntil
    );

    event PolicyRevoked(
        bytes32 indexed policyHash,
        string reason
    );

    // ========== 构造函数 ==========

    constructor(address _agentRegistry)
        EIP712("AGLAgentPassport", "1")
    {
        require(_agentRegistry != address(0), "AgentPassport: zero registry");
        agentRegistry = IAgentRegistry(_agentRegistry);
        _nextAttestationId = 1;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
    }

    // ========== 属性管理 ==========

    function setAttribute(
        uint256 agentId,
        AttributeType attrType,
        string calldata rawValue,
        uint256 validUntil
    ) external {
        _requireAgentActive(agentId);
        require(
            hasRole(REGISTRAR_ROLE, msg.sender) || _isAgentOwner(agentId, msg.sender),
            "AgentPassport: unauthorized"
        );

        bytes32 attrHash = keccak256(abi.encodePacked(rawValue));

        _attributes[agentId].push(AgentAttribute({
            attrType: attrType,
            attrHash: attrHash,
            rawValue: rawValue,
            issuedAt: block.timestamp,
            validUntil: validUntil,
            issuer: msg.sender,
            revoked: false
        }));

        emit AttributeSet(agentId, attrType, attrHash, rawValue, validUntil);
    }

    function getAttributes(uint256 agentId)
        external view returns (AgentAttribute[] memory)
    {
        return _attributes[agentId];
    }

    function getAttributesByType(uint256 agentId, AttributeType attrType)
        external view returns (AgentAttribute[] memory)
    {
        uint256 count = 0;
        AgentAttribute[] storage allAttrs = _attributes[agentId];
        for (uint256 i = 0; i < allAttrs.length; i++) {
            if (allAttrs[i].attrType == attrType && !allAttrs[i].revoked) {
                count++;
            }
        }

        AgentAttribute[] memory result = new AgentAttribute[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < allAttrs.length; i++) {
            if (allAttrs[i].attrType == attrType && !allAttrs[i].revoked) {
                result[idx] = allAttrs[i];
                idx++;
            }
        }
        return result;
    }

    // ========== 验证者 Attestation ==========

    function issueAttestation(
        uint256 agentId,
        AttributeType attributeType,
        string calldata attributeValue,
        string calldata schemaURI,
        uint256 validUntil
    ) external onlyRole(VERIFIER_ROLE) returns (uint256 attestationId) {
        _requireAgentActive(agentId);
        require(validUntil > block.timestamp, "AgentPassport: invalid validity");

        attestationId = _nextAttestationId++;
        bytes32 attrHash = keccak256(abi.encodePacked(attributeValue));

        _attestations[attestationId] = Attestation({
            attestationId: attestationId,
            agentId: agentId,
            verifier: msg.sender,
            attributeType: attributeType,
            attributeHash: attrHash,
            schemaURI: schemaURI,
            validUntil: validUntil,
            issuedAt: block.timestamp,
            revoked: false
        });

        _agentAttestations[agentId].push(attestationId);

        emit AttestationIssued(
            attestationId, agentId, msg.sender,
            attributeType, attrHash, validUntil
        );
    }

    /**
     * @notice 通过 EIP-712 签名签发 attestation (链下签名 + 链上提交)
     * @dev [V3 FIX] 修复 nonce 读写错位漏洞:
     *      - 新增 signer 和 nonce 参数，由提交者提供
     *      - nonce 必须等于 verifierNonce[signer]，否则 revert
     *      - signer 地址纳入 EIP-712 签名数据，与 nonce 绑定
     *      - nonce 统一从 signer 读取、写入 signer
     * @param signer 验证者 (签名者) 地址 — [V3 新增]
     * @param nonce 当前 nonce 值 — [V3 新增]
     */
    function issueAttestationBySignature(
        uint256 agentId,
        AttributeType attributeType,
        string calldata attributeValue,
        string calldata schemaURI,
        uint256 validUntil,
        uint256 deadline,
        bytes calldata signature,
        address signer,       // [V3] 签名者地址
        uint256 nonce         // [V3] 签名者当前 nonce
    ) external returns (uint256 attestationId) {
        _requireAgentActive(agentId);
        require(validUntil > block.timestamp, "AgentPassport: invalid validity");
        require(block.timestamp <= deadline, "AgentPassport: signature expired");

        // [V3 FIX] nonce 从 signer 读取，与签名中的 signer 绑定
        require(nonce == verifierNonce[signer], "AgentPassport: invalid nonce");

        bytes32 attrHash = keccak256(abi.encodePacked(attributeValue));

        bytes32 structHash = keccak256(abi.encode(
            ATTESTATION_TYPEHASH,
            signer,       // [V3] signer 纳入签名数据
            agentId,
            uint8(attributeType),
            attrHash,
            validUntil,
            nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address recoveredSigner = hash.recover(signature);

        require(recoveredSigner == signer, "AgentPassport: signer mismatch");
        require(hasRole(VERIFIER_ROLE, recoveredSigner), "AgentPassport: signer not verifier");

        // [V3 FIX] nonce 写入 signer (读写一致)
        verifierNonce[signer] = nonce + 1;

        attestationId = _nextAttestationId++;

        _attestations[attestationId] = Attestation({
            attestationId: attestationId,
            agentId: agentId,
            verifier: signer,
            attributeType: attributeType,
            attributeHash: attrHash,
            schemaURI: schemaURI,
            validUntil: validUntil,
            issuedAt: block.timestamp,
            revoked: false
        });

        _agentAttestations[agentId].push(attestationId);

        emit AttestationIssued(
            attestationId, agentId, signer,
            attributeType, attrHash, validUntil
        );
    }

    function revokeAttestation(uint256 attestationId, string calldata reason) external {
        Attestation storage att = _attestations[attestationId];
        require(att.attestationId != 0, "AgentPassport: attestation not found");
        require(
            msg.sender == att.verifier || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "AgentPassport: unauthorized"
        );
        require(!att.revoked, "AgentPassport: already revoked");

        att.revoked = true;
        emit AttestationRevoked(attestationId, reason);
    }

    function getAttestation(uint256 attestationId)
        external view returns (Attestation memory)
    {
        return _attestations[attestationId];
    }

    function getAgentAttestationIds(uint256 agentId)
        external view returns (uint256[] memory)
    {
        return _agentAttestations[agentId];
    }

    function isValidAttestation(uint256 attestationId) external view returns (bool) {
        Attestation storage att = _attestations[attestationId];
        if (att.attestationId == 0) return false;
        if (att.revoked) return false;
        if (att.validUntil != 0 && block.timestamp > att.validUntil) return false;
        return true;
    }

    // ========== ERC-8196 Policy 集成 ==========

    function registerPolicy(
        uint256 agentId,
        address agentWallet,
        uint256 validUntil,
        uint8 minVerificationScore
    ) external returns (bytes32 policyHash) {
        _requireAgentActive(agentId);
        require(
            msg.sender == agentWallet || _isAgentOwner(agentId, msg.sender),
            "AgentPassport: unauthorized"
        );
        require(validUntil > block.timestamp, "AgentPassport: invalid validity");

        policyHash = keccak256(abi.encodePacked(
            agentId, agentWallet, validUntil, minVerificationScore, block.timestamp
        ));

        _policies[policyHash] = AgentPolicy({
            policyHash: policyHash,
            agentId: agentId,
            owner: msg.sender,
            agent: agentWallet,
            validUntil: validUntil,
            minVerificationScore: minVerificationScore,
            isActive: true
        });

        _agentPolicies[agentId].push(policyHash);

        emit PolicyRegistered(policyHash, agentId, msg.sender, agentWallet, validUntil);
    }

    function revokePolicy(bytes32 policyHash, string calldata reason) external {
        AgentPolicy storage policy = _policies[policyHash];
        require(policy.isActive, "AgentPassport: policy not active");
        require(
            msg.sender == policy.owner || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "AgentPassport: unauthorized"
        );

        policy.isActive = false;
        emit PolicyRevoked(policyHash, reason);
    }

    function getPolicy(bytes32 policyHash) external view returns (AgentPolicy memory) {
        return _policies[policyHash];
    }

    function getAgentPolicies(uint256 agentId) external view returns (bytes32[] memory) {
        return _agentPolicies[agentId];
    }

    // ========== 护照导出 ==========

    function exportPassport(uint256 agentId)
        external view
        returns (
            address agentWallet,
            uint256 activeAttestationCount,
            uint256 totalAttestationCount,
            uint256 policyCount,
            bool hasActivePolicy
        )
    {
        address wallet = agentRegistry.getAgentWallet(agentId);
        uint256[] memory attIds = _agentAttestations[agentId];

        uint256 activeCount = 0;
        for (uint256 i = 0; i < attIds.length; i++) {
            Attestation storage att = _attestations[attIds[i]];
            if (!att.revoked && (att.validUntil == 0 || block.timestamp <= att.validUntil)) {
                activeCount++;
            }
        }

        bytes32[] memory policyHashes = _agentPolicies[agentId];
        bool hasActive = false;
        for (uint256 i = 0; i < policyHashes.length; i++) {
            if (_policies[policyHashes[i]].isActive) {
                hasActive = true;
                break;
            }
        }

        return (wallet, activeCount, attIds.length, policyHashes.length, hasActive);
    }

    // ========== 管理员函数 ==========

    function addVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VERIFIER_ROLE, verifier);
    }

    function removeVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VERIFIER_ROLE, verifier);
    }

    // ========== 内部函数 ==========

    // [V3.1 FIX] 重命名并增加 active 状态检查
    function _requireAgentActive(uint256 agentId) internal view {
        address wallet = agentRegistry.getAgentWallet(agentId);
        require(wallet != address(0), "AgentPassport: no wallet bound");
        // [V3.1] 检查 Agent 活跃状态
        (,,,, bool active) = agentRegistry.getAgentInfo(agentId);
        require(active, "AgentPassport: agent inactive");
    }

    function _isAgentOwner(uint256 agentId, address account) internal view returns (bool) {
        try IERC721(address(agentRegistry)).ownerOf(agentId) returns (address owner) {
            return owner == account;
        } catch {
            return false;
        }
    }

    // ========== ERC-165 ==========

    function supportsInterface(bytes4 interfaceId)
        public view override(AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
