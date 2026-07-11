# AGL Agent Passport V3.1 — 安全修复文档

**版本**: V3 → V3.1  
**日期**: 2026-07-11  
**修复漏洞数**: 2 MEDIUM  
**影响合约**: AccessGateway.sol, AgentPassport.sol  
**前提**: V3 合约已在 Base Mainnet 部署运行  
**部署状态**: V3.1 编译通过，待部署

---

## 变更摘要

| 合约 | 代码大小变化 | 修改内容 |
|------|-------------|---------|
| AgentRegistry | 不变 | 无修改 |
| AgentPassport | +718 bytes | _requireAgentActive 增加 active 状态检查 |
| CompliancePassport | 不变 | 无修改 |
| AccessGateway | +930 bytes | consumeProofOfAgent 权限控制 + 两函数增加 active 检查 |

---

## 修复 #1 [MEDIUM]: consumeProofOfAgent 访问控制

### 问题
`consumeProofOfAgent` 是 public 函数，任何人都可以提交有效签名消费他人 nonce。

### 修复
```solidity
// [V3.1 FIX] 仅允许 gatewayService 或 Agent 自身调用
require(
    msg.sender == gatewayService || msg.sender == agentWallet,
    "AccessGateway: unauthorized"
);
```

### 攻击面分析
- **修复前**: 任何地址可提交有效签名 → nonce 被消费 → 原始调用者需重新签名
- **修复后**: 仅 gatewayService 或 Agent 自身可调用 → 消除 nonce 被恶意消费的可能

---

## 修复 #2 [MEDIUM]: Agent Active 状态检查

### 问题
`verifyProofOfAgent` 和 `consumeProofOfAgent` 不检查 Agent 的 active 状态，已停用的 Agent 仍可通过身份验证。

### 修复 (AccessGateway)
接口新增 `getAgentInfo`:
```solidity
interface IAgentRegistryForGateway {
    // ...existing functions...
    function getAgentInfo(uint256 agentId) external view returns (
        address owner, address agentWallet, string memory agentURI,
        uint256 registeredAt, bool active
    );
}
```

`verifyProofOfAgent` 增加 active 检查:
```solidity
// [V3.1 FIX] 4. 验证 Agent 活跃状态
(,,,, bool active) = agentRegistry.getAgentInfo(agentId);
if (!active) return (false, 0);
```

`consumeProofOfAgent` 增加 active 检查:
```solidity
// [V3.1 FIX] 验证 Agent 活跃状态
(,,,, bool active) = agentRegistry.getAgentInfo(agentId);
require(active, "AccessGateway: agent inactive");
```

### 修复 (AgentPassport)
`_requireAgentActive` 增加 active 检查:
```solidity
function _requireAgentActive(uint256 agentId) internal view {
    address wallet = agentRegistry.getAgentWallet(agentId);
    require(wallet != address(0), "AgentPassport: no wallet bound");
    // [V3.1] 检查 Agent 活跃状态
    (,,,, bool active) = agentRegistry.getAgentInfo(agentId);
    require(active, "AgentPassport: agent inactive");
}
```

### 影响范围
- `issueAttestation` — 停用的 Agent 无法再获得 attestation
- `issueAttestationBySignature` — 停用的 Agent 无法通过签名获得 attestation
- `recordRiskScore` (CompliancePassport) — 停用的 Agent 无法被评分
- `issueCertificate` (CompliancePassport) — 停用的 Agent 无法获得证书

---

## 编译验证

```
solc 0.8.24+commit.e3a8715a
Optimizer: --via-ir --optimize

AgentRegistry:       28,976 bytes (不变)
AgentPassport:       26,948 bytes (+718)
CompliancePassport:  32,624 bytes (不变)
AccessGateway:       31,268 bytes (+930)
```

所有合约编译成功，无错误。

---

## 部署迁移计划

### 前置条件
- Base Mainnet Deployer 余额充足 (部署2合约约需 0.005 ETH)
- V3 合约数据快照 (Agent/Attestation/RiskScore/Certificate 记录)

### 部署步骤
1. 部署 AgentPassport V3.1
2. 部署 AccessGateway V3.1
3. 重新授予 VERIFIER_ROLE (AgentPassport)
4. 更新 Gateway service 引用 (如适用)
5. E2E 验证

### 数据迁移
- AgentRegistry 和 CompliancePassport 无需变更
- AgentPassport: 需要重新签发 attestation（因为合约地址变更）
- AccessGateway: 活跃 session 需要重新建立

### 回退方案
- V3 合约继续运行，V3.1 并行部署
- 如 V3.1 发现问题，回退到 V3

---

## 决策建议

**当前评估**: V3 已在线上运行，2个 MEDIUM 问题影响有限：
- MEDIUM-1 (consumeProofOfAgent 无权限): 仅影响可用性，不影响数据完整性
- MEDIUM-2 (active 状态未检查): 属于设计完善性问题

**建议**: 
- 如 V3 刚部署不久 → 立即部署 V3.1 替换
- 如 V3 已运行较长时间且有数据 → 可在下一次版本迭代时升级
- 当前 V3 可安全运行，无紧急风险
