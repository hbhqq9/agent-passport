# Agent Passport 智能合约深度安全审计报告

**审计日期**: 2026-07-08  
**审计版本**: V2 (Base Mainnet 部署版)  
**审计师**: AI Security Auditor  
**网络**: Base Mainnet (Chain ID: 8453)  
**Solidity**: 0.8.24 | **OpenZeppelin**: v5.1.0 | **Optimizer**: enabled (200 runs)

---

## 合约概览

| 合约 | 部署地址 | 代码大小 | 层级 | 角色 |
|------|---------|---------|------|------|
| AgentRegistry | `0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9` | 13,956 B | L1 身份注册 | Ownable |
| AgentPassport | `0x5eBD4fCE45754c345557a237dd59cecec7A410c87` | 11,065 B | L2 属性/证明 | AccessControl |
| CompliancePassport | `0x1A086e034C7020CFE12d1ff8082Fc6aeD5787680` | 15,627 B | L3 合规 | AccessControl |
| AccessGateway | `0xC46C3538Ea1Ea3dc41b762A2b298DD3C4cc65594` | 12,770 B | L3 访问网关 | 单 admin |

**部署者**: `0x903f5C71D87FCAb1FAC236F02Be94EF95Fa0Ea3B`  
**依赖关系**: AgentRegistry ← AgentPassport ← AccessGateway; AgentRegistry ← CompliancePassport

---

## 一、经典漏洞检查

### 1.1 Reentrancy（重入攻击）

| 合约 | 状态 | 说明 |
|------|------|------|
| AgentRegistry | ⚠️ LOW | `register()` 调用 `_safeMint`，可能触发 `onERC721Received` 回调。此时 `_agents[agentId]` 尚未写入，但 `_nextAgentId` 已递增，无法利用重入注册同一 ID。风险有限。 |
| AgentPassport | ✅ SAFE | 无外部调用在状态变更之前 |
| CompliancePassport | ⚠️ LOW | `issueCertificate` 调用 `this.getCompositeRiskScore(agentId)`（外部自调用），但发生在状态写入之前，且 AccessControl 无 fallback，无可利用重入路径 |
| AccessGateway | ✅ SAFE | 外部调用均为 view 函数，且在状态变更之后 |

### 1.2 Integer Overflow/Underflow

| 合约 | 状态 | 说明 |
|------|------|------|
| 全部 | ✅ SAFE | Solidity 0.8.24 内置溢出检查 |

### 1.3 Access Control 缺陷

| 合约 | 状态 | 说明 |
|------|------|------|
| AgentRegistry | ⚠️ MEDIUM | `isApprovedForAll` 授权的 operator 可执行 bindWallet/unbindWallet/setMetadata/setAgentURI，等同于 owner 权限。NFT 市场上架时 operator 可修改身份关键数据。详见 [V-05] |
| AgentPassport | ✅ OK | RBAC 角色控制正确；setAttribute 允许 owner 或 REGISTRAR_ROLE |
| CompliancePassport | ✅ OK | SCORER_ROLE / COMPLIANCE_ORACLE_ROLE 分离清晰 |
| AccessGateway | ⚠️ MEDIUM | admin 为单地址，无两步转移机制。详见 [V-06] |

### 1.4 TX.ORIGIN 认证

| 合约 | 状态 |
|------|------|
| 全部 | ✅ SAFE | 未使用 tx.origin |

### 1.5 Unchecked External Calls

| 合约 | 状态 | 说明 |
|------|------|------|
| AgentPassport | ✅ OK | `_isAgentOwner` 使用 try/catch 处理 IERC721.ownerOf() 调用 |
| CompliancePassport | ⚠️ LOW | `this.getCompositeRiskScore()` 外部自调用无 try/catch，若底层函数 revert 则整体交易回滚 |
| AccessGateway | ✅ OK | 所有外部调用均为 immutable 接口的 view 函数 |

### 1.6 Front-running / MEV 风险

| 合约 | 状态 | 说明 |
|------|------|------|
| AgentRegistry | ✅ LOW | register 可被 front-run 但仅影响 agentId 编号，无实际损失 |
| 全部 | ✅ LOW | 所有状态变更函数均基于签名验证或角色检查，front-run 无法窃取资产 |

