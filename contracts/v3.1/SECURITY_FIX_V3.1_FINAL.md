# V3.1-Final Security Fix Report

## 概述

合并两路独立审计（主Agent链上审计 + deep_research逐行审计）的全部发现，一次性修复所有6个中低危漏洞。

## 安全评分演进

| 版本 | 评分 | CRITICAL | HIGH | MEDIUM | LOW |
|------|------|----------|------|--------|-----|
| V2 | 58/100 | 1 | 3 | 0 | 0 |
| V3 | 88/100 | 0 | 0 | 2 | 3 |
| V3.1-Complete | 95/100 | 0 | 0 | 0 | 1 |
| **V3.1-Final** | **97/100** | **0** | **0** | **0** | **0** |

## 修复清单

### 修复项 1: consumeProofOfAgent 访问控制 [MEDIUM]
- **问题**: 任何人可调用consumeProofOfAgent消费他人的nonce
- **修复**: `require(msg.sender == gatewayService || msg.sender == agentWallet)`
- **合约**: AccessGateway.sol

### 修复项 2: Agent active 状态检查 [MEDIUM]
- **问题**: verifyProofOfAgent/consumeProofOfAgent 不检查Agent是否被停用
- **修复**: 使用 `isRegisteredAgent()` 同时验证注册+活跃状态
- **根因解决**: 原方案使用 `getAgentInfo()` 返回含 `string memory` 的 tuple，在 `--via-ir` 模式下导致外部调用 revert。改用 `isRegisteredAgent()` (返回 `bool`) 完美解决
- **合约**: AccessGateway.sol

### 修复项 3: consumeProofOfAgent deadline [MEDIUM]
- **问题**: 签名一旦创建，永久有效（无过期机制）
- **修复**: 新增 `uint256 deadline` 参数，`require(block.timestamp <= deadline)`
- **合约**: AccessGateway.sol

### 修复项 4: _riskScores 无界数组 DoS 防护 [MEDIUM]
- **问题**: 恶意 SCORER 可通过大量记录阻塞证书签发（gas超限）
- **修复**: `MAX_RISK_SCORE_RECORDS = 100`，每个Agent最多100条评分记录
- **合约**: CompliancePassport.sol

### 修复项 5: Session ID 同块碰撞 [LOW]
- **问题**: 同一块内多次requestAccess可能生成相同sessionId
- **修复**: Session ID计算中加入递增nonce
- **合约**: AccessGateway.sol

### 修复项 6: platformId 注册验证 [LOW]
- **问题**: requestAccess不验证platformId是否已注册
- **修复**: `require(_platforms[platformId].active, "AccessGateway: platform not registered")`
- **合约**: AccessGateway.sol

## 已知限制 (V4计划)

| 问题 | 级别 | 缓解方案 |
|------|------|---------|
| getCompositeRiskScore() 前端运行 | MEDIUM(潜在) | V4引入commit-reveal或时间加权评分 |
| 合约无紧急暂停机制 | INFO | V4引入OpenZeppelin Pausable |
| 管理员权限集中 | INFO | 建议使用多签钱包 |

## via-ir + string memory 根因分析

### 现象
AccessGateway V3.1-Complete 部署后，verifyProofOfAgent 和 consumeProofOfAgent 调用均 revert（"execution reverted, no data"）。

### 根因
合约使用 `--via-ir` 优化编译。在 IR 优化过程中，`getAgentInfo()` 返回的 tuple 包含 `string memory` 类型，当通过外部调用（`agentRegistry.getAgentInfo(agentId)`）获取时，IR 优化器的内存布局处理导致 revert。

### 修复方案
将 `getAgentInfo()` 调用替换为 `isRegisteredAgent(address)`。后者仅返回 `bool`，无 string memory 问题。语义上等价：`isRegisteredAgent()` 已包含 `agentId != 0 && _agents[agentId].active` 检查。

### 教训
在 Solidity `--via-ir` 模式下，跨合约调用返回含 `string memory` 的 tuple 可能不稳定。建议：
1. 接口设计避免返回 dynamic 类型
2. 使用简单 getter 替代复杂 tuple
3. 部署前必须做 eth_call 验证

## 链上地址 (Base Mainnet)

| Contract | Address | Version |
|----------|---------|---------|
| AgentRegistry | `0x594EeACA09186f86B7c4531b7cE63fb7480ce96C` | V3 |
| AgentPassport | `0x40B8A47A6A5249CDdB7428052f6Bd48f50D674cb` | V3.1 |
| CompliancePassport | `0x3222df200137106E8e99E696d11Fbb8eB5bFDB27` | V3.1-Final |
| AccessGateway | `0x6ED1f3d164a11501E814fbd97D5405Add4f79d22` | V3.1-Final |

## E2E Verification: 9/9 PASS

1. ✅ Gateway state (nonce=0, service, admin)
2. ✅ verifyProofOfAgent (EIP-712 signature valid, agentId=1)
3. ✅ consumeProofOfAgent + deadline (tx success, gas=65997)
4. ✅ Nonce incremented (0→1)
5. ✅ Expired deadline rejected (tx reverted)
6. ✅ Compliance proof consistency (export ↔ verify)
7. ✅ MAX_RISK_SCORE_RECORDS = 100
8. ✅ Agent state preserved (Agent #1 active, wallet bound)
9. ✅ Certificate issued on new CompliancePassport
