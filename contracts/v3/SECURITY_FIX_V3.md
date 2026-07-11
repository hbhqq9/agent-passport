# Security Fix V3 — Agent Passport Contract Suite

**版本**: V2 → V3  
**日期**: 2025-07-11  
**修复漏洞数**: 4 (1 CRITICAL + 3 HIGH)  
**影响合约**: AgentPassport.sol, CompliancePassport.sol, AccessGateway.sol  

---

## 漏洞总览

| # | 严重级别 | 漏洞名称 | 位置 | 状态 |
|---|---------|---------|------|------|
| 1 | CRITICAL | EIP-712 Nonce 读写错位 | AgentPassport + CompliancePassport (3个函数) | ✅ 已修复 |
| 2 | HIGH | verifyProofOfAgent 跨链签名重放 | AccessGateway.sol | ✅ 已修复 |
| 3 | HIGH | issueCertificateBySignature 允许伪造 riskScore | CompliancePassport.sol | ✅ 已修复 |
| 4 | HIGH | verifyComplianceProof 永久失效 | CompliancePassport.sol | ✅ 已修复 |

---

## 漏洞 #1: EIP-712 Nonce 读写错位 (CRITICAL)

### 根因分析

在 `AgentPassport.issueAttestationBySignature`、`CompliancePassport.recordRiskScoreBySignature` 和 `CompliancePassport.issueCertificateBySignature` 三个函数中，存在 nonce 读取地址与写入地址不一致的严重缺陷：

```solidity
// V2 代码 (有漏洞)
uint256 nonce = nonceMapping[msg.sender];  // 从提交者 (msg.sender) 读取
// ... 签名恢复 ...
address signer = hash.recover(signature);
nonceMapping[signer] = nonce + 1;          // 写入签名者 (signer)
```

**攻击路径**:
1. Verifier A 签发签名 S1 (nonce=0)，交给 Relayer R1
2. Relayer R1 提交 S1 → nonce 从 `verifierNonce[R1]=0` 读取，写入 `verifierNonce[A]=1`
3. Relayer R2 拿到同一签名 S1 → nonce 从 `verifierNonce[R2]=0` 读取（R2 的 nonce 也是 0）
4. S1 被再次成功执行 → **重放攻击成功**

核心问题：不同提交者的 nonce 互相独立，但都写入同一个 signer 的 slot，导致无法防重放。

### 修复方案

1. **EIP-712 TYPEHASH 增加 `signer` 字段**：将签名者与 nonce 绑定
2. **新增 `signer` 和 `nonce` 函数参数**：打破循环依赖（恢复 signer 需要 nonce，但 nonce 来自 signer）
3. **nonce 统一从 signer 读取/写入**

```solidity
// V3 修复后
bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
    "Attestation(address signer,uint256 agentId,uint8 attributeType,bytes32 attributeHash,uint256 validUntil,uint256 nonce)"
);

function issueAttestationBySignature(
    ...,
    address signer,       // [V3 新增] 签名者地址
    uint256 nonce         // [V3 新增] 签名者当前 nonce
) external {
    require(nonce == verifierNonce[signer], "invalid nonce");  // 统一从 signer 读取
    
    bytes32 structHash = keccak256(abi.encode(
        ATTESTATION_TYPEHASH,
        signer,           // [V3] signer 纳入签名数据
        ...
        nonce
    ));
    address recovered = hash.recover(signature);
    require(recovered == signer, "signer mismatch");
    
    verifierNonce[signer] = nonce + 1;  // 统一写入 signer (读写一致)
}
```

