# Agent Passport SDK

**5-minute EU AI Act Art.50 compliance for AI Agents on Base.**

Agent Passport is a compliance proof system that helps platforms ensure every AI agent they interact with carries verifiable proof of regulatory compliance — starting with Art.50 disclosure obligations.

## Install

```bash
pip install agent-passport
```

## Quick Start

```python
from agent_passport import AgentPassportClient, passport_guard, set_default_client

# Initialize (read-only)
client = AgentPassportClient(rpc_url="https://mainnet.base.org")
set_default_client(client)

# Protect your agent handler with one decorator
@passport_guard(required_scope="art50")
def handle(agent_id, query):
    return f"Compliant response to: {query}"
```

## Register an Agent

```python
client = AgentPassportClient(
    rpc_url="https://mainnet.base.org",
    private_key="0xYOUR_KEY"
)
agent_id = client.register_agent(
    name="MyAgent",
    operator="0xYourAddress",
    metadata_uri="https://example.com/metadata.json"
)
```

## Art.50 Disclosure

```python
from agent_passport import Art50ComplianceChecker

checker = Art50ComplianceChecker(client)
header = checker.generate_disclosure_header(agent_id, interaction_type="chat")
# => X-AI-Disclosure: agent=0x...; compliant=true; scope=art50; type=chat
```

## Deployed Contracts (Base Mainnet)

| Contract          | Address                                      |
|-------------------|----------------------------------------------|
| AgentRegistry     | `0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9` |
| AgentPassport     | `0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96` |
| AccessGateway     | `0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9` |
| CompliancePassport| `0x799B35c31DeF0fB679F46026f81743D397A27959` |

## Features

- **`@passport_guard`** — Decorator to enforce compliance checks on any handler
- **`Art50ComplianceChecker`** — Check compliance status and generate disclosure headers
- **`DelegationManager`** — Create and verify agent delegation chains
- **Read-only mode** — No private key needed for verification and queries

## Links

- [White Paper](https://github.com/agl-governance/erc8226-adapter/blob/master/docs/agent-passport-whitepaper.md)
- [Smart Contracts](https://github.com/agl-governance/erc8226-adapter/tree/master/contracts)
- [Codeberg Mirror](https://codeberg.org/agl-governance/erc8226-adapter)

## License

MIT
