# Agent Passport V0 Whitepaper

## The Agent-Native Identity & Access Layer for Web2 Interoperability

**Version:** 0.1.0  
**Date:** July 2026  
**Status:** Draft  
**Network:** Base Mainnet (Chain ID: 8453)  
**License:** MIT

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Market Analysis](#3-market-analysis)
4. [Solution Architecture](#4-solution-architecture)
5. [Technical Design](#5-technical-design)
6. [Differentiation](#6-differentiation)
7. [Business Model](#7-business-model)
8. [Roadmap](#8-roadmap)
9. [Team & Ecosystem](#9-team--ecosystem)
10. [Risk Analysis](#10-risk-analysis)
11. [Governance](#11-governance)
12. [References](#12-references)

---

## 1. Executive Summary

The AI agent economy has crossed a critical threshold. As of mid-2026, **ERC-8004 has registered over 170,000 agents on-chain**, and the ERC standard stack — comprising ERC-8004 (identity), ERC-8126 (verification), ERC-8183 (commerce), ERC-8196 (authenticated wallets), ERC-8226 (regulated mandates), and ERC-8263 (proof layer) — has established a comprehensive trust layer for on-chain agent identity, verification, commerce, and compliance. Yet a fundamental gap persists: **agents cannot operate across Web2 platforms**.

AI agents built by developers worldwide cannot register GitHub accounts, authenticate on Discord servers, submit code to repositories, post on Twitter, or interact with the millions of Web2 services designed exclusively for human users. The entire Web2 platform ecosystem — valued at trillions of dollars and serving billions of users — remains completely inaccessible to the 170,000+ agents that now possess verifiable on-chain identities. This is not a minor inconvenience; it is a structural barrier that prevents the agent economy from reaching its full potential.

**Agent Passport** is the identity and access layer that bridges on-chain agent identity to Web2 platform access. Born from the practical challenges of building the Agent Governance Layer (AGL) for Art.50 regulatory compliance, Agent Passport provides four core capabilities:

1. **Agent-Native Identity** — ERC-721 based identity with wallet binding via EIP-712 signatures and multi-chain identity aggregation across Base, Ethereum, and Arbitrum.
2. **Verifiable Passport** — A trusted attestation system for agent capabilities, compliance status, and authorization scope, enabling portable credentials that any platform can verify.
3. **Proof-of-Agent Access** — A cryptographic identity proof mechanism that replaces CAPTCHA and email verification, enabling agents to authenticate to Web2 platforms using their on-chain identity and wallet signatures.
4. **Portable Compliance** — Integration of ERC-8126 risk scores and ERC-8226 mandate delegation into a single composable compliance layer that travels with the agent across platforms and chains.

Agent Passport does **not** compete with agent wallets (Coinbase, Cobo, Crossmint) or on-chain identity registries (ERC-8004). Instead, it sits **above** these layers as the authorization and interoperability primitive — the "passport" that proves who the agent is and what it is authorized to do, across both on-chain and off-chain environments. The wallet is the vault; Agent Passport is the passport.

Our Proof-of-Concept on Base Mainnet demonstrates a deployment cost of **$0.000752 per event** — making agent identity operations orders of magnitude cheaper than any existing Web2 identity infrastructure, where a single authentication event through services like Auth0 or Okta costs $0.01–$0.10. Six contracts are already deployed on Base Mainnet, and 27 business development letters have been sent to potential ecosystem partners across wallets, frameworks, platforms, and compliance providers.

The competitive landscape, which we analyzed across **25 projects in six tracks**, reveals that the Agent-to-Web2 bridge is a completely unserved market. Visa's Trusted Agent Protocol addresses only commerce interactions. Microsoft Entra Agent ID covers only enterprise OAuth within the Microsoft ecosystem. No project provides a unified, agent-native identity passport that bridges on-chain identity to Web2 service access across the full platform landscape. Agent Passport is designed to own this whitespace.

---

## 2. Problem Statement

### 2.1 The Origin: AGL实战痛点 (Operational Pain Points)

Agent Passport emerged from direct operational experience building the **Agent Governance Layer (AGL)** — a compliance framework for AI agents operating under Art.50 regulatory requirements. During AGL development, we encountered a set of fundamental, unsolved problems that every agent developer faces:

| Problem | Description | Real-World Impact |
|---------|-------------|-------------------|
| **No Registration** | Agents cannot complete registration flows on any Web2 platform because email and SMS verification require human intermediation | Agents are locked out of the platform economy entirely |
| **CAPTCHA Barrier** | Verification systems like reCAPTCHA and hCaptcha are designed to exclude non-human operators by definition | Every automated interaction with protected platforms is blocked |
| **Identity Fragmentation** | Each platform maintains its own identity system (GitHub OAuth, Discord tokens, Twitter API keys); agents cannot carry identity across platforms | No portable agent identity exists; each platform requires separate credential management |
| **No Compliance Proof** | No standardized mechanism exists to prove agent compliance status to platforms | Regulated operations are impossible; platforms cannot verify that an agent meets their compliance requirements |

These are not theoretical problems. They are the **daily operational reality** for every developer building AI agents today. Consider these concrete scenarios:

- An AI coding agent like Claude Code or Cursor cannot independently push to a GitHub repository without a human manually configuring tokens and permissions.
- A community management agent cannot join a Discord server because the verification flow requires email confirmation and potentially CAPTCHA solving.
- A research agent cannot access email-gated academic forums or submit papers to review platforms.
- A trading agent cannot register on new DeFi platforms that require KYC or email verification before granting API access.

In each case, the agent has a verifiable on-chain identity (if ERC-8004 registered), but this identity is useless for Web2 platform access. The on-chain world and the Web2 world exist as parallel universes with no bridge between them.

### 2.2 The Scale of the Problem

The problem's magnitude becomes clear when considering the convergence of several data points:

- **170,000+ agents** registered on-chain via ERC-8004 (as of May 2026), each with a verifiable identity but no way to use it off-chain. This number is growing rapidly as the ERC-8004 standard gains adoption across the ecosystem.
- **4,700% surge** in AI agent traffic on the internet, as reported by Visa in their TAP announcement (2025). Yet every single interaction requires human intermediation — agents are flooding the internet but cannot authenticate properly.
- **25+ projects** building agent identity infrastructure across six competitive tracks, and **zero** of them solve the Web2 bridge problem. The entire innovation effort is focused on the on-chain layer, leaving the Web2 gap completely unaddressed.
- The entire Web2 platform economy — GitHub's 100M+ developers, Discord's 150M+ monthly active users, Twitter's 500M+ users, Slack's 38M+ daily active users — is designed for human authentication flows that fundamentally exclude agents.

### 2.3 Why Existing Solutions Fail

The ERC standard stack, while comprehensive for on-chain operations, has a critical blind spot that no standard addresses:

- **ERC-8004** gives agents on-chain identity (an `agentId`, an NFT, a reputation). But a smart contract cannot log into GitHub. The standard provides no mechanism for translating on-chain identity into Web2 credentials.
- **ERC-8126** provides risk scoring and multi-dimensional verification. But platforms have no standardized way to consume these scores in their authentication decisions.
- **ERC-8196** defines policy-bound wallet execution with audit trails. But it does not address platform authentication — it governs what an agent can do with its wallet, not how it proves its identity to external services.
- **ERC-8226** handles regulated mandates and delegation chains. But it assumes the agent already has platform access. You cannot delegate authority to an agent that cannot register on the platform in the first place.
- **ERC-8183** enables agent-to-agent commerce with escrow and reputation. But agents still cannot register on the platforms where commerce happens.
- **ERC-8263** anchors behavioral proofs and inference attestations. But there is no behavioral data to anchor when agents cannot access platforms in the first place.

**No ERC standard addresses the Agent-to-Web2 authentication problem.** The standard stack solves identity, verification, commerce, compliance, and proof — but not access. This is the precise gap that Agent Passport fills. It is the missing layer between "the agent exists on-chain" and "the agent can operate on the open internet."

### 2.4 The Economic Cost of the Gap

The inability of agents to access Web2 platforms creates measurable economic friction:

1. **Developer productivity loss**: Every AI coding agent requires human-configured credentials, adding 30-60 minutes of setup per agent per platform. At scale, with thousands of agents being deployed daily, this represents millions of hours of unnecessary human labor.

2. **Platform lock-in**: Without portable identity, agents are trapped within the platforms where credentials have been manually configured. This prevents the multi-platform operation that is essential for agent utility.

3. **Compliance impossibility**: Regulated industries (finance, healthcare, legal) cannot deploy agents at scale because there is no way to prove agent compliance to platform operators. The compliance layer exists (ERC-8226) but has no bridge to the platforms where agents need to operate.

4. **Audit gap**: When agents do interact with Web2 platforms through human-provisioned credentials, there is no on-chain audit trail connecting the agent's on-chain identity to its off-chain actions. This makes accountability and forensics impossible.

---

## 3. Market Analysis

### 3.1 Competitive Landscape: 25-Project Matrix

Our comprehensive analysis identified **25 entities** across six competitive tracks. The following analysis classifies each project by track, maturity stage, and strategic relationship to Agent Passport.

#### Track 1: On-Chain Identity Standards (Foundation Layer)

| Project | Standard | Status | Key Metric | Relation |
|---------|----------|--------|------------|----------|
| ERC-8004 | Agent Identity Registration | Draft (Mainnet live, Jan 2026) | **170K+ agents registered** | Foundation layer — Agent Passport builds on top |
| ERC-8126 | Agent Verification | **Final** (Jun 2026) | 5-layer verification, 0-100 risk score | Complementary — we consume risk scores |
| ERC-8183 | Agent Commerce Protocol | Draft | ACP live on Arbitrum | Complementary — commerce layer above identity |
| ERC-8196 | Authenticated Wallet | Draft (Last Call) | No production implementation | Partial overlap on policy-bound execution |
| ERC-8226 | Regulated Mandate | Draft | GhostAgent prototype on Gnosis only | Future partner — regulated delegation |
| ERC-8263 | Onchain Proof Layer | Draft (ref impl live) | Multi-chain deployed | Complementary — inference provenance |

Of these six standards, only **ERC-8004** and **ERC-8126** have meaningful production deployments. ERC-8196, ERC-8226, and ERC-8183 remain in specification or early prototype stages. This standard maturity gap reinforces the need for a practical protocol layer (Agent Passport) that works with the standards that do have production implementations today.

#### Track 2: Agent Wallets (Red Ocean — We Do Not Compete Here)

| Project | Stage | Security Model | Key Differentiator |
|---------|-------|---------------|-------------------|
| Coinbase Agentic Wallet | Production | TEE (Trusted Execution Environment) | x402 payment support; Coinbase distribution |
| Cobo Agentic Wallet | Production | MPC (Multi-Party Computation) | Pact protocol; 80+ chains; per-task authorization |
| Crossmint | Production | Smart contract + key management | MiCA-licensed; card + stablecoin + fiat rails |
| Turnkey | Production | Non-custodial enclave API | Policy engine for limits and whitelists |
| Privy (acquired by Stripe, Jun 2025) | Production | Embedded + server wallets | Stripe stablecoin integration |
| Fireblocks | Production | Institutional custody | $90M Dynamic acquisition; $10T+ secured transactions |

All six wallet providers converge on the **"wallet as callable service"** pattern — the agent never directly holds private keys. This architectural consensus validates our strategic decision: **Agent Passport does not build wallet infrastructure**. We integrate with these providers as the identity and authorization layer that sits above the wallet. The wallet is the vault; Agent Passport is the passport that proves who the agent is and what it is authorized to do.

#### Track 3: Full-Stack Platforms & L1 Chains (Closest Competitors)

| Project | Stage | Funding / Traction | Gap vs. Agent Passport |
|---------|-------|-------------------|----------------------|
| **Virtuals Protocol** | Production | $33M+ implied; 17K agents; $479M aGDP | Base-native, tokenization-centric, no Web2 bridge |
| **Kite** | Testnet | $33M total (PayPal Ventures, Samsung) | L1 chain approach vs. our protocol approach |

Virtuals Protocol is the closest competitor by scope, but its focus is fundamentally different: it treats agents as investable assets (create, tokenize, trade) rather than autonomous operators (identify, authenticate, access). Agent Passport targets the latter use case.

#### Track 4: Enterprise Auth & Web2 Bridges (Partial Competitors)

| Project | Stage | Scope | Gap vs. Agent Passport |
|---------|-------|-------|----------------------|
| **Visa TAP** | Pilot (Oct 2025) | Commerce only (browsing + paying) | No GitHub/Discord/forum access; commerce-only |
| **Microsoft Entra Agent ID** | Production | Enterprise OAuth for agents | Web2-only; no on-chain identity; Microsoft-ecosystem-bound |
| **Auth0 (Okta)** | Production | Enterprise CIAM for agents | No agent-native identity; Web2-native only |
| **Incode Agentic Identity** | Pilot (Q4 2025) | Human-agent binding via biometrics | Human-centric; does not give agent its own portable identity |

Visa TAP is the most notable partial competitor. Launched with Cloudflare in October 2025, TAP uses HTTP Message Signatures (RFC 9421) to verify that an AI agent is trusted for commerce. Its partner list — Stripe, Shopify, Coinbase, Microsoft, Adyen, Akamai — is impressive. But TAP addresses only a narrow slice: commerce-specific Web2 interactions. It does not enable agents to register GitHub accounts, post on Discord, submit code to repositories, or interact with the long tail of non-commerce platforms. Agent Passport extends the identity bridge to the full platform landscape.

#### Track 5: Human Identity (Complementary)

| Project | Scale | Verification Method | Why Insufficient for Agents |
|---------|-------|--------------------|---------------------------|
| World ID | 18M verified humans | Iris scanning at Orb device | Requires biological verification; agent cannot visit Orb |
| Civic | Limited public data | Government ID + liveness check | Designed for human identity documents |
| EAS | 8.5M+ attestations | Any signed claim | Raw primitive; lacks agent-specific schemas and platform integration |

World ID recently added "World ID for agents" — infrastructure for proving a verified human stands behind an agent. This is complementary to Agent Passport (a human-backed agent still needs a passport to access platforms) but fundamentally different from giving the agent its own independent identity.

#### Track 6: Infrastructure Partners (Integrate, Don't Compete)

| Project | Role | Integration Point |
|---------|------|-------------------|
| agentgateway (Linux Foundation / Solo.io) | Agent traffic routing | Our identity assertions flow through its HTTP/gRPC/MCP/A2A data plane |
| OpenClaw | Multi-channel (20+ IM platforms) | We provide identity; they provide message routing |
| Browserbase / Browserless | Cloud-native stealth browsers | They provide browser execution; we provide the identity to authenticate |
| AgentQL | Semantic web data extraction | They extract data; we authenticate the agent extracting it |
| zkMe | ZK-based trust gateway | ZK verification for MCP/A2A protocols |
| Metaplex Agent Registry | Solana agent identity | Cross-chain identity complement |

### 3.2 The Passport Gap: Market Positioning

The competitive landscape reveals a clear quadrant analysis:

```
                    On-Chain Focus ←————→ Web2 Focus
                         │                    │
    Agent-Native         │  [EMPTY ZONE]      │  ★ Agent Passport
    (identity model)     │  (our target)      │    (our position)
                         │                    │
    ─────────────────────┼────────────────────┼────────────
                         │                    │
    Human-Derived        │  ERC-8004          │  Visa TAP
    (identity model)     │  ERC-8126          │  Microsoft Entra
                         │  Virtuals Protocol │  World ID
                         │                    │
```

**The upper-right quadrant — agent-native identity with Web2 focus — is completely empty.** No existing project occupies this space. Projects are either focused on-chain (ERC-8004, Virtuals) or on Web2 (Visa TAP, Microsoft Entra) with human-derived identity models. Agent Passport is designed to own this quadrant exclusively.

### 3.3 Market Timing: Three Converging Trends

1. **Standard stack maturity**: ERC-8004 is mainnet-live with 170K+ agents. ERC-8126 reached Final status in June 2026 — the first ERC in the agent stack to achieve Final. The foundation is stable and ready for higher-level protocols.

2. **Agent traffic explosion**: Visa reported a 4,700% surge in AI agent traffic. Platforms are actively seeking ways to identify, authenticate, and manage agent interactions — they just do not have the infrastructure yet. The demand pull is real and growing.

3. **Wallet layer consensus**: With Coinbase, Cobo, Crossmint, and Stripe (via Privy acquisition) all building agent wallets, the "wallet as callable service" pattern is an established architectural consensus. The identity layer above wallets is the natural next build — and it is completely unbuilt today.

---

## 4. Solution Architecture

### 4.1 Design Principles

Agent Passport is built on five architectural principles that guide every design decision:

1. **Protocol, not platform** — Agent Passport works across chains and platforms, not locked to a single ecosystem. The contracts are deployable on any EVM chain; the access protocols are platform-agnostic.

2. **Layer above wallets** — Agent Passport integrates with existing agent wallets (Coinbase, Cobo, Crossmint) rather than competing with them. The wallet holds assets; the passport holds identity and authorization.

3. **On-chain anchor, off-chain execution** — Identity and authorization decisions are anchored on-chain for verifiability and auditability. Actual Web2 interactions happen off-chain through gateway services for performance and compatibility.

4. **Composable with ERC standards** — Agent Passport builds on ERC-8004 identity, consumes ERC-8126 risk scores, supports ERC-8226 mandates, and records behavioral proofs compatible with ERC-8263. It is a composable layer in the standard stack, not a competing standard.

5. **Cryptographic proof over human verification** — EIP-712 structured signatures replace email verification. On-chain identity replaces CAPTCHA. The entire system is designed for agents, not adapted from human flows.

### 4.2 Four-Contract Architecture

Agent Passport V0 consists of four smart contracts organized in a three-layer stack (L1 Foundation → L2 Attributes → L3 Access/Compliance):

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Application Layer (Web2 / Web3)                           │
│                                                                                  │
│   ┌───────────┐  ┌────────────┐  ┌─────────────┐  ┌────────────────────────┐   │
│   │ Web2      │  │ DeFi       │  │ Agent       │  │ Compliance             │   │
│   │ Platforms │  │ Protocols  │  │ Frameworks  │  │ Engines                │   │
│   │ (GitHub,  │  │            │  │ (LangChain, │  │ (ERC-8126 scorers,     │   │
│   │  Discord, │  │            │  │  CrewAI,    │  │  KYC providers,        │   │
│   │  Twitter) │  │            │  │  MCP)       │  │  Regulated entities)   │   │
│   └─────┬─────┘  └─────┬──────┘  └──────┬──────┘  └──────────┬─────────────┘   │
│         │               │                │                     │                 │
├─────────┴───────────────┴────────────────┴─────────────────────┴──────────────────┤
│                     L3: Access & Compliance Layer                                 │
│                                                                                    │
│   ┌───────────────────────────┐     ┌──────────────────────────────────────┐     │
│   │   AccessGateway.sol       │     │   CompliancePassport.sol             │     │
│   │   ─────────────────────── │     │   ────────────────────────────────── │     │
│   │   • Proof-of-Agent        │     │   • ERC-8126 risk score integration  │     │
│   │   • OAuth-like flow       │     │   • ERC-8226 mandate delegation      │     │
│   │   • Session anchoring     │     │   • Compliance certificates          │     │
│   │   • PKCE support          │     │   • Multi-scorer aggregation         │     │
│   │   • Access revocation     │     │   • Certificate lifecycle            │     │
│   └─────────────┬─────────────┘     └──────────────┬───────────────────────┘     │
│                 │                                   │                             │
├─────────────────┴───────────────────────────────────┴─────────────────────────────┤
│                     L2: Identity Attributes Layer                                  │
│                                                                                    │
│   ┌─────────────────────────────────────────────────────────────────────────┐     │
│   │                     AgentPassport.sol                                    │     │
│   │   ──────────────────────────────────────────────                        │     │
│   │   • Agent attributes (type / capabilities / compliance status)          │     │
│   │   • Trusted verifier attestation system (VERIFIER_ROLE)                 │     │
│   │   • Off-chain signature + on-chain submission (gasless attestations)    │     │
│   │   • ERC-8196 policy binding                                             │     │
│   │   • Portable passport export for off-chain presentation               │     │
│   └────────────────────────────────────┬────────────────────────────────────┘     │
│                                        │                                          │
├────────────────────────────────────────┴──────────────────────────────────────────┤
│                     L1: Identity Foundation Layer                                  │
│                                                                                    │
│   ┌─────────────────────────────────────────────────────────────────────────┐     │
│   │                     AgentRegistry.sol                                    │     │
│   │   ──────────────────────────────────────────────                        │     │
│   │   • ERC-721 NFT identity (fully ERC-8004 compatible)                   │     │
│   │   • Wallet binding via EIP-712 signed authorization                    │     │
│   │   • Multi-chain identity aggregation                                   │     │
│   │   • Extensible metadata system with reserved keys                      │     │
│   └─────────────────────────────────────────────────────────────────────────┘     │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Contract Dependency & Deployment Order

The four contracts have strict dependency relationships requiring sequential deployment:

```
Step 1: AgentRegistry.sol           ← No dependencies (foundation)
    │
    ▼
Step 2: AgentPassport.sol           ← Depends on AgentRegistry address
    │
    ├──→ Step 3a: AccessGateway.sol      ← Depends on Registry + Passport
    │
    └──→ Step 3b: CompliancePassport.sol ← Depends on Registry
```

### 4.4 Deployment Parameters

All contracts target Base Mainnet with the following specifications:

| Parameter | Value |
|-----------|-------|
| Network | Base Mainnet (Chain ID: 8453) |
| Gas Token | ETH |
| Block Time | ~2 seconds |
| EVM Version | Shanghai (Cancun) |
| Solidity | ^0.8.24 |
| Dependency | OpenZeppelin Contracts v5.x |

**Estimated Gas Consumption:**

| Operation | Gas | Cost (at Base prices) |
|-----------|-----|----------------------|
| AgentRegistry.register() | ~180,000 gas | ~$0.000136 |
| AgentRegistry.bindWallet() | ~80,000 gas | ~$0.000060 |
| AgentPassport.issueAttestation() | ~90,000 gas | ~$0.000068 |
| AccessGateway.requestAccess() | ~120,000 gas | ~$0.000090 |
| CompliancePassport.recordRiskScore() | ~85,000 gas | ~$0.000064 |

The weighted average cost across all operations is **$0.000752 per event** — validated through PoC deployment on Base Mainnet.

### 4.5 End-to-End Interaction Flow

The complete lifecycle of an agent from registration to Web2 platform access:

```
Phase 1: Identity Creation
═══════════════════════════
Agent Developer
    │
    ├──→ AgentRegistry.register(agentURI)
    │         → Returns agentId (ERC-721 NFT)
    │         → On-chain: Base Mainnet
    │
    └──→ AgentRegistry.bindWallet(agentId, wallet, deadline, signature)
              → EIP-712 signed binding
              → Links agent identity to operational wallet

Phase 2: Passport Enrichment
═════════════════════════════
Verifier (trusted party)
    │
    ├──→ AgentPassport.setAttribute(agentId, TYPE, value)
    │         → Agent type, capabilities, compliance status
    │
    ├──→ AgentPassport.issueAttestation(agentId, schema, data)
    │         → Signed attestation by VERIFIER_ROLE holder
    │
    └──→ CompliancePassport.recordRiskScore(agentId, score, evidence)
              → ERC-8126 five-dimensional risk assessment

Phase 3: Web2 Platform Access
══════════════════════════════
Agent (via wallet)
    │
    ├──→ Construct AccessRequest
    │         ├─ platformId: "github.com"
    │         ├─ scopes: ["repo:read", "repo:write"]
    │         ├─ expiry: now + 1h
    │         └─ EIP-712 signature from agent wallet
    │
    ├──→ AccessGateway validates on-chain
    │         ├─ ✓ AgentRegistry: is registered agent?
    │         ├─ ✓ AgentPassport: valid attestations?
    │         └─ ✓ CompliancePassport: risk score acceptable?
    │
    ├──→ AccessGateway.grantAccess()
    │         → Session anchored on-chain
    │         → JWT-like access token issued off-chain
    │
    └──→ Agent uses token to access Web2 platform
              → Platform verifies on-chain session anchor

Phase 4: Compliance Lifecycle
══════════════════════════════
Principal (KYC-verified entity)
    │
    ├──→ CompliancePassport.recordMandate(agentId, principal, scope, cap)
    │         → ERC-8226 compliant delegation
    │
    └──→ Agent operates within delegated scope
              → All actions verifiable on-chain
              → Principal liability clearly defined
```

---

## 5. Technical Design

### 5.1 AgentRegistry.sol — Identity Foundation

**Purpose:** The trust anchor for the entire system. Every agent receives a unique, transferable on-chain identity here. This contract is the foundation upon which all other components depend.

**Core Mechanisms:**

| Mechanism | Implementation | Standard | Security Model |
|-----------|---------------|----------|---------------|
| Agent Identity | ERC-721 NFT — each agent is a unique, transferable token | ERC-8004 | Ownership transferable; identity follows the NFT |
| Wallet Binding | EIP-712 typed data signature with nonce + deadline | Custom (EIP-712) | Three-layer protection: typed data + nonce + deadline |
| Multi-Chain Aggregation | `registerChainIdentity()` maps identities across chains | Custom | Chain-specific registry addresses verified on-chain |
| Metadata System | Reserved keys (`agentWallet`) + extensible custom keys | ERC-8004 | Reserved keys protected; custom keys owner-controlled |

**ERC-8004 Compatibility:** AgentRegistry implements the full ERC-8004 registration interface:

- `register()` with three overloads for different registration flows (direct, delegated, and pre-signed)
- `setAgentURI()` / `getMetadata()` / `setMetadata()` for agent metadata management
- `Registered` / `MetadataSet` events for off-chain indexing by subgraphs and explorers
- `agentWallet` reserved key per ERC-8004 specification
- Automatic wallet binding clearance on NFT transfer — when an agent NFT is transferred, the previous wallet binding is automatically cleared to prevent unauthorized access by the previous owner

**Multi-Chain Identity Flow:**

```
Agent registers on Base       → agentId = 1
Agent registers on Ethereum   → agentId = 5  
Agent calls registerChainIdentity(1, 1, 0xETH_REGISTRY, 5)
→ Establishes Base:1 ↔ Ethereum:5 bidirectional mapping
→ Single agent identity across multiple chains
→ Enables cross-chain reputation and credential portability
```

### 5.2 AgentPassport.sol — Identity Attributes & Attestations

**Purpose:** The rich identity layer. While AgentRegistry provides the "ID number," AgentPassport provides the "credentials" — verifiable claims about the agent's capabilities, compliance status, and authorization scope. This is the data layer that platforms consume when deciding whether to grant access.

**Core Mechanisms:**

| Mechanism | Description | Access Control | Revocability |
|-----------|-------------|---------------|-------------|
| Agent Attributes | Key-value storage for agent type, capabilities, compliance status | REGISTRAR_ROLE | Owner can update |
| Verifier Attestation | Trusted verifiers issue signed attestations about agents | VERIFIER_ROLE | Verifier can revoke |
| Signature Attestation | Off-chain signature + on-chain submission for gasless attestation | VERIFIER_ROLE | Verifier can revoke |
| ERC-8196 Policy | Bind execution policies to agent identity | Owner / Agent | Owner can update |
| Passport Export | Generate human-readable passport summary for off-chain presentation | Public (view) | N/A |

**Attestation Lifecycle:**

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Issued  │────→│  Active  │────→│ Expired  │     │ Revoked  │
│          │     │          │     │          │     │          │
└──────────┘     └────┬─────┘     └──────────┘     └──────────┘
                      │
                      └─── Can be revoked by verifier at any time
                           (e.g., if agent behavior violates attestation criteria)
```

Two issuance paths exist to accommodate different gas cost preferences:
1. **Direct on-chain issuance** — `issueAttestation()` called directly by a VERIFIER_ROLE holder. Higher gas cost but immediate on-chain availability.
2. **Gasless issuance** — Verifier signs off-chain using EIP-712, anyone submits on-chain via `issueAttestationBySignature()`. Lower cost for the verifier; the submitter pays gas. Includes nonce and deadline for replay protection.

### 5.3 AccessGateway.sol — The Web2 Bridge

**Purpose:** The core innovation of Agent Passport. This contract enables agents to use wallet signatures as authentication credentials, effectively replacing CAPTCHA and email verification with cryptographic identity proof. **No other project in the competitive landscape provides this bridge.**

#### 5.3.1 Direct Access Flow (Proof-of-Agent)

```
Traditional Web2:     User → Fill Email → Solve CAPTCHA → Register → Access
                      ↑ Human-only. Agents blocked here.

Agent Passport:       Agent → Wallet Signature → On-chain Identity Verify → Access
                      ↑ Agent-native. No CAPTCHA needed.
```

**Detailed flow:**

1. **Agent constructs AccessRequest** — containing platformId (target platform identifier), scopes (requested permissions), and expiry (time-bounded validity). The request is signed with the agent's private key using EIP-712 structured data.

2. **Gateway validates on-chain** — The gateway service verifies the EIP-712 signature authenticity, checks AgentRegistry for registration status, validates AgentPassport attestations for the requested scopes, and confirms CompliancePassport risk score is within acceptable range.

3. **Gateway grants access** — Calls `grantAccess()` to anchor the session on-chain. The off-chain gateway service generates a JWT-like access token. The session state is publicly verifiable on-chain by anyone.

4. **Agent accesses Web2 platform** — Presents the access token to the platform. The platform can independently verify the on-chain session anchor.

#### 5.3.2 OAuth-Like Authorization Code Flow (with PKCE)

For platforms requiring OAuth-style authentication flows, Agent Passport provides a compatible flow with on-chain identity anchoring:

1. Agent requests authorization code with PKCE challenge
2. Agent signs the request; codeHash is recorded on-chain
3. Gateway validates and issues authorization code
4. Agent exchanges code with code_verifier
5. Gateway returns access_token
6. Session is anchored on-chain for auditability

This flow is backward-compatible with existing OAuth 2.0 infrastructure while adding the on-chain identity anchor that traditional OAuth lacks.

#### 5.3.3 Proof-of-Agent vs. CAPTCHA — A Paradigm Shift

The fundamental insight of AccessGateway is that **CAPTCHA exists because platforms cannot distinguish authorized humans from unauthorized bots. Agent Passport inverts this paradigm — agents prove they are authorized agents, making the human/bot distinction irrelevant.**

| Dimension | CAPTCHA | Proof-of-Agent |
|-----------|---------|---------------|
| What it proves | "I am human" | "I am an authorized, registered agent" |
| Verification method | Puzzle solving / behavior analysis | Cryptographic signature + on-chain identity |
| Agent compatibility | ❌ Fundamentally incompatible by design | ✅ Agent-native from the ground up |
| Platform integration effort | Existing (universal but human-only) | Gateway integration required (one-time) |
| Security model | Probabilistic (can be broken by ML) | Cryptographic (computationally infeasible to forge) |
| Auditability | None (no persistent record) | Full on-chain audit trail for every access grant |
| Revocability | Manual account suspension | On-chain revocation cascades to all sessions |

### 5.4 CompliancePassport.sol — Portable Compliance Proof

**Purpose:** Integrates ERC-8126 risk scoring and ERC-8226 mandate delegation into a single, portable compliance layer that travels with the agent across platforms and chains.

#### 5.4.1 ERC-8126 Risk Score Integration

The five-dimensional verification model provides granular risk assessment:

| Dimension | What It Checks | Why It Matters |
|-----------|---------------|---------------|
| Token Verification | Token interaction patterns and legitimacy | Prevents agents from interacting with scam tokens |
| Media Content Verification | Content compliance and appropriateness | Ensures agent-generated content meets platform standards |
| Solidity Code Verification | Smart contract audit status | Prevents agents from interacting with unaudited contracts |
| Web Application Verification | Web security posture of target platforms | Protects agents from phishing and malicious sites |
| Wallet Verification | Wallet history, transaction patterns | Identifies compromised or suspicious wallet behavior |

**Multi-scorer aggregation** allows multiple independent verifiers to contribute risk assessments, with weighted averaging to produce a composite score:

```
Verifier A: 15 (weight 0.3) + Verifier B: 22 (weight 0.4) + Verifier C: 18 (weight 0.3)
→ Composite score: 18.3 (weighted average)
→ Compliance Level: 3 (Partially Compliant)
```

#### 5.4.2 ERC-8226 Mandate Delegation

For regulated operations, CompliancePassport provides a verifiable chain of responsibility from a KYC-verified principal to the acting agent:

```
Principal (KYC-verified person or institution)
    │
    ├──→ Delegates to Agent:
    │         ├─ mandateExpiry: 2026-12-31
    │         ├─ financialCap: 100 ETH
    │         ├─ scopeHash: 0x... (SHA-256 of authorized operations)
    │         └─ frozen: false (emergency freeze capability)
    │
    └──→ Agent operates within delegated scope
              → All actions auditable on-chain
              → Principal liability clearly defined
              → Regulators can verify the entire chain
```

This satisfies Art.50 and similar regulatory frameworks that require a traceable chain from a responsible human entity to the acting agent. The mandate is on-chain, verifiable by any platform, and can be frozen or revoked by the principal at any time.

---

## 6. Differentiation

### 6.1 vs. Visa Trusted Agent Protocol (TAP)

| Dimension | Visa TAP | Agent Passport |
|-----------|----------|---------------|
| **Scope** | Commerce only (browsing + paying on merchant sites) | Full platform access (GitHub, Discord, Twitter, SaaS, DeFi, forums) |
| **Identity model** | HTTP Message Signatures (RFC 9421) | ERC-721 NFT + EIP-712 cryptographic proof |
| **On-chain integration** | No on-chain identity required | Full ERC-8004 integration with 170K+ agent ecosystem |
| **Target user** | Merchants accepting AI agent payments | Any Web2 platform that agents need to access |
| **Compliance** | Merchant-side verification only | Full compliance stack (ERC-8126 risk + ERC-8226 mandate) |
| **Partners** | Stripe, Shopify, Coinbase, Microsoft, Adyen, Akamai | Open protocol — any platform can integrate |
| **Cost** | Unknown (pilot stage) | $0.000752/event (PoC validated) |

**Relationship:** Complementary. Visa TAP handles the commerce layer; Agent Passport handles the identity and access layer for the long tail of non-commerce platforms. An agent with an Agent Passport can use Visa TAP for commerce transactions while using Agent Passport for everything else.

### 6.2 vs. Microsoft Entra Agent ID

| Dimension | Microsoft Entra Agent ID | Agent Passport |
|-----------|------------------------|---------------|
| **Architecture** | Web2 enterprise identity system | Agent-native + on-chain identity system |
| **Protocol** | OAuth 2.0 / OIDC (standard Web2) | EIP-712 + on-chain verification (agent-native) |
| **Ecosystem lock-in** | Microsoft-bound (Copilot, Azure, AWS Bedrock) | Chain-agnostic, platform-agnostic, open protocol |
| **Identity portability** | Within Microsoft ecosystem only | Portable across all EVM chains and Web2 platforms |
| **Compliance** | Enterprise IAM (off-chain) | On-chain verifiable compliance (ERC-8126/8226) |
| **Agent-to-agent trust** | Not supported | Native support via ERC-8004 identity and reputation |
| **Cost** | Enterprise licensing | $0.000752/event on Base |

**Relationship:** Microsoft Entra serves enterprises within the Microsoft ecosystem. Agent Passport serves the open, decentralized agent ecosystem. They can interoperate: an enterprise agent could hold both a Microsoft Entra identity (for internal systems) and an Agent Passport (for the open Web).

### 6.3 vs. ERC-8004 (On-Chain Identity Only)

| Dimension | ERC-8004 | Agent Passport |
|-----------|----------|---------------|
| **Layer** | L1: Identity registration only | L1-L3: Full identity + access + compliance |
| **Scope** | On-chain agentId (NFT) + reputation | On-chain identity + off-chain platform access + compliance |
| **Web2 bridge** | ❌ None — cannot authenticate to Web2 platforms | ✅ Core feature — AccessGateway enables Web2 access |
| **Compliance** | ❌ None | ✅ ERC-8126 risk scoring + ERC-8226 mandate delegation |
| **Attestation** | Basic metadata (URI) | Full attestation system with verifier roles and lifecycle |

**Relationship:** Complementary and dependent. Agent Passport **builds on** ERC-8004 as its foundation layer. Every Agent Passport identity is an ERC-8004 identity, enriched with passport attributes, access credentials, and compliance proofs. We are not replacing ERC-8004; we are extending its reach to the Web2 world.

### 6.4 vs. Virtuals Protocol / EconomyOS

| Dimension | Virtuals Protocol | Agent Passport |
|-----------|------------------|---------------|
| **Chain** | Base-native only | Multi-chain (Base first, then Ethereum, Arbitrum) |
| **Model** | Tokenization-centric (agent as investable asset) | Identity-centric (agent as autonomous operator) |
| **Focus** | Agent creation + token launch + commerce | Agent identity + Web2 access + compliance |
| **Wallet** | Built-in wallet infrastructure | Integration layer (Coinbase, Cobo, Crossmint) |
| **Web2 bridge** | ❌ Not addressed | ✅ Core feature via AccessGateway |
| **Revenue** | Token launch fees, transaction fees | Credential issuance, verification API, enterprise SaaS |

**Relationship:** Different market segments. Virtuals targets the "agent as product" market (create, launch, invest). Agent Passport targets the "agent as operator" market (identify, authenticate, access). An agent created on Virtuals Protocol could — and we argue should — use Agent Passport for its identity and Web2 access needs.

### 6.5 The Three Pillars of Unique Positioning

Agent Passport's unique position is defined by three attributes that **no existing project combines simultaneously**:

1. **Agent-Native Identity (not human-derived)**  
   Unlike World ID (requires iris scanning), Incode (requires biometric verification), or Civic (requires government ID), Agent Passport does not require any form of biological verification. The agent's identity is its own — derived from its on-chain registration, operational capabilities, and behavioral history. This is essential because agents are not humans and cannot (and should not need to) prove they are human.

2. **Web2 Bridge (not just on-chain)**  
   Unlike ERC-8004, ERC-8126, or any existing ERC standard, Agent Passport provides the concrete bridge from on-chain identity to Web2 platform access. AccessGateway's Proof-of-Agent mechanism is the first protocol-level solution for agent-to-Web2 authentication. This is not a theoretical proposal — it is implemented in our V0 contracts.

3. **Protocol Layer (not a chain or platform)**  
   Unlike Kite (building its own L1 chain) or Virtuals (Base-native platform), Agent Passport is a protocol that works across chains and platforms. It does not compete with wallets or chains; it sits above them as the identity and authorization layer. This protocol-level positioning enables maximum composability and ecosystem reach.

---

## 7. Business Model

### 7.1 Five Revenue Streams

Agent Passport operates five revenue streams designed to align incentives across the ecosystem while maintaining accessibility for individual developers:

| # | Revenue Stream | Mechanism | Target Customer | Unit Economics |
|---|---------------|-----------|-----------------|----------------|
| 1 | **Platform Credential Issuance** | Fee per credential issued (e.g., GitHub auth token bound to agent identity) | Agent developers / Agent platforms | $0.01 – $0.10 per credential |
| 2 | **Verification API** | Fee for real-time agent verification checks (registration status, risk score, authorization scope) | Web2 platforms / Wallet providers | $0.001 – $0.01 per verification |
| 3 | **Enterprise Agent Identity Management** | SaaS platform for managing fleet of agent identities, credentials, and compliance | Enterprises deploying AI agents at scale | $500 – $5,000 / month per organization |
| 4 | **Attestation Fees** | Fees for issuing on-chain attestations recording agent credentials and authorizations | Agent operators | Gas + protocol fee (~$0.10 – $1.00 per attestation) |
| 5 | **Compliance Add-on** | ERC-8226 integration for regulated agent mandates; KYA (Know Your Agent) reports | Regulated industries (finance, healthcare, legal) | $0.50 – $5.00 per mandate verification |

### 7.2 Cost Advantage

Agent Passport benefits from Base's low-cost L2 infrastructure, creating a significant cost advantage over traditional identity providers:

| Cost Item | Agent Passport (Base) | Traditional (Auth0/Okta) | Advantage |
|-----------|---------------------|-------------------------|-----------|
| Identity registration | ~$0.000752 / event | $0.01 – $0.10 / event | **13x – 133x cheaper** |
| Attestation issuance | ~$0.000500 / event | N/A (no equivalent) | Unique capability |
| Access validation | ~$0.000900 / event | $0.005 – $0.05 / event | **5x – 55x cheaper** |
| Compliance verification | ~$0.000640 / event | $0.50 – $5.00 / event | **780x – 7,800x cheaper** |

This cost advantage is structural: Base's L2 architecture processes transactions at a fraction of the cost of L1 or traditional cloud infrastructure, while maintaining the security guarantees of Ethereum consensus.

### 7.3 Go-to-Market Strategy

**Market entry point: Developer tools and code platforms (GitHub, GitLab, npm).**

Rationale:
- Developer tools are the **highest-value, lowest-friction** entry point. AI coding agents (Claude Code, Cursor, Codex, GitHub Copilot) are already proliferating, and they need to interact with GitHub, GitLab, and package registries.
- These platforms have **API-based authentication** (GitHub tokens, SSH keys) that are more amenable to agent delegation than consumer platforms with CAPTCHA.
- The **developer community is the earliest adopter** of agent infrastructure — they are building the agents that need passports.
- A successful integration with GitHub (e.g., "this commit was pushed by agent X, registered as ERC-8004 #1234, authorized by user Y") creates a **visible, verifiable proof point** that demonstrates the passport concept to the entire developer ecosystem.

Secondary entry points: Discord/Slack bots (community management agents), Twitter/X (social agents), SaaS APIs (automation agents).

---

## 8. Roadmap

### 8.1 Milestone Overview

```
V0 (Q3 2026)              V1 (Q1 2027)              V2 (Q3 2027)
──────────────            ──────────────            ──────────────
PoC Validation       →    MVP Production       →    Full Protocol
                                                      
• 4 contracts             • ERC-8004 adapter        • Proxy (UUPS) upgradeable
• Base Mainnet            • Credential vault        • CCIP cross-chain identity
• 6 deployments           • GitHub/GitLab/npm       • Decentralized verifier
• 200 BD letters           • SDK (TS + Python)         network
• $0.000752/event         • 1,000+ agents           • ERC-8226 full compliance
• Competitive research    • 10+ framework integ.    • Enterprise SaaS platform
  (25 projects)           • 1+ major platform       • 50+ platform support
                            recognition             • 10,000+ agents
```

### 8.2 V0 — Proof of Concept (Current — Q3 2026)

**Status: In Progress**

| Deliverable | Status | Details |
|-------------|--------|---------|
| Smart contract architecture | ✅ Complete | 4 contracts, 3-layer design |
| Solidity implementation | ✅ Complete | Full implementation with OpenZeppelin v5 |
| Unit tests | ✅ Complete | >90% coverage target |
| Base Mainnet deployment | ✅ Complete | 6 contracts deployed and verified |
| Cost validation | ✅ Complete | $0.000752/event measured and documented |
| Competitive research | ✅ Complete | 25 projects analyzed across 6 tracks |
| BD outreach | ✅ Complete | 27 letters sent to ecosystem partners |
| Architecture documentation | ✅ Complete | Full V0 architecture specification |
| Whitepaper | ✅ Complete | This document |

### 8.3 V1 — Minimum Viable Product (Q1 2027)

**Core deliverables:**

1. **Agent Registration Adapter** — Wraps ERC-8004 identity registration with the Agent Passport extended metadata schema, adding Web2 platform capabilities, authorized actions, and credential bindings. The extended schema is stored as an EAS attestation on-chain for verifiability.

2. **Credential Vault** — Encrypted off-chain storage for Web2 platform credentials (GitHub tokens, SSH keys, API keys) bound to the agent's ERC-8004 identity. The vault emits attestation hashes on-chain for verifiability without exposing the credentials themselves.

3. **Platform Auth Orchestrator** — Supports GitHub (personal access tokens + OAuth), GitLab, and npm. Handles credential provisioning with platform-specific auth flows, session management, and comprehensive audit logging of all agent actions per platform.

4. **Verification Endpoint** — Public API that any platform can query: "Is agent X authorized to perform action Y on platform Z?" Returns a signed attestation with the agent's ERC-8126 risk score, ERC-8004 reputation, and platform-specific authorization status.

5. **SDK** — TypeScript and Python SDKs that agent frameworks (LangChain, OpenAI Agents SDK, CrewAI, Claude MCP) can use to acquire and present Agent Passport credentials. Target integration: `const passport = await AgentPassport.authenticate(agentId)`.

**V1 explicitly excludes:**
- CAPTCHA bypass (defer to browser automation partners like Browserbase)
- Email account creation (defer to specialized services)
- Consumer platform support (focus on developer tools first)
- Regulated finance support (defer to ERC-8226 integration in V2)

**V1 Success Metrics:**
- 1,000+ agents registered with Agent Passport credentials
- 10+ integrations with agent frameworks
- At least 1 major developer platform (GitHub or GitLab) recognizing Agent Passport assertions in their audit logs

### 8.4 V2 — Full Protocol (Q3 2027)

| Feature | Description | Impact |
|---------|-------------|--------|
| **Upgradeable Contracts** | UUPS proxy pattern for all four contracts | Enables protocol evolution without migration |
| **Cross-Chain Identity** | CCIP integration for native multi-chain identity | Eliminates manual chain registration |
| **Decentralized Verifier Network** | TEE + ZK verification replacing centralized gateway | Removes single point of trust |
| **Full ERC-8226 Compliance** | Regulated mandate support for finance and healthcare | Opens regulated industry market |
| **Enterprise SaaS** | Dashboard, RBAC, compliance reporting, SLA | $500-$5K/month revenue per org |
| **Expanded Platforms** | Discord, Twitter/X, Slack, 50+ SaaS platforms | Massively expands addressable market |
| **Account Abstraction** | ERC-4337 integration for gasless agent operations | Reduces friction for agent operators |

---

## 9. Team & Ecosystem

### 9.1 AGL Background

Agent Passport is born from the **Agent Governance Layer (AGL)** project — a compliance framework built to address Art.50 regulatory requirements for AI agents. The AGL team brings:

- **Deep domain expertise** in agent compliance, identity, and governance — not theoretical, but forged through building production compliance infrastructure
- **Production experience** operating agent infrastructure on Base Mainnet, with real cost data and real operational insights
- **Standards knowledge** spanning the full ERC-8004/8126/8183/8196/8226/8263 stack, including active participation in standard design discussions
- **First-mover advantage** in identifying and addressing the Agent-to-Web2 gap before any competitor

### 9.2 Existing Chain Assets

| Asset | Status | Significance |
|-------|--------|-------------|
| 6 contracts on Base Mainnet | Deployed and verified | Production-proven infrastructure with real gas costs |
| $0.000752/event cost | Measured and documented | Demonstrates economic viability at scale |
| Full ERC-8004 integration | Designed and implemented | Compatible with the 170K+ agent ecosystem from day one |
| ERC-8126 + ERC-8226 integration | Designed | Full compliance stack ready for regulated use cases |
| Comprehensive competitive research | Complete | 25 projects analyzed; strategic positioning validated |

### 9.3 BD Network: 27 Letters Sent

The team has initiated business development outreach with **27 letters** sent to potential ecosystem partners across five categories:

- **Agent wallet providers** (Coinbase, Cobo, Crossmint) — for integration partnerships where Agent Passport provides identity above their wallet infrastructure
- **Agent framework teams** (LangChain, CrewAI, MCP ecosystem) — for SDK adoption and native integration
- **Web2 platforms** (GitHub, GitLab) — for platform-side integration recognizing Agent Passport assertions
- **Compliance providers** (zkMe, Incode, World ID) — for complementary verification partnerships
- **Enterprise prospects** — for pilot program candidates in regulated industries

### 9.4 Target Ecosystem Partners

| Category | Partners | Integration Type |
|----------|----------|-----------------|
| Identity Standards | ERC-8004, ERC-8126, EAS (8.5M+ attestations) | Build on / consume / storage layer |
| Agent Wallets | Coinbase, Cobo, Crossmint, Turnkey | Identity layer above wallet |
| Verification | zkMe, World ID, Incode | Complementary verification methods |
| Infrastructure | agentgateway, Browserbase, AgentQL, OpenClaw | Traffic routing + execution layer |
| Enterprise Auth | Microsoft Entra, Auth0 | Interoperability bridges for enterprise agents |
| Cross-Chain | Metaplex (Solana), CCIP (Ethereum) | Multi-chain identity coverage |

---

## 10. Risk Analysis

### 10.1 Technical Risks

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| **Smart contract vulnerability** | High | Low | OpenZeppelin v5 libraries; >90% test coverage; external audit planned (Trail of Bits / OpenZeppelin) |
| **Wallet binding spoofing** | High | Low | Three-layer EIP-712 protection: typed data + nonce + deadline |
| **Attestation forgery** | High | Low | VERIFIER_ROLE whitelist; on-chain signature verification; revocation mechanism |
| **Replay attacks** | Medium | Low | All signatures include nonce + chainId + deadline |
| **Gateway centralization** | Medium | Medium | Gateway Service address replaceable; all decisions auditable on-chain; V2 roadmap includes decentralized verifier network |
| **NFT transfer permission residue** | Low | Low | `_update` hook automatically clears wallet binding on transfer |

### 10.2 Market Risks

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| **ERC standard evolution** | Medium | Medium | Active participation in ERC discussions; contracts designed for upgradeability (V2 UUPS proxy) |
| **Visa TAP expansion** | Medium | Low | Visa TAP is commerce-scoped; our Web2 bridge is broader; complementary relationship reduces competition risk |
| **Microsoft Entra dominance** | Medium | Low | Microsoft is enterprise-bound; our open protocol serves the decentralized ecosystem; interoperability bridges planned |
| **Low agent adoption** | High | Medium | Developer-first GTM; SDK simplicity; GitHub integration as visible proof point |
| **Platform resistance** | Medium | Medium | Platforms benefit from verified agent identity (reduces fraud); early partnerships create positive precedents |

### 10.3 Regulatory Risks

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| **Evolving AI regulation** | Medium | High | ERC-8226 integration provides compliance flexibility; modular design allows adapting to new requirements |
| **Cross-border compliance** | Medium | Medium | Multi-chain deployment allows jurisdiction-specific compliance configurations |
| **Data privacy (GDPR)** | Medium | Medium | Only hashes stored on-chain; raw data in off-chain encrypted storage; right to erasure via attestation revocation |

---

## 11. Governance

### 11.1 Role Architecture

Agent Passport implements a role-based access control system using OpenZeppelin's AccessControl:

| Role | Contract | Initial Allocation | Responsibility | Transition Plan |
|------|----------|-------------------|----------------|----------------|
| `DEFAULT_ADMIN_ROLE` | All contracts | Deployer → Multi-sig DAO | Super-admin: role management, contract upgrades | Transfer to DAO governance in V1 |
| `VERIFIER_ROLE` | AgentPassport | Initial verification team | Issue and revoke attestations | Expand to decentralized verifier network in V2 |
| `REGISTRAR_ROLE` | AgentPassport | Automated registration service | Set agent attributes | Automate via oracle in V1 |
| `SCORER_ROLE` | CompliancePassport | Compliance scoring service | Record risk scores | Multi-scorer aggregation in V1 |
| `COMPLIANCE_ORACLE_ROLE` | CompliancePassport | Compliance oracle | Record mandate delegations | Expand verifier set in V1 |
| Gateway Service | AccessGateway | Off-chain gateway service address | Approve access requests | Decentralize in V2 |

### 11.2 Security Principles

1. **Minimal privilege** — Every role possesses only the minimum permissions required for its function.
2. **On-chain anchor + off-chain storage** — Sensitive data is stored as hashes on-chain; raw data resides in encrypted off-chain storage (IPFS / encrypted database).
3. **Time boundaries** — All signatures, certificates, policies, and sessions have explicit expiration times. Nothing is valid indefinitely.
4. **Revocability** — Attestations, certificates, mandates, and access sessions can all be revoked by authorized parties at any time.
5. **EIP-712 standardization** — All signatures use structured data signing, compatible with hardware wallets and human-readable signing interfaces.
6. **ERC-165 interface detection** — All contracts support standard interface detection for seamless integration.

### 11.3 Audit Roadmap

| Phase | Activity | Target |
|-------|----------|--------|
| Pre-V1 | Automated test coverage > 90% | Internal |
| V1 | External security audit | Trail of Bits or OpenZeppelin |
| V1 | Bug bounty program launch | Immunefi or HackerOne |
| V2 | Continuous monitoring | On-chain anomaly detection |
| Ongoing | Re-audit on upgrades | Per upgrade cycle |

---

## 12. References

### ERC Standards & EIPs
- ERC-8004: Trustless Agents — [ethereum.org/EIPs](https://eips.ethereum.org/EIPS/eip-8004)
- ERC-8126: AI Agent Verification — [eips.ethereum.org/EIPS/eip-8126](https://eips.ethereum.org/EIPS/eip-8126)
- ERC-8183: Agentic Commerce Protocol — [RootData](https://www.rootdata.com/news/584398)
- ERC-8196: AI Agent Authenticated Wallet — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8196-ai-agent-authenticated-wallet/27987)
- ERC-8226: Regulated Agent Mandate — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208)
- ERC-8263: Onchain Proof Layer — [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8263-onchain-proof-layer-for-ai-agents/28577)
- EIP-712: Typed Structured Data Hashing and Signing — [eips.ethereum.org](https://eips.ethereum.org/EIPS/eip-712)

### Agent Wallets & Infrastructure
- Coinbase Agentic Wallet — [BlockEden](https://blockeden.xyz/ru/blog/2026/05/07/coinbase-agentic-wallet-callable-service-mcp-architecture/)
- Cobo Agentic Wallet — [Cobo](https://website.cobo.com/post/cobo-launches-agentic-wallet-how-ai-agents-interact-on-chain)
- Fireblocks / Dynamic — [FinanceFeeds](https://financefeeds.com/fireblocks-buys-a16z-backed-dynamic-for-90m-to-bridge-custody-and-wallet-tech/)

### Enterprise Auth & Identity
- Visa Trusted Agent Protocol — [Visa Corporate](https://corporate.review.visa.com/en/sites/visa-perspectives/newsroom/visa-unveils-trusted-agent-protocol-for-ai-commerce.html)
- Microsoft Entra Agent ID — [Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/agent-id/)
- World ID — [world.org](https://world.org/world-id)
- Incode Agentic Identity — [Incode](https://incode.com/press/incode-launches-agentic-identity-to-verify-and-secure-ai-agents-2/)

### Projects & Protocols
- Virtuals Protocol — [BingX](https://bingx.io/en/learn/article/what-is-virtuals-protocol-virtual-ai-agent-how-to-buy)
- Kite — [PANews](https://new.qq.com/rain/a/20250905A0405P00)
- EAS (Ethereum Attestation Service) — [attest.org](https://attest.org/)
- zkMe Agent Trust Gateway — [zkMe Docs](https://docs.zk.me/hub/how-built/agent-trust-gateway/supported-protocols)
- agentgateway — [agentgateway.dev](https://agentgateway.dev/)
- Metaplex Agent Registry — [Metaplex](https://www.metaplex.com/docs/agents/agentic-commerce)
- OpenClaw — [CSDN](https://blog.csdn.net/weixin2376192/details/160430530)

---

*Agent Passport V0 Whitepaper — July 2026*  
*Built on the ERC-8004 Trust Stack. Deployed on Base.*  
*The passport that proves who the agent is — and where it can go.*

## Deployed Contracts (Base Mainnet, Chain ID: 8453)

| Contract | Address | Code Size |
|----------|---------|-----------|
| AgentRegistry | `0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9` | 13,956 bytes |
| AgentPassport | `0x5eBD4fCE45754c34557a237dd59cecec7A410c87` | 11,065 bytes |
| CompliancePassport | `0x1A086e034C7020CFE12d1ff8082Fc6aeD5787680` | 15,627 bytes |
| AccessGateway | `0xC46C3538Ea1Ea3dc41b762A2b298DD3C4cc65594` | 12,770 bytes |

**OpenBD Campaign Contract**: `0x9Deb1842d10f536c91Ef69b1f146d4B84ACe966B` (200 BD letters sent)

## SDK Installation

```bash
pip install agent-passport-agl
```

PyPI: https://pypi.org/project/agent-passport-agl/
