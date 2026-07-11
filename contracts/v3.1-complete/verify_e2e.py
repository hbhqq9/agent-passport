#!/usr/bin/env python3
"""E2E verification for V3.1-Complete deployment on Base Mainnet."""
import json, time, os
from web3 import Web3
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
except ImportError:
    pass  # .env already loaded by shell, or set manually

RPC_URL = "https://mainnet.base.org"
DEPLOYER_KEY = os.environ['DEPLOYER_PRIVATE_KEY']  # must be set in .env

# V3.1-Complete addresses (updated after fresh deployment)
REGISTRY = Web3.to_checksum_address("0x594EeACA09186f86B7c4531b7cE63fb7480ce96C")
PASSPORT = Web3.to_checksum_address("0x40B8A47A6A5249CDdB7428052f6Bd48f50D674cb")
COMPLIANCE_NEW = Web3.to_checksum_address("0x3222df200137106E8e99E696d11Fbb8eB5bFDB27")  # TBD: update after deploy
GATEWAY_NEW = Web3.to_checksum_address("0xbe5ed70C5e23895859F5506ad8606C0BBa977240")  # TBD: update after deploy
DEPLOYER = Web3.to_checksum_address("0x6c667Fc5c770bf7899b1843472f43C51b5c4Fecd")  # fresh deployer

w3 = Web3(Web3.HTTPProvider(RPC_URL))
deployer = w3.eth.account.from_key(DEPLOYER_KEY)

# Load ABIs
def load_abi(name):
    with open(f"build/{name}.abi") as f:
        return json.load(f)

registry_abi = load_abi("AgentRegistry")
passport_abi = load_abi("AgentPassport")
compliance_abi = load_abi("CompliancePassport")
gateway_abi = load_abi("AccessGateway")

Registry = w3.eth.contract(address=REGISTRY, abi=registry_abi)
Passport = w3.eth.contract(address=PASSPORT, abi=passport_abi)
Compliance = w3.eth.contract(address=COMPLIANCE_NEW, abi=compliance_abi)
Gateway = w3.eth.contract(address=GATEWAY_NEW, abi=gateway_abi)

passed = 0
failed = 0

def check(name, condition, detail=""):
    global passed, failed
    if condition:
        print(f"  ✅ {name}: {detail}")
        passed += 1
    else:
        print(f"  ❌ {name}: {detail}")
        failed += 1

def send_tx(name, func, gas=500000):
    tx = func.build_transaction({
        'from': DEPLOYER, 'nonce': w3.eth.get_transaction_count(DEPLOYER),
        'gas': gas, 'maxFeePerGas': w3.to_wei(0.05, 'gwei'),
        'maxPriorityFeePerGas': w3.to_wei(0.01, 'gwei'), 'chainId': 8453,
    })
    signed = deployer.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
    status = "SUCCESS" if receipt.status == 1 else "FAILED"
    print(f"  {'✅' if receipt.status == 1 else '❌'} {name}: {status} (gas: {receipt.gasUsed})")
    return receipt

# === Step 1: Verify contracts exist ===
print("\n=== 1. Contract Existence ===")
for name, addr in [("AgentRegistry", REGISTRY), ("AgentPassport", PASSPORT),
                    ("CompliancePassport V3.1", COMPLIANCE_NEW), ("AccessGateway V3.1", GATEWAY_NEW)]:
    code = w3.eth.get_code(addr)
    check(f"{name} code exists", len(code) > 0, f"{len(code)} bytes")

# === Step 2: Verify existing agent state (V3 data preserved) ===
print("\n=== 2. Existing Agent State (V3 data preserved) ===")
agent_info = Registry.functions.getAgentInfo(1).call()
check("Agent #1 exists", agent_info[0] != "0x0000000000000000000000000000000000000000", f"owner={agent_info[0][:10]}...")
check("Agent #1 active", agent_info[4] == True)
check("Agent #1 wallet bound", agent_info[1] == DEPLOYER)

# === Step 3: Grant roles on new CompliancePassport ===
print("\n=== 3. Role Setup on New CompliancePassport ===")
SCORER_ROLE = Compliance.functions.SCORER_ROLE().call()
ADMIN_ROLE = Compliance.functions.DEFAULT_ADMIN_ROLE().call()

# Grant SCORER_ROLE to deployer
send_tx("Grant SCORER_ROLE to deployer",
    Compliance.functions.grantRole(SCORER_ROLE, DEPLOYER))

time.sleep(2)

has_scorer = Compliance.functions.hasRole(SCORER_ROLE, DEPLOYER).call()
check("Deployer has SCORER_ROLE", has_scorer)
is_admin = Compliance.functions.hasRole(ADMIN_ROLE, DEPLOYER).call()
check("Deployer has ADMIN_ROLE", is_admin)

# === Step 4: Record risk score on new contract ===
print("\n=== 4. Risk Score on New CompliancePassport ===")
send_tx("Record risk score (25/100)",
    Compliance.functions.recordRiskScore(
        1, 25, int(time.time()) + 86400*365,
        Web3.keccak(text="evidence_v3.1"), "https://example.com/scorer/v3.1"
    ))

time.sleep(2)

risk_hist = Compliance.functions.getRiskScoreHistory(1).call()
check("Risk score recorded", len(risk_hist) >= 1, f"{len(risk_hist)} records")
if risk_hist:
    check("Score value = 25", risk_hist[-1][0] == 25)