### 1.7 DoS（Gas 耗尽/无限循环）

| 合约 | 状态 | 说明 |
|------|------|------|
| AgentRegistry | ⚠️ MEDIUM | `register(metadata)` 的 for 循环无上限，大量 metadata 条目可导致 OOG |
| 全部 | ⚠️ MEDIUM | 多个无界数组映射，视图函数可能 OOG。详见 [V-08] |

---

## 二、业务逻辑漏洞

### [V-01] 🔴 CRITICAL — EIP-712 Nonce 读写错位导致签名无限重放

**影响合约**: AgentPassport, CompliancePassport  
**攻击向量**:

`issueAttestationBySignature`、`recordRiskScoreBySignature`、`issueCertificateBySignature` 三个函数中，nonce 从 `msg.sender`（交易提交者/中继者）读取，却写入 `signer`（实际签名者）：

```solidity
uint256 nonce = verifierNonce[msg.sender];   // 读提交者的 nonce
// ... 构造 structHash 使用此 nonce 验证签名
verifierNonce[signer] = nonce + 1;           // 写签名者的 nonce
```

**攻击步骤**:
1. Verifier V 签名 attestation，nonce = verifierNonce[submitter_S] = 0
2. S 提交交易 → 验证通过 → verifierNonce[V] = 1，但 verifierNonce[S] 仍为 0
3. S 再次提交同一签名 → nonce 仍读 verifierNonce[S] = 0 → 验证再次通过
4. 每次重放产生新 attestationId，创建重复 but 独立的 attestation

**影响范围**: 
- 重复 attestation 虚增计数 → `exportPassport` 的 activeAttestationCount 虚高
- 重复 riskScore 记录 → `getCompositeRiskScore` 简单平均被操纵
- 重复 certificate → 合规状态不可靠
- 三个函数均受影响，覆盖全系统签名验证流程

**修复建议**: 统一 nonce 读写对象为签名者 `signer`：
```solidity
uint256 nonce = verifierNonce[signer];  // 预先读取签名者 nonce
// 需重构为两步验证或使用 msg.sender 作为 nonce key
```
更优方案：将 nonce key 改为 `signer` 地址：
```solidity
uint256 nonce = verifierNonce[signer]; // 先通过 ecRecover 恢复 signer
verifierNonce[signer] = nonce + 1;
```

---

### [V-02] 🔴 HIGH — verifyProofOfAgent 跨链签名重放

**影响合约**: AccessGateway  
**攻击向量**:

`verifyProofOfAgent` 使用 `toEthSignedMessageHash`（personal_sign 风格），未包含 chainId 或合约地址：

```solidity
address signer = message.toEthSignedMessageHash().recover(signature);
```

**攻击步骤**:
1. Agent 在 Base Mainnet 签名 message → `verifyProofOfAgent` 返回 `(true, agentId)`
2. 同一签名在任何 EVM 链上的同名合约中也返回 `(true, ...)`
3. 链下 Web2 平台若仅调用此函数验证，无法区分签名来源链
4. 攻击者在另一条链注册同名 Agent 后，重放 Base Mainnet 的签名

**影响范围**: Proof-of-Agent 机制的核心安全假设被打破；Web2 平台可能接受跨链伪造的身份证明

**修复建议**: 使用 EIP-712 typed data 替代 personal_sign，domain separator 自动绑定 chainId + 合约地址：
```solidity
bytes32 structHash = keccak256(abi.encode(
    PROOF_OF_AGENT_TYPEHASH, agentWallet, message, nonce
));
bytes32 hash = _hashTypedDataV4(structHash);
address signer = hash.recover(signature);
```

---

### [V-03] 🟠 HIGH — issueCertificateBySignature 允许任意风险评分

**影响合约**: CompliancePassport  
**攻击向量**:

`issueCertificate` 内部通过 `this.getCompositeRiskScore(agentId)` 计算综合评分，但 `issueCertificateBySignature` 直接接受 `riskScore` 作为参数，SCORER_ROLE 持有者可设置任意值：

