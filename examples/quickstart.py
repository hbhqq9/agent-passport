"""
Quick start example for Agent Passport SDK.

Usage:
    pip install agent-passport
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
# print(f"Registered agent: {agent_id.hex()}")

# 3. Use the guard decorator to protect your agent handler
@passport_guard(required_scope="data_access")
def handle_user_request(agent_id: str, query: str):
    """This function will only execute if the agent has valid compliance proof."""
    return f"Processing: {query}"

# 4. Check Art.50 compliance
# status = client.get_compliance_status(agent_id)
# print(f"Art.50 compliant: {status.art50_compliant}")

# 5. Generate Art.50 disclosure header
# from agent_passport import Art50ComplianceChecker
# checker = Art50ComplianceChecker(client)
# header = checker.generate_disclosure_header(agent_id, interaction_type="chat")
# print(header)

print("Agent Passport SDK initialized successfully!")
print("Visit https://github.com/agl-governance/agent-passport for docs.")
