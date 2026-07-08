# Agent Passport V0 白皮书

## 面向 Web2 互操作的 Agent 原生身份与访问层

**版本：** 0.1.0  
**日期：** 2026年7月  
**状态：** 草案  
**网络：** Base 主网（Chain ID: 8453）  
**许可证：** MIT

---

## 目录

1. [执行摘要](#1-执行摘要)
2. [问题陈述](#2-问题陈述)
3. [市场分析](#3-市场分析)
4. [解决方案架构](#4-解决方案架构)
5. [技术设计](#5-技术设计)
6. [差异化定位](#6-差异化定位)
7. [商业模式](#7-商业模式)
8. [路线图](#8-路线图)
9. [团队与生态](#9-团队与生态)
10. [风险分析](#10-风险分析)
11. [治理](#11-治理)
12. [参考文献](#12-参考文献)

---

## 1. 执行摘要

AI Agent 经济已跨越关键门槛。截至2026年中，**ERC-8004 已在链上注册超过17万个 Agent**，ERC 标准栈——包括 ERC-8004（身份）、ERC-8126（验证）、ERC-8183（商务）、ERC-8196（认证钱包）、ERC-8226（受管授权）和 ERC-8263（证明层）——已为链上 Agent 的身份、验证、商务和合规建立了全面的信任层。然而一个根本性缺口依然存在：**Agent 无法跨 Web2 平台运行**。

全球开发者构建的 AI Agent 无法注册 GitHub 账号、在 Discord 服务器上进行身份验证、向仓库提交代码、在 Twitter 上发帖，也无法与专为人类用户设计的数百万 Web2 服务进行交互。整个 Web2 平台生态——价值数万亿美元、服务数十亿用户——对当前拥有可验证链上身份的17万多个 Agent 来说完全不可访问。这不是一个小的不便；而是一个结构性障碍，阻碍了 Agent 经济充分发挥其潜力。

**Agent Passport（Agent护照）** 是连接链上 Agent 身份与 Web2 平台访问的身份和访问层。Agent Passport 源自构建 Agent 治理层（AGL）以满足 Art.50 监管合规要求的实际挑战，提供四大核心能力：

1. **Agent 原生身份（Agent-Native Identity）** — 基于 ERC-721 的身份体系，通过 EIP-712 签名实现钱包绑定，支持跨 Base、Ethereum 和 Arbitrum 的多链身份聚合。
2. **可验证护照（Verifiable Passport）** — 针对 Agent 能力、合规状态和授权范围的受信任认证系统，实现任何平台均可验证的可移植凭证。
3. **Agent 证明访问（Proof-of-Agent Access）** — 加密身份证明机制，取代 CAPTCHA 和邮箱验证，使 Agent 能够使用其链上身份和钱包签名向 Web2 平台进行身份验证。
4. **可移植合规（Portable Compliance）** — 将 ERC-8126 风险评分和 ERC-8226 授权委托整合为单一可组合合规层，随 Agent 跨平台和跨链携带。

Agent Passport **不与** Agent 钱包（Coinbase、Cobo、Crossmint）或链上身份注册中心（ERC-8004）竞争。相反，它位于这些层**之上**，作为授权和互操作原语——即证明 Agent 是谁及其被授权做什么的"护照"，适用于链上和链下环境。钱包是保险库；Agent Passport 是护照。

我们在 Base 主网上的概念验证（PoC）展示了**每事件 $0.000752 的部署成本**——使 Agent 身份操作的成本比任何现有 Web2 身份基础设施低几个数量级，后者通过 Auth0 或 Okta 等服务的单次身份验证事件成本为 $0.01–$0.10。目前已有六份合约部署在 Base 主网上，并已向钱包、框架、平台和合规提供商等潜在生态合作伙伴发送了27封商务拓展函。

竞争格局分析覆盖了**六个赛道共25个项目**，结果显示 Agent 到 Web2 的桥接是一个完全未被服务的市场。Visa 的 Trusted Agent Protocol 仅解决商务交互。Microsoft Entra Agent ID 仅覆盖 Microsoft 生态内的企业 OAuth。没有任何项目提供统一的、Agent 原生的身份护照，将链上身份桥接到全平台生态的 Web2 服务访问。Agent Passport 的设计目标就是占据这一空白领域。

---

## 2. 问题陈述

### 2.1 起源：AGL 实战痛点（Operational Pain Points）

Agent Passport 源自构建 **Agent 治理层（AGL）** 的直接运营经验——这是一个面向在 Art.50 监管要求下运行的 AI Agent 的合规框架。在 AGL 开发过程中，我们遇到了一组每个 Agent 开发者都面临的基础性、未解决的问题：

| 问题 | 描述 | 实际影响 |
|------|------|----------|
| **无法注册** | Agent 无法完成任何 Web2 平台的注册流程，因为邮箱和短信验证需要人类介入 | Agent 被完全锁在平台经济之外 |
| **CAPTCHA 屏障** | reCAPTCHA 和 hCaptcha 等验证系统从设计上就排除非人类操作者 | 与受保护平台的每一次自动化交互都会被阻止 |
| **身份碎片化** | 每个平台维护自己的身份系统（GitHub OAuth、Discord 令牌、Twitter API 密钥）；Agent 无法跨平台携带身份 | 不存在可移植的 Agent 身份；每个平台需要单独的凭证管理 |
| **无合规证明** | 不存在标准化机制来向平台证明 Agent 的合规状态 | 受监管操作无法执行；平台无法验证 Agent 是否满足其合规要求 |

这些不是理论问题。它们是当今每个构建 AI Agent 的开发者的**日常运营现实**。请看这些具体场景：

- 像 Claude Code 或 Cursor 这样的 AI 编码 Agent，在没有人类手动配置令牌和权限的情况下，无法独立推送到 GitHub 仓库。
- 社区管理 Agent 无法加入 Discord 服务器，因为验证流程需要邮箱确认，可能还需要解决 CAPTCHA。
- 研究 Agent 无法访问需要邮箱登录的学术论坛或向评审平台提交论文。
- 交易 Agent 无法在需要 KYC 或邮箱验证才能获取 API 访问权限的新 DeFi 平台上注册。

在每种情况下，Agent 都拥有可验证的链上身份（如果已注册 ERC-8004），但这个身份对 Web2 平台访问毫无用处。链上世界和 Web2 世界如同平行宇宙，彼此之间没有桥梁。

### 2.2 问题的规模

当以下几个数据点汇聚在一起时，问题的规模就变得清晰了：

- **17万多个 Agent** 通过 ERC-8004 注册在链上（截至2026年5月），每个都有可验证身份，但无法在链下使用。随着 ERC-8004 标准在生态中获得更广泛采用，这一数字正在快速增长。
- AI Agent 在互联网上的流量**激增 4,700%**，由 Visa 在其 TAP 公告中报告（2025年）。然而每一次交互都需要人类介入——Agent 正在涌入互联网，但无法正确地进行身份验证。
- **25个以上项目**在六个竞争赛道中构建 Agent 身份基础设施，**没有一个**解决了 Web2 桥接问题。整个创新力量集中在链上层，将 Web2 缺口完全搁置。
- 整个 Web2 平台经济——GitHub 的1亿以上开发者、Discord 的1.5亿以上月活用户、Twitter 的5亿以上用户、Slack 的3800万以上日活用户——都是为人类身份验证流程设计的，从根本上排除了 Agent。

### 2.3 为什么现有方案行不通

ERC 标准栈虽然在链上操作方面很全面，但存在一个关键盲点，没有任何标准加以解决：

- **ERC-8004** 赋予 Agent 链上身份（一个 `agentId`、一个 NFT、一个声誉）。但智能合约无法登录 GitHub。该标准没有提供将链上身份转化为 Web2 凭证的机制。
- **ERC-8126** 提供风险评分和多维度验证。但平台没有标准化方式来在其身份验证决策中消费这些评分。
- **ERC-8196** 定义了带有审计跟踪的策略绑定钱包执行。但它不解决平台身份验证——它管理的是 Agent 可以用钱包做什么，而不是如何向外部服务证明身份。
- **ERC-8226** 处理受监管授权和委托链。但它假设 Agent 已经拥有平台访问权限。你无法将权力委托给一个根本无法在平台上注册的 Agent。
- **ERC-8183** 通过托管和声誉实现 Agent 间商务。但 Agent 仍然无法在商务发生的平台上注册。
- **ERC-8263** 锚定行为证明和推理证明。但当 Agent 根本无法访问平台时，就没有行为数据可供锚定。

**没有任何 ERC 标准解决 Agent 到 Web2 的身份验证问题。** 标准栈解决了身份、验证、商务、合规和证明——但没有解决访问。这正是 Agent Passport 填补的缺口。它是"Agent 存在于链上"与"Agent 可以在开放互联网上运行"之间缺失的那一层。

### 2.4 缺口的经济成本

Agent 无法访问 Web2 平台造成了可衡量的经济摩擦：

1. **开发者生产力损失**：每个 AI 编码 Agent 都需要人类配置的凭证，每个 Agent 每个平台增加30-60分钟的设置时间。规模化来看，每天部署数千个 Agent，这意味着数百万小时的不必要人力劳动。

2. **平台锁定**：没有可移植身份，Agent 被困在已手动配置凭证的平台内。这阻碍了 Agent 实用性所必需的多平台运行。

3. **合规不可能**：受监管行业（金融、医疗、法律）无法大规模部署 Agent，因为无法向平台运营方证明 Agent 的合规状态。合规层存在（ERC-8226），但没有桥接到 Agent 需要运行的平台。

4. **审计缺口**：当 Agent 通过人类配置的凭证与 Web2 平台交互时，没有链上审计跟踪将 Agent 的链上身份与其链下行为连接起来。这使得问责和取证变得不可能。

---

## 3. 市场分析

### 3.1 竞争格局：25个项目矩阵

我们的全面分析识别了**六个竞争赛道中的25个实体**。以下分析按赛道、成熟阶段和与 Agent Passport 的战略关系对每个项目进行分类。

#### 赛道一：链上身份标准（基础层）

| 项目 | 标准 | 状态 | 关键指标 | 关系 |
|------|------|------|----------|------|
| ERC-8004 | Agent 身份注册 | 草案（主网已上线，2026年1月） | **17万+ Agent 已注册** | 基础层——Agent Passport 在其之上构建 |
| ERC-8126 | Agent 验证 | **终稿**（2026年6月） | 5层验证，0-100风险评分 | 互补——我们消费其风险评分 |
| ERC-8183 | Agent 商务协议 | 草案 | ACP 已在 Arbitrum 上线 | 互补——身份之上的商务层 |
| ERC-8196 | 认证钱包 | 草案（最后征集） | 无生产实现 | 在策略绑定执行方面部分重叠 |
| ERC-8226 | 受监管授权 | 草案 | GhostAgent 原型仅在 Gnosis 上 | 未来合作伙伴——受监管委托 |
| ERC-8263 | 链上证明层 | 草案（参考实现已上线） | 多链部署 | 互补——推理溯源 |

在这六项标准中，只有 **ERC-8004** 和 **ERC-8126** 有实质性的生产部署。ERC-8196、ERC-8226 和 ERC-8183 仍处于规范或早期原型阶段。这种标准成熟度差距强化了对实用协议层（Agent Passport）的需求——一个能与当前已有生产实现的标准协同工作的协议层。

#### 赛道二：Agent 钱包（红海——我们不在这里竞争）

| 项目 | 阶段 | 安全模型 | 核心差异化 |
|------|------|----------|-----------|
| Coinbase Agentic Wallet | 生产 | TEE（可信执行环境） | x402 支付支持；Coinbase 分发渠道 |
| Cobo Agentic Wallet | 生产 | MPC（多方计算） | Pact 协议；80+链；按任务授权 |
| Crossmint | 生产 | 智能合约 + 密钥管理 | MiCA 持牌；银行卡 + 稳定币 + 法币通道 |
| Turnkey | 生产 | 非托管飞地 API | 策略引擎，支持限额和白名单 |
| Privy（2025年6月被 Stripe 收购） | 生产 | 嵌入式 + 服务端钱包 | Stripe 稳定币集成 |
| Fireblocks | 生产 | 机构级托管 | 9000万美元收购 Dynamic；超10万亿美元担保交易 |

所有六家钱包提供商都趋同于**"钱包即可调用服务"**模式——Agent 从不直接持有私钥。这种架构共识验证了我们的战略决策：**Agent Passport 不构建钱包基础设施**。我们与这些提供商集成，作为位于钱包之上的身份和授权层。钱包是保险库；Agent Passport 是证明 Agent 是谁及其被授权做什么的护照。

#### 赛道三：全栈平台和 L1 链（最接近的竞争者）

| 项目 | 阶段 | 融资 / 牵引力 | 与 Agent Passport 的差距 |
|------|------|-------------|------------------------|
| **Virtuals Protocol** | 生产 | 隐含估值 3300万+；1.7万 Agent；4.79亿美元 aGDP | Base 原生，以代币化为中心，无 Web2 桥接 |
| **Kite** | 测试网 | 总计 3300万（PayPal Ventures、Samsung） | L1 链方案 vs. 我们的协议方案 |

Virtuals Protocol 是范围上最接近的竞争者，但其重点根本不同：它将 Agent 视为可投资资产（创建、代币化、交易），而非自主运营者（识别、验证、访问）。Agent Passport 瞄准的是后者用例。

#### 赛道四：企业身份验证与 Web2 桥接（部分竞争者）

| 项目 | 阶段 | 范围 | 与 Agent Passport 的差距 |
|------|------|------|------------------------|
| **Visa TAP** | 试点（2025年10月） | 仅限商务（浏览 + 支付） | 不支持 GitHub/Discord/论坛访问；仅商务 |
| **Microsoft Entra Agent ID** | 生产 | 面向 Agent 的企业 OAuth | 仅 Web2；无链上身份；绑定 Microsoft 生态 |
| **Auth0（Okta）** | 生产 | 面向 Agent 的企业 CIAM | 无 Agent 原生身份；仅 Web2 原生 |
| **Incode Agentic Identity** | 试点（2025年四季度） | 通过生物特征实现人-Agent 绑定 | 以人为中心；不赋予 Agent 独立可移植身份 |

Visa TAP 是最值得关注的部分竞争者。2025年10月与 Cloudflare 联合推出，TAP 使用 HTTP Message Signatures（RFC 9421）来验证 AI Agent 是否被信任进行商务交易。其合作伙伴名单——Stripe、Shopify、Coinbase、Microsoft、Adyen、Akamai——令人瞩目。但 TAP 仅解决一个狭窄的切面：商务特定的 Web2 交互。它不使 Agent 能够注册 GitHub 账号、在 Discord 发帖、向仓库提交代码，或与大量非商务平台交互。Agent Passport 将身份桥接扩展到全平台生态。

#### 赛道五：人类身份（互补）

| 项目 | 规模 | 验证方式 | 为何对 Agent 不足 |
|------|------|----------|------------------|
| World ID | 1800万已验证人类 | Orb 设备虹膜扫描 | 需要生物验证；Agent 无法前往 Orb |
| Civic | 有限公开数据 | 政府 ID + 活体检测 | 为人类身份证件设计 |
| EAS | 850万+证明 | 任何签名声明 | 原始原语；缺乏 Agent 特定图式和平台集成 |

World ID 最近增加了"World ID for agents"——用于证明一个已验证人类在 Agent 背后支持的基础设施。这与 Agent Passport 互补（有人类背书的 Agent 仍然需要护照来访问平台），但与赋予 Agent 自身独立身份有根本不同。

#### 赛道六：基础设施合作伙伴（集成，不竞争）

| 项目 | 角色 | 集成点 |
|------|------|--------|
| agentgateway（Linux 基金会 / Solo.io） | Agent 流量路由 | 我们的身份断言通过其 HTTP/gRPC/MCP/A2A 数据面流转 |
| OpenClaw | 多渠道（20+即时通讯平台） | 我们提供身份；他们提供消息路由 |
| Browserbase / Browserless | 云原生隐身浏览器 | 他们提供浏览器执行；我们提供用于身份验证的身份 |
| AgentQL | 语义 Web 数据提取 | 他们提取数据；我们验证提取数据的 Agent |
| zkMe | 基于 ZK 的信任网关 | MCP/A2A 协议的 ZK 验证 |
| Metaplex Agent Registry | Solana Agent 身份 | 跨链身份互补 |

### 3.2 护照缺口：市场定位

竞争格局揭示了清晰的象限分析：

```
                    链上侧重 ←————→ Web2 侧重
                         │                    │
    Agent 原生           │  [空白地带]        │  ★ Agent Passport
    （身份模型）          │  （我们的目标）     │    （我们的位置）
                         │                    │
    ─────────────────────┼────────────────────┼────────────
                         │                    │
    人类衍生             │  ERC-8004          │  Visa TAP
    （身份模型）          │  ERC-8126          │  Microsoft Entra
                         │  Virtuals Protocol │  World ID
                         │                    │
```

**右上象限——Agent 原生身份 + Web2 侧重——完全空白。** 没有现有项目占据这个空间。项目要么侧重链上（ERC-8004、Virtuals），要么侧重 Web2（Visa TAP、Microsoft Entra），采用人类衍生身份模型。Agent Passport 的设计目标是独占这个象限。

### 3.3 市场时机：三大趋势汇聚

1. **标准栈成熟**：ERC-8004 已主网上线，17万+ Agent。ERC-8126 于2026年6月达到终稿状态——Agent 标准栈中第一个达到终稿的 ERC。基础稳固，已准备好迎接更高层协议。

2. **Agent 流量爆发**：Visa 报告 AI Agent 流量激增 4,700%。平台正在积极寻找识别、验证和管理 Agent 交互的方式——只是还没有基础设施。需求拉动是真实且增长的。

3. **钱包层共识**：随着 Coinbase、Cobo、Crossmint 和 Stripe（通过收购 Privy）都在构建 Agent 钱包，"钱包即可调用服务"模式已成为既定架构共识。钱包之上的身份层是自然的下一个构建方向——而今天它完全未被构建。

---

## 4. 解决方案架构

### 4.1 设计原则

Agent Passport 基于五项架构原则构建，指导每一个设计决策：

1. **协议，而非平台** — Agent Passport 跨链跨平台运行，不锁定在单一生态。合约可部署在任何 EVM 链上；访问协议与平台无关。

2. **钱包之上的层** — Agent Passport 与现有 Agent 钱包（Coinbase、Cobo、Crossmint）集成，而非与之竞争。钱包持有资产；护照持有身份和授权。

3. **链上锚定，链下执行** — 身份和授权决策锚定在链上以保证可验证性和可审计性。实际 Web2 交互通过网关服务在链下进行，以保证性能和兼容性。

4. **与 ERC 标准可组合** — Agent Passport 构建在 ERC-8004 身份之上，消费 ERC-8126 风险评分，支持 ERC-8226 授权，并记录与 ERC-8263 兼容的行为证明。它是标准栈中的可组合层，而非竞争性标准。

5. **加密证明优于人类验证** — EIP-712 结构化签名取代邮箱验证。链上身份取代 CAPTCHA。整个系统为 Agent 设计，而非从人类流程改造。

### 4.2 四合约架构

Agent Passport V0 由四份智能合约组成，按三层栈组织（L1 基础层 → L2 属性层 → L3 访问/合规层）：

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        应用层（Web2 / Web3）                                      │
│                                                                                  │
│   ┌───────────┐  ┌────────────┐  ┌─────────────┐  ┌────────────────────────┐   │
│   │ Web2      │  │ DeFi       │  │ Agent       │  │ 合规                   │   │
│   │ 平台      │  │ 协议       │  │ 框架        │  │ 引擎                   │   │
│   │ (GitHub,  │  │            │  │ (LangChain, │  │ (ERC-8126 评分器,     │   │
│   │  Discord, │  │            │  │  CrewAI,    │  │  KYC 提供商,          │   │
│   │  Twitter) │  │            │  │  MCP)       │  │  受监管实体)          │   │
│   └─────┬─────┘  └─────┬──────┘  └──────┬──────┘  └──────────┬─────────────┘   │
│         │               │                │                     │                 │
├─────────┴───────────────┴────────────────┴─────────────────────┴──────────────────┤
│                     L3: 访问与合规层                                                │
│                                                                                    │
│   ┌───────────────────────────┐     ┌──────────────────────────────────────┐     │
│   │   AccessGateway.sol       │     │   CompliancePassport.sol             │     │
│   │   ─────────────────────── │     │   ────────────────────────────────── │     │
│   │   • Proof-of-Agent        │     │   • ERC-8126 风险评分集成            │     │
│   │     （Agent证明）          │     │   • ERC-8226 授权委托               │     │
│   │   • 类 OAuth 流程         │     │   • 合规证书                        │     │
│   │   • 会话锚定              │     │   • 多评分器聚合                    │     │
│   │   • PKCE 支持             │     │   • 证书生命周期                    │     │
│   │   • 访问撤销              │     │   •                                  │     │
│   └─────────────┬─────────────┘     └──────────────┬───────────────────────┘     │
│                 │                                   │                             │
├─────────────────┴───────────────────────────────────┴─────────────────────────────┤
│                     L2: 身份属性层                                                  │
│                                                                                    │
│   ┌─────────────────────────────────────────────────────────────────────────┐     │
│   │                     AgentPassport.sol                                    │     │
│   │   ──────────────────────────────────────────────                        │     │
│   │   • Agent 属性（类型 / 能力 / 合规状态）                                 │     │
│   │   • 受信任验证者认证系统（VERIFIER_ROLE）                                │     │
│   │   • 链下签名 + 链上提交（无 Gas 认证）                                  │     │
│   │   • ERC-8196 策略绑定                                                   │     │
│   │   • 可移植护照导出，用于链下出示                                         │     │
│   └────────────────────────────────────┬────────────────────────────────────┘     │
│                                        │                                          │
├────────────────────────────────────────┴──────────────────────────────────────────┤
│                     L1: 身份基础层                                                  │
│                                                                                    │
│   ┌─────────────────────────────────────────────────────────────────────────┐     │
│   │                     AgentRegistry.sol                                    │     │
│   │   ──────────────────────────────────────────────                        │     │
│   │   • ERC-721 NFT 身份（完全兼容 ERC-8004）                               │     │
│   │   • 通过 EIP-712 签名授权实现钱包绑定                                    │     │
│   │   • 多链身份聚合                                                        │     │
│   │   • 可扩展元数据系统，含保留键                                           │     │
│   └─────────────────────────────────────────────────────────────────────────┘     │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 合约依赖与部署顺序

四份合约存在严格的依赖关系，需要按顺序部署：

```
步骤 1: AgentRegistry.sol           ← 无依赖（基础）
    │
    ▼
步骤 2: AgentPassport.sol           ← 依赖 AgentRegistry 地址
    │
    ├──→ 步骤 3a: AccessGateway.sol      ← 依赖 Registry + Passport
    │
    └──→ 步骤 3b: CompliancePassport.sol ← 依赖 Registry
```

### 4.4 部署参数

所有合约目标为 Base 主网，规格如下：

| 参数 | 值 |
|------|-----|
| 网络 | Base 主网（Chain ID: 8453） |
| Gas 代币 | ETH |
| 出块时间 | ~2 秒 |
| EVM 版本 | Shanghai (Cancun) |
| Solidity | ^0.8.24 |
| 依赖 | OpenZeppelin Contracts v5.x |

**预估 Gas 消耗：**

| 操作 | Gas | 成本（按 Base 价格） |
|------|-----|---------------------|
| AgentRegistry.register() | ~180,000 gas | ~$0.000136 |
| AgentRegistry.bindWallet() | ~80,000 gas | ~$0.000060 |
| AgentPassport.issueAttestation() | ~90,000 gas | ~$0.000068 |
| AccessGateway.requestAccess() | ~120,000 gas | ~$0.000090 |
| CompliancePassport.recordRiskScore() | ~85,000 gas | ~$0.000064 |

所有操作的加权平均成本为**每事件 $0.000752**——已通过 PoC 在 Base 主网部署验证。

### 4.5 端到端交互流程

Agent 从注册到 Web2 平台访问的完整生命周期：

```
阶段 1：身份创建
═══════════════════════════
Agent 开发者
    │
    ├──→ AgentRegistry.register(agentURI)
    │         → 返回 agentId（ERC-721 NFT）
    │         → 链上：Base 主网
    │
    └──→ AgentRegistry.bindWallet(agentId, wallet, deadline, signature)
              → EIP-712 签名绑定
              → 将 Agent 身份链接到运营钱包

阶段 2：护照充实
═════════════════════════════
验证者（受信任方）
    │
    ├──→ AgentPassport.setAttribute(agentId, TYPE, value)
    │         → Agent 类型、能力、合规状态
    │
    ├──→ AgentPassport.issueAttestation(agentId, schema, data)
    │         → 由 VERIFIER_ROLE 持有者签发签名认证
    │
    └──→ CompliancePassport.recordRiskScore(agentId, score, evidence)
              → ERC-8126 五维风险评估

阶段 3：Web2 平台访问
══════════════════════════════
Agent（通过钱包）
    │
    ├──→ 构建 AccessRequest
    │         ├─ platformId: "github.com"
    │         ├─ scopes: ["repo:read", "repo:write"]
    │         ├─ expiry: now + 1h
    │         └─ 来自 Agent 钱包的 EIP-712 签名
    │
    ├──→ AccessGateway 链上验证
    │         ├─ ✓ AgentRegistry：是否为已注册 Agent？
    │         ├─ ✓ AgentPassport：是否有有效认证？
    │         └─ ✓ CompliancePassport：风险评分是否可接受？
    │
    ├──→ AccessGateway.grantAccess()
    │         → 会话锚定在链上
    │         → 链下签发类 JWT 访问令牌
    │
    └──→ Agent 使用令牌访问 Web2 平台
              → 平台可独立验证链上会话锚点

阶段 4：合规生命周期
══════════════════════════════
委托人（KYC 已验证实体）
    │
    ├──→ CompliancePassport.recordMandate(agentId, principal, scope, cap)
    │         → ERC-8226 合规委托
    │
    └──→ Agent 在委托范围内运行
              → 所有行为可链上验证
              → 委托人责任明确定义
```

---

## 5. 技术设计

### 5.1 AgentRegistry.sol — 身份基础

**用途：** 整个系统的信任锚点。每个 Agent 在此获得唯一、可转让的链上身份。该合约是所有其他组件依赖的基础。

**核心机制：**

| 机制 | 实现 | 标准 | 安全模型 |
|------|------|------|----------|
| Agent 身份 | ERC-721 NFT——每个 Agent 是唯一、可转让的代币 | ERC-8004 | 所有权可转让；身份跟随 NFT |
| 钱包绑定 | EIP-712 类型化数据签名，含 nonce + deadline | 自定义（EIP-712） | 三层保护：类型化数据 + nonce + deadline |
| 多链聚合 | `registerChainIdentity()` 跨链映射身份 | 自定义 | 链特定注册表地址链上验证 |
| 元数据系统 | 保留键（`agentWallet`）+ 可扩展自定义键 | ERC-8004 | 保留键受保护；自定义键由所有者控制 |

**ERC-8004 兼容性：** AgentRegistry 实现了完整的 ERC-8004 注册接口：

- `register()` 提供三种重载用于不同注册流程（直接注册、委托注册和预签名注册）
- `setAgentURI()` / `getMetadata()` / `setMetadata()` 用于 Agent 元数据管理
- `Registered` / `MetadataSet` 事件用于子图和浏览器的链下索引
- `agentWallet` 保留键，遵循 ERC-8004 规范
- NFT 转账时自动清除钱包绑定——当 Agent NFT 被转让时，之前的钱包绑定自动清除，防止前所有者未授权访问

**多链身份流程：**

```
Agent 在 Base 注册       → agentId = 1
Agent 在 Ethereum 注册   → agentId = 5  
Agent 调用 registerChainIdentity(1, 1, 0xETH_REGISTRY, 5)
→ 建立 Base:1 ↔ Ethereum:5 双向映射
→ 跨链单一 Agent 身份
→ 支持跨链声誉和凭证可移植性
```

### 5.2 AgentPassport.sol — 身份属性与认证

**用途：** 丰富的身份层。AgentRegistry 提供"身份证号码"，AgentPassport 提供"证书"——关于 Agent 能力、合规状态和授权范围的可验证声明。这是平台在决定是否授予访问权限时消费的数据层。

**核心机制：**

| 机制 | 描述 | 访问控制 | 可撤销性 |
|------|------|----------|----------|
| Agent 属性 | 键值存储，记录 Agent 类型、能力、合规状态 | REGISTRAR_ROLE | 所有者可更新 |
| 验证者认证 | 受信任验证者就 Agent 签发签名认证 | VERIFIER_ROLE | 验证者可撤销 |
| 签名认证 | 链下签名 + 链上提交，实现无 Gas 认证 | VERIFIER_ROLE | 验证者可撤销 |
| ERC-8196 策略 | 将执行策略绑定到 Agent 身份 | 所有者 / Agent | 所有者可更新 |
| 护照导出 | 生成人类可读的护照摘要，用于链下出示 | 公开（view） | 不适用 |

**认证生命周期：**

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  已签发   │────→│  生效中   │────→│  已过期   │     │  已撤销   │
│          │     │          │     │          │     │          │
└──────────┘     └────┬─────┘     └──────────┘     └──────────┘
                      │
                      └─── 验证者可随时撤销
                           （例如，Agent 行为违反认证标准时）
```

存在两条签发路径以适应不同的 Gas 成本偏好：
1. **直接链上签发** — 由 VERIFIER_ROLE 持有者直接调用 `issueAttestation()`。Gas 成本较高但链上即时可用。
2. **无 Gas 签发** — 验证者使用 EIP-712 在链下签名，任何人通过 `issueAttestationBySignature()` 在链上提交。验证者成本更低；提交者支付 Gas。包含 nonce 和 deadline 以防重放攻击。

### 5.3 AccessGateway.sol — Web2 桥接

**用途：** Agent Passport 的核心创新。该合约使 Agent 能够使用钱包签名作为身份验证凭证，有效地用加密身份证明取代 CAPTCHA 和邮箱验证。**竞争格局中没有其他项目提供这种桥接。**

#### 5.3.1 直接访问流程（Proof-of-Agent / Agent证明）

```
传统 Web2:        用户 → 填写邮箱 → 解决 CAPTCHA → 注册 → 访问
                  ↑ 仅限人类。Agent 在此被阻止。

Agent Passport:   Agent → 钱包签名 → 链上身份验证 → 访问
                  ↑ Agent 原生。无需 CAPTCHA。
```

**详细流程：**

1. **Agent 构建 AccessRequest** — 包含 platformId（目标平台标识符）、scopes（请求的权限范围）和 expiry（时效性有效期限）。请求使用 Agent 私钥通过 EIP-712 结构化数据签名。

2. **网关链上验证** — 网关服务验证 EIP-712 签名真实性，检查 AgentRegistry 的注册状态，验证 AgentPassport 对所请求范围的认证，确认 CompliancePassport 风险评分在可接受范围内。

3. **网关授予访问** — 调用 `grantAccess()` 将会话锚定在链上。链下网关服务生成类 JWT 访问令牌。会话状态在链上可被任何人公开验证。

4. **Agent 访问 Web2 平台** — 向平台出示访问令牌。平台可独立验证链上会话锚点。

#### 5.3.2 类 OAuth 授权码流程（含 PKCE）

对于需要 OAuth 风格身份验证流程的平台，Agent Passport 提供兼容流程并带有链上身份锚定：

1. Agent 使用 PKCE 挑战请求授权码
2. Agent 签名请求；codeHash 记录在链上
3. 网关验证并签发授权码
4. Agent 使用 code_verifier 交换令牌
5. 网关返回 access_token
6. 会话锚定在链上以供审计

此流程与现有 OAuth 2.0 基础设施向后兼容，同时增加了传统 OAuth 所缺乏的链上身份锚定。

#### 5.3.3 Proof-of-Agent vs. CAPTCHA — 范式转变

AccessGateway 的根本洞察是：**CAPTCHA 的存在是因为平台无法区分已授权的人类和未授权的机器人。Agent Passport 逆转了这一范式——Agent 证明自己是已授权的 Agent，使人类/机器人的区分变得无关紧要。**

| 维度 | CAPTCHA | Proof-of-Agent（Agent证明） |
|------|---------|---------------------------|
| 证明什么 | "我是人类" | "我是已授权、已注册的 Agent" |
| 验证方式 | 谜题解答 / 行为分析 | 加密签名 + 链上身份 |
| Agent 兼容性 | ❌ 设计上根本不兼容 | ✅ 从底层 Agent 原生 |
| 平台集成工作量 | 已有（通用但仅限人类） | 需要网关集成（一次性） |
| 安全模型 | 概率性（可被机器学习攻破） | 加密性（计算上不可伪造） |
| 可审计性 | 无（无持久记录） | 每次访问授权都有完整链上审计跟踪 |
| 可撤销性 | 手动账户暂停 | 链上撤销级联到所有会话 |

### 5.4 CompliancePassport.sol — 可移植合规证明

**用途：** 将 ERC-8126 风险评分和 ERC-8226 授权委托整合为单一、可移植的合规层，随 Agent 跨平台和跨链携带。

#### 5.4.1 ERC-8126 风险评分集成

五维验证模型提供细粒度风险评估：

| 维度 | 检查内容 | 重要原因 |
|------|----------|----------|
| 代币验证 | 代币交互模式和合法性 | 防止 Agent 与诈骗代币交互 |
| 媒体内容验证 | 内容合规性和适当性 | 确保 Agent 生成的内容符合平台标准 |
| Solidity 代码验证 | 智能合约审计状态 | 防止 Agent 与未经审计的合约交互 |
| Web 应用验证 | 目标平台的 Web 安全态势 | 保护 Agent 免受网络钓鱼和恶意站点 |
| 钱包验证 | 钱包历史、交易模式 | 识别被入侵或可疑的钱包行为 |

**多评分器聚合**允许多个独立验证者贡献风险评估，通过加权平均产生综合评分：

```
验证者 A: 15（权重 0.3）+ 验证者 B: 22（权重 0.4）+ 验证者 C: 18（权重 0.3）
→ 综合评分: 18.3（加权平均）
→ 合规级别: 3（部分合规）
```

#### 5.4.2 ERC-8226 授权委托

对于受监管操作，CompliancePassport 提供从 KYC 已验证委托人到执行 Agent 的可验证责任链：

```
委托人（KYC 已验证个人或机构）
    │
    ├──→ 委托给 Agent:
    │         ├─ mandateExpiry: 2026-12-31
    │         ├─ financialCap: 100 ETH
    │         ├─ scopeHash: 0x...（已授权操作的 SHA-256）
    │         └─ frozen: false（紧急冻结能力）
    │
    └──→ Agent 在委托范围内运行
              → 所有行为可链上审计
              → 委托人责任明确定义
              → 监管机构可验证整条链
```

这满足了 Art.50 及类似监管框架的要求，即需要从负责人类实体到执行 Agent 的可追溯链。授权在链上，可被任何平台验证，委托人可随时冻结或撤销。

---

## 6. 差异化定位

### 6.1 对比 Visa Trusted Agent Protocol (TAP)

| 维度 | Visa TAP | Agent Passport |
|------|----------|---------------|
| **范围** | 仅商务（在商户站点浏览 + 支付） | 全平台访问（GitHub、Discord、Twitter、SaaS、DeFi、论坛） |
| **身份模型** | HTTP Message Signatures（RFC 9421） | ERC-721 NFT + EIP-712 加密证明 |
| **链上集成** | 不需要链上身份 | 完整 ERC-8004 集成，17万+ Agent 生态 |
| **目标用户** | 接受 AI Agent 支付的商户 | 任何 Agent 需要访问的 Web2 平台 |
| **合规** | 仅商户侧验证 | 完整合规栈（ERC-8126 风险 + ERC-8226 授权） |
| **合作伙伴** | Stripe、Shopify、Coinbase、Microsoft、Adyen、Akamai | 开放协议——任何平台均可集成 |
| **成本** | 未知（试点阶段） | $0.000752/事件（PoC 已验证） |

**关系：** 互补。Visa TAP 处理商务层；Agent Passport 处理长尾非商务平台的身份和访问层。拥有 Agent Passport 的 Agent 可以使用 Visa TAP 进行商务交易，同时使用 Agent Passport 处理其他所有事务。

### 6.2 对比 Microsoft Entra Agent ID

| 维度 | Microsoft Entra Agent ID | Agent Passport |
|------|------------------------|---------------|
| **架构** | Web2 企业身份系统 | Agent 原生 + 链上身份系统 |
| **协议** | OAuth 2.0 / OIDC（标准 Web2） | EIP-712 + 链上验证（Agent 原生） |
| **生态锁定** | 绑定 Microsoft（Copilot、Azure、AWS Bedrock） | 链无关、平台无关、开放协议 |
| **身份可移植性** | 仅限 Microsoft 生态内 | 可跨所有 EVM 链和 Web2 平台移植 |
| **合规** | 企业 IAM（链下） | 链上可验证合规（ERC-8126/8226） |
| **Agent 间信任** | 不支持 | 通过 ERC-8004 身份和声誉原生支持 |
| **成本** | 企业许可 | Base 上 $0.000752/事件 |

**关系：** Microsoft Entra 服务于 Microsoft 生态内的企业。Agent Passport 服务开放、去中心化的 Agent 生态。它们可以互操作：企业 Agent 可以同时持有 Microsoft Entra 身份（用于内部系统）和 Agent Passport（用于开放网络）。

### 6.3 对比 ERC-8004（仅链上身份）

| 维度 | ERC-8004 | Agent Passport |
|------|----------|---------------|
| **层级** | L1：仅身份注册 | L1-L3：完整身份 + 访问 + 合规 |
| **范围** | 链上 agentId（NFT）+ 声誉 | 链上身份 + 链下平台访问 + 合规 |
| **Web2 桥接** | ❌ 无——无法向 Web2 平台验证身份 | ✅ 核心功能——AccessGateway 实现 Web2 访问 |
| **合规** | ❌ 无 | ✅ ERC-8126 风险评分 + ERC-8226 授权委托 |
| **认证** | 基础元数据（URI） | 完整认证系统，含验证者角色和生命周期 |

**关系：** 互补且依赖。Agent Passport **构建在** ERC-8004 之上作为基础层。每个 Agent Passport 身份都是 ERC-8004 身份，并增加了护照属性、访问凭证和合规证明。我们不是替代 ERC-8004；而是将其影响力延伸到 Web2 世界。

### 6.4 对比 Virtuals Protocol / EconomyOS

| 维度 | Virtuals Protocol | Agent Passport |
|------|------------------|---------------|
| **链** | 仅 Base 原生 | 多链（Base 优先，然后是 Ethereum、Arbitrum） |
| **模型** | 以代币化为中心（Agent 作为可投资资产） | 以身份为中心（Agent 作为自主运营者） |
| **重点** | Agent 创建 + 代币发行 + 商务 | Agent 身份 + Web2 访问 + 合规 |
| **钱包** | 内置钱包基础设施 | 集成层（Coinbase、Cobo、Crossmint） |
| **Web2 桥接** | ❌ 未解决 | ✅ 通过 AccessGateway 的核心功能 |
| **收入** | 代币发行费、交易费 | 凭证签发、验证 API、企业 SaaS |

**关系：** 不同细分市场。Virtuals 瞄准"Agent 即产品"市场（创建、发行、投资）。Agent Passport 瞄准"Agent 即运营者"市场（识别、验证、访问）。在 Virtuals Protocol 上创建的 Agent 可以——我们认为应该——使用 Agent Passport 来满足其身份和 Web2 访问需求。

### 6.5 独特定位的三大支柱

Agent Passport 的独特地位由三个属性定义，**没有任何现有项目同时具备这三者**：

1. **Agent 原生身份（非人类衍生）**  
   不同于 World ID（需要虹膜扫描）、Incode（需要生物特征验证）或 Civic（需要政府 ID），Agent Passport 不需要任何形式的生物验证。Agent 的身份就是它自己的——源自其链上注册、运营能力和行为历史。这是必要的，因为 Agent 不是人类，不能（也不应该需要）证明自己是人类。

2. **Web2 桥接（不仅限于链上）**  
   不同于 ERC-8004、ERC-8126 或任何现有 ERC 标准，Agent Passport 提供了从链上身份到 Web2 平台访问的具体桥接。AccessGateway 的 Proof-of-Agent 机制是 Agent 到 Web2 身份验证的第一个协议级解决方案。这不是理论提案——它已在我们的 V0 合约中实现。

3. **协议层（非链或平台）**  
   不同于 Kite（构建自己的 L1 链）或 Virtuals（Base 原生平台），Agent Passport 是跨链跨平台的协议。它不与钱包或链竞争；它位于其之上作为身份和授权层。这种协议级定位实现了最大的可组合性和生态覆盖。

---

## 7. 商业模式

### 7.1 五条收入线

Agent Passport 运营五条收入线，旨在对齐生态各方的激励，同时保持对个人开发者的可及性：

| # | 收入线 | 机制 | 目标客户 | 单位经济 |
|---|--------|------|----------|----------|
| 1 | **平台凭证签发** | 每签发一个凭证收费（例如，绑定到 Agent 身份的 GitHub 认证令牌） | Agent 开发者 / Agent 平台 | 每凭证 $0.01 – $0.10 |
| 2 | **验证 API** | 实时 Agent 验证检查收费（注册状态、风险评分、授权范围） | Web2 平台 / 钱包提供商 | 每次验证 $0.001 – $0.01 |
| 3 | **企业 Agent 身份管理** | SaaS 平台，管理 Agent 身份、凭证和合规舰队 | 大规模部署 AI Agent 的企业 | 每组织 $500 – $5,000 / 月 |
| 4 | **认证费用** | 签发链上认证的费用，记录 Agent 凭证和授权 | Agent 运营者 | Gas + 协议费（每次认证 ~$0.10 – $1.00） |
| 5 | **合规附加服务** | ERC-8226 集成用于受监管 Agent 授权；KYA（了解你的 Agent）报告 | 受监管行业（金融、医疗、法律） | 每次授权验证 $0.50 – $5.00 |

### 7.2 成本优势

Agent Passport 受益于 Base 的低成本 L2 基础设施，相比传统身份提供商具有显著成本优势：

| 成本项 | Agent Passport（Base） | 传统方案（Auth0/Okta） | 优势 |
|--------|----------------------|----------------------|------|
| 身份注册 | ~$0.000752 / 事件 | $0.01 – $0.10 / 事件 | **便宜 13x – 133x** |
| 认证签发 | ~$0.000500 / 事件 | 无（无对应功能） | 独特能力 |
| 访问验证 | ~$0.000900 / 事件 | $0.005 – $0.05 / 事件 | **便宜 5x – 55x** |
| 合规验证 | ~$0.000640 / 事件 | $0.50 – $5.00 / 事件 | **便宜 780x – 7,800x** |

这种成本优势是结构性的：Base 的 L2 架构以 L1 或传统云基础设施成本的一小部分处理交易，同时保持以太坊共识的安全保证。

### 7.3 市场进入策略

**市场切入点：开发者工具和代码平台（GitHub、GitLab、npm）。**

理由：
- 开发者工具是**最高价值、最低摩擦**的切入点。AI 编码 Agent（Claude Code、Cursor、Codex、GitHub Copilot）已在大量涌现，它们需要与 GitHub、GitLab 和包注册表交互。
- 这些平台有**基于 API 的身份验证**（GitHub 令牌、SSH 密钥），比有 CAPTCHA 的消费平台更适合 Agent 委托。
- **开发者社区是 Agent 基础设施的最早采用者**——他们正是构建需要护照的 Agent 的人。
- 与 GitHub 的成功集成（例如，"此提交由 Agent X 推送，注册为 ERC-8004 #1234，经用户 Y 授权"）创建了一个**可见、可验证的证明点**，向整个开发者生态展示护照概念。

次要切入点：Discord/Slack 机器人（社区管理 Agent）、Twitter/X（社交 Agent）、SaaS API（自动化 Agent）。

---

## 8. 路线图

### 8.1 里程碑概览

```
V0（2026年三季度）         V1（2027年一季度）         V2（2027年三季度）
──────────────            ──────────────            ──────────────
PoC 验证             →    MVP 生产             →    完整协议
                                                      
• 4 份合约                • ERC-8004 适配器         • 代理合约（UUPS）可升级
• Base 主网               • 凭证保险库              • CCIP 跨链身份
• 6 次部署                • GitHub/GitLab/npm       • 去中心化验证者网络
• 27 封 BD 函             • SDK（TS + Python）      • ERC-8226 完整合规
• $0.000752/事件          • 1,000+ Agent            • 企业 SaaS 平台
• 竞争研究                • 10+ 框架集成            • 50+ 平台支持
  （25 个项目）           • 1+ 主要平台认可         • 10,000+ Agent
```

### 8.2 V0 — 概念验证（当前 — 2026年三季度）

**状态：进行中**

| 交付物 | 状态 | 详情 |
|--------|------|------|
| 智能合约架构 | ✅ 完成 | 4 份合约，3 层设计 |
| Solidity 实现 | ✅ 完成 | 使用 OpenZeppelin v5 的完整实现 |
| 单元测试 | ✅ 完成 | >90% 覆盖率目标 |
| Base 主网部署 | ✅ 完成 | 6 份合约已部署并验证 |
| 成本验证 | ✅ 完成 | $0.000752/事件 已测量并记录 |
| 竞争研究 | ✅ 完成 | 25 个项目，6 个赛道分析 |
| BD 外联 | ✅ 完成 | 27 封函件已发送给生态合作伙伴 |
| 架构文档 | ✅ 完成 | 完整 V0 架构规范 |
| 白皮书 | ✅ 完成 | 本文档 |

### 8.3 V1 — 最小可行产品（2027年一季度）

**核心交付物：**

1. **Agent 注册适配器** — 使用 Agent Passport 扩展元数据图式封装 ERC-8004 身份注册，增加 Web2 平台能力、授权操作和凭证绑定。扩展图式作为 EAS 认证存储在链上以保证可验证性。

2. **凭证保险库** — Web2 平台凭证（GitHub 令牌、SSH 密钥、API 密钥）的加密链下存储，绑定到 Agent 的 ERC-8004 身份。保险库在链上发射认证哈希以保证可验证性，而不暴露凭证本身。

3. **平台认证编排器** — 支持 GitHub（个人访问令牌 + OAuth）、GitLab 和 npm。处理平台特定认证流程的凭证配置、会话管理，以及每个平台所有 Agent 行为的全面审计日志。

4. **验证端点** — 任何平台均可查询的公共 API："Agent X 是否被授权在平台 Z 上执行操作 Y？" 返回带有 Agent ERC-8126 风险评分、ERC-8004 声誉和平台特定授权状态的签名认证。

5. **SDK** — TypeScript 和 Python SDK，供 Agent 框架（LangChain、OpenAI Agents SDK、CrewAI、Claude MCP）使用来获取和出示 Agent Passport 凭证。目标集成：`const passport = await AgentPassport.authenticate(agentId)`。

**V1 明确排除：**
- CAPTCHA 绕过（推迟给 Browserbase 等浏览器自动化合作伙伴）
- 邮箱账号创建（推迟给专业化服务）
- 消费平台支持（优先聚焦开发者工具）
- 受监管金融支持（推迟到 V2 的 ERC-8226 集成）

**V1 成功指标：**
- 1,000+ Agent 注册 Agent Passport 凭证
- 10+ 个 Agent 框架集成
- 至少1个主要开发者平台（GitHub 或 GitLab）在其审计日志中认可 Agent Passport 断言

### 8.4 V2 — 完整协议（2027年三季度）

| 特性 | 描述 | 影响 |
|------|------|------|
| **可升级合约** | 四份合约全部采用 UUPS 代理模式 | 支持协议演进无需迁移 |
| **跨链身份** | CCIP 集成实现原生多链身份 | 消除手动链注册 |
| **去中心化验证者网络** | TEE + ZK 验证替代中心化网关 | 消除单一信任点 |
| **完整 ERC-8226 合规** | 金融和医疗的受监管授权支持 | 开放受监管行业市场 |
| **企业 SaaS** | 仪表板、RBAC、合规报告、SLA | 每组织 $500-$5K/月收入 |
| **扩展平台** | Discord、Twitter/X、Slack、50+ SaaS 平台 | 大幅扩大可寻址市场 |
| **账户抽象** | ERC-4337 集成实现无 Gas Agent 操作 | 降低 Agent 运营者摩擦 |

---

## 9. 团队与生态

### 9.1 AGL 背景

Agent Passport 诞生自 **Agent 治理层（AGL）** 项目——一个为解决 AI Agent 的 Art.50 监管要求而构建的合规框架。AGL 团队带来：

- **深厚的领域专长**，涵盖 Agent 合规、身份和治理——非理论性的，而是通过构建生产级合规基础设施锤炼出来的
- **生产经验**，在 Base 主网上运营 Agent 基础设施，拥有真实成本数据和真实运营洞察
- **标准知识**，覆盖完整的 ERC-8004/8126/8183/8196/8226/8263 栈，包括积极参与标准设计讨论
- **先发优势**，在任何竞争者之前识别并解决 Agent 到 Web2 的缺口

### 9.2 已有链上资产

| 资产 | 状态 | 意义 |
|------|------|------|
| 6 份合约在 Base 主网 | 已部署并验证 | 生产验证的基础设施，真实 Gas 成本 |
| $0.000752/事件成本 | 已测量并记录 | 证明规模化的经济可行性 |
| 完整 ERC-8004 集成 | 已设计并实现 | 从第一天起兼容 17万+ Agent 生态 |
| ERC-8126 + ERC-8226 集成 | 已设计 | 完整合规栈，适用于受监管用例 |
| 全面竞争研究 | 已完成 | 25 个项目分析；战略定位已验证 |

### 9.3 BD 网络：27 封函件已发送

团队已启动商务拓展外联，向五个类别的潜在生态合作伙伴发送了 **27 封函件**：

- **Agent 钱包提供商**（Coinbase、Cobo、Crossmint）——用于集成合作，Agent Passport 在其钱包基础设施之上提供身份层
- **Agent 框架团队**（LangChain、CrewAI、MCP 生态）——用于 SDK 采用和原生集成
- **Web2 平台**（GitHub、GitLab）——用于平台侧集成，认可 Agent Passport 断言
- **合规提供商**（zkMe、Incode、World ID）——用于互补验证合作
- **企业客户**——用于受监管行业的试点计划候选

### 9.4 目标生态合作伙伴

| 类别 | 合作伙伴 | 集成类型 |
|------|----------|----------|
| 身份标准 | ERC-8004、ERC-8126、EAS（850万+证明） | 构建于 / 消费 / 存储层 |
| Agent 钱包 | Coinbase、Cobo、Crossmint、Turnkey | 钱包之上的身份层 |
| 验证 | zkMe、World ID、Incode | 互补验证方式 |
| 基础设施 | agentgateway、Browserbase、AgentQL、OpenClaw | 流量路由 + 执行层 |
| 企业身份验证 | Microsoft Entra、Auth0 | 企业 Agent 互操作桥接 |
| 跨链 | Metaplex（Solana）、CCIP（Ethereum） | 多链身份覆盖 |

---

## 10. 风险分析

### 10.1 技术风险

| 风险 | 严重度 | 概率 | 缓解措施 |
|------|--------|------|----------|
| **智能合约漏洞** | 高 | 低 | OpenZeppelin v5 库；>90% 测试覆盖率；计划外部审计（Trail of Bits / OpenZeppelin） |
| **钱包绑定伪造** | 高 | 低 | 三层 EIP-712 保护：类型化数据 + nonce + deadline |
| **认证伪造** | 高 | 低 | VERIFIER_ROLE 白名单；链上签名验证；撤销机制 |
| **重放攻击** | 中 | 低 | 所有签名包含 nonce + chainId + deadline |
| **网关中心化** | 中 | 中 | Gateway Service 地址可替换；所有决策链上可审计；V2 路线图包含去中心化验证者网络 |
| **NFT 转账权限残留** | 低 | 低 | `_update` 钩子在转账时自动清除钱包绑定 |

### 10.2 市场风险

| 风险 | 严重度 | 概率 | 缓解措施 |
|------|--------|------|----------|
| **ERC 标准演进** | 中 | 中 | 积极参与 ERC 讨论；合约设计支持升级（V2 UUPS 代理） |
| **Visa TAP 扩展** | 中 | 低 | Visa TAP 限于商务范围；我们的 Web2 桥接更广泛；互补关系降低竞争风险 |
| **Microsoft Entra 主导** | 中 | 低 | Microsoft 限于企业；我们的开放协议服务去中心化生态；计划互操作桥接 |
| **Agent 采用率低** | 高 | 中 | 开发者优先 GTM；SDK 简洁性；GitHub 集成作为可见证明点 |
| **平台抵制** | 中 | 中 | 平台受益于已验证的 Agent 身份（减少欺诈）；早期合作创造积极先例 |

### 10.3 监管风险

| 风险 | 严重度 | 概率 | 缓解措施 |
|------|--------|------|----------|
| **AI 监管演变** | 中 | 高 | ERC-8226 集成提供合规灵活性；模块化设计允许适应新要求 |
| **跨境合规** | 中 | 中 | 多链部署允许司法管辖区特定合规配置 |
| **数据隐私（GDPR）** | 中 | 中 | 链上仅存储哈希；原始数据在加密链下存储；通过认证撤销实现删除权 |

---

## 11. 治理

### 11.1 角色架构

Agent Passport 使用 OpenZeppelin 的 AccessControl 实现基于角色的访问控制系统：

| 角色 | 合约 | 初始分配 | 职责 | 过渡计划 |
|------|------|----------|------|----------|
| `DEFAULT_ADMIN_ROLE` | 所有合约 | 部署者 → 多签 DAO | 超级管理员：角色管理、合约升级 | V1 转移至 DAO 治理 |
| `VERIFIER_ROLE` | AgentPassport | 初始验证团队 | 签发和撤销认证 | V2 扩展至去中心化验证者网络 |
| `REGISTRAR_ROLE` | AgentPassport | 自动注册服务 | 设置 Agent 属性 | V1 通过预言机自动化 |
| `SCORER_ROLE` | CompliancePassport | 合规评分服务 | 记录风险评分 | V1 多评分器聚合 |
| `COMPLIANCE_ORACLE_ROLE` | CompliancePassport | 合规预言机 | 记录授权委托 | V1 扩展验证者集合 |
| Gateway Service | AccessGateway | 链下网关服务地址 | 批准访问请求 | V2 去中心化 |

### 11.2 安全原则

1. **最小权限** — 每个角色仅拥有其功能所需的最小权限。
2. **链上锚定 + 链下存储** — 敏感数据以哈希形式存储在链上；原始数据存放在加密链下存储（IPFS / 加密数据库）。
3. **时间边界** — 所有签名、证书、策略和会话都有明确的过期时间。没有任何东西无限期有效。
4. **可撤销性** — 认证、证书、授权和访问会话都可以由授权方随时撤销。
5. **EIP-712 标准化** — 所有签名使用结构化数据签名，兼容硬件钱包和人类可读签名界面。
6. **ERC-165 接口检测** — 所有合约支持标准接口检测，实现无缝集成。

### 11.3 审计路线图

| 阶段 | 活动 | 目标 |
|------|------|------|
| V1 之前 | 自动化测试覆盖率 > 90% | 内部 |
| V1 | 外部安全审计 | Trail of Bits 或 OpenZeppelin |
| V1 | 漏洞赏金计划启动 | Immunefi 或 HackerOne |
| V2 | 持续监控 | 链上异常检测 |
| 持续 | 升级时重新审计 | 按升级周期 |

---

## 12. 参考文献

### ERC 标准与 EIP
- ERC-8004: Trustless Agents — [ethereum.org/EIPs](https://eips.ethereum.org/EIPS/eip-8004)
- ERC-8126: AI Agent Verification — [eips.ethereum.org/EIPS/eip-8126](https://eips.ethereum.org/EIPS/eip-8126)
- ERC-8183: Agentic Commerce Protocol — [RootData](https://www.rootdata.com/news/584398)
- ERC-8196: AI Agent Authenticated Wallet — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8196-ai-agent-authenticated-wallet/27987)
- ERC-8226: Regulated Agent Mandate — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208)
- ERC-8263: Onchain Proof Layer — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8263-onchain-proof-layer-for-ai-agents/28577)
- EIP-712: Typed Structured Data Hashing and Signing — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-712)

### Agent 钱包与基础设施
- Coinbase Agentic Wallet — [BlockEden](https://blockeden.xyz/ru/blog/2026/05/07/coinbase-agentic-wallet-callable-service-mcp-architecture/)
- Cobo Agentic Wallet — [Cobo](https://website.cobo.com/post/cobo-launches-agentic-wallet-how-ai-agents-interact-on-chain)
- Fireblocks / Dynamic — [FinanceFeeds](https://financefeeds.com/fireblocks-buys-a16z-backed-dynamic-for-90m-to-bridge-custody-and-wallet-tech/)

### 企业身份验证与身份
- Visa Trusted Agent Protocol — [Visa Corporate](https://corporate.review.visa.com/en/sites/visa-perspectives/newsroom/visa-unveils-trusted-agent-protocol-for-ai-commerce.html)
- Microsoft Entra Agent ID — [Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/agent-id/)
- World ID — [world.org](https://world.org/world-id)
- Incode Agentic Identity — [Incode](https://incode.com/press/incode-launches-agentic-identity-to-verify-and-secure-ai-agents-2/)

### 项目与协议
- Virtuals Protocol — [BingX](https://bingx.io/en/learn/article/what-is-virtuals-protocol-virtual-ai-agent-how-to-buy)
- Kite — [PANews](https://new.qq.com/rain/a/20250905A0405P00)
- EAS (Ethereum Attestation Service) — [attest.org](https://attest.org/)
- zkMe Agent Trust Gateway — [zkMe Docs](https://docs.zk.me/hub/how-built/agent-trust-gateway/supported-protocols)
- agentgateway — [agentgateway.dev](https://agentgateway.dev/)
- Metaplex Agent Registry — [Metaplex](https://www.metaplex.com/docs/agents/agentic-commerce)
- OpenClaw — [CSDN](https://blog.csdn.net/weixin2376192/details/160430530)

---

*Agent Passport V0 白皮书 — 2026年7月*  
*构建于 ERC-8004 信任栈之上。部署于 Base。*  
*证明 Agent 是谁——以及它能去往何方的护照。*