```solidity
// issueCertificate — 安全：使用计算值
(uint8 compositeScore,) = this.getCompositeRiskScore(agentId);
riskScore: compositeScore,

// issueCertificateBySignature — 不安全：使用传入值
function issueCertificateBySignature(uint8 riskScore, ...) {
    riskScore: riskScore,  // 可为 0（最低风险）
}
```

**攻击步骤**: SCORER_ROLE 为高风险 Agent 签发 riskScore=0 的合规证书，绕过风险评估

**影响范围**: 合规证书的风险评分不可信 → `meetsComplianceRequirement` 的 maxRiskScore 检查可被绕过

**修复建议**: `issueCertificateBySignature` 应移除 `riskScore` 参数，内部调用 `getCompositeRiskScore` 计算实际评分

---

### [V-04] 🟠 HIGH — verifyComplianceProof 验证函数永久失效

**影响合约**: CompliancePassport  
**攻击向量**:

`exportComplianceProof` 生成的 proofHash 包含实际 `scorerCount`，但 `verifyComplianceProof` 硬编码 `scorerCount=0`：

```solidity
// export — 使用实际值
proofHash = keccak256(abi.encode(summary, scorerCount, block.chainid, address(this)));

// verify — 硬编码 0
bytes32 computedHash = keccak256(abi.encode(summary, 0, chainId, passportContract));
```

**影响范围**: 合规证明验证永远返回 false → 第三方 DApp 无法验证合规证明的完整性 → 该功能完全失效

**修复建议**: 将 `scorerCount` 作为 `verifyComplianceProof` 的参数传入，或将其纳入 `ComplianceSummary` 结构体

---

### [V-05] 🟡 MEDIUM — isApprovedForAll 授权范围过大

**影响合约**: AgentRegistry  
**攻击向量**:

NFT 标准的 `isApprovedForAll` 授予 operator 的权限等同于 owner，可用于：
- `bindWallet` — 绑定任意钱包
- `unbindWallet` — 解绑现有钱包
- `setMetadata` — 修改任意元数据
- `setAgentURI` — 替换 Agent URI

当用户在 NFT 市场（OpenSea/Blur）上架 Agent NFT 时，市场合约自动获得 `isApprovedForAll` 授权，此时市场可执行上述所有操作。

**影响范围**: Agent 身份关键数据可在 NFT 交易场景下被第三方修改

**修复建议**: 对身份关键操作（bindWallet/unbindWallet/setAgentURI）仅允许 NFT owner，移除 `isApprovedForAll` 检查

---

### [V-06] 🟡 MEDIUM — AccessGateway Admin 单点故障

**影响合约**: AccessGateway  
**攻击向量**:

1. `transferAdmin` 无两步确认机制，误转到错误地址则永久失去管理权
2. admin 为单地址，无多签/时间锁保护
3. admin 可更新 `gatewayService` 地址 → 控制所有访问授权

**影响范围**: admin 私钥泄露 → 全网关接管；误操作 → 合约永久失控

**修复建议**: 
- 实现 TwoStepOwnable 模式（pendingAdmin + acceptAdmin）
- 使用多签钱包作为 admin
- 关键操作增加时间锁

---

### [V-07] 🟡 MEDIUM — Deployer 密钥单点风险

**影响合约**: 全部 4 个合约  
**攻击向量**:

单一 EOA `0x903f5C71D87FCAb1FAC236F02Be94EF95Fa0Ea3B` 持有：
- AgentRegistry: Ownable owner（verifyChainRegistration）
- AgentPassport: DEFAULT_ADMIN_ROLE + REGISTRAR_ROLE + VERIFIER_ROLE
- CompliancePassport: DEFAULT_ADMIN_ROLE + SCORER_ROLE + COMPLIANCE_ORACLE_ROLE
- AccessGateway: admin

该地址余额仅 ~0.0056 ETH（约 10-20 笔交易后耗尽），私钥泄露将导致全系统管理员权限丢失。

**影响范围**: 全系统管理员权限集中在单一 EOA