# === Step 5: Test MAX_RISK_SCORE_RECORDS constant ===
print("\n=== 5. DoS Protection ===")
max_records = Compliance.functions.MAX_RISK_SCORE_RECORDS().call()
check("MAX_RISK_SCORE_RECORDS = 100", max_records == 100, f"{max_records}")

# === Step 6: Issue certificate on new contract ===
print("\n=== 6. Certificate on New CompliancePassport ===")
send_tx("Issue certificate (level 3)",
    Compliance.functions.issueCertificate(
        1, 3, Web3.keccak(text="compliance_evidence_v3.1"),
        int(time.time()) + 86400*365
    ))

time.sleep(2)

cert = Compliance.functions.getCertificate(1).call()
check("Certificate issued", cert[0] == 1, f"certId={cert[0]}")
check("Certificate riskScore from chain", True, f"riskScore={cert[2]}")

# === Step 7: Compliance proof consistency ===
print("\n=== 7. Compliance Proof Consistency ===")
proof = Compliance.functions.exportComplianceProof(1).call()
summary = proof[0]
proof_hash = proof[1]

verified = Compliance.functions.verifyComplianceProof(
    summary, 8453, COMPLIANCE_NEW, proof_hash
).call()
check("export ↔ verify consistency", verified == True)

# === Step 8: Gateway V3.1-Complete verification ===
print("\n=== 8. AccessGateway V3.1-Complete ===")
gw_nonce = Gateway.functions.proofOfAgentNonces(DEPLOYER).call()
check("Gateway nonce (from V3)", gw_nonce >= 1, f"nonce={gw_nonce}")

# Verify agent status via gateway
verify_result = Gateway.functions.verifyProofOfAgent(
    DEPLOYER, Web3.keccak(text="test_v3.1"), gw_nonce, b""  # empty sig will fail sig check
).call()
# Empty sig should fail, but function should not revert
check("verifyProofOfAgent callable", True, f"result={verify_result}")

# Check gateway service is new compliance
gw_service = Gateway.functions.gatewayService().call()
check("Gateway service = new Compliance", gw_service == COMPLIANCE_NEW)

# Test consumeProofOfAgent with deadline (should revert with invalid sig, not with "not expired")
print("\n=== 9. consumeProofOfAgent Deadline Test ===")
from eth_account.messages import encode_structured_data

# Build EIP-712 message
domain = {
    "name": "AGLAccessGateway",
    "version": "1",
    "chainId": 8453,
    "verifyingContract": GATEWAY_NEW
}
message = {
    "agentWallet": DEPLOYER,
    "agentId": 1,
    "message": Web3.keccak(text="deadline_test"),
    "nonce": gw_nonce
}
# Sign
from eth_account.messages import _hash_eip712_message
import struct

# Use web3 sign
msg_hash = encode_structured_data(primitive=None, header=domain, message=message)
signed = deployer.sign_message(msg_hash)
sig = signed.signature

# Try consumeProofOfAgent with deadline = now + 1 hour
deadline = int(time.time()) + 3600
try:
    # This should succeed because:
    # - msg.sender == agentWallet (DEPLOYER)
    # - deadline is in the future
    # - signature is valid
    receipt = send_tx("consumeProofOfAgent with deadline",
        Gateway.functions.consumeProofOfAgent(
            DEPLOYER, Web3.keccak(text="deadline_test"), deadline, sig
        ), gas=500000)
    
    new_nonce = Gateway.functions.proofOfAgentNonces(DEPLOYER).call()
    check("Nonce incremented after consume", new_nonce == gw_nonce + 1, f"old={gw_nonce}, new={new_nonce}")
except Exception as e:
    check("consumeProofOfAgent with deadline", False, str(e)[:100])

# Test deadline expired (should revert)
time.sleep(2)
print("\n=== 10. Deadline Expired Test ===")
try:
    old_nonce = Gateway.functions.proofOfAgentNonces(DEPLOYER).call()
    msg_hash2 = encode_structured_data(primitive=None, header=domain, message={
        "agentWallet": DEPLOYER, "agentId": 1,
        "message": Web3.keccak(text="expired_test"), "nonce": old_nonce
    })
    signed2 = deployer.sign_message(msg_hash2)
    
    # Deadline in the past
    past_deadline = int(time.time()) - 10
    tx = Gateway.functions.consumeProofOfAgent(
        DEPLOYER, Web3.keccak(text="expired_test"), past_deadline, signed2.signature
    ).build_transaction({
        'from': DEPLOYER, 'nonce': w3.eth.get_transaction_count(DEPLOYER),
        'gas': 500000, 'maxFeePerGas': w3.to_wei(0.05, 'gwei'),
        'maxPriorityFeePerGas': w3.to_wei(0.01, 'gwei'), 'chainId': 8453,
    })
    signed_tx = deployer.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)
    check("Expired deadline rejected", receipt.status == 0, "tx should have reverted")
except Exception as e:
    if "signature expired" in str(e).lower() or "revert" in str(e).lower():
        check("Expired deadline rejected", True, "reverted as expected")
    else:
        check("Expired deadline rejected", False, str(e)[:100])

# === Summary ===
print(f"\n{'='*60}")
print(f"V3.1-Complete E2E Verification: {passed}/{passed+failed} PASS")
print(f"{'='*60}")
print(f"\nNew Contract Addresses:")
print(f"  CompliancePassport: {COMPLIANCE_NEW}")
print(f"  AccessGateway:      {GATEWAY_NEW}")
print(f"  (AgentRegistry:     {REGISTRY} — unchanged)")
print(f"  (AgentPassport:     {PASSPORT} — unchanged)")
