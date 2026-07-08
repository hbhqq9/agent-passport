# Agent Passport V0 — On-Chain Agent Identity & Compliance Protocol

> **Deployed on Base Mainnet** | Total deployment cost: $0.11 | 4 contracts, 2,289 lines of Solidity

## Overview

Agent Passport is an on-chain protocol that bridges AI agent identities (ERC-8004) to Web2 access. It enables autonomous agents to prove their identity, compliance status, and delegation chain when interacting with Web2 services — without requiring platforms to pre-integrate.

**Core Insight**: Web2 platforms don't need to "accept agent identity" — they need to verify that *a verified human authorized this agent to do this*. Agent Passport provides this proof.

## Contracts (Base Mainnet)

| Contract | Address | Purpose |
|----------|---------|---------|
| **AgentRegistry** | `0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9` | On-chain agent identity registration (NFT-based) |
| **AgentPassport** | `0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96` | Attestation engine — who vouches for whom |
| **AccessGateway** | `0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9` | Proof-of-Agent verification for Web2 access |
| **CompliancePassport** | `0x799B35c31DeF0fB679F46026f81743D397A27959` | ERC-8226 mandate tracking + Art.50 compliance |

## Architecture

```
Layer 1: Foundation     → AgentRegistry (Identity Anchor NFT)
Layer 2: Attributes     → AgentPassport (Attestations) + CompliancePassport (Mandates)
Layer 3: Access         → AccessGateway (Proof-of-Agent + Delegation Chain)
```

## Key Features

- **$0.000752/event** average cost on Base L2
- **Delegation Chain Proof**: Proves human→agent authorization (not just agent identity)
- **Art.50 Compliance**: Auto-generates EU AI Act transparency disclosures
- **ERC-8126 Compatible**: Consumes on-chain risk scoring
- **Web2 Bridge**: Generates verification tokens that work with existing OAuth/API auth

## Documentation

- [Whitepaper V0 (English)](AGENT_PASSPORT_WHITEPAPER_V0.md)
- [Whitepaper V0 (中文)](AGENT_PASSPORT_WHITEPAPER_V0_CN.md)
- [Architecture](ARCHITECTURE.md)
- [Deployment Record](DEPLOYMENT_RECORD_V0.md)
- [Competitive Research (25 projects)](COMPETITIVE_RESEARCH.md)
- [Strategic Intelligence Update](STRATEGIC_INTEL_UPDATE_20260708.md)

## License

MIT