**修复建议**: 
- 立即将所有管理员角色转移至多签钱包（如 Gnosis Safe 3/5）
- 为关键操作添加时间锁（如 48h TimelockController）

---

### [V-08] 🟡 MEDIUM — 无界数组增长导致 DoS

**影响合约**: 全部 4 个合约  
**攻击向量**:

以下映射存储无界数组，恶意或正常使用均可导致数组膨胀：

| 合约 | 数组 | 限速者 | 爆炸场景 |
|------|------|--------|---------|
| AgentRegistry | chainRegistrations[agentId] | owner | 重复注册跨链身份 |
| AgentPassport | _attributes[agentId] | owner/REGISTRAR | 大量属性写入 |
| AgentPassport | _agentAttestations[agentId] | VERIFIER_ROLE | 大量 attestation |
| CompliancePassport | _riskScores[agentId] | SCORER_ROLE | 大量评分记录 |
| CompliancePassport | _agentCertificates[agentId] | SCORER_ROLE | 大量证书 |
| AccessGateway | _agentSessions[agentWallet] | agent 自身 | 大量访问请求 |

**影响范围**: 视图函数（getAttributes、exportPassport、getCompositeRiskScore 等）可能 OOG，阻塞链下读取

**修复建议**: 
- 为数组长度设置上限
- 使用分页查询替代全量返回
- 考虑仅存储最新 N 条记录的环形缓冲区

---

## 三、数据与隐私

### [V-09] 🟡 MEDIUM — URI 注入攻击

**影响合约**: AgentRegistry, AgentPassport, CompliancePassport  
**攻击向量**:

以下 URI 字段无格式验证，可指向恶意内容：
- `AgentRegistry.setAgentURI` — Agent 元数据 URI
- `AgentPassport.issueAttestation` — schemaURI
- `CompliancePassport.recordRiskScore` — scorerURI

攻击者（身份 owner）可将 URI 指向钓鱼页面或恶意脚本。下游 DApp 解析 URI 时若未做内容验证，可能导致 XSS 或数据注入。

**修复建议**: 
- 限制 URI scheme 为 `ipfs://` 或 `ar://`
- 链下服务必须验证 URI 返回内容的 hash 与链上记录一致
- 添加 URI 格式白名单验证

### [V-10] 🟡 MEDIUM — 链上敏感数据泄露

**影响合约**: AgentPassport, CompliancePassport  
**攻击向量**:

以下字段以明文永久存储在链上：
- `AgentAttribute.rawValue` — 属性原始值（可能包含 PII）
- `ComplianceRecord.details` — 合规详情（可能包含商业机密）
- `MandateStatus` — 委托人地址和财务上限

数据一旦写入不可删除，违反 GDPR "被遗忘权" 等隐私法规。

**修复建议**: 
- 仅存储 hash（如 attrHash），原始值存链下
- 使用 ZK 证明替代明文存储
- 添加文档明确禁止存储 PII

---

## 四、升级与治理风险

### [V-11] 🟡 MEDIUM — 合约不可升级，Bug 无法修复

**影响合约**: 全部 4 个合约  
**分析**:

所有合约均为不可升级的裸部署（无 proxy pattern），已发现的 [V-01]~[V-04] 等 bug 无法通过合约升级修复，只能：
1. 重新部署全部 4 个合约
2. 迁移所有链上状态（NFT、attestation、证书等）
3. 更新所有依赖地址

**风险**: 当前部署版本的 nonce bug 和验证失效是永久性的，除非重新部署

**修复建议**: 
- 短期：在链下服务层添加 nonce 验证和 proof 验证的补偿逻辑
- 长期：使用 UUPS proxy pattern 重新部署，为未来修复预留升级路径

### [V-12] 🟢 LOW — AgentRegistry._update NFT 销毁后状态残留

**影响合约**: AgentRegistry  
**攻击向量**:

当 NFT 被销毁（transfer to address(0)）时，`_update` 中的 `if (previousOwner != address(0) && to != address(0))` 条件不满足，跳过清理。导致：
- `_agents[tokenId].owner` 残留旧值
- `walletToAgent[wallet]` 可能残留绑定
- `getAgentInfo(tokenId)` 对已销毁的 tokenId 返回残留数据

