"""
Contract addresses and minimal ABIs for Agent Passport V0 on Base Mainnet.
"""

# ── Deployed Contract Addresses (Base Mainnet) ──────────────────────────────
ADDRESSES = {
    "AgentRegistry": "0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9",
    "AgentPassport": "0x5eBD4fCE45754c34557a237dd59cecec7A410c87",
    "AccessGateway": "0xC46C3538Ea1Ea3dc41b762A2b298DD3C4cc65594",
    "CompliancePassport": "0x1A086e034C7020CFE12d1ff8082Fc6aeD5787680",
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
