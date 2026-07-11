#!/usr/bin/env python3
"""Deploy V3.1-Complete contracts to Base Mainnet.
Only CompliancePassport and AccessGateway need redeployment (code changed).
AgentRegistry and AgentPassport remain the same.
"""
import json, time, sys
from web3 import Web3

# === Config ===
RPC_URL = "https://mainnet.base.org"
DEPLOYER_KEY = "0xREDACTED_KEY_COMPROMISED_2"
REGISTRY_ADDR = "0x594EeACA09186f86B7c4531b7cE63fb7480ce96C"  # V3 (unchanged)
PASSPORT_ADDR = "0x40B8A47A6A5249CDdB7428052f6Bd48f50D674cb"  # V3.1 (unchanged)
BUILD_DIR = "./build"

w3 = Web3(Web3.HTTPProvider(RPC_URL))
deployer = w3.eth.account.from_key(DEPLOYER_KEY)
print(f"Deployer: {deployer.address}")
bal = w3.eth.get_balance(deployer.address)
print(f"Balance: {w3.from_wei(bal, 'ether')} ETH")

if bal < w3.to_wei(0.003, 'ether'):
    print("ERROR: Insufficient balance!")
    sys.exit(1)

def deploy_contract(name, abi_path, bin_path, constructor_args=None):
    with open(abi_path) as f:
        abi = json.load(f)
    with open(bin_path) as f:
        bytecode = f.read().strip()
    
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    
    if constructor_args:
        tx = Contract.constructor(*constructor_args).build_transaction({
            'from': deployer.address,
            'nonce': w3.eth.get_transaction_count(deployer.address),
            'gas': 5000000,
            'maxFeePerGas': w3.to_wei(0.05, 'gwei'),
            'maxPriorityFeePerGas': w3.to_wei(0.01, 'gwei'),
            'chainId': 8453,
        })
    else:
        tx = Contract.constructor().build_transaction({
            'from': deployer.address,
            'nonce': w3.eth.get_transaction_count(deployer.address),
            'gas': 5000000,
            'maxFeePerGas': w3.to_wei(0.05, 'gwei'),
            'maxPriorityFeePerGas': w3.to_wei(0.01, 'gwei'),
            'chainId': 8453,
        })
    
    signed = deployer.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    print(f"  Tx sent: {tx_hash.hex()}")
    
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
    print(f"  Status: {'SUCCESS' if receipt.status == 1 else 'FAILED'}")
    print(f"  Gas used: {receipt.gasUsed}")
    print(f"  Contract: {receipt.contractAddress}")
    return receipt.contractAddress, tx_hash.hex(), receipt.gasUsed

# === Deploy CompliancePassport V3.1-Complete ===
print("\n=== Deploying CompliancePassport V3.1-Complete ===")
compliance_addr, compliance_tx, compliance_gas = deploy_contract(
    "CompliancePassport",
    f"{BUILD_DIR}/CompliancePassport.abi",
    f"{BUILD_DIR}/CompliancePassport.bin",
    [Web3.to_checksum_address(REGISTRY_ADDR)]
)
time.sleep(3)

# === Deploy AccessGateway V3.1-Complete ===
# Gateway service = new CompliancePassport address
print("\n=== Deploying AccessGateway V3.1-Complete ===")
gateway_addr, gateway_tx, gateway_gas = deploy_contract(
    "AccessGateway",
    f"{BUILD_DIR}/AccessGateway.abi",
    f"{BUILD_DIR}/AccessGateway.bin",
    [
        Web3.to_checksum_address(REGISTRY_ADDR),
        Web3.to_checksum_address(PASSPORT_ADDR),
        Web3.to_checksum_address(compliance_addr),  # new gateway service = new compliance
    ]
)

print(f"\n{'='*60}")
print(f"V3.1-Complete Deployment Summary")
print(f"{'='*60}")
print(f"AgentRegistry (V3, unchanged):   {REGISTRY_ADDR}")
print(f"AgentPassport (V3.1, unchanged): {PASSPORT_ADDR}")
print(f"CompliancePassport V3.1-Complete: {compliance_addr} (gas: {compliance_gas})")
print(f"AccessGateway V3.1-Complete:      {gateway_addr} (gas: {gateway_gas})")
print(f"\nTx hashes:")
print(f"  CompliancePassport: {compliance_tx}")
print(f"  AccessGateway:      {gateway_tx}")
print(f"\nTotal gas: {compliance_gas + gateway_gas}")

# Save deployment info
deploy_info = {
    "version": "V3.1-Complete",
    "deployed_at": time.strftime("%Y-%m-%d %H:%M:%S UTC"),
    "chain": "Base Mainnet (8453)",
    "contracts": {
        "AgentRegistry": {"address": REGISTRY_ADDR, "version": "V3 (unchanged)"},
        "AgentPassport": {"address": PASSPORT_ADDR, "version": "V3.1 (unchanged)"},
        "CompliancePassport": {"address": compliance_addr, "tx": compliance_tx, "gas": compliance_gas},
        "AccessGateway": {"address": gateway_addr, "tx": gateway_tx, "gas": gateway_gas},
    },
    "deployer": deployer.address,
    "total_gas": compliance_gas + gateway_gas
}

with open("deployment_v3.1_complete.json", "w") as f:
    json.dump(deploy_info, f, indent=2)
print(f"\nDeployment info saved to deployment_v3.1_complete.json")
