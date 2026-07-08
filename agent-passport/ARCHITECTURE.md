# AGL Agent Passport — V0 Architecture

> **Agent Governance Layer (AGL)** — AI Agent 原生身份与访问平台
> 基于 ERC 标准栈的 V0 智能合约架构设计

---

## 1. 项目背景与问题

### 1.1 行业痛点

AI Agent 在跨平台操作中面临根本性障碍：

| 问题 | 描述 |
|------|------|
| **无法注册** | Agent 无法在任何 Web2 平台完成注册流程（邮箱/手机号验证） |
| **无法通过 CAPTCHA** | 验证码系统天然排斥非人类操作者 |
| **无法跨平台操作** | 每个平台有独立的身份体系，Agent 无法携带身份 |
| **无合规证明** | 缺乏标准化的合规状态证明机制 |

### 1.2 解决方案

**Wallet-First Identity**: 以钱包地址作为 Agent 身份锚点，通过密码学证明替代传统身份验证。Agent 用私钥签名代替邮箱注册，用 ZK 证明替代 CAPTCHA。

---

## 2. 标准栈与层级架构

### 2.1 ERC 标准栈

| 层级 | 标准 | 名称 | 状态 | 职责 |
|------|------|------|------|------|
| L1 | **ERC-8004** | Agent Identity Registration | Draft | Agent 链上身份注册（ERC-721 NFT） |
| L2 | **ERC-8196** | Authenticated Wallet | Last Call | 策略绑定的交易执行 |
| L2 | **ERC-8126** | Agent Verification/Risk Score | Finalized | 0-100 风险评分，ZK 验证 |
| L3 | **ERC-8226** | Regulated Agent Mandate | Draft | 合规委托（我们的 AGL 层） |
| L4 | **ERC-8263** | Behavior Attestation | Draft | 行为证明锚定 |
| L5 | **ERC-8183** | Agent Commerce Protocol | Draft | 商业交易层（Job 原语） |

### 2.2 V0 合约架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Application Layer (Web2/Web3)                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│   │ Web2 平台 │  │ DeFi 协议│  │ Agent 框架│  │ Compliance Engine │   │
│   └─────┬────┘  └─────┬────┘  └─────┬────┘  └────────┬─────────┘   │
│         │              │              │                 │              │
├─────────┴──────────────┴──────────────┴─────────────────┴──────────────┤
│                     L3: Access & Compliance Layer                       │
│  ┌────────────────────┐       ┌──────────────────────────┐             │
│  │  AccessGateway.sol │       │  CompliancePassport.sol  │             │
│  │  ───────────────── │       │  ─────────────────────── │             │
│  │  • Proof-of-Agent  │       │  • ERC-8126 风险评分集成  │             │
│  │  • OAuth-like flow │       │  • ERC-8226 委托状态集成  │             │
│  │  • Session 锚定    │       │  • 合规证明导出/验证      │             │
│  │  • PKCE 支持       │       │  • 多评分者聚合          │             │
│  └─────────┬──────────┘       └────────────┬─────────────┘             │
│            │                                │                           │
├────────────┴────────────────────────────────┴───────────────────────────┤
│                     L2: Identity Attributes Layer                       │
│  ┌──────────────────────────────────────────────────────────┐          │
│  │                  AgentPassport.sol                        │          │
│  │  ─────────────────────────────────────                    │          │
│  │  • Agent 属性存储 (类型/能力/合规状态)                     │          │
│  │  • 验证者 Attestation 签发                                │          │
│  │  • ERC-8196 Policy 集成                                  │          │
│  │  • 护照导出                                              │          │
│  └──────────────────────────┬───────────────────────────────┘          │
│                             │                                          │
├─────────────────────────────┴──────────────────────────────────────────┤
│                     L1: Identity Foundation Layer                       │
│  ┌──────────────────────────────────────────────────────────┐          │
│  │                  AgentRegistry.sol                        │          │
│  │  ─────────────────────────────────                       │          │
│  │  • ERC-721 NFT 身份                                      │          │
│  │  • 钱包地址绑定 (EIP-712)                                │          │
│  │  • 多链身份聚合                                          │          │
│  │  • 元数据系统                                            │          │
│  └──────────────────────────────────────────────────────────┘          │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 合约详细设计

