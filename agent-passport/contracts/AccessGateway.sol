// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AccessGateway
 * @author AGL Team
 * @notice 访问网关合约 — Agent 通过钱包签名生成 access token 登录 Web2 平台
 * @dev V0 概念设计：链下验证 + 链上锚定，OAuth-like 流程
 *
 * 架构层级: L3 — Access Layer
 * 标准依赖: ERC-8004 (Identity), ERC-8196 (Policy-bound execution)
 *
 * 核心流程:
 *   1. Agent 用钱包签名生成 AccessRequest
 *   2. 链下 Gateway 服务验证签名 + 检查 passport 状态
 *   3. 签发短期 access token (链下 JWT-like)
 *   4. 会话锚定到链上 (可选，用于审计)
 *   5. 支持 OAuth-like 授权码流程
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

    // ========== 数据结构 ==========

    /// @notice 访问请求状态
    enum AccessState {
        NONE,           // 未请求
        REQUESTED,      // 已请求，待验证
        ACTIVE,         // 活跃
        EXPIRED,        // 已过期
        REVOKED         // 已撤销
    }

    /// @notice 访问会话
    struct AccessSession {
        bytes32 sessionId;
        address agentWallet;
        uint256 agentId;
        string platformId;         // 目标平台标识
        string[] scopes;           // 请求的权限范围
        AccessState state;
        uint256 issuedAt;
        uint256 expiresAt;
        bytes32 anchorHash;        // 链上锚定哈希
    }

    /// @notice 授权码 (OAuth-like 流程)
    struct AuthorizationCode {
        bytes32 codeHash;
        address agentWallet;
        uint256 agentId;
        string platformId;
        string redirectURI;
        string codeChallenge;      // PKCE challenge
        uint256 nonce;
        uint256 expiresAt;
        bool used;
        bool issued;
    }

    /// @notice 平台注册信息
    struct PlatformInfo {
        string platformId;
        address operator;          // 平台运营方地址
        string callbackURI;        // 回调地址
        bool active;
        string[] supportedScopes;  // 支持的权限范围
    }

    // ========== 状态变量 ==========

    IAgentRegistryForGateway public immutable agentRegistry;
    IAgentPassportForGateway public immutable agentPassport;

    /// @notice Gateway 服务地址 (链下验证服务的链上身份)
    address public gatewayService;

    /// @notice sessionId => AccessSession
    mapping(bytes32 => AccessSession) internal _sessions;

    /// @notice agentWallet => 活跃会话列表
    mapping(address => bytes32[]) internal _agentSessions;

    /// @notice codeHash => AuthorizationCode
    mapping(bytes32 => AuthorizationCode) internal _authCodes;

    /// @notice platformId => PlatformInfo
    mapping(string => PlatformInfo) internal _platforms;

    /// @notice agentWallet => nonce
    mapping(address => uint256) public accessNonces;

    /// @notice 管理员
    address public admin;

    // ========== 事件 ==========

    event AccessRequested(
        bytes32 indexed sessionId,
        address indexed agentWallet,
        uint256 indexed agentId,
        string platformId,
        uint256 expiresAt
    );

    event AccessGranted(
        bytes32 indexed sessionId,
        address indexed agentWallet,
        string platformId,
        bytes32 anchorHash
    );

    event AccessRevoked(
        bytes32 indexed sessionId,
        string reason
    );

    event AuthCodeIssued(
        bytes32 indexed codeHash,
        address indexed agentWallet,
        string platformId,
        uint256 expiresAt
    );

    event AuthCodeExchanged(
        bytes32 indexed codeHash,
        bytes32 indexed sessionId
    );

    event PlatformRegistered(
        string platformId,
        address indexed operator
    );

    event SessionAnchored(
        bytes32 indexed sessionId,
        bytes32 anchorHash
    );

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

    // ========== Agent 访问请求 (Proof-of-Agent) ==========

    /**
     * @notice Agent 提交访问请求 (钱包签名)
     * @dev Agent 用私钥签名 AccessRequest，提交到链上或链下 Gateway
     * @param platformId 目标平台标识
     * @param scopes 请求的权限范围
     * @param expiry 请求有效期
     * @param signature Agent 钱包的 EIP-712 签名
     * @return sessionId 会话 ID
     */
    function requestAccess(
        string calldata platformId,
        string[] calldata scopes,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bytes32 sessionId) {
        require(expiry > block.timestamp, "AccessGateway: expired");
        require(bytes(platformId).length > 0, "AccessGateway: empty platform");
        require(scopes.length > 0, "AccessGateway: no scopes");

        // 验证签名者是否为注册的 Agent 钱包
        uint256 nonce = accessNonces[msg.sender];
        uint256 agentId = agentRegistry.getAgentByWallet(msg.sender);
        require(agentId != 0, "AccessGateway: not registered agent");

        bytes32 structHash = keccak256(abi.encode(
            ACCESS_REQUEST_TYPEHASH,
            msg.sender,
            agentId,
            platformId,
            keccak256(abi.encode(scopes)),
            nonce,
            expiry
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == msg.sender, "AccessGateway: invalid signature");

        accessNonces[msg.sender] = nonce + 1;

        // 创建会话
        sessionId = keccak256(abi.encodePacked(
            msg.sender, agentId, platformId, nonce, block.timestamp
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

    /**
     * @notice Gateway 服务批准访问 (链下验证后调用)
     * @dev 仅 Gateway 服务可调用，代表链下验证通过
     */
    function grantAccess(
        bytes32 sessionId,
        bytes32 anchorHash
    ) external {
        require(msg.sender == gatewayService, "AccessGateway: not gateway");
        AccessSession storage session = _sessions[sessionId];
        require(session.state == AccessState.REQUESTED, "AccessGateway: invalid state");
        require(block.timestamp <= session.expiresAt, "AccessGateway: session expired");

        session.state = AccessState.ACTIVE;
        session.anchorHash = anchorHash;

        emit AccessGranted(sessionId, session.agentWallet, session.platformId, anchorHash);
        emit SessionAnchored(sessionId, anchorHash);
    }

    /**
     * @notice Agent 自行撤销访问
     */
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

    /**
     * @notice Agent 请求授权码 (PKCE 增强)
     * @dev 类似 OAuth2 的 authorization_code flow + PKCE
     */
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
            AUTH_CODE_TYPEHASH,
            msg.sender,
            agentId,
            platformId,
            redirectURI,
            codeChallenge,
            nonce,
            expiry
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

    /**
     * @notice 交换授权码 (Gateway 服务验证 PKCE 后调用)
     * @dev 类似 OAuth2 token exchange
     * @param codeHash 授权码哈希
     * @param codeVerifier PKCE code_verifier
     * @return sessionId 创建的会话 ID
     */
    function exchangeAuthCode(
        bytes32 codeHash,
        string calldata codeVerifier
    ) external returns (bytes32 sessionId) {
        require(msg.sender == gatewayService, "AccessGateway: not gateway");
        AuthorizationCode storage code = _authCodes[codeHash];
        require(code.issued, "AccessGateway: code not found");
        require(!code.used, "AccessGateway: code already used");
        require(block.timestamp <= code.expiresAt, "AccessGateway: code expired");

        // PKCE 验证: SHA256(codeVerifier) == codeChallenge
        bytes32 challenge = sha256(abi.encodePacked(codeVerifier));
        require(
            keccak256(abi.encodePacked(challenge)) ==
            keccak256(abi.encodePacked(code.codeChallenge)),
            "AccessGateway: PKCE mismatch"
        );

        code.used = true;

        // 创建会话
        sessionId = keccak256(abi.encodePacked(
            code.agentWallet, code.agentId, code.platformId, code.nonce, block.timestamp
        ));

        _sessions[sessionId] = AccessSession({
            sessionId: sessionId,
            agentWallet: code.agentWallet,
            agentId: code.agentId,
            platformId: code.platformId,
            scopes: new string[](0),  // 由平台方定义
            state: AccessState.ACTIVE,
            issuedAt: block.timestamp,
            expiresAt: block.timestamp + 3600,  // 1 小时默认
            anchorHash: bytes32(0)
        });

        _agentSessions[code.agentWallet].push(sessionId);

        emit AuthCodeExchanged(codeHash, sessionId);
        emit AccessGranted(sessionId, code.agentWallet, code.platformId, bytes32(0));
    }

    // ========== 平台管理 ==========

    /**
     * @notice 注册平台
     */
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

    /**
     * @notice 获取平台信息
     */
    function getPlatform(string calldata platformId)
        external
        view
        returns (PlatformInfo memory)
    {
        return _platforms[platformId];
    }

    // ========== 查询函数 ==========

    /**
     * @notice 获取会话状态
     */
    function getSession(bytes32 sessionId) external view returns (AccessSession memory) {
        return _sessions[sessionId];
    }

    /**
     * @notice 获取 Agent 的活跃会话数量
     */
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

    /**
     * @notice 验证 Agent 的 Proof-of-Agent (替代 CAPTCHA)
     * @dev 链下服务可调用此函数验证 Agent 身份
     * @param agentWallet Agent 钱包地址
     * @param message 验证消息
     * @param signature Agent 签名
     * @return isValid 身份是否有效
     * @return agentId Agent ID
     */
    function verifyProofOfAgent(
        address agentWallet,
        bytes32 message,
        bytes calldata signature
    ) external view returns (bool isValid, uint256 agentId) {
        // 1. 验证签名
        address signer = message.toEthSignedMessageHash().recover(signature);
        if (signer != agentWallet) return (false, 0);

        // 2. 验证是否为注册的 Agent
        agentId = agentRegistry.getAgentByWallet(agentWallet);
        if (agentId == 0) return (false, 0);

        // 3. 验证 Agent 钱包绑定
        address boundWallet = agentRegistry.getAgentWallet(agentId);
        if (boundWallet != agentWallet) return (false, 0);

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