### 受影响函数
- `AgentPassport.issueAttestationBySignature` — 新增 `signer`, `nonce` 参数
- `CompliancePassport.recordRiskScoreBySignature` — 新增 `signer`, `nonce` 参数
- `CompliancePassport.issueCertificateBySignature` — 新增 `signer`, `nonce` 参数 (同时修复漏洞 #3)

### API 变更
```diff
- function issueAttestationBySignature(uint256, AttributeType, string, string, uint256, uint256, bytes)
+ function issueAttestationBySignature(uint256, AttributeType, string, string, uint256, uint256, bytes, address signer, uint256 nonce)

- function recordRiskScoreBySignature(uint256, uint8, uint256, bytes32, uint256, bytes)
+ function recordRiskScoreBySignature(uint256, uint8, uint256, bytes32, uint256, bytes, address signer, uint256 nonce)

- function issueCertificateBySignature(uint256, uint8 riskScore, uint8, bytes32, uint256, uint256, bytes)
+ function issueCertificateBySignature(uint256, uint8 complianceLevel, bytes32, uint256, uint256, bytes, address signer, uint256 nonce)
```

---

## 漏洞 #2: verifyProofOfAgent 跨链签名重放 (HIGH)

### 根因分析

`AccessGateway.verifyProofOfAgent` 使用 `toEthSignedMessageHash` 进行签名验证：

```solidity
// V2 代码 (有漏洞)
function verifyProofOfAgent(address agentWallet, bytes32 message, bytes calldata signature)
    external view returns (bool isValid, uint256 agentId)
{
    address signer = message.toEthSignedMessageHash().recover(signature);
    // ...
}
```

`toEthSignedMessageHash` 生成的是 `\x19Ethereum Signed Message:\n32` + message，**不包含 chainId 或合约地址**。这意味着：

1. Agent 在链 A (chainId=1) 上签名 message M
2. 攻击者将同一签名提交到链 B (chainId=42161) 的相同合约
3. 签名在链 B 上同样有效 → **跨链重放攻击**

### 修复方案

改用 EIP-712 结构化签名。EIP-712 的 domain separator 自动包含 `chainId` 和 `verifyingContract`：

```solidity
// V3 修复后
bytes32 private constant PROOF_OF_AGENT_TYPEHASH = keccak256(
    "ProofOfAgent(address agentWallet,uint256 agentId,bytes32 message,uint256 nonce)"
);

// 新增 nonce 防重放
mapping(address => uint256) public proofOfAgentNonces;

function verifyProofOfAgent(
    address agentWallet,
    bytes32 message,
    uint256 nonce,          // [V3 新增]
    bytes calldata signature
) external view returns (bool isValid, uint256 agentId) {
    require(nonce == proofOfAgentNonces[agentWallet], "invalid nonce");

    // EIP-712: domain separator 包含 chainId + verifyingContract
    bytes32 structHash = keccak256(abi.encode(
        PROOF_OF_AGENT_TYPEHASH,
        agentWallet, agentId, message, nonce
    ));
    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = hash.recover(signature);
    // ...
}

// 新增消费 nonce 的版本
function consumeProofOfAgent(...) external returns (bool, uint256);
```

### 安全性保证
- **跨链防护**: EIP-712 domain separator 包含 `block.chainid` + `address(this)`，签名无法跨链/跨合约重放
- **链上防护**: 新增 `proofOfAgentNonces` + `consumeProofOfAgent` 防止同一链上重放

### API 变更
```diff
- function verifyProofOfAgent(address, bytes32, bytes) external view returns (bool, uint256)
+ function verifyProofOfAgent(address, bytes32, uint256 nonce, bytes) external view returns (bool, uint256)
+ function consumeProofOfAgent(address, bytes32, bytes) external returns (bool, uint256)  // 新增
```

---

## 漏洞 #3: issueCertificateBySignature 允许伪造 riskScore (HIGH)

### 根因分析

`CompliancePassport.issueCertificateBySignature` 接受外部传入的 `riskScore` 参数：

```solidity
// V2 代码 (有漏洞)
function issueCertificateBySignature(
    uint256 agentId,
    uint8 riskScore,        // ← 外部传入，可被恶意设置为 0
    uint8 complianceLevel,
    ...
) external returns (uint256 certId) {
    // ...
    _certificates[certId] = ComplianceCertificate({
        riskScore: riskScore,   // ← 直接使用外部值
        ...
    });
}
```

**攻击路径**:
1. 恶意评分者签名时设置 `riskScore=0`（假装最安全）
2. 任何人提交该签名到链上
3. 获得 riskScore=0 的合规证书，绕过实际风险评估
4. 与链上已有的实际评分（可能很高）完全脱钩

### 修复方案

移除 `riskScore` 参数，改为从链上已有评分记录动态读取：

```solidity
// V3 修复后
function issueCertificateBySignature(
    uint256 agentId,
    // [V3] 移除 riskScore 参数
    uint8 complianceLevel,
    bytes32 evidenceHash,
    uint256 validUntil,
    uint256 deadline,
    bytes calldata signature,
    address signer,
    uint256 nonce
) external returns (uint256 certId) {
    // ...
    
    // [V3 FIX] 从链上已有记录读取真实 riskScore
    (uint8 actualRiskScore,) = this.getCompositeRiskScore(agentId);
    
    _certificates[certId] = ComplianceCertificate({
        riskScore: actualRiskScore,   // [V3] 使用链上真实评分
        ...
    });
}
```

### API 变更
```diff
- function issueCertificateBySignature(uint256, uint8 riskScore, uint8, bytes32, uint256, uint256, bytes)
+ function issueCertificateBySignature(uint256, uint8 complianceLevel, bytes32, uint256, uint256, bytes, address signer, uint256 nonce)
```

**注意**: `riskScore` 参数被移除，`complianceLevel` 成为第一个 uint8 参数。

---

## 漏洞 #4: verifyComplianceProof 永久失效 (HIGH)

### 根因分析

`CompliancePassport.verifyComplianceProof` 函数中 scorerCount 被硬编码为 0：

```solidity
// V2 代码 (有漏洞)
function verifyComplianceProof(...) external pure returns (bool) {
    bytes32 computedHash = keccak256(abi.encode(
        summary,
        0,  // ← 硬编码为 0，但 exportComplianceProof 使用真实值
        chainId,
        passportContract
    ));
    return computedHash == expectedHash;  // 永远为 false (除非 scorerCount 恰好为 0)
}
```

**问题**:
- `exportComplianceProof` 使用 `getCompositeRiskScore()` 返回的真实 `scorerCount` 生成 proofHash
- `verifyComplianceProof` 使用硬编码 `0` 重新计算 proofHash
- 两者不一致 → **合规证明永远验证失败**

### 修复方案

将函数从 `pure` 改为 `view`，动态查询实际 scorer 数量：

```solidity
// V3 修复后
function verifyComplianceProof(...) external view returns (bool) {  // pure → view
    // [V3 FIX] 动态查询实际活跃评分者数量
    uint256 scorerCount = _getActiveScorerCount(summary.agentId);
    
    bytes32 computedHash = keccak256(abi.encode(
        summary,
        scorerCount,    // [V3] 使用动态值
        chainId,
        passportContract
    ));
    return computedHash == expectedHash;
}

// [V3 新增] 内部函数
function _getActiveScorerCount(uint256 agentId) internal view returns (uint256 count) {
    RiskScoreRecord[] storage records = _riskScores[agentId];
    for (uint256 i = 0; i < records.length; i++) {
        if (!records[i].revoked &&
            (records[i].validUntil == 0 || block.timestamp <= records[i].validUntil)) {
            count++;
        }
    }
}
```

### API 变更
```diff
- function verifyComplianceProof(...) external pure returns (bool)
+ function verifyComplianceProof(...) external view returns (bool)
```

**注意**: `pure` → `view` 是 ABI 级别的变更，调用方需要适配。

---

## 测试验证步骤

### 1. 编译验证
```bash
cd /app/data/所有对话/主对话/agent-passport/contracts/v3/
bash compile.sh
# 期望: 4 个合约全部编译成功
```

### 2. 漏洞 #1 测试 — Nonce 防重放
```
Test: NonceReplayPrevention
1. 部署 V3 合约
2. Verifier A 签名 attestation (nonce=0)
3. Relayer R1 提交签名 → 成功, verifierNonce[A] = 1
4. Relayer R2 提交同一签名 → revert "invalid nonce"
5. Relayer R1 传入 signer=A, nonce=1 → revert "signer mismatch" (签名中的 nonce=0)
```

### 3. 漏洞 #2 测试 — 跨链重放防护
```
Test: CrossChainReplayPrevention  
1. 在 chainId=31337 (Hardhat) 上部署 V3 合约
2. Agent 用 EIP-712 签名 ProofOfAgent
3. 调用 verifyProofOfAgent → 成功
4. 构造另一个 chainId 的 domain separator → 签名恢复失败
5. 调用 consumeProofOfAgent → 成功, nonce 递增
6. 再次调用 consumeProofOfAgent → revert "invalid nonce"
```

### 4. 漏洞 #3 测试 — riskScore 不可伪造
```
Test: RiskScoreCannotBeForged
1. 先记录 riskScore=80 (高风险)
2. 签名签发证书 (原代码可传 riskScore=0)
3. V3: 证书中的 riskScore = 80 (从链上读取的真实值)
4. 验证: certificate.riskScore == 80 ✅
```

### 5. 漏洞 #4 测试 — 合规证明验证
```
Test: ComplianceProofVerification
1. 记录 3 个有效 riskScore
2. 调用 exportComplianceProof → 得到 (summary, proofHash)
3. 调用 verifyComplianceProof(summary, chainId, contract, proofHash) → true
4. V2: 此步骤返回 false (scorerCount 硬编码为 0)
5. V3: 此步骤返回 true ✅
```

---

## 部署迁移计划 (V2 → V3)

### 阶段 1: 准备 (T-7 天)
- [ ] 代码审查 V3 合约
- [ ] 完成安全审计 (本修复基于审计报告)
- [ ] 编写完整测试用例 (Foundry/Hardhat)
- [ ] 在测试网部署验证

### 阶段 2: 测试网部署 (T-3 天)
- [ ] 部署 AgentRegistry V3 (无变更，可选)
- [ ] 部署 AgentPassport V3
- [ ] 部署 CompliancePassport V3
- [ ] 部署 AccessGateway V3
- [ ] 集成测试 + 前端适配

### 阶段 3: 主网部署 (T-0)
1. **暂停旧合约操作** (如适用)
2. **按顺序部署**:
   - AgentRegistry V3 (如需)
   - AgentPassport V3 → 重新授权 verifier
   - CompliancePassport V3 → 重新授权 scorer + oracle
   - AccessGateway V3 → 更新 gateway service
3. **数据迁移**:
   - AgentPassport: attestation 数据需要在新合约上重新签发
   - CompliancePassport: riskScore 记录和证书需要重新录入
   - AccessGateway: 活跃会话需要重新建立
4. **通知相关方**:
   - 通知所有 verifier 更新签名逻辑 (新 TYPEHASH + 新增参数)
   - 通知所有 platform 更新 Proof-of-Agent 签名逻辑 (EIP-712)
   - 更新 SDK 中的 ABI 和合约地址

### 阶段 4: 验证 (T+1 天)
- [ ] 验证所有合约状态正确
- [ ] 验证核心功能正常 (签发 attestation, 合规检查, 访问请求)
- [ ] 验证旧合约已停用
- [ ] 监控 Gas 使用量

### 向后兼容性说明

| 函数 | 兼容性 | 说明 |
|------|--------|------|
| `issueAttestationBySignature` | ⚠️ 不兼容 | 新增 signer/nonce 参数 |
| `recordRiskScoreBySignature` | ⚠️ 不兼容 | 新增 signer/nonce 参数 |
| `issueCertificateBySignature` | ⚠️ 不兼容 | 移除 riskScore, 新增 signer/nonce |
| `verifyProofOfAgent` | ⚠️ 不兼容 | 新增 nonce 参数, 签名方式变更 |
| `verifyComplianceProof` | ⚠️ 不兼容 | pure → view |
| 其他函数 | ✅ 完全兼容 | 无变更 |

---

## 编译产物

```
v3/build/
├── AgentRegistry.abi          (15,065 bytes)
├── AgentRegistry.bin          (28,976 bytes)
├── AgentPassport.abi          (13,402 bytes)
├── AgentPassport.bin          (26,230 bytes)
├── CompliancePassport.abi     (18,012 bytes)
├── CompliancePassport.bin     (32,624 bytes)
├── AccessGateway.abi          (9,196 bytes)
├── AccessGateway.bin          (30,338 bytes)
└── ... (OpenZeppelin 依赖产物)
```

**编译器**: solc 0.8.24+  
**优化**: --via-ir --optimize
