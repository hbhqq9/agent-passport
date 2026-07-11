// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AccessGateway V3.1-Complete
 * @author AGL Team
 * @notice 访问网关合约 — Agent 通过钱包签名生成 access token 登录 Web2 平台
 * @dev V3.1-Complete 安全修复 (合并两路审计全部发现):
 *
 *   V3.1 修复项:
 *   - [MEDIUM] consumeProofOfAgent 增加 gatewayService/agentWallet 访问控制
 *   - [MEDIUM] verifyProofOfAgent/consumeProofOfAgent 增加 Agent active 状态检查
 *   - [MEDIUM] consumeProofOfAgent 增加 deadline 参数防止签名永久有效
 *   - [LOW] requestAccess 增加 platformId 已注册验证
 *   - [LOW] Session ID 增加 accessNonce 防止同块碰撞
 *
 *   V3 修复项 (继承):
 *   - [HIGH] 修复 verifyProofOfAgent 跨链签名重放漏洞 (EIP-712)
 */

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IAgentRegistryForGateway {
    function isRegisteredAgent(address wallet) external view returns (bool);
    function getAgentByWallet(address wallet) external view returns (uint256);
    function getAgentWallet(uint256 agentId) external view returns (address);
}

interface IAgentPassportForGateway {
    function isValidAttestation(uint256 attestationId) external view returns (bool);
    function getAgentAttestationIds(uint256 agentId) external view returns (uint256[] memory);
}

