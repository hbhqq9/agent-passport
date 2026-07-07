# ERC-8226 Reference Implementation

Production-grade implementation of [ERC-8226: Regulated Agent Mandate](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208) on Base mainnet.

## Overview

This repository provides a **dual-layer architecture** for ERC-8226 compliance:

1. **ERC8226Adapter** - Standard IComplianceProvider interface (ERC-8226 compliant)
2. **ComplianceEngine** - Enhanced implementation with audit chain, role separation, and upgradeability

## Problem Solved

The official ERC-8226 specification (PR #1844, merged 2026-06-29) defines `IComplianceProvider` with:
- `grantPrincipal(address, bytes32 identityRef, uint48 expiresAt)`
- `revokePrincipal(address, ReasonCode)`
- `checkPrincipal(address, bytes32 identityRef)`

However, production compliance systems often require additional features:
- HMAC audit chains for tamper-proof records
- Role-based access control (separation of duties)
- UUPS upgradeability for protocol evolution
- Emergency pause mechanisms

This implementation bridges the gap by providing an **adapter pattern** that exposes the standard ERC-8226 interface while delegating to an enhanced compliance engine.

## Contract Addresses (Base Mainnet)

| Contract | Address | Description |
|----------|---------|-------------|
| ERC8226Adapter | `0xE87b5F4D18E431cBFb281A5Af376DAE2995bbC0d` | Standard IComplianceProvider interface |
| ComplianceEngine (Proxy) | `0xa493ae1230adf41a0d55bd405a9caa3e90e7e0d2` | Enhanced engine with audit chain |
| TransparencyLogger | `0xcC567FCd0ea1C92039483bCc01b7aC9bc45E19C7` | EU AI Act Art.50 transparency proofs |

## Architecture

```
┌─────────────────────────────────────────┐
│   ERC-8226 AgentMandate Contract        │
│   (calls IComplianceProvider)           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   ERC8226Adapter                        │
│   - grantPrincipal / revokePrincipal    │
│   - checkPrincipal                      │
│   - ERC165 interface detection          │
└────────────────┬────────────────────────┘
                 │ delegates to
                 ▼
┌─────────────────────────────────────────┐
│   ComplianceEngine (Enhanced)           │
│   - HMAC audit chain                    │
│   - Role-based access (ORACLE/OFFICER)  │
│   - UUPS upgradeable                    │
│   - Pausable emergency response         │
└─────────────────────────────────────────┘
```

## Key Features

### ERC8226Adapter
- ✅ Full ERC-8226 IComplianceProvider compliance
- ✅ ERC165 interface detection
- ✅ Delegates to enhanced ComplianceEngine
- ✅ Backward compatible

### ComplianceEngine
- ✅ HMAC audit chain (tamper-proof records)
- ✅ Role separation: ORACLE / COMPLIANCE_OFFICER / EMERGENCY
- ✅ UUPS proxy pattern (upgradeable)
- ✅ Pausable (emergency response)
- ✅ ReentrancyGuard

## Use Cases

### For AI Agent Platforms
Integrate ERC-8226 compliance delegation for regulated assets:
- Tokenized securities
- Real-world assets (RWA)
- Regulated DeFi protocols

### For Supervision Layers (e.g., Overmind)
Pair the adapter with AI Agent monitoring:
- **Overmind**: Agent behavior supervision + risk detection
- **AGL**: Compliance delegation + audit trails
- **Together**: Complete compliance stack for regulated industries

## Integration Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IComplianceProvider is IERC165 {
    enum ReasonCode {
        COMPLIANT, KYC_EXPIRED, AML_FLAG, NOT_ACCREDITED,
        NOT_QUALIFIED, JURISDICTION_BLOCKED, IDENTITY_NOT_FOUND,
        ATTESTATION_REVOKED, OTHER
    }
    
    function grantPrincipal(address, bytes32, uint48) external;
    function revokePrincipal(address, ReasonCode) external;
    function checkPrincipal(address, bytes32) external view returns (bool, ReasonCode, uint48);
}

contract MyRegulatedAgent {
    IComplianceProvider public complianceProvider;
    
    constructor(address _provider) {
        complianceProvider = IComplianceProvider(_provider);
    }
    
    function executeRegulatedTransaction(
        bytes32 identityRef
    ) external {
        (bool eligible, , ) = complianceProvider.checkPrincipal(
            msg.sender,
            identityRef
        );
        require(eligible, "Not compliant");
        
        // Execute regulated transaction...
    }
}
```

## Deployment

Contracts deployed on Base mainnet:
- ERC8226Adapter: [0xE87b5F4D18E431cBFb281A5Af376DAE2995bbC0d](https://basescan.org/address/0xE87b5F4D18E431cBFb281A5Af376DAE2995bbC0d)
- ComplianceEngine: [0xa493ae1230adf41a0d55bd405a9caa3e90e7e0d2](https://basescan.org/address/0xa493ae1230adf41a0d55bd405a9caa3e90e7e0d2)

## References

- [ERC-8226 Specification](https://github.com/ethereum/ERCs/pull/1844)
- [ERC-8226 Discussion](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208)
- [EU AI Act Art.50](https://artificialintelligenceact.eu/)
- [MiCA Regulation](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1114)

## Collaboration

Open for collaboration with:
- AI Agent supervision layers (Overmind, etc.)
- Regulated DeFi protocols
- RWA tokenization platforms
- Compliance service providers

Contact: [GitHub Issues](https://github.com/yourusername/erc8226-reference-implementation/issues)

## License

MIT
