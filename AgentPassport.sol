// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AgentPassport
 * @author AGL Team
 * @notice Agent 护照合约 — 存储 Agent 身份属性与验证者签发的 attestation
 * @dev 集成 ERC-8196 认证钱包、ERC-8004 身份解析
 *
 * 架构层级: L2 — Identity Attributes & Attestations
 * 标准依赖: ERC-8196 (Authenticated Wallet), ERC-8004 (Identity)
 *
 * 核心功能:
 *   1. 存储 Agent 的类型、能力、合规状态等属性
 *   2. 支持授权验证者签发 attestation (证明)
 *   3. 集成 ERC-8196 的 Policy 机制
 *   4. 护照数据可导出/可验证
 */

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAgentRegistry {
    function isRegisteredAgent(address wallet) external view returns (bool);
    function getAgentByWallet(address wallet) external view returns (uint256);
    function getAgentWallet(uint256 agentId) external view returns (address);
}

contract AgentPassport is EIP712, AccessControl {
    using ECDSA for bytes32;

    // ========== 角色 ==========
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // ========== EIP-712 类型 ==========
    bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
        "Attestation(uint256 agentId,uint8 attributeType,bytes32 attributeHash,uint256 validUntil,uint256 nonce)"
    );

    // ========== 数据结构 ==========

    /// @notice Agent 属性类型枚举
    enum AttributeType {
        AGENT_TYPE,       // Agent 类型 (0:通用, 1:交易, 2:社交, 3:数据, 4:开发)
        CAPABILITY,       // 能力声明
        COMPLIANCE,       // 合规状态
        VERIFICATION,     // 验证状态
        CUSTOM            // 自定义属性
    }

    /// @notice Agent 属性记录
    struct AgentAttribute {
        AttributeType attrType;
        bytes32 attrHash;           // keccak256 属性值哈希
        string rawValue;            // 原始值 (短字符串直接存储)
        uint256 issuedAt;
        uint256 validUntil;         // 0 = 永久有效
        address issuer;             // 签发者地址
        bool revoked;
    }

    /// @notice Attestation 记录 (验证者签发)
    struct Attestation {
        uint256 attestationId;
        uint256 agentId;
        address verifier;           // 验证者地址
        AttributeType attributeType;
        bytes32 attributeHash;      // 属性值哈希
        string schemaURI;           // 属性 schema 定义
        uint256 validUntil;         // 有效截止时间
        uint256 issuedAt;
        bool revoked;
    }

    /// @notice ERC-8196 策略记录
    struct AgentPolicy {
        bytes32 policyHash;
        uint256 agentId;
        address owner;
        address agent;
        uint256 validUntil;
        uint8 minVerificationScore; // ERC-8126 最低验证分数
        bool isActive;
    }

    // ========== 状态变量 ==========

    IAgentRegistry public immutable agentRegistry;
    uint256 private _nextAttestationId;

    /// @notice agentId => 属性列表
    mapping(uint256 => AgentAttribute[]) internal _attributes;

    /// @notice attestationId => Attestation
    mapping(uint256 => Attestation) internal _attestations;

    /// @notice agentId => attestation 列表
    mapping(uint256 => uint256[]) internal _agentAttestations;

    /// @notice agentId => 策略哈希列表
    mapping(uint256 => bytes32[]) internal _agentPolicies;

    /// @notice 策略哈希 => AgentPolicy
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

    /**
     * @notice 设置 Agent 属性 (仅 Registrar 或 Agent 拥有者)
     */
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

    /**
     * @notice 获取 Agent 属性列表
     */
    function getAttributes(uint256 agentId)
        external
        view
        returns (AgentAttribute[] memory)
    {
        return _attributes[agentId];
    }

    /**
     * @notice 获取指定类型的属性
     */
    function getAttributesByType(uint256 agentId, AttributeType attrType)
        external
        view
        returns (AgentAttribute[] memory)
    {
        // 计算匹配数量
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

    /**
     * @notice 验证者签发 attestation (链上直接签发)
     * @param agentId 目标 Agent ID
     * @param attributeType 属性类型
     * @param attributeValue 属性值
     * @param schemaURI 属性 schema URI
     * @param validUntil 有效截止时间
     */
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
     * @dev 验证者离线签名，任意方提交到链上
     */
    function issueAttestationBySignature(
        uint256 agentId,
        AttributeType attributeType,
        string calldata attributeValue,
        string calldata schemaURI,
        uint256 validUntil,
        uint256 deadline,
        bytes calldata signature
    ) external returns (uint256 attestationId) {
        _requireAgentActive(agentId);
        require(validUntil > block.timestamp, "AgentPassport: invalid validity");
        require(block.timestamp <= deadline, "AgentPassport: signature expired");

        // 恢复签名者
        uint256 nonce = verifierNonce[msg.sender];  // 提交者作为 nonce 的一部分
        bytes32 attrHash = keccak256(abi.encodePacked(attributeValue));

        bytes32 structHash = keccak256(abi.encode(
            ATTESTATION_TYPEHASH,
            agentId,
            uint8(attributeType),
            attrHash,
            validUntil,
            nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);

        require(hasRole(VERIFIER_ROLE, signer), "AgentPassport: signer not verifier");

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

    /**
     * @notice 撤销 attestation
     */
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

    /**
     * @notice 获取 attestation 详情
     */
    function getAttestation(uint256 attestationId)
        external
        view
        returns (Attestation memory)
    {
        return _attestations[attestationId];
    }

    /**
     * @notice 获取 Agent 的所有 attestation IDs
     */
    function getAgentAttestationIds(uint256 agentId)
        external
        view
        returns (uint256[] memory)
    {
        return _agentAttestations[agentId];
    }

    /**
     * @notice 验证 attestation 是否当前有效
     */
    function isValidAttestation(uint256 attestationId) external view returns (bool) {
        Attestation storage att = _attestations[attestationId];
        if (att.attestationId == 0) return false;
        if (att.revoked) return false;
        if (att.validUntil != 0 && block.timestamp > att.validUntil) return false;
        return true;
    }

    // ========== ERC-8196 Policy 集成 ==========

    /**
     * @notice 注册 ERC-8196 兼容策略
     * @dev 绑定 Agent 钱包的 Policy 到护照，实现身份-策略关联
     */
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

    /**
     * @notice 撤销策略
     */
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

    /**
     * @notice 查询 Agent 的策略
     */
    function getPolicy(bytes32 policyHash) external view returns (AgentPolicy memory) {
        return _policies[policyHash];
    }

    function getAgentPolicies(uint256 agentId) external view returns (bytes32[] memory) {
        return _agentPolicies[agentId];
    }

    // ========== 护照导出 ==========

    /**
     * @notice 导出 Agent 护照摘要 (链上可读)
     * @dev 返回护照核心数据供链下系统使用
     */
    function exportPassport(uint256 agentId)
        external
        view
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

    function _requireAgentActive(uint256 agentId) internal view {
        address wallet = agentRegistry.getAgentWallet(agentId);
        require(wallet != address(0), "AgentPassport: no wallet bound");
    }

    function _isAgentOwner(uint256 agentId, address account) internal view returns (bool) {
        // 检查是否为 AgentRegistry NFT 的 owner
        try IERC721(address(agentRegistry)).ownerOf(agentId) returns (address owner) {
            return owner == account;
        } catch {
            return false;
        }
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