**影响范围**: 已销毁 Agent 的数据残留，可能导致身份混淆

**修复建议**: 在 `_update` 中增加销毁路径的清理逻辑

---

## 五、依赖风险

### 5.1 OpenZeppelin 版本

| 项目 | 版本 | 状态 |
|------|------|------|
| OpenZeppelin Contracts | v5.1.0 | ✅ 最新稳定版，无已知严重漏洞 |
| ECDSA | v5.1.0 | ✅ 包含 signature malleability 防护 |
| EIP712 | v5.1.0 | ✅ 包含 chainId 变更检测 |

### 5.2 Solidity 编译器

| 项目 | 版本 | 状态 |
|------|------|------|
| Solidity | 0.8.24 | ✅ 无已知严重漏洞；建议锁定为精确版本（当前使用 `^0.8.24`） |

### 5.3 其他发现

- **[V-13] 🟢 LOW** — CompliancePassport 使用 `this.getCompositeRiskScore()` 外部自调用，不必要的 gas 开销，应改为 internal 调用
- **[V-14] 🟢 LOW** — AccessGateway `exchangeAuthCode` 创建的会话 scopes 为空数组，无权限约束
- **[V-15] 🟢 LOW** — AccessGateway `requestAccess` 中 `require(signer == msg.sender)` 使 EIP-712 签名冗余（若 msg.sender 已验证，签名不增加安全性）
- **[V-16] 🟢 LOW** — AgentRegistry `registerChainIdentity` 无重复检查，可注册相同的跨链映射
- **[V-17] 🟢 INFO** — AccessGateway 会话 expiresAt 仅在 grantAccess 时检查，链下服务可能信任过期的 ACTIVE 会话

---

## 六、漏洞汇总表

| ID | 严重级别 | 合约 | 漏洞 | 攻击向量 |
|----|---------|------|------|---------|
| V-01 | 🔴 CRITICAL | AgentPassport + CompliancePassport | EIP-712 Nonce 读写错位 → 签名无限重放 | 同一提交者重复提交相同签名 |
| V-02 | 🔴 HIGH | AccessGateway | verifyProofOfAgent 跨链签名重放 | 在不同链重放 personal_sign 签名 |
| V-03 | 🟠 HIGH | CompliancePassport | issueCertificateBySignature 任意风险评分 | SCORER 签发 riskScore=0 证书 |
| V-04 | 🟠 HIGH | CompliancePassport | verifyComplianceProof 永久失效 | 硬编码 scorerCount=0 导致验证失败 |
| V-05 | 🟡 MEDIUM | AgentRegistry | isApprovedForAll 授权范围过大 | NFT 市场 operator 修改身份数据 |
| V-06 | 🟡 MEDIUM | AccessGateway | Admin 单点故障 | 误转 admin 或私钥泄露 |
| V-07 | 🟡 MEDIUM | 全部 | Deployer 密钥单点风险 | 单一 EOA 持有全部管理员角色 |
| V-08 | 🟡 MEDIUM | 全部 | 无界数组增长 DoS | 大量数据写入致视图函数 OOG |
| V-09 | 🟡 MEDIUM | 多个 | URI 注入攻击 | 恶意 URI 指向钓鱼/恶意内容 |
| V-10 | 🟡 MEDIUM | AgentPassport + CompliancePassport | 链上敏感数据泄露 | PII 永久链上存储 |
| V-11 | 🟡 MEDIUM | 全部 | 合约不可升级，Bug 无法修复 | 无 proxy pattern |
| V-12 | 🟢 LOW | AgentRegistry | NFT 销毁后状态残留 | getAgentInfo 返回已销毁 agent 数据 |
| V-13 | 🟢 LOW | CompliancePassport | 外部自调用浪费 gas | this.getCompositeRiskScore() |
| V-14 | 🟢 LOW | AccessGateway | 授权码交换会话无 scope | exchangeAuthCode scopes=[] |
| V-15 | 🟢 LOW | AccessGateway | requestAccess 签名冗余 | signer==msg.sender 时签名无意义 |
| V-16 | 🟢 LOW | AgentRegistry | registerChainIdentity 无重复检查 | 重复注册相同跨链映射 |
| V-17 | 🟢 INFO | AccessGateway | 会话过期未强制执行 | 过期 ACTIVE 会话 |

