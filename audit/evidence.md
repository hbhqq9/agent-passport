# Agent Passport Security Audit — Evidence File

**审计日期**: 2026-07-08
**审计范围**: AgentRegistry, AgentPassport, CompliancePassport, AccessGateway (Base Mainnet)

---

## E-01: EIP-712 Nonce 读写错位 — AgentPassport.issueAttestationBySignature

**来源**: AgentPassport.sol L196-L213
**声明**: `issueAttestationBySignature` 中 nonce 从 `msg.sender`（提交者）读取，却写入 `signer`（签名者），导致同一提交者可无限重放同一签名

**原始代码**:
```solidity
// L199: nonce 从 msg.sender 读取
uint256 nonce = verifierNonce[msg.sender];

// L200-L207: 用此 nonce 构造 structHash 并验证签名
bytes32 structHash = keccak256(abi.encode(
    ATTESTATION_TYPEHASH, agentId, uint8(attributeType),
    attrHash, validUntil, nonce
));
bytes32 hash = _hashTypedDataV4(structHash);
address signer = hash.recover(signature);

// L210: nonce 更新写入 signer，而非 msg.sender
verifierNonce[signer] = nonce + 1;
```

**攻击向量**:
1. Verifier V 为提交者 S 签名 attestation，nonce = verifierNonce[S] = 0
2. S 提交，签名验证通过，verifierNonce[V] = 0+1 = 1，verifierNonce[S] 不变仍为 0
3. S 可用同一签名再次提交，nonce 仍读 verifierNonce[S] = 0，签名仍有效
4. 每次重放创建新的 attestationId，产生重复 attestation

**影响**: 无限签名重放 → 重复 attestation → 虚增 attestation 计数 → 操纵合规指标

---

## E-02: EIP-712 Nonce 读写错位 — CompliancePassport.recordRiskScoreBySignature

**来源**: CompliancePassport.sol L175-L195
**声明**: 与 E-01 相同的 nonce 错位 bug，影响风险评分签名提交

**原始代码**:
```solidity
uint256 nonce = scorerNonces[msg.sender];  // 读 msg.sender 的 nonce
// ... 签名验证使用此 nonce
scorerNonces[signer] = nonce + 1;          // 写入 signer 的 nonce
```

**攻击向量**: 同 E-01，提交者可重放风险评分签名

**影响**: 重复风险评分记录 → 操纵综合评分计算（简单平均被重复记录稀释/放大）

---

## E-03: EIP-712 Nonce 读写错位 — CompliancePassport.issueCertificateBySignature

**来源**: CompliancePassport.sol L285-L305
**声明**: 同 E-01/E-02 的 nonce 错位 bug，影响合规证书签名签发

**原始代码**:
```solidity
uint256 nonce = scorerNonces[msg.sender];  // 读 msg.sender 的 nonce
// ... 签名验证
scorerNonces[signer] = nonce + 1;          // 写入 signer 的 nonce
```

**攻击向量**: 同 E-01

**影响**: 重复合规证书签发 → 合规状态不可靠

---

## E-04: verifyProofOfAgent 跨链签名重放

**来源**: AccessGateway.sol L263-L277
**声明**: `verifyProofOfAgent` 使用 `toEthSignedMessageHash`（personal_sign 风格），未绑定 chainId 或合约地址

**原始代码**:
```solidity
function verifyProofOfAgent(
    address agentWallet,
    bytes32 message,
    bytes calldata signature
) external view returns (bool isValid, uint256 agentId) {
    address signer = message.toEthSignedMessageHash().recover(signature);
    if (signer != agentWallet) return (false, 0);
    // ...
}
```

**攻击向量**:
1. Agent 在 Base Mainnet 签名 message → 验证通过
2. 同一签名在 Ethereum Mainnet / Polygon / 其他 EVM 链上的同名合约也验证通过
3. 链下服务若仅依赖此函数验证，无法区分签名来源链

**影响**: Proof-of-Agent 可跨链伪造 → 未授权访问 Web2 平台

---

## E-05: issueCertificateBySignature 允许任意风险评分

**来源**: CompliancePassport.sol L272-L305
**声明**: `issueCertificate` 内部计算综合评分，但 `issueCertificateBySignature` 直接接受 `riskScore` 参数