### 3.1 AgentRegistry.sol — 身份注册

**职责**: 整个系统的信任基础层，每个 Agent 在此获得唯一的链上身份。

**核心机制**:

| 机制 | 说明 |
|------|------|
| ERC-721 NFT | 每个 Agent 是一个 NFT，拥有者可转移 |
| Wallet Binding | 通过 EIP-712 签名绑定 Agent 操作钱包 |
| Multi-chain | 同一 Agent 可注册多链身份，聚合展示 |
| Metadata | 支持 `agentWallet` 等保留键和自定义元数据 |

**ERC-8004 兼容性**:
- 实现 `register()` 三重重载函数
- 实现 `setAgentURI()` / `getMetadata()` / `setMetadata()`
- 实现 `Registered` / `MetadataSet` 事件
- 遵循 `agentWallet` 保留键规范
- 转账时自动清除钱包绑定

**多链身份聚合流程**:
```
Agent 在 Base 注册 → agentId=1
Agent 在 Ethereum 注册 → agentId=5
Agent 调用 registerChainIdentity(1, 1, 0xETH_REGISTRY, 5)
→ 建立 Base:1 ↔ Ethereum:5 的映射
```

### 3.2 AgentPassport.sol — 身份护照

**职责**: 存储 Agent 的身份属性，支持可信验证者签发 attestation。

**核心机制**:

| 机制 | 说明 |
|------|------|
| Agent Attributes | 类型/能力/合规状态等属性存储 |
| Verifier Attestation | VERIFIER_ROLE 持有者可签发证明 |
| Signature Attestation | 支持链下签名 + 链上提交 |
| ERC-8196 Policy | 绑定 Agent 策略到护照 |
| Passport Export | 链上可读的护照摘要 |

**Attestation 生命周期**:
```
验证者签发 → Active → 过期/撤销
    ↓
链上直接签发 (issueAttestation)
或 链下签名 + 链上提交 (issueAttestationBySignature)
```

### 3.3 AccessGateway.sol — 访问网关

**职责**: 让 Agent 用钱包签名替代传统登录方式，实现 Proof-of-Agent 替代 CAPTCHA。

**核心流程 — 直接访问**:
```
1. Agent 构造 AccessRequest
   ├─ platformId: "github.com"
   ├─ scopes: ["repo:read", "repo:write"]
   ├─ expiry: 当前时间 + 1h
   └─ 用 Agent 私钥 EIP-712 签名

2. 提交到链上 / 链下 Gateway 服务
   ├─ 验证签名有效性
   ├─ 检查 AgentRegistry 注册状态
   ├─ 检查 AgentPassport attestation
   └─ 检查 CompliancePassport 风险评分

3. Gateway 服务批准
   ├─ 调用 grantAccess() 锚定到链上
   ├─ 生成 JWT-like access token (链下)
   └─ 会话状态链上可查

4. Agent 使用 token 访问 Web2 平台
   └─ 平台侧验证 token 链上锚定状态
```

**核心流程 — OAuth-like 授权码**:
```
1. Agent → Platform: 请求授权码 (with PKCE)
2. Agent 签名 → 链上记录 codeHash
3. Gateway 验证 → 签发授权码
4. Agent → Gateway: 交换授权码 (with code_verifier)
5. Gateway → Agent: 返回 access_token
6. 会话锚定到链上
```

**Proof-of-Agent 替代 CAPTCHA**:
```
传统流程: 用户 → 填写邮箱 → 通过 CAPTCHA → 注册成功
AGL 流程: Agent → 钱包签名 → 链上身份验证 → 访问授权
```

### 3.4 CompliancePassport.sol — 合规护照

**职责**: 集成 ERC-8126 风险评分和 ERC-8226 合规状态，提供可移植的合规证明。

