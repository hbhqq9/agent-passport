# Agent Passport

**AI Agent Compliance Proof System for EU AI Act Art.50**

Agent Passport provides on-chain compliance infrastructure enabling AI agents to prove regulatory compliance (EU AI Act Article 50) through verifiable, tamper-proof credentials on Base Mainnet.

## Quick Start

```bash
pip install agent-passport
```

```python
from agent_passport import AgentPassportClient, passport_guard

client = AgentPassportClient(rpc_url="https://mainnet.base.org")

@passport_guard(required_scope="data_access")
def handle_request(agent_id: str, query: str):
    return f"Processing: {query}"
```

## Project Structure

- `agent_passport/` - Python SDK package
- `agent-passport/` - Whitepapers, architecture docs, analysis
- `contracts/` - ERC-8226 Adapter smart contracts
- `docs/` - Blog posts and announcements
- `art50-self-assessment.html` - Art.50 compliance self-assessment tool

## Deployed Contracts (Base Mainnet)

| Contract | Address |
|----------|---------|
| AgentRegistry | `0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9` |
| AgentPassport | `0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96` |
| AccessGateway | `0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9` |
| CompliancePassport | `0x799B35c31DeF0fB679F46026f81743D397A27959` |
| ERC8226Adapter | `0xE87b5F4D18E431cBFb281A5Af376DAE2995bbC0d` |
| OpenBD | `0x9Deb1842d10f536c91Ef69b1f146d4B84ACe966B` |

## Documentation

- [V0 Whitepaper](agent-passport/AGENT_PASSPORT_WHITEPAPER_V0.md)
- [中文白皮书](agent-passport/AGENT_PASSPORT_WHITEPAPER_V0_CN.md)
- [Architecture](agent-passport/ARCHITECTURE.md)
- [Competitive Research](agent-passport/COMPETITIVE_RESEARCH.md)
- [V0.1 Pivot Strategy](agent-passport/AGENT_PASSPORT_DUAN_YONGPING_ANALYSIS.md)

## Links

- GitHub: https://github.com/hbhqq9/agent-passport
- Codeberg: https://codeberg.org/agl-governance/erc8226-adapter

*Powered by Agent Passport Governance*