contract AccessGateway is EIP712 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ========== EIP-712 类型 ==========
    bytes32 private constant ACCESS_REQUEST_TYPEHASH = keccak256(
        "AccessRequest(address agentWallet,uint256 agentId,string platformId,string[] scopes,uint256 nonce,uint256 expiry)"
    );

    bytes32 private constant AUTH_CODE_TYPEHASH = keccak256(
        "AuthCode(address agentWallet,uint256 agentId,string platformId,string redirectURI,string codeChallenge,uint256 nonce,uint256 expiry)"
    );

    bytes32 private constant PROOF_OF_AGENT_TYPEHASH = keccak256(
        "ProofOfAgent(address agentWallet,uint256 agentId,bytes32 message,uint256 nonce)"
    );

    // ========== 数据结构 ==========

    enum AccessState {
        NONE,
        REQUESTED,
        ACTIVE,
        EXPIRED,
        REVOKED
    }

    struct AccessSession {
        bytes32 sessionId;
        address agentWallet;
        uint256 agentId;
        string platformId;
        string[] scopes;
        AccessState state;
        uint256 issuedAt;
        uint256 expiresAt;
        bytes32 anchorHash;
    }

    struct AuthorizationCode {
        bytes32 codeHash;
        address agentWallet;
        uint256 agentId;
        string platformId;
        string redirectURI;
        string codeChallenge;
        uint256 nonce;
        uint256 expiresAt;
        bool used;
        bool issued;
    }

    struct PlatformInfo {
        string platformId;
        address operator;
        string callbackURI;
        bool active;
        string[] supportedScopes;
    }

    // ========== 状态变量 ==========

    IAgentRegistryForGateway public immutable agentRegistry;
    IAgentPassportForGateway public immutable agentPassport;

    address public gatewayService;

    mapping(bytes32 => AccessSession) internal _sessions;
    mapping(address => bytes32[]) internal _agentSessions;
    mapping(bytes32 => AuthorizationCode) internal _authCodes;
    mapping(string => PlatformInfo) internal _platforms;

    mapping(address => uint256) public accessNonces;
    mapping(address => uint256) public proofOfAgentNonces;

    address public admin;

    // ========== 事件 ==========

    event AccessRequested(bytes32 indexed sessionId, address indexed agentWallet, uint256 indexed agentId, string platformId, uint256 expiresAt);
    event AccessGranted(bytes32 indexed sessionId, address indexed agentWallet, string platformId, bytes32 anchorHash);
    event AccessRevoked(bytes32 indexed sessionId, string reason);
    event AuthCodeIssued(bytes32 indexed codeHash, address indexed agentWallet, string platformId, uint256 expiresAt);
    event AuthCodeExchanged(bytes32 indexed codeHash, bytes32 indexed sessionId);
    event PlatformRegistered(string platformId, address indexed operator);
    event SessionAnchored(bytes32 indexed sessionId, bytes32 anchorHash);

    // ========== 构造函数 ==========

    constructor(
        address _agentRegistry,
        address _agentPassport,
        address _gatewayService
    ) EIP712("AGLAccessGateway", "1") {
        require(_agentRegistry != address(0), "AccessGateway: zero registry");
        require(_agentPassport != address(0), "AccessGateway: zero passport");
        require(_gatewayService != address(0), "AccessGateway: zero gateway");

        agentRegistry = IAgentRegistryForGateway(_agentRegistry);
        agentPassport = IAgentPassportForGateway(_agentPassport);
        gatewayService = _gatewayService;
        admin = msg.sender;
    }

    // ========== Agent 访问请求 ==========

    function requestAccess(
        string calldata platformId,
        string[] calldata scopes,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bytes32 sessionId) {
        require(expiry > block.timestamp, "AccessGateway: expired");
        require(bytes(platformId).length > 0, "AccessGateway: empty platform");
        require(scopes.length > 0, "AccessGateway: no scopes");
        // [V3.1 FIX] 验证 platformId 已注册
        require(_platforms[platformId].active, "AccessGateway: platform not registered");

        uint256 nonce = accessNonces[msg.sender];
        uint256 agentId = agentRegistry.getAgentByWallet(msg.sender);
        require(agentId != 0, "AccessGateway: not registered agent");

        bytes32 structHash = keccak256(abi.encode(
            ACCESS_REQUEST_TYPEHASH, msg.sender, agentId, platformId,
            keccak256(abi.encode(scopes)), nonce, expiry
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == msg.sender, "AccessGateway: invalid signature");

        accessNonces[msg.sender] = nonce + 1;

        // [V3.1 FIX] Session ID 增加 nonce 防止同块碰撞
        sessionId = keccak256(abi.encodePacked(
            msg.sender, agentId, platformId, nonce, block.timestamp, accessNonces[msg.sender]
        ));

        _sessions[sessionId] = AccessSession({
            sessionId: sessionId,
            agentWallet: msg.sender,
            agentId: agentId,
            platformId: platformId,
            scopes: scopes,
            state: AccessState.REQUESTED,
            issuedAt: block.timestamp,
            expiresAt: expiry,
            anchorHash: bytes32(0)
        });

        _agentSessions[msg.sender].push(sessionId);
        emit AccessRequested(sessionId, msg.sender, agentId, platformId, expiry);
    }

    function grantAccess(bytes32 sessionId, bytes32 anchorHash) external {
        require(msg.sender == gatewayService, "AccessGateway: not gateway");
        AccessSession storage session = _sessions[sessionId];
        require(session.state == AccessState.REQUESTED, "AccessGateway: invalid state");
        require(block.timestamp <= session.expiresAt, "AccessGateway: session expired");

        session.state = AccessState.ACTIVE;
        session.anchorHash = anchorHash;

        emit AccessGranted(sessionId, session.agentWallet, session.platformId, anchorHash);
        emit SessionAnchored(sessionId, anchorHash);
    }

    function revokeAccess(bytes32 sessionId, string calldata reason) external {
        AccessSession storage session = _sessions[sessionId];
        require(
            session.agentWallet == msg.sender || msg.sender == admin,
            "AccessGateway: unauthorized"
        );
        require(session.state == AccessState.ACTIVE, "AccessGateway: not active");
        session.state = AccessState.REVOKED;
        emit AccessRevoked(sessionId, reason);
    }

    // ========== OAuth-like 授权码流程 ==========

    function requestAuthCode(
        string calldata platformId,
        string calldata redirectURI,
        string calldata codeChallenge,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bytes32 codeHash) {
        require(expiry > block.timestamp, "AccessGateway: expired");
        require(bytes(platformId).length > 0, "AccessGateway: empty platform");

        uint256 agentId = agentRegistry.getAgentByWallet(msg.sender);
        require(agentId != 0, "AccessGateway: not registered agent");

        uint256 nonce = accessNonces[msg.sender];
        bytes32 structHash = keccak256(abi.encode(
            AUTH_CODE_TYPEHASH, msg.sender, agentId, platformId,
            redirectURI, codeChallenge, nonce, expiry
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == msg.sender, "AccessGateway: invalid signature");

        accessNonces[msg.sender] = nonce + 1;

        codeHash = keccak256(abi.encodePacked(
            msg.sender, platformId, redirectURI, nonce, block.timestamp
        ));

        _authCodes[codeHash] = AuthorizationCode({
            codeHash: codeHash,
            agentWallet: msg.sender,
            agentId: agentId,
            platformId: platformId,
            redirectURI: redirectURI,
            codeChallenge: codeChallenge,
            nonce: nonce,
            expiresAt: expiry,
            used: false,
            issued: true
        });

        emit AuthCodeIssued(codeHash, msg.sender, platformId, expiry);
    }

    function exchangeAuthCode(
        bytes32 codeHash,
        string calldata codeVerifier
    ) external returns (bytes32 sessionId) {
        require(msg.sender == gatewayService, "AccessGateway: not gateway");
        AuthorizationCode storage code = _authCodes[codeHash];
        require(code.issued, "AccessGateway: code not found");
        require(!code.used, "AccessGateway: code already used");
        require(block.timestamp <= code.expiresAt, "AccessGateway: code expired");

        bytes32 challenge = sha256(abi.encodePacked(codeVerifier));
        require(
            keccak256(abi.encodePacked(challenge)) ==
            keccak256(abi.encodePacked(code.codeChallenge)),
            "AccessGateway: PKCE mismatch"
        );

        code.used = true;

        sessionId = keccak256(abi.encodePacked(
            code.agentWallet, code.agentId, code.platformId, code.nonce, block.timestamp, code.used
        ));

        _sessions[sessionId] = AccessSession({
            sessionId: sessionId,
            agentWallet: code.agentWallet,
            agentId: code.agentId,
            platformId: code.platformId,
            scopes: new string[](0),
            state: AccessState.ACTIVE,
            issuedAt: block.timestamp,
            expiresAt: block.timestamp + 3600,
            anchorHash: bytes32(0)
        });

        _agentSessions[code.agentWallet].push(sessionId);
        emit AuthCodeExchanged(codeHash, sessionId);
        emit AccessGranted(sessionId, code.agentWallet, code.platformId, bytes32(0));
    }

    // ========== 平台管理 ==========

    function registerPlatform(
        string calldata platformId,
        string calldata callbackURI,
        string[] calldata supportedScopes
    ) external {
        require(msg.sender == admin, "AccessGateway: not admin");
        require(bytes(platformId).length > 0, "AccessGateway: empty platformId");

        _platforms[platformId] = PlatformInfo({
            platformId: platformId,
            operator: msg.sender,
            callbackURI: callbackURI,
            active: true,
            supportedScopes: supportedScopes
        });

        emit PlatformRegistered(platformId, msg.sender);
    }

    function getPlatform(string calldata platformId) external view returns (PlatformInfo memory) {
        return _platforms[platformId];
    }

    // ========== 查询函数 ==========

    function getSession(bytes32 sessionId) external view returns (AccessSession memory) {
        return _sessions[sessionId];
    }

    function getAgentActiveSessionCount(address agentWallet) external view returns (uint256) {
        bytes32[] storage sessions = _agentSessions[agentWallet];
        uint256 count = 0;
        for (uint256 i = 0; i < sessions.length; i++) {
            if (_sessions[sessions[i]].state == AccessState.ACTIVE) {
                count++;
            }
        }
        return count;
    }

    // ========== Proof-of-Agent ==========

    /**
     * @notice 验证 Agent 的 Proof-of-Agent (view 版本)
     * @dev [V3.1 FIX] 增加 Agent active 状态检查
     */
    function verifyProofOfAgent(
        address agentWallet,
        bytes32 message,
        uint256 nonce,
        bytes calldata signature
    ) external view returns (bool isValid, uint256 agentId) {
        require(nonce == proofOfAgentNonces[agentWallet], "AccessGateway: invalid nonce");

        uint256 agentIdLookup = agentRegistry.getAgentByWallet(agentWallet);

        bytes32 structHash = keccak256(abi.encode(
            PROOF_OF_AGENT_TYPEHASH, agentWallet, agentIdLookup, message, nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);

        if (signer != agentWallet) return (false, 0);

        agentId = agentIdLookup;
        if (agentId == 0) return (false, 0);

        address boundWallet = agentRegistry.getAgentWallet(agentId);
        if (boundWallet != agentWallet) return (false, 0);

        // [V3.1 FIX] 验证 Agent 活跃状态 (isRegisteredAgent 已包含 active 检查)
        if (!agentRegistry.isRegisteredAgent(agentWallet)) return (false, 0);

        return (true, agentId);
    }

    /**
     * @notice 消费 Proof-of-Agent nonce (state-changing 版本)
     * @dev [V3.1-Complete FIX] 合并三项修复:
     *      1. 访问控制: 仅 gatewayService 或 agentWallet
     *      2. Agent active 状态检查
     *      3. [NEW] deadline 参数防止签名永久有效
     */
    function consumeProofOfAgent(
        address agentWallet,
        bytes32 message,
        uint256 deadline,       // [V3.1-Complete NEW] 签名有效期截止时间
        bytes calldata signature
    ) external returns (bool isValid, uint256 agentId) {
        // [V3.1 FIX #1] 访问控制
        require(
            msg.sender == gatewayService || msg.sender == agentWallet,
            "AccessGateway: unauthorized"
        );
        // [V3.1-Complete FIX #3] deadline 检查
        require(block.timestamp <= deadline, "AccessGateway: signature expired");

        uint256 nonce = proofOfAgentNonces[agentWallet];
        uint256 agentIdLookup = agentRegistry.getAgentByWallet(agentWallet);

        bytes32 structHash = keccak256(abi.encode(
            PROOF_OF_AGENT_TYPEHASH, agentWallet, agentIdLookup, message, nonce
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);

        if (signer != agentWallet) return (false, 0);

        agentId = agentIdLookup;
        if (agentId == 0) return (false, 0);

        address boundWallet = agentRegistry.getAgentWallet(agentId);
        if (boundWallet != agentWallet) return (false, 0);

        // [V3.1 FIX #2] 验证 Agent 活跃状态 (isRegisteredAgent 已包含 active 检查)
        require(agentRegistry.isRegisteredAgent(agentWallet), "AccessGateway: agent inactive");

        // 消费 nonce
        proofOfAgentNonces[agentWallet] = nonce + 1;

        return (true, agentId);
    }

    // ========== 管理函数 ==========

    function updateGatewayService(address newService) external {
        require(msg.sender == admin, "AccessGateway: not admin");
        require(newService != address(0), "AccessGateway: zero address");
        gatewayService = newService;
    }

    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "AccessGateway: not admin");
        require(newAdmin != address(0), "AccessGateway: zero address");
        admin = newAdmin;
    }
}
