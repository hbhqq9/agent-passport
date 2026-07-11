"""
Contract addresses and minimal ABIs for Agent Passport V3 on Base Mainnet.

V3 Changes (Security Fixes):
  - verifyProofOfAgent: added `nonce` parameter, now uses EIP-712 signatures
  - New consumeProofOfAgent function for on-chain nonce consumption
  - issueAttestationBySignature: added signer/nonce params
  - recordRiskScoreBySignature: added signer/nonce params
  - issueCertificateBySignature: removed riskScore param, added signer/nonce
  - verifyComplianceProof: pure -> view (now returns correct results)

NOTE: Contract addresses are placeholders until V3 is deployed.
      Update ADDRESSES after mainnet deployment.
"""

# ── Deployed Contract Addresses (Base Mainnet) ──────────────────────────────
# TODO: Update these addresses after V3 deployment
ADDRESSES = {
    "AgentRegistry": "0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9",  # Unchanged (no vuln)
    "AgentPassport": "",        # TODO: Update after V3 deployment
    "AccessGateway": "",        # TODO: Update after V3 deployment
    "CompliancePassport": "",   # TODO: Update after V3 deployment
}

# V2 addresses (for migration reference)
V2_ADDRESSES = {
    "AgentRegistry": "0xbeeFd54855e133055c6C5be8fD6549c3Fd92e0D9",
    "AgentPassport": "0x5eBD4fCE45754c34557a237dd59cecec7A410c87",
    "AccessGateway": "0xC46C3538Ea1Ea3dc41b762A2b298DD3C4cc65594",
    "CompliancePassport": "0x1A086e034C7020CFE12d1ff8082Fc6aeD5787680",
}

# ── Minimal ABIs (V3) ───────────────────────────────────────────────────────
# Only the functions the SDK actually calls.

AGENT_REGISTRY_ABI = [
    {
        "inputs": [
            {"name": "name", "type": "string"},
            {"name": "operator", "type": "address"},
            {"name": "metadataURI", "type": "string"},
        ],
        "name": "registerAgent",
        "outputs": [{"name": "agentId", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "uint256"}],
        "name": "getAgentInfo",
        "outputs": [
            {
                "name": "",
                "type": "tuple",
                "components": [
                    {"name": "owner", "type": "address"},
                    {"name": "agentWallet", "type": "address"},
                    {"name": "agentURI", "type": "string"},
                    {"name": "registeredAt", "type": "uint256"},
                    {"name": "active", "type": "bool"},
                ],
            }
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "agentId", "type": "uint256"},
            {"name": "wallet", "type": "address"},
            {"name": "deadline", "type": "uint256"},
            {"name": "signature", "type": "bytes"},
        ],
        "name": "bindWallet",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
]

AGENT_PASSPORT_ABI = [
    {
        "inputs": [
            {"name": "agentId", "type": "uint256"},
            {"name": "attributeType", "type": "uint8"},
            {"name": "attributeValue", "type": "string"},
            {"name": "schemaURI", "type": "string"},
            {"name": "validUntil", "type": "uint256"},
        ],
        "name": "issueAttestation",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "attestationId", "type": "uint256"}],
        "name": "getAttestation",
        "outputs": [
            {
                "name": "",
                "type": "tuple",
                "components": [
                    {"name": "attestationId", "type": "uint256"},
                    {"name": "agentId", "type": "uint256"},
                    {"name": "verifier", "type": "address"},
                    {"name": "attributeType", "type": "uint8"},
                    {"name": "attributeHash", "type": "bytes32"},
                    {"name": "schemaURI", "type": "string"},
                    {"name": "validUntil", "type": "uint256"},
                    {"name": "issuedAt", "type": "uint256"},
                    {"name": "revoked", "type": "bool"},
                ],
            }
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "uint256"}],
        "name": "getAgentAttestationIds",
        "outputs": [{"name": "", "type": "uint256[]"}],
        "stateMutability": "view",
        "type": "function",
    },
]

ACCESS_GATEWAY_ABI = [
    # [V3 CHANGED] verifyProofOfAgent now takes nonce parameter
    {
        "inputs": [
            {"name": "agentWallet", "type": "address"},
            {"name": "message", "type": "bytes32"},
            {"name": "nonce", "type": "uint256"},      # V3: new parameter
            {"name": "signature", "type": "bytes"},
        ],
        "name": "verifyProofOfAgent",
        "outputs": [
            {"name": "isValid", "type": "bool"},
            {"name": "agentId", "type": "uint256"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    # [V3 NEW] consumeProofOfAgent — on-chain nonce consumption
    {
        "inputs": [
            {"name": "agentWallet", "type": "address"},
            {"name": "message", "type": "bytes32"},
            {"name": "signature", "type": "bytes"},
        ],
        "name": "consumeProofOfAgent",
        "outputs": [
            {"name": "isValid", "type": "bool"},
            {"name": "agentId", "type": "uint256"},
        ],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    # [V3 NEW] proofOfAgentNonces — query nonce
    {
        "inputs": [{"name": "wallet", "type": "address"}],
        "name": "proofOfAgentNonces",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
]

COMPLIANCE_PASSPORT_ABI = [
    {
        "inputs": [
            {"name": "agentId", "type": "uint256"},
            {"name": "score", "type": "uint8"},
            {"name": "validUntil", "type": "uint256"},
            {"name": "evidenceHash", "type": "bytes32"},
            {"name": "scorerURI", "type": "string"},
        ],
        "name": "recordRiskScore",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [
            {"name": "agentId", "type": "uint256"},
            {"name": "complianceLevel", "type": "uint8"},
            {"name": "evidenceHash", "type": "bytes32"},
            {"name": "validUntil", "type": "uint256"},
        ],
        "name": "issueCertificate",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"name": "certId", "type": "uint256"}],
        "name": "getCertificate",
        "outputs": [
            {"name": "certId", "type": "uint256"},
            {"name": "agentId", "type": "uint256"},
            {"name": "riskScore", "type": "uint8"},
            {"name": "complianceLevel", "type": "uint8"},
            {"name": "evidenceHash", "type": "bytes32"},
            {"name": "validUntil", "type": "uint256"},
            {"name": "issuedAt", "type": "uint256"},
            {"name": "issuer", "type": "address"},
            {"name": "revoked", "type": "bool"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"name": "agentId", "type": "uint256"}],
        "name": "getAgentCertificateIds",
        "outputs": [{"name": "", "type": "uint256[]"}],
        "stateMutability": "view",
        "type": "function",
    },
]
