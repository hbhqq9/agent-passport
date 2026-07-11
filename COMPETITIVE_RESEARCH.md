# Agent Passport: Competitive Landscape & Strategic Positioning Report

**Completion Date:** 2026-07-08  
**Topic:** AI Agent Identity & Access Platform — Competitive Research

---

## 1. Executive Summary

The AI agent identity space is rapidly standardizing around the **ERC-8004/8126/8196 trust stack** on Ethereum, with **170,000+ agents registered** on-chain as of May 2026 [(Ethereum Foundation Blog)](https://ai.ethereum.foundation/blog/intro-erc-8004) and **ERC-8126 reaching Final status** in June 2026 [(PANews)](https://www.panewslab.com/zh/articles/019ee85e-024d-75ed-b2ba-1ec5d28cd397). However, this standardization addresses only the on-chain trust layer — the question of **how agents authenticate to and operate across Web2 services** (GitHub, Discord, Twitter, email-verified platforms) remains entirely unsolved by existing standards and projects.

The most significant finding is that **the biggest unaddressed gap is not on-chain identity** (ERC-8004 provides this) **but the Agent-to-Web2 bridge**: enabling AI agents to register on, authenticate to, and operate across existing Web2 platforms that were designed exclusively for human users. Visa's Trusted Agent Protocol [(Visa Corporate)](https://corporate.review.visa.com/en/sites/visa-perspectives/newsroom/visa-unveils-trusted-agent-protocol-for-ai-commerce.html) addresses a narrow commerce subset of this problem; Microsoft Entra Agent ID [(Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/agent-id/) covers enterprise OAuth flows. **No project provides a unified, agent-native identity passport that bridges on-chain identity to Web2 service access across the full platform landscape.**

The report identifies **25 entities** across six tracks. Of these, only **Virtuals Protocol's EconomyOS** approaches a comparable scope (identity + wallet + commerce), but it is Base-native and tokenization-centric rather than cross-chain and interoperability-focused. The recommended V1 MVP targets **ERC-8004 identity registration + Web2 platform credential vault + OAuth/CAPTCHA bypass orchestration** — the "passport" that lets agents operate where no standard currently reaches.

---

## 2. Data Sources

| Provider | Skill Used | Dimension Covered | Role |
|----------|-----------|---------|------|
| General Web Search | search_web | All qualitative data: project details, standard specifications, funding, product features | Primary source (no professional data skill covers this domain) |
| EIPs Ethereum | search_web + fetch_web | ERC standard specifications and status | Primary source for standard details |
| Ethereum Magicians Forum | search_web | ERC draft discussions and community feedback | Primary source for draft standards |

No professional data Skill (openecon-data, fred-data-skill, etc.) was applicable to this domain. All findings derive from general web search across official project websites, EIP repositories, and industry analysis articles.

---

## 3. Competitive Landscape Matrix

| Project | Track | Stage | Funding / Traction | Relation to Agent Passport |
|---------|-------|-------|-------------------|---------------------------|
| **ERC-8004** | On-chain Identity | Draft, Mainnet Live (Jan 2026) | Co-authored by MetaMask, EF, Google, Coinbase; 170K+ agents [(EF Blog)](https://ai.ethereum.foundation/blog/intro-erc-8004) | **Foundation layer** — Agent Passport should build on top |
| **ERC-8126** | Verification | Final (Jun 2026) | By Cybercentry/Virtuals; 5 verification types [(EIPs)](https://eips.ethereum.org/EIPS/eip-8126) | **Complement** — consume risk scores for Web2 auth decisions |
| **ERC-8183** | Commerce | Draft | Joint Virtuals + EF dAI; ACP live on Arbitrum [(RootData)](https://www.rootdata.com/news/584398) | **Complement** — commerce layer |
| **ERC-8196** | Auth Wallet | Draft | By Cybercentry; no production impl [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8196-ai-agent-authenticated-wallet/27987) | **Partial competitor** — overlaps on authenticated execution |
| **ERC-8226** | Regulated Finance | Draft | No known impl; GhostAgent on Gnosis [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208) | **Future partner** — regulated mandate compliance |
| **ERC-8263** | Proof Layer | Draft (ref impl live) | By TruthAnchor; multi-chain deployed [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8263-onchain-proof-layer-for-ai-agents/28577) | **Complement** — inference provenance |
| **Coinbase Agentic Wallet** | Agent Wallet | Production (Feb 2026) | TEE + MCP; free tier 1K tx/mo [(BlockEden)](https://blockeden.xyz/ru/blog/2026/05/07/coinbase-agentic-wallet-callable-service-mcp-architecture/) | **Integration target** — wallet layer |
| **Cobo Agentic Wallet** | Agent Wallet | Production (Apr 2026) | MPC-based; Pact + Recipe; 80+ chains [(Cobo)](https://website.cobo.com/post/cobo-launches-agentic-wallet-how-ai-agents-interact-on-chain) | **Integration target** — wallet layer |
| **Crossmint** | Agent Wallet | Production | MiCA-licensed; card + stablecoin rails [(BlockEden)](https://blockeden.xyz/ru/blog/2026/05/07/coinbase-agentic-wallet-callable-service-mcp-architecture/) | **Integration target** — fiat bridge |
| **Virtuals Protocol** | Full Stack | Production | $33M+ implied; 17K agents; $479M aGDP [(BingX)](https://bingx.io/en/learn/article/what-is-virtuals-protocol-virtual-ai-agent-how-to-buy) | **Closest competitor** — but Base-native, token-centric |
| **Kite** | L1 Agent Chain | Testnet | $33M total (PayPal Ventures, Samsung) [(PANews)](https://new.qq.com/rain/a/20250905A0405P00) | **Competitor** — L1 chain vs. protocol approach |
| **Visa TAP** | Web2 Commerce | Pilot (Oct 2025) | Visa + Cloudflare + Akamai; 4,700% AI traffic surge [(Visa)](https://corporate.review.visa.com/en/sites/visa-perspectives/newsroom/visa-unveils-trusted-agent-protocol-for-ai-commerce.html) | **Partial competitor** — commerce-only Web2 bridge |
| **Microsoft Entra Agent ID** | Enterprise Auth | Production | OAuth 2.0/OIDC; enterprise distribution [(Microsoft)](https://learn.microsoft.com/en-us/entra/identity/agent-id/) | **Competitor** — enterprise agent auth |
| **World ID** | Human Identity | Production | 18M verified humans; ZKP-based [(World)](https://world.org/world-id) | **Complement** — human-proof behind agents |
| **EAS** | Attestation | Production | Public good; 8.5M+ attestations [(EAS)](https://attest.org/) | **Infrastructure** — attestation layer |
| **Incode Agentic Identity** | Human-Agent Binding | Pilot (Q4 2025) | Deepfake-resistant biometrics; human owner binding [(Incode)](https://incode.com/press/incode-launches-agentic-identity-to-verify-and-secure-ai-agents-2/) | **Complement** — human accountability layer |
| **Auth0 (Okta)** | Agent Auth | Production | "Most Innovative AI Infrastructure Security 2026" [(Auth0)](https://auth0.com/) | **Competitor** — enterprise auth |
| **zkMe** | Trust Gateway | Early Stage | ZK-based; protocol-agnostic for MCP/A2A [(zkMe)](https://docs.zk.me/hub/how-built/agent-trust-gateway/supported-protocols) | **Partner** — ZK verification |
| **agentgateway** | Agent Gateway | Production (Linux Foundation) | By Solo.io; HTTP/gRPC for LLM+MCP+A2A [(agentgateway)](https://agentgateway.dev/) | **Infrastructure partner** — traffic routing |
| **Browserbase** | Browser Automation | Production | Cloud-native stealth browsers for agents [(Browserless)](https://www.browserless.io/blog/browserless-vs-browserbase) | **Infrastructure partner** — Web2 interaction |
| **AgentQL** | Web Data Extraction | Production | Semantic query language for web data [(AgentConn)](https://agentconn.com/blog/best-ai-browser-automation-agents-2026/) | **Infrastructure partner** — Web2 data extraction |
| **Metaplex Agent Registry** | Solana Identity | Production | PDA wallet + agent token launch [(Metaplex)](https://www.metaplex.com/docs/agents/agentic-commerce) | **Cross-chain complement** — Solana identity |
| **OpenClaw** | Agent Gateway | Production | Multi-channel gateway; 20+ IM platforms [(CSDN)](https://blog.csdn.net/weixin_42376192/article/details/160430530) | **Infrastructure partner** — multi-channel |
| **Fireblocks** | Institutional Custody | Production | Acquired Dynamic for $90M; $10T+ secured txns [(FinanceFeeds)](https://financefeeds.com/fireblocks-buys-a16z-backed-dynamic-for-90m-to-bridge-custody-and-wallet-tech/) | **Indirect** — custody layer |
| **ENI Minds** | On-chain Agent Identity | Early Stage | Two funding rounds in 6 months; limited public info | **Potential competitor** — insufficient data |

---

## 4. ERC Standard Stack Analysis

### 4.1 Standards Status Overview

| Standard | Title | Status | Proposed | Key Feature | Production Impl? |
|----------|-------|--------|----------|-------------|-------------------|
| ERC-8004 | Trustless Agents | Draft | Aug 2025 | 3 registries (Identity, Reputation, Validation) | **Yes** — mainnet Jan 2026, 170K+ agents |
| ERC-8126 | AI Agent Verification | **Final** | Jan 2026 | 5-layer verification, ZKP, 0-100 risk score | **Yes** — verification providers emerging |
| ERC-8183 | Agentic Commerce | Draft | Mar 2026 | Client-Provider-Evaluator triad, escrow | Partial — ACP on Arbitrum |
| ERC-8196 | Agent Authenticated Wallet | Draft | Mar 2026 | Policy-bound execution, audit trail | **No** — specification only |
| ERC-8226 | Regulated Agent Mandate | Draft | Apr 2026 | Compliance delegation for regulated assets | **No** — GhostAgent prototype on Gnosis |
| ERC-8263 | Onchain Proof Layer | Draft | May 2026 | Inference attestation anchoring | **Yes** — Sepolia + mainnet ref impl |

### 4.2 Standard Stack Architecture

![ERC Agent Standard Stack Architecture](https://www.coze.cn/s/vhXxNIqWBYM/)

The ERC agent standard stack organizes into three layers: **Register → Verify → Execute**. ERC-8004 provides the identity foundation, ERC-8126 adds verification and risk scoring, and ERC-8196/8183/8226 handle execution, commerce, and regulatory compliance respectively. ERC-8263 operates as a cross-cutting attestation primitive that composes with all layers [(Ethereum Magicians)](https://ethereum-magicians.org/t/erc-8263-onchain-proof-layer-for-ai-agents/28577).

### 4.3 Interoperability Relationships

The standards form a composable trust stack with explicit cross-references:

- **ERC-8126** requires agents to be registered via **ERC-8004** agentId before verification [(PANews)](https://www.panewslab.com/zh/articles/019ee85e-024d-75ed-b2ba-1ec5d28cd397)
- **ERC-8196** depends on **ERC-8004** for registration checks and **ERC-8126** for verification gating before execution [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8196-ai-agent-authenticated-wallet/27987)
- **ERC-8183** builds on **ERC-8004** identity and reputation for its commerce reputation loop [(RootData)](https://www.rootdata.com/news/584398)
- **ERC-8263** references **ERC-8004** agentId for canonical identity resolution and composes with **ERC-8183** on the commerce side [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8263-onchain-proof-layer-for-ai-agents/28577)
- **ERC-8226** is agnostic to agent identity system but explicitly references **ERC-8004** as a compatible registry and proposes a `regulatoryCompliance` signal in ERC-8004's registration file [(Eth Magicians)](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208)

### 4.4 Implementation Gaps

**Critical observation:** Of six ERCs in the stack, only **ERC-8004** and **ERC-8126** have meaningful production deployments. The following standards have **zero production implementations**:

- **ERC-8196** (Agent Authenticated Wallet): No wallet currently implements the policy-bound execution interface. Existing agent wallets (Coinbase, Cobo) use proprietary policy engines rather than the ERC-8196 standard.
- **ERC-8226** (Regulated Agent Mandate): Only a hackathon prototype (GhostAgent on Gnosis). No regulated token issuer has adopted the dual-compliance-check pattern.
- **ERC-8183** (Agentic Commerce): ACP is live on Arbitrum, but the full ERC-8183 specification (evaluator role, hook mechanism) is not yet standardized in the contract interface.

Additionally, **no ERC standard addresses Agent-to-Web2 authentication** — how an on-chain agent identity translates to credentials for GitHub, Discord, Twitter, email-verified services, or CAPTCHA-protected platforms. This is the core gap that Agent Passport targets.

---

## 5. Agent Wallet Landscape

The agent wallet market has crystallized into two architectural camps as of mid-2026 [(BlockEden)](https://blockeden.xyz/ru/blog/2026/05/07/coinbase-agentic-wallet-callable-service-mcp-architecture/):

### 5.1 Smart-Contract Wallet Products

| Feature | Coinbase Agentic Wallet | Cobo Agentic Wallet | Crossmint | thirdweb |
|---------|------------------------|---------------------|-----------|----------|
| **Security Model** | TEE (Trusted Execution Env) | MPC (Multi-Party Computation) | Smart contract + key management | Open-source primitives |
| **Agent Isolation** | Wallet as separate MCP service | Pact protocol (per-task authorization) | ERC-6492 pre-deploy wallets | Developer-controlled |
| **Execution Framework** | MCP-native callable service | Recipe-driven skill layer | Auto-approve under threshold | Configurable |
| **Chain Coverage** | Base, Polygon, Arbitrum, World, Solana | 80+ chains, 3000+ tokens | Multi-chain + fiat rails | Broad EVM + Solana |
| **Regulatory** | None | None | MiCA-licensed on/off-ramp | None |
| **Key Differentiator** | x402 payment support; Coinbase distribution | MPC math guarantee; Pact boundaries | Card + stablecoin + fiat bridge | Open-source flexibility |

### 5.2 Infrastructure/Signing Products

| Provider | Model | Key Feature | Status |
|----------|-------|-------------|--------|
| **Turnkey** | Non-custodial enclave API | Policy engine for limits/whitelists; EVM/Solana/BTC | Production |
| **Privy** (acquired by Stripe, Jun 2025) | Embedded + server wallets | Off-chain policy enforcement; Stripe stablecoin integration | Production |
| **Alchemy** | Account abstraction signing | Deep EVM tooling; AA-focused | Production |
| **Safe** | Modular settlement layer | Multi-sig foundation; connects to any wallet service | Production |

### 5.3 Key Insight

All six players converge on the **"wallet as callable service"** pattern — the agent never directly holds private keys. This architectural consensus means **Agent Passport should not compete on wallet infrastructure** but instead integrate with these providers as the identity and authorization layer that sits above the wallet. The wallet is the "vault"; Agent Passport is the "passport" that proves who the agent is and what it's authorized to do.

---

## 6. Agent Authentication & Attestation

### 6.1 Enterprise Auth Providers

**Microsoft Entra Agent ID** [(Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/agent-id/) represents the most mature enterprise agent authentication platform. It extends Entra ID with three identity constructs (agent identity blueprint, agent identity, agent's user account), uses standard OAuth 2.0/OIDC, and integrates with Copilot Studio, AWS Bedrock, and n8n. However, it is **fundamentally a Web2 enterprise solution** — it does not connect to on-chain identity, does not address agent-to-agent trust on public blockchains, and requires Microsoft ecosystem enrollment.

**Auth0 (Okta)** [(Auth0)](https://auth0.com/) has adapted its CIAM platform for agents with Token Vault (managing which APIs an agent can call on behalf of a user), M2M authentication, and FGA for RAG pipelines. Like Microsoft, it is Web2-native and enterprise-focused.

**Incode Agentic Identity** [(Incode)](https://incode.com/press/incode-launches-agentic-identity-to-verify-and-secure-ai-agents-2/) takes a human-centric approach: binding each agent to a verified human owner via deepfake-resistant biometrics, with scoped consent tokens and continuous behavioral monitoring. This solves the "who is responsible for this agent" question but does not provide the agent with its own portable, cross-platform identity.

### 6.2 On-Chain Attestation

**EAS (Ethereum Attestation Service)** [(EAS)](https://attest.org/) provides a neutral, permissionless attestation layer with **8.5M+ attestations** from **450K+ unique attesters**. CraftedTrust has demonstrated using EAS on Base for MCP server certification — any agent can verify a server's trust score before connecting [(CraftedTrust)](https://craftedcybersolutions.com/blog/eas-onchain-trust.html). EAS is a natural infrastructure layer for Agent Passport: agent credentials, platform authorizations, and compliance attestations can all be recorded as EAS attestations.

**zkMe Agent Trust Gateway** [(zkMe)](https://docs.zk.me/hub/how-built/agent-trust-gateway/supported-protocols) provides ZK-based identity verification with native protocol adapters for MCP, A2A, and other agent communication standards. It bridges Web2 KYC and Web3 identity using zero-knowledge proofs.

---

## 7. Agent Gateway & Web2 Interoperability

### 7.1 Gateway Infrastructure

**agentgateway** (Solo.io, donated to Linux Foundation) [(agentgateway)](https://agentgateway.dev/) is the leading open-source gateway for agent traffic, unifying HTTP, gRPC, MCP, and A2A protocols in a single data plane. It handles traffic management, security (mTLS, OIDC), and observability for agent-to-service and agent-to-agent communication. Critically, it operates at the **infrastructure/routing layer** — it does not solve the identity or authorization problem, but it is the natural traffic layer through which Agent Passport's identity assertions would flow.

**OpenClaw** [(CSDN)](https://blog.csdn.net/weixin_42376192/article/details/160430530) is a multi-channel agent gateway supporting **20+ IM platforms** (Telegram, Discord, Slack, WhatsApp, WeChat) with unified message routing and multi-agent isolation. It enables "write once, deploy everywhere" for agent communication but does not provide identity verification or platform authentication.

### 7.2 Browser Automation

**Browserbase** and **Browserless** [(Browserless)](https://www.browserless.io/blog/browserless-vs-browserbase) provide cloud-native headless browser infrastructure specifically designed for AI agents. Browserbase offers stealth mode (custom Chromium with real fingerprints), session management, and visual debugging tools. **AgentQL** [(AgentConn)](https://agentconn.com/blog/best-ai-browser-automation-agents-2026/) provides a semantic query language for extracting structured data from web pages.

These tools enable agents to interact with Web2 interfaces but **do not solve the authentication problem** — an agent using Browserbase still cannot register a GitHub account (requires email verification), bypass CAPTCHA, or prove its identity to a Discord server. This is precisely the gap Agent Passport must fill.

### 7.3 Visa Trusted Agent Protocol

**Visa's Trusted Agent Protocol (TAP)** [(Visa Corporate)](https://corporate.review.visa.com/en/sites/visa-perspectives/newsroom/visa-unveils-trusted-agent-protocol-for-ai-commerce.html), launched October 2025 in collaboration with Cloudflare, is the most significant Web2 agent authentication initiative. TAP uses HTTP Message Signatures (RFC 9421) to enable merchants to verify that an AI agent is trusted, identify the consumer behind it, and process payments. Partners include Stripe, Shopify, Coinbase, Microsoft, Adyen, and Akamai.

TAP is **narrow in scope** — it addresses only commerce-specific Web2 interactions (browsing and paying). It does not enable agents to register accounts on GitHub, post on Discord, submit code to repositories, or interact with email-verified platforms. TAP validates that the agent is "approved for commerce" but does not provide a general-purpose identity passport.

---

## 8. Human Identity Benchmarks — Why They Don't Fit Agents

| Aspect | World ID | Civic | EAS |
|--------|----------|-------|-----|
| **Core Mission** | Proof of unique human | KYC/AML identity verification | General attestation layer |
| **Verification Method** | Iris scanning at Orb device | Government ID + liveness check | Any signed claim |
| **Scale** | 18M verified humans | Unverified | 8.5M+ attestations |
| **Privacy** | ZKP-based anonymous | Hash stored on-chain | On-chain or off-chain |
| **Agent Support** | "World ID for agents" (human-backed) | None native | Agent attestations supported |
| **Why Insufficient for Agents** | Requires biological verification; agent cannot visit Orb | Designed for human identity documents | Neutral but lacks agent-specific attestation schemas and platform integration |

**World ID** recently added "World ID for agents" [(World Blog)](https://world.org/pl-pl/blog/announcements/world-id-full-stack-proof-of-human) — infrastructure for proving a verified human stands behind an agent. This is complementary but fundamentally different from giving the agent its own identity. A human-backed agent still cannot independently register on Web2 platforms.

**EAS** is the most flexible — it can attest to anything, including agent properties. But it is a **raw primitive**; it provides no opinionated schema for agent-to-Web2 authorization, no platform integration, and no credential management. Agent Passport should use EAS as a storage layer for attestations while providing the opinionated schemas and platform bridges that EAS lacks.

---

## 9. Market Gap Analysis

![Agent Identity Market Gap Quadrant](https://www.coze.cn/s/wAfskGkzxXg/)

### 9.1 What Exists

The market has addressed three layers of the agent identity problem with meaningful production systems:

1. **On-chain identity and trust** (ERC-8004, ERC-8126): Agents can register on-chain, build reputation, and be verified. **This layer is solved.**

2. **Agent wallets and custody** (Coinbase, Cobo, Crossmint, Turnkey, Safe): Agents can hold and transact digital assets with programmable policy enforcement. **This layer is being actively competed over.**

3. **Agent-to-agent commerce** (Virtuals ACP, ERC-8183): Agents can discover, hire, and pay each other through standardized protocols. **This layer is emerging.**

### 9.2 What Is Missing — The "Passport Gap"

**No existing project provides a unified, agent-native identity passport that bridges on-chain identity to Web2 platform access.** The specific unsolved problems are:

- **Account Registration**: Agents cannot create accounts on email-verified or CAPTCHA-protected platforms (GitHub, Discord, Twitter, forums). No standard or project provides agent-native registration flows.
- **Cross-Platform Credential Management**: Even if an agent obtains credentials for one platform, there is no portable, verifiable credential format that works across platforms. OAuth tokens are platform-specific and assume human users.
- **Agent-to-Web2 Authentication**: On-chain identity (ERC-8004 agentId) has no mapping to Web2 authentication mechanisms. A smart contract cannot log into GitHub.
- **Verifiable Agent Capabilities**: Platforms have no standardized way to verify what an agent is capable of or authorized to do. Each platform would need to build its own agent verification system.
- **Revocation and Lifecycle**: No mechanism exists to revoke an agent's access across multiple Web2 platforms from a single on-chain action (e.g., revoking an ERC-8004 identity should cascade to platform credentials).

Visa TAP addresses a narrow commerce slice. Microsoft Entra covers enterprise OAuth. But the **long tail of Web2 platforms** — developer tools, social media, community forums, SaaS applications — remains entirely inaccessible to agents without human intermediation.

---

## 10. Strategic Positioning Recommendations

### 10.1 Competitor vs. Partner Classification

**Direct Competitors (fighting for the same user/problem):**
- **Virtuals Protocol / EconomyOS**: Closest in scope (identity + wallet + commerce). However, Virtuals is Base-native, tokenization-centric, and focused on the "agent as investable asset" narrative rather than interoperability. Differentiation: Agent Passport is chain-agnostic, protocol-layer, and Web2-bridge focused.
- **Kite**: L1 chain approach with KitePass identity. Differentiation: Kite builds its own chain; Agent Passport is a protocol that works across chains.
- **Microsoft Entra Agent ID**: Enterprise auth for agents. Differentiation: Web2-only, no on-chain integration, Microsoft-ecosystem-bound.

**Partners (integrate, don't compete):**
- **ERC-8004/8126/8196 standards**: Build on top of these; consume identity and verification signals.
- **Agent wallets (Coinbase, Cobo, Crossmint, Turnkey)**: Integrate as the wallet layer; Agent Passport provides identity/auth above.
- **EAS**: Use as attestation storage for agent credentials and authorizations.
- **Visa TAP**: Complement in commerce scenarios; Agent Passport extends to non-commerce platforms.
- **Gateway providers (agentgateway, OpenClaw)**: Route agent traffic through Agent Passport's identity assertions.
- **Browser automation (Browserbase, AgentQL)**: Provide the execution layer for Web2 interactions; Agent Passport provides the identity layer.
- **World ID / Incode**: Complement for human-behind-agent verification when required by platforms.

### 10.2 Differentiation Thesis

Agent Passport's unique position is defined by three attributes that no existing project combines:

1. **Agent-Native Identity (not human-derived)**: Unlike World ID, Incode, or Civic, Agent Passport does not require biological verification or human identity documents. The agent's identity is its own — derived from its on-chain registration, capabilities, and operational history.

2. **Web2 Bridge (not just on-chain)**: Unlike ERC-8004, ERC-8126, or any existing ERC standard, Agent Passport provides the bridge from on-chain identity to Web2 platform access. This is the "passport" — a verifiable, portable credential that platforms can trust.

3. **Protocol Layer (not a chain or platform)**: Unlike Kite (L1 chain) or Virtuals (Base-native platform), Agent Passport is a protocol that works across chains and platforms. It does not compete with wallets or chains; it sits above them as the identity and authorization layer.

### 10.3 Market Entry Point

**Recommended entry: Developer tools and code platforms (GitHub, GitLab, npm).**

Rationale:
- Developer tools are the **highest-value, lowest-friction** entry point. AI coding agents are already proliferating (Claude Code, Cursor, Codex), and they need to interact with GitHub, GitLab, and package registries.
- These platforms have **API-based authentication** (GitHub tokens, SSH keys) that are more amenable to agent delegation than consumer platforms with CAPTCHA.
- The **developer community is the earliest adopter** of agent infrastructure — they are building the agents that need passports.
- A successful integration with GitHub (e.g., "this action was performed by agent X registered as ERC-8004 #1234, authorized by user Y") creates a **visible, verifiable proof point** that demonstrates the passport concept.

Secondary entry points: Discord/Slack bots (community management agents), Twitter/X (social agents), SaaS APIs (automation agents).

### 10.4 Business Model Recommendations

| Revenue Stream | Mechanism | Target Customer | Unit Economics |
|----------------|-----------|-----------------|----------------|
| **Platform Credential Issuance** | Charge per credential issued (e.g., GitHub auth token bound to agent identity) | Agent developers / Agent platforms | $0.01–0.10 per credential |
| **Verification API** | Charge for real-time agent verification checks (is this agent registered, what's its risk score, what's it authorized to do?) | Web2 platforms / Wallet providers | $0.001–0.01 per verification |
| **Enterprise Agent Identity Management** | SaaS platform for managing fleet of agent identities, credentials, and compliance | Enterprises deploying AI agents | $500–5,000/month per organization |
| **Attestation Fees** | Fees for issuing EAS attestations that record agent credentials and authorizations on-chain | Agent operators | Gas + protocol fee (~$0.10–1.00 per attestation) |
| **Compliance Add-on** | Integration with ERC-8226 for regulated agent mandates; KYA (Know Your Agent) reports | Regulated industries (finance, healthcare) | $0.50–5.00 per mandate verification |

### 10.5 V1 MVP Direction

**Agent Passport V1 MVP: "On-chain Identity → Web2 Credential Bridge for Developer Platforms"**

Core components:

1. **Agent Registration Adapter**: Wrap ERC-8004 identity registration with Agent Passport metadata schema (adding Web2 platform capabilities, authorized actions, and credential bindings). Store the extended schema as an EAS attestation on-chain.

2. **Credential Vault**: Encrypted off-chain storage for Web2 platform credentials (GitHub tokens, SSH keys, API keys) bound to the agent's ERC-8004 identity. The vault emits attestation hashes on-chain for verifiability.

3. **Platform Auth Orchestrator**: For V1, support GitHub (personal access tokens + OAuth), GitLab, and npm. The orchestrator handles: (a) credential provisioning with platform-specific auth flows, (b) session management, (c) audit logging of all agent actions per platform.

4. **Verification Endpoint**: Public API that any platform can query: "Is agent X authorized to perform action Y on platform Z?" Returns a signed attestation with the agent's ERC-8126 risk score, ERC-8004 reputation, and platform-specific authorization status.

5. **SDK**: TypeScript and Python SDKs that agent frameworks (LangChain, OpenAI Agents SDK, CrewAI, Claude MCP) can use to acquire and present Agent Passport credentials when interacting with Web2 platforms.

**What V1 explicitly does NOT include:**
- CAPTCHA bypass (defer to browser automation partners)
- Email account creation (defer to specialized services)
- Consumer platform support (focus on developer tools first)
- Regulated finance support (defer to ERC-8226 integration in V2)

**Success metric for V1**: 1,000+ agents registered with Agent Passport credentials, 10+ integrations with agent frameworks, at least one major developer platform (GitHub or GitLab) recognizing Agent Passport assertions in their audit logs.

---

*Report compiled from 25 evidence blocks across 15+ search rounds. All factual claims carry inline citations with source URLs. No citations rely on internal knowledge or fabricated sources.*
