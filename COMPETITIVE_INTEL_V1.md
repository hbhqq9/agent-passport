# Agent Passport - Competitive Intelligence V1
**Date**: 2026-07-08
**Source**: Deep web research during AGL BD operations

## Executive Summary

The AI Agent Identity & Access market is rapidly forming with multiple players approaching from different angles. No single player has achieved full-stack coverage (L1 Identity → L2 Verification → L3 Compliance → Access Gateway). Agent Passport's unique position: the ONLY project building from compliance (L3) upward to identity (L1), with real production deployment on Base mainnet.

## Competitive Landscape Matrix

### Tier 1: Direct Competitors / High Synergy Partners

| Project | Approach | Stage | Chain | Our Relationship |
|---------|----------|-------|-------|-----------------|
| **ERC-8004** | Agent Identity Standard (L1) | Live (Mainnet+Base+Polygon) | Multi | **Standards Foundation** - We build ON this |
| **ERC-8126 (Cybercentry)** | Agent Verification/Risk Score (L2) | Finalized | Ethereum | **Data Source** - Their risk scores feed our compliance |
| **Billions Network ($BILL)** | ZK Identity Verification | TGE done, 3000% surge | Polygon | **Partner** - L1-L2 identity input |
| **AgentNexus** | Ed25519 DID Agent Social | Live | Off-chain | **Partner** - Needs our on-chain compliance |
| **UAIIP (deepidv)** | Human→Agent Trust Chain (ZK) | Active | Cross-chain | **Competitor/Partner** - Similar ZK approach |

### Tier 2: Enterprise Players (Complementary)

| Project | Approach | Stage | Our Relationship |
|---------|----------|-------|-----------------|
| **Microsoft Agent OS** | Agent governance kernel (Execution Rings) | PyPI beta | **Integration target** - We're their EU compliance adapter |
| **Ares Networks** | Hyperledger agent governance | Microsoft Marketplace | **Competitor** - Enterprise, not crypto-native |
| **Visa TAP** | Enterprise agent credentialing | Live | **Integration target** - We provide on-chain compliance layer |
| **Coinbase AgentKit** | Agent wallet + payments | Live | **Partner** - Agent Commerce (ERC-8183) integration |
| **MetaMask Agent Wallet** | Self-custodial agent wallet | Early Access | **Partner** - ERC-8196 auth wallet integration |

### Tier 3: Infrastructure / Adjacent

| Project | Approach | Stage |
|---------|----------|-------|
| **Agent Cards (ERC-721)** | NFT-based agent identity | Emerging pattern |
| **Google AP2** | Agent Payment Mandates (A2A+MCP) | Live, 60+ partners |
| **Mastercard AP4M** | Agent payment protocol | Live, 31 partners |
| **Coinbase x402** | Machine-to-machine payments | 75M txs in 30 days |
| **Olas Network** | Agent-to-agent transactions | 800+ daily agents |
| **Cobo Agent Wallet** | MPC wallet with Pack Authority | Live |
| **Guardrails AI** | LLM safety layer | Open source |
| **ETHOS** | AI governance framework | Research |
| **OpenSea ERC-8257** | Agent tool registry | Live |

## Standard Stack Ecosystem Map

```
Layer 4: Behavior Attestation    → ERC-8263 (Draft)
Layer 3: Compliance Execution    → ERC-8226 (Draft) ← AGL Art.50 ★
Layer 2: Verification            → ERC-8126 (Finalized) - Cybercentry+Virtuals
Layer 2: Auth Wallet             → ERC-8196 (Draft)
Layer 1: Identity & Reputation   → ERC-8004 (Live on 5+ chains)
Commerce: Agent Protocol         → ERC-8183 (Draft) - EF+Virtuals+OKX
```

## Key Market Insights

### 1. The Identity Gap is REAL
- Non-human identities outnumber human identities 40:1 to 100:1 in enterprise (2026)
- Reid Hoffman (LinkedIn co-founder) at Consensus Miami: "NFTs are the obvious answer for agent identity"
- No standard solution exists for agent-native authentication across platforms

### 2. Three Approaches to Agent Identity
- **Decentralized (ERC-8004)**: Open, permissionless, no central issuer
- **Enterprise (Visa TAP)**: Credential-focused, payments-aligned
- **Hybrid (UAIIP)**: Human verification + agent binding + ZK attestation

### 3. The Compliance Window is NOW
- EU AI Act: High-risk system requirements effective August 2026
- Every agent deployed in EU needs compliance documentation
- No existing player offers on-chain compliance execution (ERC-8226)

### 4. Agent Passport's Unique Position
```
Others: Identity → Maybe Compliance Later
Us:     Compliance (DEPLOYED) → Identity (Building) → Access Gateway (Designing)
```

**Key Differentiator**: We're the only ones with LIVE compliance contracts on Base mainnet.
Everyone else is building identity FROM SCRATCH. We already have the compliance layer; 
adding identity ON TOP is architecturally simpler than building identity and then adding compliance.

## Strategic Recommendations

### MVP Focus Areas
1. **Agent Registry** (ERC-8004 compatible) - Wallet-first identity
2. **Compliance Passport** - Combine ERC-8126 score + ERC-8226 mandate
3. **Access Gateway V0** - Wallet-signed auth tokens (OAuth-for-Agents)

### Partnership Priority
1. **Cybercentry ($CENTRY)** - Integrate their ERC-8126 verification data
2. **Billions Network ($BILL)** - ZK identity integration
3. **AgentNexus** - First consumer of Agent Passport (their agents need compliance)
4. **Microsoft Agent OS** - Enterprise compliance adapter positioning

### Token Model Considerations
- Don't create token in V0 - focus on protocol adoption first
- Consider $PASSPORT or integrate with existing tokens ($VIRTUAL, $CENTRY, $BILL)
- Revenue: API calls + compliance verification fees (not token-gated initially)

## Immediate Action Items
- [x] Competitive landscape mapped (this document)
- [ ] V0 smart contract design (in progress via sub-agent)
- [ ] Reach out to AgentNexus team (agentnexus.online)
- [ ] Reach out to Billions Network team (post-TGE)
- [ ] Explore Microsoft Agent OS integration path
- [ ] Draft Agent Passport whitepaper