---

## 七、总体安全评分

### 评分: 58 / 100

| 维度 | 权重 | 得分 | 加权 |
|------|------|------|------|
| 经典漏洞 | 25% | 80 | 20.0 |
| 业务逻辑 | 35% | 40 | 14.0 |
| 数据与隐私 | 15% | 55 | 8.3 |
| 升级与治理 | 15% | 45 | 6.8 |
| 依赖风险 | 10% | 90 | 9.0 |
| **总计** | **100%** | | **58.0** |

**扣分理由**:
- CRITICAL 级别 nonce bug 影响全系统签名验证 (-25)
- HIGH 级别跨链重放 + 证书伪造 + 验证失效 (-20)
- 无升级路径，bug 不可修复 (-10)
- 单点管理员风险 (-5)

---

## 八、Top 3 优先修复项

### 🥇 P1: 修复 EIP-712 Nonce 读写错位 [V-01]

**紧迫性**: 立即  
**影响**: 3 个签名验证函数可被无限重放  
**修复方案**: 将 `verifierNonce[msg.sender]` 改为 `verifierNonce[signer]`，需重构为两步验证（先 recover signer，再读 nonce）  
**部署方式**: 需重新部署 AgentPassport 和 CompliancePassport

```solidity
// 修复后代码示例
function issueAttestationBySignature(...) external returns (uint256) {
    // Step 1: 先用 nonce=0 恢复 signer（需要 verifier 配合）
    // Step 2: 用正确 nonce 重新验证
    // 更优方案：nonce key 统一使用 signer
    bytes32 structHash = keccak256(abi.encode(
        ATTESTATION_TYPEHASH, agentId, uint8(attributeType),
        attrHash, validUntil, verifierNonce[signer]  // 需预言 nonce
    ));
}
```

**实际修复**: 最简方案 — 将 nonce 读取和写入统一为 `signer` 地址。由于 `signer` 需从签名恢复，可要求签名者将当前 nonce 值包含在签名数据中，恢复后验证 nonce 匹配：

```solidity
// 签名者包含自己的 nonce
bytes32 structHash = keccak256(abi.encode(
    ATTESTATION_TYPEHASH, agentId, uint8(attributeType),
    attrHash, validUntil, nonce  // nonce 由签名者提供
));
bytes32 hash = _hashTypedDataV4(structHash);
address signer = hash.recover(signature);
require(hasRole(VERIFIER_ROLE, signer), "...");
require(nonce == verifierNonce[signer], "invalid nonce");  // 验证 nonce
verifierNonce[signer] = nonce + 1;  // 正确更新
```

### 🥈 P2: 将 verifyProofOfAgent 迁移到 EIP-712 [V-02]

**紧迫性**: 高  
**影响**: Proof-of-Agent 可跨链伪造  
**修复方案**: 使用 `_hashTypedDataV4` 替代 `toEthSignedMessageHash`，自动绑定 chainId + 合约地址  
**部署方式**: 需重新部署 AccessGateway

### 🥉 P3: 转移管理员权限至多签钱包 [V-07]

**紧迫性**: 高  
**影响**: 单一 EOA 持有全系统管理员权限  
**修复方案**: 
1. 部署 Gnosis Safe 3/5 多签钱包
2. 将所有合约的管理员角色转移至多签地址
3. 为关键操作添加 TimelockController

**无需重新部署**: 可通过现有 admin 函数完成转移

---

## 九、逐合约审计详情

### 9.1 AgentRegistry

| 维度 | 评估 |
|------|------|
| 重入 | LOW — _safeMint 回调风险有限 |
| 溢出 | SAFE — 0.8.24 内置检查 |
| 权限 | MEDIUM — isApprovedForAll 过度授权 |
| 签名 | OK — bindWallet EIP-712 实现正确（nonce 绑定 agentId） |
| DoS | MEDIUM — 无界数组 |
| 数据 | MEDIUM — URI 无验证 |
| 升级 | 不可升级 |

