"""
Quick start example for Agent Passport SDK V2.

Usage:
    pip install agent-passport-agl
    python quickstart.py
"""
from agent_passport import AgentPassportClient, passport_guard, set_default_client

# 1. Initialize client (read-only mode, no private key needed)
client = AgentPassportClient(rpc_url="https://mainnet.base.org")
set_default_client(client)

# 2. Register an agent (requires private key)
# client_with_key = AgentPassportClient(
#     rpc_url="https://mainnet.base.org",
#     private_key="0xYOUR_PRIVATE_KEY"
# )
# agent_id = client_with_key.register_agent(
#     name="MyAgent",
#     operator="0xYourAddress",
#     metadata_uri="https://example.com/agent-metadata.json"
# )
# print(f"Registered agent with ID: {agent_id}")  # int (uint256), starts at 1

# 3. Get agent information
# agent_info = client.get_agent(agent_id)
# print(f"Owner: {agent_info.owner}")
# print(f"Agent Wallet: {agent_info.agent_wallet}")
# print(f"Agent URI: {agent_info.agent_uri}")
# print(f"Active: {agent_info.active}")

# 4. Use the guard decorator to protect your agent handler
@passport_guard(required_scope=1)  # attribute_type=1
def handle_user_request(agent_id: int, query: str):
    """This function will only execute if the agent has valid compliance proof."""
    return f"Processing: {query}"

# 5. Check compliance status (certificates)
# certificates = client.get_compliance_status(agent_id)
# for cert in certificates:
#     print(f"Cert {cert.cert_id}: level={cert.compliance_level}, risk={cert.risk_score}")

# 6. Generate Art.50 disclosure header
# from agent_passport import Art50ComplianceChecker
# checker = Art50ComplianceChecker(client)
# header = checker.generate_disclosure_header(agent_id, interaction_type="chat")
# print(header)

# 7. Verify agent proof via AccessGateway
# is_valid, verified_agent_id = client.verify_agent(
#     agent_wallet="0x...",
#     message=b"\\x00" * 32,
#     signature=b"...",
# )
# print(f"Valid: {is_valid}, Agent ID: {verified_agent_id}")

# 8. List attestations for an agent
# attestation_ids = client.get_agent_attestation_ids(agent_id)
# for att_id in attestation_ids:
#     att = client.get_attestation(att_id)
#     print(f"Attestation {att.attestation_id}: type={att.attribute_type}, revoked={att.revoked}")

print("Agent Passport SDK V2 initialized successfully!")
print("Visit https://github.com/hbhqq9/agent-passport for docs.")
