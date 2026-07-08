# Agent Passport V0 — Base Mainnet Deployment Record

**部署日期**: 2026-07-08 09:50 CST
**网络**: Base Mainnet (Chain ID: 8453)
**总Gas费用**: 0.000083 ETH (~$0.11)

## 合约地址

| 合约 | 地址 | 层级 | 功能 |
|------|------|------|------|
| **AgentRegistry** | `0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9` | L1 | ERC-8004兼容Agent身份NFT |
| **AgentPassport** | `0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96` | L2 | 可验证凭证/属性声明系统 |
| **AccessGateway** | `0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9` | L3 | Proof-of-Agent访问（替代CAPTCHA） |
| **CompliancePassport** | `0x799B35c31DeF0fB679F46026f81743D397A27959` | L3 | ERC-8126+ERC-8226可移植合规 |

## 部署交易

| 合约 | Tx Hash | Block | Gas Used |
|------|---------|-------|----------|
| AgentRegistry | `0x5e54d3c0758a67dc753e55b750a30044e242cce56435bb1a94ef74d2806a0269` | 48,343,129 | 3,000,000 |
| AgentPassport | `0xd36cc028fb103c601efe82858bc8eb8141cebbe16d5b5e98100aa62620fd858d` | 48,343,129 | 2,542,424 |
| AccessGateway | `0x7bc4ad6ff7062e0675be391a1abdd4e3caa5f89ffaae3f24a10b31b50ab74d37` | 48,343,130 | 2,882,463 |
| CompliancePassport | `0x6129251eb6a0c3d7f551f290b8b708c428ce1bfa326d86d2dc4a5b5e43a2d951` | 48,343,130 | 3,000,000 |

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
- **角色**: DEFAULT_ADMIN_ROLE（所有合约）
- **部署后余额**: 0.009543 ETH

## 下一步

1. 注册首个Agent身份（测试AgentRegistry.register()）
2. 发行首个Attestation（测试AgentPassport.issueAttestation()）
3. 测试AccessGateway的Proof-of-Agent流程
4. 创建SDK（TypeScript + Python）
5. 上传源码到Codeberg仓库