**ERC-8126 风险评分体系**:
```
评分范围: 0 (最安全) — 100 (最高风险)

五维检查模型:
├─ Token Verification (代币交互)
├─ Media Content Verification (内容合规)
├─ Solidity Code Verification (代码审计)
├─ Web Application Verification (Web 安全)
└─ Wallet Verification (钱包历史)

多评分者聚合:
  Score_A = 15 (Verifier A)
  Score_B = 22 (Verifier B)
  Score_C = 18 (Verifier C)
  → Composite = 18 (加权平均)
```

**ERC-8226 委托状态**:
```
Principal (KYC 验证通过的人/机构)
    │
    ├── 授权 Agent (委托范围/时间/金额上限)
    │
    └── MandateStatus
        ├── principal: 0xABC...
        ├── mandateExpiry: 2026-12-31
        ├── financialCap: 100 ETH
        ├── scopeHash: 0x... (授权范围)
        └── frozen: false
```

**合规等级映射**:
| 等级 | 名称 | 条件 |
|------|------|------|
| 5 | Fully Compliant | 综合评分 ≥ 90 |
| 4 | Mostly Compliant | 综合评分 ≥ 70 |
| 3 | Partially Compliant | 综合评分 ≥ 50 |
| 2 | Minimally Compliant | 综合评分 ≥ 30 |
| 1 | Non-Compliant | 综合评分 ≥ 10 |
| 0 | Unverified | 综合评分 < 10 |

---

## 4. 合约间交互关系

### 4.1 数据流图

```
                    ┌─────────────────┐
                    │  Agent Wallet   │
                    │  (Agent 私钥)    │
                    └────────┬────────┘
                             │ EIP-712 签名
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    AgentRegistry.sol                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐          │
│  │ Agent NFT│  │ Wallet   │  │ Multi-Chain      │          │
│  │ (ERC-721)│  │ Binding  │  │ Registration     │          │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘          │
│       │              │                 │                     │
│       │    getAgentByWallet()           │                     │
│       │    getAgentWallet()            │                     │
│       │    isRegisteredAgent()         │                     │
└───────┴──────────────┴─────────────────┴────────────────────┘
        │                │                    │
        │                ▼                    ▼
┌───────┴────────────────────────────────────────────────────┐
│                   AgentPassport.sol                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐    │
│  │  Attributes  │  │ Attestations │  │ ERC-8196      │    │
│  │  (属性存储)   │  │ (验证者签发)  │  │ Policy 集成   │    │
│  └──────┬───────┘  └──────┬───────┘  └───────────────┘    │
│         │                 │                                 │
│         │   getAttestation()  exportPassport()              │
│         │   isValidAttestation()                            │
└─────────┴─────────────────┴────────────────────────────────┘
          │                 │
          ▼                 ▼
┌─────────────────────┐  ┌──────────────────────────────────┐
│  AccessGateway.sol  │  │  CompliancePassport.sol           │
│  ┌───────────────┐  │  │  ┌────────────────────────────┐  │
│  │ Proof-of-Agent│  │  │  │ ERC-8126 Risk Score 集成   │  │
│  │ OAuth Flow    │  │  │  │ ERC-8226 Mandate 集成      │  │
│  │ Session Mgmt  │  │  │  │ Certificate 签发/导出      │  │
│  └───────┬───────┘  │  │  └────────────────────────────┘  │
│          │          │  │                                    │
└──────────┴──────────┘  └──────────────────────────────────┘
          │                        │
          ▼                        ▼
┌──────────────────────────────────────────────────────────┐
│                  External Systems                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │ Web2 平台 │  │ ERC-8263 │  │ ERC-8183 │  │ ZK Proofs│ │
│  │ (GitHub,  │  │ Behavior │  │ Commerce │  │ (评分   │  │
│  │  Twitter) │  │ Attest   │  │ Protocol │  │  证据)  │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
└──────────────────────────────────────────────────────────┘
```