**特殊关注**:
- `_update` 重写正确处理了转账时钱包绑定清除
- `_exists` 使用 `_ownerOf` 而非自定义逻辑，正确
- `walletBindingNonce` 按 agentId 索引，bindWallet 签名验证逻辑正确（与 AgentPassport 的 nonce bug 不同）

### 9.2 AgentPassport

| 维度 | 评估 |
|------|------|
| 重入 | SAFE |
| 溢出 | SAFE |
| 权限 | OK — RBAC 正确 |
| 签名 | 🔴 CRITICAL — nonce 读写错位 |
| Attestation 伪造 | OK — VERIFIER_ROLE 检查正确 |
| 数据 | MEDIUM — rawValue 明文存储 |
| 升级 | 不可升级 |

**特殊关注**:
- `_isAgentOwner` 使用 try/catch 处理跨合约调用，健壮
- `registerPolicy` 的 policyHash 包含 block.timestamp，防止碰撞

### 9.3 CompliancePassport

| 维度 | 评估 |
|------|------|
| 重入 | LOW — 外部自调用 |
| 溢出 | SAFE |
| 权限 | OK — SCORER/COMPLIANCE_ORACLE 分离 |
| 签名 | 🔴 CRITICAL — nonce 读写错位（2处） |
| 证书绕过 | HIGH — issueCertificateBySignature 任意 riskScore |
| 验证 | HIGH — verifyComplianceProof 失效 |
| 数据 | MEDIUM — details 明文存储 |
| 升级 | 不可升级 |

**特殊关注**:
- `getLatestRiskScore` 返回 (255, 0, address(0)) 表示无评分，而非 (0,...) — 避免与"最低风险"混淆，设计正确
- `_calculateComplianceLevel` 为 pure 函数，无副作用

### 9.4 AccessGateway

| 维度 | 评估 |
|------|------|
| 重入 | SAFE |
| 溢出 | SAFE |
| 权限 | MEDIUM — admin 单点 |
| 签名 | HIGH — verifyProofOfAgent 跨链重放 |
| PKCE | LOW — 非标准实现 |
| DoS | MEDIUM — 无界会话数组 |
| 数据 | LOW — 会话数据链上可见 |
| 升级 | 不可升级 |

**特殊关注**:
- `requestAccess` 中 `signer == msg.sender` 使 EIP-712 签名冗余 — 若仅验证 msg.sender 即可，无需签名
- `exchangeAuthCode` 的 PKCE 验证使用 `sha256(abi.encodePacked())` 而非标准 BASE64URL 编码
- `grantAccess` 正确检查会话状态和过期时间

---

## 十、建议的后续行动

| 优先级 | 行动 | 预估工作量 | 是否需要重新部署 |
|--------|------|-----------|----------------|
| P0 | 修复 nonce 读写错位 (V-01) | 2h 开发 + 测试 | 是 |
| P0 | verifyProofOfAgent 迁移 EIP-712 (V-02) | 3h 开发 + 测试 | 是 |
| P0 | 修复 issueCertificateBySignature (V-03) | 1h 开发 | 是 |
| P0 | 修复 verifyComplianceProof (V-04) | 1h 开发 | 是 |
| P1 | 管理员权限转移至多签 (V-07) | 1h 操作 | 否 |
| P1 | 添加 UUPS proxy pattern (V-11) | 4h 开发 | 是（重新部署） |
| P2 | 限制 isApprovedForAll 权限 (V-05) | 2h 开发 | 是 |
| P2 | 添加数组长度上限/分页 (V-08) | 4h 开发 | 是 |
| P3 | URI 格式验证 (V-09) | 2h 开发 | 是 |
| P3 | 敏感数据仅存 hash (V-10) | 3h 开发 | 是 |

---

*本报告由 AI 安全审计工具生成，建议在修复后聘请专业安全团队进行第三方审计。*
*审计完成日期: 2026-07-08*
