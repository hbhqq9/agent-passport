"""
Contract addresses and minimal ABIs for Agent Passport V0 on Base Mainnet.
"""

# ── Deployed Contract Addresses (Base Mainnet) ──────────────────────────────
ADDRESSES = {
    "AgentRegistry": "0xbfd8Be6cBDa1Fb7A262E2A49c321E083a73638C9",
    "AgentPassport": "0x612Fdf1DFCABf73131DD1D517C5f365cC3FD4b96",
    "AccessGateway": "0x3dD4c216bc82145CDb1AF30b94d84383aa9292f9",
    "CompliancePassport": "0x799B35c31DeF0fB679F46026f81743D397A27959",
}

# ── Minimal ABIs ────────────────────────────────────────────────────────────
# Only the functions the SDK actually calls.

AGENT_REGISTRY_ABI = [
    {
        "inputs": [
            {"name": "name", "type": "string"},
            {"name": "operator", "type": "address"},
            {"name": "metadataURI", "type": "string"},
        ],
        "name": "registerAgent",
        "outputs": [{"name": "agentId", "type": "bytes32"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "bytes32"}],
        "name": "getAgent",
        "outputs": [
            {"name": "name", "type": "string"},
            {"name": "operator", "type": "address"},
            {"name": "active", "type": "bool"},
            {"name": "metadataURI", "type": "string"},
            {"name": "registeredAt", "type": "uint256"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "bytes32"}],
        "name": "isRegistered",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "operator", "type": "address"}],
        "name": "getAgentCount",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
]

AGENT_PASSPORT_ABI = [
    {
        "inputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "scope", "type": "string"},
            {"name": "evidenceURI", "type": "string"},
        ],
        "name": "issueAttestation",
        "outputs": [{"name": "attestationId", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "attestationId", "type": "uint256"}],
        "name": "getAttestation",
        "outputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "scope", "type": "string"},
            {"name": "evidenceURI", "type": "string"},
            {"name": "issuer", "type": "address"},
            {"name": "issuedAt", "type": "uint256"},
            {"name": "revoked", "type": "bool"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "scope", "type": "string"},
        ],
        "name": "hasAttestation",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "bytes32"}],
        "name": "getAttestationsByAgent",
        "outputs": [{"name": "", "type": "uint256[]"}],
        "stateMutability": "view",
        "type": "function",
    },
]

ACCESS_GATEWAY_ABI = [
    {
        "inputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "resource", "type": "string"},
        ],
        "name": "checkAccess",
        "outputs": [
            {"name": "allowed", "type": "bool"},
            {"name": "reason", "type": "string"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "requiredScope", "type": "string"},
        ],
        "name": "verifyDelegation",
        "outputs": [
            {"name": "valid", "type": "bool"},
            {"name": "delegator", "type": "address"},
            {"name": "expiresAt", "type": "uint256"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
]

COMPLIANCE_PASSPORT_ABI = [
    {
        "inputs": [{"name": "agentId", "type": "bytes32"}],
        "name": "getComplianceStatus",
        "outputs": [
            {"name": "art50Compliant", "type": "bool"},
            {"name": "riskScore", "type": "uint8"},
            {"name": "disclosureLevel", "type": "string"},
            {"name": "lastAudit", "type": "uint256"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "agentId", "type": "bytes32"},
            {"name": "interactionType", "type": "string"},
        ],
        "name": "generateDisclosure",
        "outputs": [
            {"name": "headerValue", "type": "string"},
            {"name": "metadata", "type": "string"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "bytes32"}],
        "name": "isCompliant",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function",
    },
]