**对比代码**:
```solidity
// issueCertificate — 内部计算
(uint8 compositeScore,) = this.getCompositeRiskScore(agentId);
_certificates[certId] = ComplianceCertificate({
    riskScore: compositeScore,  // 使用计算值
    // ...
});

// issueCertificateBySignature — 外部传入
function issueCertificateBySignature(
    // ...
    uint8 riskScore,            // 任意值！
    // ...
) {
    _certificates[certId] = ComplianceCertificate({
        riskScore: riskScore,   // 直接使用传入值
        // ...
    });
}
```

**攻击向量**: SCORER_ROLE 持有者可通过 `issueCertificateBySignature` 签发 riskScore=0 的证书，绕过实际风险评估

**影响**: 合规证书风险评分可被伪造 → 合规绕过

---

## E-06: verifyComplianceProof 永远验证失败

**来源**: CompliancePassport.sol L353-L365
**声明**: 验证函数硬编码 scorerCount=0，但导出函数使用实际 scorerCount

**对比代码**:
```solidity
// exportComplianceProof
proofHash = keccak256(abi.encode(
    summary,
    scorerCount,        // 实际值（如 3）
    block.chainid,
    address(this)
));

// verifyComplianceProof
bytes32 computedHash = keccak256(abi.encode(
    summary,
    0,                  // 硬编码 0！
    chainId,
    passportContract
));
```

**影响**: 合规证明验证功能完全失效 → 第三方无法链上验证合规证明

---

## E-07: Deployer 单点控制 — 无多签/时间锁

**来源**: DEPLOYMENT_RECORD_V0.md
**声明**: 单一地址 `0x903f5C71D87FCAb1FAC236F02Be94EF95Fa0Ea3B` 持有全部合约的所有管理员角色

**角色列表**:
- AgentRegistry: Ownable owner
- AgentPassport: DEFAULT_ADMIN_ROLE + REGISTRAR_ROLE + VERIFIER_ROLE
- CompliancePassport: DEFAULT_ADMIN_ROLE + SCORER_ROLE + COMPLIANCE_ORACLE_ROLE
- AccessGateway: admin (单地址)

**影响**: 私钥泄露 → 全系统接管；无时间锁 → 无法应急响应

---

## E-08: AgentRegistry._update NFT 销毁后状态残留

**来源**: AgentRegistry.sol L258-L270
**声明**: NFT 销毁（to=address(0)）时跳过 `_agents` 更新，导致残留数据

**原始代码**:
```solidity
function _update(address to, uint256 tokenId, address auth)
    internal override returns (address from)
{
    address previousOwner = super._update(to, tokenId, auth);
    if (previousOwner != address(0) && to != address(0)) {
        // 仅在非销毁时更新
        address wallet = _agents[tokenId].agentWallet;
        if (wallet != address(0)) {
            delete walletToAgent[wallet];
            _agents[tokenId].agentWallet = address(0);
        }
        _agents[tokenId].owner = to;
    }
    // 当 to == address(0)（销毁），_agents[tokenId] 不清理
    return previousOwner;
}
```

**影响**: 销毁后的 agentId 仍有 _agents 数据，getAgentInfo 返回残留信息；walletToAgent 可能残留绑定

---

## E-09: isApprovedForAll 授权范围过大

**来源**: AgentRegistry.sol bindWallet/unbindWallet/setMetadata/setAgentURI
**声明**: 这些函数同时允许 owner 和 isApprovedForAll 的 operator 调用

**影响**: NFT 市场上架时，operator（如 OpenSea）可绑定/解绑钱包、修改 URI 和元数据

---

## E-10: AccessGateway admin 无两步转移

**来源**: AccessGateway.sol L244-L248
**声明**: `transferAdmin` 直接设置新 admin，无 pending 确认机制

**原始代码**:
```solidity
function transferAdmin(address newAdmin) external {
    require(msg.sender == admin, "AccessGateway: not admin");
    require(newAdmin != address(0), "AccessGateway: zero address");
    admin = newAdmin;  // 直接转移，无确认步骤
}
```

**影响**: 误转到错误地址 → 合约永久失去管理权

---

## E-11: PKCE 实现不符合 RFC 7636

**来源**: AccessGateway.sol L215-L222
**声明**: PKCE 验证使用 `sha256(abi.encodePacked(codeVerifier))` 而非标准 `BASE64URL(SHA256(ASCII(code_verifier)))`