### 4.2 关键交互路径

#### 路径 1: Agent 注册到访问平台

```
Agent Wallet
    │
    ├──→ AgentRegistry.register(agentURI)           → 获得 agentId
    ├──→ AgentRegistry.bindWallet(id, wallet, ...)   → 绑定操作钱包
    ├──→ AgentPassport.setAttribute(id, TYPE, ...)   → 声明能力
    ├──→ AccessGateway.requestAccess(platform, ...)  → 请求访问
    └──→ Gateway Service (off-chain)                 → 验证 + 签发 token
```

#### 路径 2: 合规评估

```
Verifier (SCORER_ROLE)
    │
    ├──→ CompliancePassport.recordRiskScore(id, 15, ...)  → 记录风险评分
    ├──→ CompliancePassport.recordComplianceCheck(id, KYC, ...)  → 通过合规检查
    └──→ CompliancePassport.issueCertificate(id, 4, ...)  → 签发合规证书
```

#### 路径 3: 合规委托 (ERC-8226)

```
Principal (KYC 验证的用户)
    │
    ├──→ CompliancePassport.recordMandate(id, principal, ...)  → 记录委托
    └──→ Agent 在委托范围内执行操作
```

---

## 5. 部署计划

### 5.1 Base 主网优先策略

| 阶段 | 内容 | 目标 |
|------|------|------|
| **Phase 0** | 单元测试 + 本地集成测试 | 确保合约逻辑正确 |
| **Phase 1** | Base Sepolia 测试网部署 | 端到端流程验证 |
| **Phase 2** | Base Mainnet 部署 | 生产环境上线 |
| **Phase 3** | 跨链扩展 (Ethereum, Arbitrum) | 多链身份聚合 |

### 5.2 部署顺序

合约存在依赖关系，必须按顺序部署：

```
Step 1: AgentRegistry.sol          ← 无依赖
    │
    ▼
Step 2: AgentPassport.sol          ← 依赖 AgentRegistry 地址
    │
    ├──→ Step 3a: AccessGateway.sol        ← 依赖 Registry + Passport
    │
    └──→ Step 3b: CompliancePassport.sol   ← 依赖 Registry
```

### 5.3 Base 部署参数

```
Network:         Base Mainnet (Chain ID: 8453)
Gas Token:       ETH
Block Time:      ~2s
EVM Version:     Shanghai (Cancun)
Solidity:        ^0.8.24

预计 Gas 消耗:
├─ AgentRegistry.register():        ~180,000 gas
├─ AgentRegistry.bindWallet():      ~80,000 gas
├─ AgentPassport.issueAttestation(): ~90,000 gas
├─ AccessGateway.requestAccess():   ~120,000 gas
└─ CompliancePassport.recordRiskScore(): ~85,000 gas
```

### 5.4 角色初始化

部署后需要初始化的角色：

| 角色 | 合约 | 初始分配 | 说明 |
|------|------|---------|------|
| `DEFAULT_ADMIN_ROLE` | 所有 | Deployer → 多签 DAO | 超级管理员 |
| `VERIFIER_ROLE` | AgentPassport | 初始验证团队 | 签发 attestation |
| `REGISTRAR_ROLE` | AgentPassport | 自动化注册服务 | 设置属性 |
| `SCORER_ROLE` | CompliancePassport | 合规评分服务 | 记录风险评分 |
| `COMPLIANCE_ORACLE_ROLE` | CompliancePassport | 合规预言机 | 记录委托状态 |
| Gateway Service | AccessGateway | 链下网关服务地址 | 批准访问 |

---

## 6. 安全考虑

### 6.1 关键安全风险

| 风险 | 等级 | 缓解措施 |
|------|------|---------|
| **钱包绑定欺骗** | 高 | EIP-712 签名 + nonce + deadline，三重防护 |
| **Attestation 伪造** | 高 | VERIFIER_ROLE 白名单 + 签名验证 |
| **重放攻击** | 中 | 所有签名均含 nonce + chainId + deadline |
| **评分操纵** | 中 | 多评分者聚合 + 时间权重 |
| **Gateway 中心化** | 中 | Gateway Service 地址可替换 + 链上可审计 |
| **NFT 转移后权限残留** | 低 | `_update` hook 自动清除钱包绑定 |
| **合规数据隐私** | 中 | 仅存储哈希，原始数据链下存储 |

