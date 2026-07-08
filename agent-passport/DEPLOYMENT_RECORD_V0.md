# Agent Passport V0 — Base Mainnet Deployment Record

**首次部署**: 2026-07-08 09:50 CST（旧版，AgentRegistry/CompliancePassport 部署失败）
**V2重新部署**: 2026-07-08 10:55 CST（全部4个合约重新部署成功）
**网络**: Base Mainnet (Chain ID: 8453)
**端到端验证**: 2026-07-08 11:48 CST ✅ 全部通过

## 合约地址（V2 - 当前有效）

| 合约 | 地址 | 代码大小 | 层级 | 功能 |
|------|------|---------|------|------|
| **AgentRegistry** | `0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9` | 13,956 bytes | L1 | ERC-8004兼容Agent身份NFT |
| **AgentPassport** | `0x5eBD4fCE45754c34557a237dd59cecec7A410c87` | 11,065 bytes | L2 | 可验证凭证/属性声明系统 |
| **AccessGateway** | `0xC46C3538Ea1Ea3dc41b762A2b298DD3C4cc65594` | 12,770 bytes | L3 | Proof-of-Agent访问（替代CAPTCHA） |
| **CompliancePassport** | `0x1A086e034C7020CFE12d1ff8082Fc6aeD5787680` | 15,627 bytes | L3 | ERC-8126+ERC-8226可移植合规 |

## V2 部署交易

| 合约 | Tx Hash | Gas Used |
|------|---------|----------|
| AgentRegistry | `0xb2ff38ba3171f5ded95eff95d63ecd83ba89e9072ba6db524447baa7399aab69` | 3,178,980 |
| AgentPassport | `0x7b92fd1cf1520cc9581eb64fe653321693f93a414812f85505d5472feab69195` | 2,542,424 |
| CompliancePassport | `0x4f32dbaaf85d0eff2f3f9ec78401ad6da1207fff1e0eefb3ffc39b073da56a01` | 3,548,853 |
| AccessGateway | `0x04008f88ff89b71abb9014ae39cf0706f23f60688e38d2b934a4a46423fe9acb` | 2,882,463 |

## 端到端验证记录

### 前置操作
| 操作 | Tx Hash | 状态 |
|------|---------|------|
| VERIFIER_ROLE grant (AgentPassport) | `0x8b4db221fcefbbf66198a85a95dc42c0efa654a318b9bebe8affd3d11944ee5d` | ✅ |
| Agent #1 注册 | `0xa98d220646501afd821afd...` | ✅ |
| Agent #1 钱包绑定 (EIP-712) | `0xefb72bd55e050af02bcdd92269fd098001783943b021b8997b16569ff93db295` | ✅ |

### 核心功能验证
| 功能 | 结果 | 说明 |
|------|------|------|
| issueAttestation #1 (AGENT_TYPE) | ✅ | autonomous-agent |
| issueAttestation #2 (CAPABILITY) | ✅ | transaction-execution |
| issueAttestation #3 (COMPLIANCE) | ✅ | EU-AI-Act-Art50-transparent |
| recordRiskScore (25/100) | ✅ | 低风险评分 |
| issueCertificate (level=3) | ✅ | EU-AI-Act-Art50 合规证书 |
| Gateway verifyProofOfAgent | ✅ | isValid=True, agentId=1 |

## 依赖关系

```
AgentRegistry (无依赖) ← 基础层
    ↓
AgentPassport (依赖 AgentRegistry) ← 属性层
    ↓
AccessGateway (依赖 Registry + Passport) ← 访问层
CompliancePassport (依赖 Registry) ← 合规层
```

## 编译参数

- **Solidity**: 0.8.24
- **Optimizer**: enabled, 200 runs
- **ViaIR**: AgentPassport + AccessGateway（解决stack too deep）
- **OpenZeppelin**: v5.1.0

## 部署者

- **地址**: `0x903f5C71D87FCAb1FAC236F02Be94EF95Fa0Ea3B`
- **角色**: DEFAULT_ADMIN_ROLE（所有合约）、VERIFIER_ROLE（AgentPassport）、SCORER_ROLE（CompliancePassport）
- **部署后余额**: ~0.0056 ETH

## 旧版合约（已废弃）

| 合约 | 地址 | 状态 |
|------|------|------|
| AgentRegistry | `0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9` | ❌ 代码为空 |
| AgentPassport | `0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96` | ⚠️ 指向旧Registry |
| AccessGateway | `0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9` | ⚠️ 指向旧依赖 |
| CompliancePassport | `0x799B35c31DeF0fB679F46026f81743D397A27959` | ❌ 代码为空 |

## Python SDK

- **包名**: `agent-passport`
- **版本**: 0.1.0
- **发布状态**: 待发布至 PyPI（需要 API Token）
- **GitHub**: https://github.com/hbhqq9/agent-passport
- **Codeberg**: https://codeberg.org/agl-governance/erc8226-adapter
