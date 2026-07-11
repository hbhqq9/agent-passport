# V3.1-Final Deployment (Base Mainnet)

## Contract Addresses

| Contract | Address | Version |
|----------|---------|---------|
| AgentRegistry | `0x594EeACA09186f86B7c4531b7cE63fb7480ce96C` | V3 (unchanged) |
| AgentPassport | `0x40B8A47A6A5249CDdB7428052f6Bd48f50D674cb` | V3.1 (unchanged) |
| CompliancePassport | `0x3222df200137106E8e99E696d11Fbb8eB5bFDB27` | V3.1-Complete |
| AccessGateway | `0x6ED1f3d164a11501E814fbd97D5405Add4f79d22` | V3.1-Final |

## V3.1 Fixes Applied

1. **[MEDIUM] consumeProofOfAgent 访问控制**: 仅允许 gatewayService 或 agentWallet 调用
2. **[MEDIUM] Agent active 状态检查**: verify/consume 均检查 Agent 活跃状态
3. **[MEDIUM] consumeProofOfAgent deadline**: 新增 deadline 参数防止签名永久有效
4. **[MEDIUM] _riskScores DoS 防护**: 每个 Agent 最多 100 条评分记录
5. **[LOW] Session ID 碰撞**: 增加 nonce 防止同块碰撞
6. **[LOW] platformId 验证**: requestAccess 检查平台已注册

## Root Cause: via-ir + string memory

Gateway 使用 `getAgentInfo()` (返回含 `string memory` 的 tuple) 在 `--via-ir` 优化模式下导致外部调用 revert。
修复方案: 改用 `isRegisteredAgent(address)` (返回 `bool`)，语义等价但无 string memory 问题。

## E2E Verification: 9/9 PASS

- verifyProofOfAgent: ✅
- consumeProofOfAgent + deadline: ✅
- Expired deadline rejection: ✅
- Nonce management: ✅
- Compliance proof consistency: ✅
- MAX_RISK_SCORE_RECORDS: ✅

Deployed: 2026-07-11