### 6.2 设计原则

1. **最小权限**: 每个角色只拥有完成其功能所需的最小权限
2. **链上锚定 + 链下存储**: 敏感数据以哈希形式上链，原始数据存储在 IPFS/链下
3. **时间边界**: 所有签名、证书、策略都有明确的过期时间
4. **可撤销性**: Attestation、证书、委托均可撤销
5. **EIP-712 标准化**: 所有签名使用结构化数据签名，兼容硬件钱包
6. **ERC-165 接口检测**: 支持标准接口检测，便于集成

### 6.3 审计建议

- **Phase 1**: 自动化测试覆盖率 > 90%
- **Phase 2**: 外部安全审计（推荐：Trail of Bits / OpenZeppelin）
- **Phase 3**: Bug Bounty 计划
- **持续**: 监控异常交易模式

### 6.4 Upgrade Path (V0 → V1)

| V0 | V1 方向 | 说明 |
|----|---------|------|
| 固定合约 | Proxy (UUPS) | 可升级合约架构 |
| 单链注册 | CCIP 跨链 | 原生跨链身份 |
| EOA 签名 | ERC-4337 | 账户抽象集成 |
| 中心化 Gateway | 去中心化验证网络 | TEE + ZK 验证网络 |
| 手动评分 | 自动化评分 Pipeline | 链下评分服务 + 链上聚合 |

---

## 7. 技术依赖

```
OpenZeppelin Contracts v5.x:
├── @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol
├── @openzeppelin/contracts/access/Ownable.sol
├── @openzeppelin/contracts/access/AccessControl.sol
├── @openzeppelin/contracts/utils/cryptography/EIP712.sol
├── @openzeppelin/contracts/utils/cryptography/ECDSA.sol
└── @openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol

Solidity: ^0.8.24
License: MIT
```

---

## 8. 快速集成指南

### 8.1 Web2 平台集成

```javascript
// 平台侧验证 Agent 身份
async function verifyAgentAccess(walletAddress, signature, platformId) {
    // 1. 链上验证: 是否为注册的 Agent
    const agentId = await agentRegistry.getAgentByWallet(walletAddress);
    if (agentId === 0) throw new Error("Not a registered agent");

    // 2. 链上验证: 合规评分
    const { score } = await compliancePassport.getLatestRiskScore(agentId);
    if (score > 50) throw new Error("Risk score too high");

    // 3. 链上验证: 签名有效性
    const isValid = await accessGateway.verifyProofOfAgent(
        walletAddress, message, signature
    );
    if (!isValid) throw new Error("Invalid proof");

    // 4. 签发平台侧 access token
    return issuePlatformToken(walletAddress, platformId);
}
```

### 8.2 Agent 框架集成

```python
# Agent 侧: 注册 + 请求访问
from web3 import Web3

# 1. 注册 Agent 身份
tx = agent_registry.functions.register(agent_uri).transact({'from': wallet})
agent_id = agent_registry.functions.totalAgents().call()

# 2. 绑定钱包
nonce = agent_registry.functions.walletBindingNonce(agent_id).call()
message = encode_typed_data({...})
signature = wallet.sign_typed_data(message)
agent_registry.functions.bindWallet(agent_id, wallet, deadline, signature).transact()

# 3. 请求访问平台
access_request = encode_access_request(platform_id, scopes, expiry)
signature = wallet.sign_typed_data(access_request)
session_id = access_gateway.functions.requestAccess(
    platform_id, scopes, expiry, signature
).transact({'from': wallet})
```

---

*文档版本: V0.1.0 | 生成时间: 2026-06 | 适用网络: Base Mainnet (8453)*
