// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AgentRegistry
 * @author AGL Team
 * @notice ERC-8004 兼容的 Agent 身份注册合约
 * @dev 基于 ERC-721 with URIStorage，支持钱包地址绑定身份、多链身份聚合
 *
 * 架构层级: L1 — Identity Registration
 * 标准依赖: ERC-8004 (Trustless Agents), ERC-721, EIP-712
 *
 * 核心功能:
 *   1. 钱包地址 = 身份锚点 (Wallet-First Identity)
 *   2. ERC-721 NFT 代表 Agent 身份
 *   3. 支持多链身份聚合 (同一 Agent 跨链注册)
 *   4. 元数据系统支持能力声明、端点注册
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AgentRegistry is ERC721URIStorage, Ownable, EIP712 {
    using ECDSA for bytes32;

    // ========== 常量 ==========
    bytes32 private constant WALLET_BINDING_TYPEHASH = keccak256(
        "BindWallet(uint256 agentId,address wallet,uint256 nonce,uint256 deadline)"
    );

    // ========== 数据结构 ==========

    /// @notice Agent 链上身份信息
    struct AgentInfo {
        address owner;            // 身份拥有者 (EOA / Smart Wallet)
        address agentWallet;      // Agent 操作钱包 (经 EIP-712 签名验证)
        string agentURI;          // 指向 Agent Registration File 的 URI
        uint256 registeredAt;     // 注册时间戳
        bool active;              // 是否活跃
    }

    /// @notice 多链身份注册条目
    struct ChainRegistration {
        uint256 chainId;
        address registryAddress;
        uint256 agentId;
        bool verified;
    }

    /// @notice 元数据条目 (ERC-8004 兼容)
    struct MetadataEntry {
        string metadataKey;
        bytes metadataValue;
    }

    // ========== 状态变量 ==========

    uint256 private _nextAgentId;

    /// @notice agentId => Agent 信息
    mapping(uint256 => AgentInfo) internal _agents;

    /// @notice wallet address => agentId (反向索引，一个钱包只能绑定一个身份)
    mapping(address => uint256) public walletToAgent;

    /// @notice agentId => 链注册列表
    mapping(uint256 => ChainRegistration[]) public chainRegistrations;

    /// @notice agentId => metadataKey => metadataValue
    mapping(uint256 => mapping(string => bytes)) internal _metadata;

    /// @notice agentId => nonce (用于钱包绑定签名防重放)
    mapping(uint256 => uint256) public walletBindingNonce;

    // ========== 事件 ==========

    event AgentRegistered(
        uint256 indexed agentId,
        address indexed owner,
        string agentURI,
        uint256 timestamp
    );

    event WalletBound(
        uint256 indexed agentId,
        address indexed wallet,
        uint256 timestamp
    );

    event WalletUnbound(
        uint256 indexed agentId,
        address indexed wallet
    );

    event ChainRegistered(
        uint256 indexed agentId,
        uint256 chainId,
        address registryAddress,
        uint256 remoteAgentId
    );

    event MetadataSet(
        uint256 indexed agentId,
        string indexed indexedKey,
        string key,
        bytes value
    );

    event AgentStatusChanged(
        uint256 indexed agentId,
        bool active
    );

    // ========== 构造函数 ==========

    constructor()
        ERC721("AGL Agent Identity", "AGL-ID")
        EIP712("AGLAgentRegistry", "1")
        Ownable(msg.sender)
    {
        _nextAgentId = 1;
    }

    // ========== 注册函数 ==========

    /**
     * @notice 注册新的 Agent 身份
     * @param agentURI Agent Registration File 的 URI (IPFS / HTTPS / data URI)
     * @param metadata 附加的链上元数据
     * @return agentId 新分配的 Agent ID
     */
    function register(
        string calldata agentURI,
        MetadataEntry[] calldata metadata
    ) external returns (uint256 agentId) {
        agentId = _nextAgentId++;

        // Mint NFT
        _safeMint(msg.sender, agentId);

        // 设置 URI
        if (bytes(agentURI).length > 0) {
            _setTokenURI(agentId, agentURI);
        }

        // 存储 Agent 信息
        _agents[agentId] = AgentInfo({
            owner: msg.sender,
            agentWallet: address(0),  // 钱包需要后续绑定验证
            agentURI: agentURI,
            registeredAt: block.timestamp,
            active: true
        });

        // 设置元数据
        for (uint256 i = 0; i < metadata.length; i++) {
            _setMetadata(agentId, metadata[i].metadataKey, metadata[i].metadataValue);
        }

        // 注册当前链为第一链
        chainRegistrations[agentId].push(ChainRegistration({
            chainId: block.chainid,
            registryAddress: address(this),
            agentId: agentId,
            verified: true
        }));

        emit AgentRegistered(agentId, msg.sender, agentURI, block.timestamp);
    }

    /**
     * @notice 简化注册 (仅 URI)
     */
    function register(string calldata agentURI) external returns (uint256 agentId) {
        MetadataEntry[] memory empty;
        agentId = _nextAgentId++;

        _safeMint(msg.sender, agentId);

        if (bytes(agentURI).length > 0) {
            _setTokenURI(agentId, agentURI);
        }

        _agents[agentId] = AgentInfo({
            owner: msg.sender,
            agentWallet: address(0),
            agentURI: agentURI,
            registeredAt: block.timestamp,
            active: true
        });

        chainRegistrations[agentId].push(ChainRegistration({
            chainId: block.chainid,
            registryAddress: address(this),
            agentId: agentId,
            verified: true
        }));

        emit AgentRegistered(agentId, msg.sender, agentURI, block.timestamp);
    }

    /**
     * @notice 最简注册 (无 URI，后续设置)
     */
    function register() external returns (uint256 agentId) {
        agentId = _nextAgentId++;
        _safeMint(msg.sender, agentId);

        _agents[agentId] = AgentInfo({
            owner: msg.sender,
            agentWallet: address(0),
            agentURI: "",
            registeredAt: block.timestamp,
            active: true
        });

        chainRegistrations[agentId].push(ChainRegistration({
            chainId: block.chainid,
            registryAddress: address(this),
            agentId: agentId,
            verified: true
        }));

        emit AgentRegistered(agentId, msg.sender, "", block.timestamp);
    }

    // ========== 钱包绑定 (Wallet-First Identity) ==========

    /**
     * @notice 通过 EIP-712 签名绑定 Agent 操作钱包
     * @dev Agent 钱包拥有者签名证明对钱包的控制权
     * @param agentId Agent ID
     * @param wallet 要绑定的钱包地址
     * @param deadline 签名有效期
     * @param signature Agent 钱包的 EIP-712 签名
     */
    function bindWallet(
        uint256 agentId,
        address wallet,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(_exists(agentId), "AgentRegistry: agent does not exist");
        require(
            msg.sender == ownerOf(agentId) || isApprovedForAll(ownerOf(agentId), msg.sender),
            "AgentRegistry: not owner or approved"
        );
        require(wallet != address(0), "AgentRegistry: zero address");
        require(walletToAgent[wallet] == 0, "AgentRegistry: wallet already bound");
        require(block.timestamp <= deadline, "AgentRegistry: signature expired");

        // 验证 EIP-712 签名
        uint256 nonce = walletBindingNonce[agentId];
        bytes32 structHash = keccak256(abi.encode(
            WALLET_BINDING_TYPEHASH,
            agentId,
            wallet,
            nonce,
            deadline
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == wallet, "AgentRegistry: invalid signature");

        // 更新绑定
        walletBindingNonce[agentId] = nonce + 1;
        walletToAgent[wallet] = agentId;
        _agents[agentId].agentWallet = wallet;

        emit WalletBound(agentId, wallet, block.timestamp);
    }

    /**
     * @notice 解绑钱包
     */
    function unbindWallet(uint256 agentId) external {
        require(
            msg.sender == ownerOf(agentId) || isApprovedForAll(ownerOf(agentId), msg.sender),
            "AgentRegistry: not owner or approved"
        );
        address wallet = _agents[agentId].agentWallet;
        require(wallet != address(0), "AgentRegistry: no wallet bound");

        delete walletToAgent[wallet];
        _agents[agentId].agentWallet = address(0);

        emit WalletUnbound(agentId, wallet);
    }

    // ========== 多链身份聚合 ==========

    /**
     * @notice 注册跨链身份映射
     * @param agentId 本地 Agent ID
     * @param chainId 远端链 ID
     * @param registryAddress 远端注册合约地址
     * @param remoteAgentId 远端 Agent ID
     */
    function registerChainIdentity(
        uint256 agentId,
        uint256 chainId,
        address registryAddress,
        uint256 remoteAgentId
    ) external {
        require(_exists(agentId), "AgentRegistry: agent does not exist");
        require(
            msg.sender == ownerOf(agentId),
            "AgentRegistry: not owner"
        );

        chainRegistrations[agentId].push(ChainRegistration({
            chainId: chainId,
            registryAddress: registryAddress,
            agentId: remoteAgentId,
            verified: false  // 需链下验证后由管理员确认
        }));

        emit ChainRegistered(agentId, chainId, registryAddress, remoteAgentId);
    }

    /**
     * @notice 验证跨链注册 (管理员)
     */
    function verifyChainRegistration(
        uint256 agentId,
        uint256 index
    ) external onlyOwner {
        require(index < chainRegistrations[agentId].length, "AgentRegistry: invalid index");
        chainRegistrations[agentId][index].verified = true;
    }

    // ========== 元数据管理 ==========

    /**
     * @notice 设置 Agent 元数据
     * @dev `agentWallet` 为保留键，不可通过此方法设置
     */
    function setMetadata(
        uint256 agentId,
        string calldata key,
        bytes calldata value
    ) external {
        require(
            msg.sender == ownerOf(agentId) || isApprovedForAll(ownerOf(agentId), msg.sender),
            "AgentRegistry: not owner or approved"
        );
        require(
            keccak256(bytes(key)) != keccak256(bytes("agentWallet")),
            "AgentRegistry: reserved key"
        );
        _setMetadata(agentId, key, value);
    }

    function _setMetadata(
        uint256 agentId,
        string memory key,
        bytes memory value
    ) internal {
        _metadata[agentId][key] = value;
        emit MetadataSet(agentId, key, key, value);
    }

    /**
     * @notice 获取 Agent 元数据
     */
    function getMetadata(
        uint256 agentId,
        string calldata key
    ) external view returns (bytes memory) {
        return _metadata[agentId][key];
    }

    // ========== Agent URI 更新 ==========

    function setAgentURI(uint256 agentId, string calldata newURI) external {
        require(
            msg.sender == ownerOf(agentId) || isApprovedForAll(ownerOf(agentId), msg.sender),
            "AgentRegistry: not owner or approved"
        );
        _setTokenURI(agentId, newURI);
        _agents[agentId].agentURI = newURI;
    }

    // ========== Agent 状态管理 ==========

    function setAgentActive(uint256 agentId, bool active) external {
        require(
            msg.sender == ownerOf(agentId),
            "AgentRegistry: not owner"
        );
        _agents[agentId].active = active;
        emit AgentStatusChanged(agentId, active);
    }

    // ========== 查询函数 ==========

    function getAgentInfo(uint256 agentId) external view returns (AgentInfo memory) {
        require(_exists(agentId), "AgentRegistry: agent does not exist");
        return _agents[agentId];
    }

    function getAgentWallet(uint256 agentId) external view returns (address) {
        return _agents[agentId].agentWallet;
    }

    function getAgentByWallet(address wallet) external view returns (uint256) {
        return walletToAgent[wallet];
    }

    function getChainRegistrations(uint256 agentId)
        external
        view
        returns (ChainRegistration[] memory)
    {
        return chainRegistrations[agentId];
    }

    function getChainRegistrationCount(uint256 agentId) external view returns (uint256) {
        return chainRegistrations[agentId].length;
    }

    function totalAgents() external view returns (uint256) {
        return _nextAgentId - 1;
    }

    /**
     * @notice ERC-8004 兼容：通过钱包地址解析 Agent ID
     */
    function resolveAgentId(address wallet) external view returns (uint256) {
        return walletToAgent[wallet];
    }

    /**
     * @notice 检查地址是否为已注册的 Agent 钱包
     */
    function isRegisteredAgent(address wallet) external view returns (bool) {
        uint256 agentId = walletToAgent[wallet];
        return agentId != 0 && _agents[agentId].active;
    }

    // ========== ERC-165 ==========

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ========== 内部工具 ==========

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @notice 转账时清除钱包绑定 (ERC-8004 规范)
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address from)
    {
        address previousOwner = super._update(to, tokenId, auth);

        if (previousOwner != address(0) && to != address(0)) {
            // 转移时清除钱包绑定
            address wallet = _agents[tokenId].agentWallet;
            if (wallet != address(0)) {
                delete walletToAgent[wallet];
                _agents[tokenId].agentWallet = address(0);
                emit WalletUnbound(tokenId, wallet);
            }
            _agents[tokenId].owner = to;
        }

        return previousOwner;
    }
}