**原始代码**:
```solidity
bytes32 challenge = sha256(abi.encodePacked(codeVerifier));
require(
    keccak256(abi.encodePacked(challenge)) ==
    keccak256(abi.encodePacked(code.codeChallenge)),
    "AccessGateway: PKCE mismatch"
);
```

**影响**: 与标准 OAuth2/PKCE 客户端不兼容；依赖链下实现一致性

---

## E-12: 无界数组增长 → 视图函数 Gas 耗尽

**来源**: 多处
**声明**: 以下映射存储无界数组，大量数据时视图函数超时

| 合约 | 映射 | 影响 |
|------|------|------|
| AgentRegistry | chainRegistrations[agentId] | getChainRegistrations |
| AgentPassport | _attributes[agentId] | getAttributesByType |
| AgentPassport | _agentAttestations[agentId] | exportPassport |
| CompliancePassport | _riskScores[agentId] | getCompositeRiskScore |
| CompliancePassport | _complianceRecords[agentId][checkType] | isComplianceCheckPassed |
| AccessGateway | _agentSessions[agentWallet] | getAgentActiveSessionCount |

**影响**: 大量记录后视图函数可能 OOG，影响链下读取

---

## E-13: URI 注入风险

**来源**: AgentRegistry.sol setAgentURI, AgentPassport.sol schemaURI, CompliancePassport.sol scorerURI
**声明**: URI 字段无验证，可指向恶意内容

**影响**: 下游系统解析 URI 时可能遭受内容替换攻击

---

## E-14: 链上敏感数据泄露

**来源**: AgentPassport rawValue, CompliancePassport details
**声明**: 属性原始值和合规详情以明文存储在链上

**影响**: 个人信息、商业机密等一旦写入不可删除，违反 GDPR 等隐私法规

---

## E-15: CompliancePassport 外部自调用

**来源**: CompliancePassport.sol L259, L322, L386
**声明**: `this.getCompositeRiskScore(agentId)` 使用 `this.` 前缀进行外部调用

**影响**: 不必要的 gas 开销；若 _riskScores 数组极大，可能导致 issueCertificate 交易 OOG

---

## E-16: AccessGateway 会话过期未强制执行

**来源**: AccessGateway.sol
**声明**: 会话有 expiresAt 字段，但 revokeAccess 不检查过期状态；链下服务可能信任过期的 ACTIVE 会话

**影响**: 过期会话可能被误判为有效

---

## E-17: exchangeAuthCode 创建无 scope 会话

**来源**: AccessGateway.sol L225-L240
**声明**: 授权码交换创建的会话 scopes 为空数组

```solidity
_sessions[sessionId] = AccessSession({
    // ...
    scopes: new string[](0),  // 空权限范围
    // ...
});
```

**影响**: 会话无权限约束，可能超越授权范围

---

## E-18: registerChainIdentity 无重复检查

**来源**: AgentRegistry.sol L165-L180
**声明**: 可为同一 agentId 重复注册相同的 chainId + registryAddress + remoteAgentId

**影响**: 数据冗余；链下验证时可能产生歧义

---

## E-19: Solidity 0.8.24 + OpenZeppelin 5.1.0

**来源**: 合约 pragma + package.json
**声明**: Solidity 0.8.24 无已知严重漏洞；OpenZeppelin 5.1.0 是最新稳定版

---

## E-20: 合约不可升级

**来源**: 所有 4 个合约
**声明**: 无 proxy pattern，部署后不可修改代码；发现的 bug 无法通过合约升级修复

**影响**: 需要重新部署 + 迁移才能修复任何 bug

---

## E-21: AccessGateway requestAccess 签名验证冗余

**来源**: AccessGateway.sol L128-L132
**声明**: requestAccess 中 `require(signer == msg.sender)` 要求签名者必须是调用者本身，这意味着 EIP-712 签名是冗余的（如果 msg.sender 已经是签名者，直接验证 msg.sender 即可）

**原始代码**:
```solidity
address signer = hash.recover(signature);
require(signer == msg.sender, "AccessGateway: invalid signature");
```

**影响**: 不增加安全性，反而增加 gas 消耗和用户操作复杂度；同时排除了中继者模式
