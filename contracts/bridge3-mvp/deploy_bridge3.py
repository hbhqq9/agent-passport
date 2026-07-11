#!/usr/bin/env python3
"""Bridge 3 MVP — SupplyChainWarRisk 部署脚本
部署到 Base Mainnet (Chain ID 8453)
"""
import json
import time
import sys
import os
import subprocess

# ========== 配置 ==========
RPC_URL = "https://mainnet.base.org"
CHAIN_ID = 8453
DEPLOYER_KEY = os.environ.get('DEPLOYER_PRIVATE_KEY', '')
GAS_LIMIT = 3_000_000
MAX_FEE_GWEI = 0.05
PRIORITY_FEE_GWEI = 0.01

# ========== 导入 ==========
try:
    from web3 import Web3
except ImportError:
    print("Installing web3...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "web3", "-q"])
    from web3 import Web3


def compile_contract(sol_path: str) -> tuple:
    """使用 solcx 编译合约，返回 (abi, bytecode)"""
    try:
        import solcx
    except ImportError:
        print("Installing py-solc-x...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "py-solc-x", "-q"])
        import solcx

    # 安装 solc 0.8.24
    try:
        solcx.get_solc_version()
    except Exception:
        pass

    installed = [str(v) for v in solcx.get_installed_solc_versions()]
    if '0.8.24' not in installed:
        print("Installing solc 0.8.24...")
        solcx.install_solc('0.8.24')

    solcx.set_solc_version('0.8.24')

    with open(sol_path, 'r') as f:
        source = f.read()

    compiled = solcx.compile_source(
        source,
        output_values=['abi', 'bin'],
        solc_version='0.8.24'
    )

    # 获取合约
    contract_id = None
    for key in compiled:
        if 'SupplyChainWarRisk' in key:
            contract_id = key
            break

    if not contract_id:
        raise Exception(f"Contract not found in compiled output. Keys: {list(compiled.keys())}")

    abi = compiled[contract_id]['abi']
    bytecode = compiled[contract_id]['bin']
    return abi, bytecode


def deploy():
    """部署 SupplyChainWarRisk 合约"""
    if not DEPLOYER_KEY:
        print("ERROR: DEPLOYER_PRIVATE_KEY not set in environment!")
        sys.exit(1)

    # 连接 Base Mainnet
    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    if not w3.is_connected():
        print("ERROR: Cannot connect to Base Mainnet RPC!")
        sys.exit(1)

    print(f"Connected to Base Mainnet (Chain ID: {w3.eth.chain_id})")

    deployer = w3.eth.account.from_key(DEPLOYER_KEY)
    print(f"Deployer: {deployer.address}")

    balance = w3.eth.get_balance(deployer.address)
    print(f"Balance: {Web3.from_wei(balance, 'ether')} ETH")

    if balance < Web3.to_wei(0.001, 'ether'):
        print("ERROR: Insufficient balance! Need at least 0.001 ETH")
        sys.exit(1)

    # 编译合约
    print("\n=== Compiling SupplyChainWarRisk ===")
    sol_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'SupplyChainWarRisk.sol')
    abi, bytecode = compile_contract(sol_path)
    print(f"Compilation successful. Bytecode size: {len(bytecode)} chars")

    # 保存 ABI
    output_dir = os.path.dirname(os.path.abspath(__file__))
    abi_path = os.path.join(output_dir, 'SupplyChainWarRisk.abi.json')
    with open(abi_path, 'w') as f:
        json.dump(abi, f, indent=2)
    print(f"ABI saved to: {abi_path}")

    # 部署
    print("\n=== Deploying to Base Mainnet ===")
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    nonce = w3.eth.get_transaction_count(deployer.address)
    tx = Contract.constructor().build_transaction({
        'from': deployer.address,
        'nonce': nonce,
        'gas': GAS_LIMIT,
        'maxFeePerGas': Web3.to_wei(MAX_FEE_GWEI, 'gwei'),
        'maxPriorityFeePerGas': Web3.to_wei(PRIORITY_FEE_GWEI, 'gwei'),
        'chainId': CHAIN_ID,
    })

    signed = deployer.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    print(f"Tx hash: {tx_hash.hex()}")
    print("Waiting for confirmation...")

    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=180)

    if receipt.status != 1:
        print("ERROR: Deployment failed!")
        sys.exit(1)

    contract_address = receipt.contractAddress
    gas_used = receipt.gasUsed
    gas_cost_wei = gas_used * receipt.effectiveGasPrice
    gas_cost_eth = Web3.from_wei(gas_cost_wei, 'ether')

    print(f"\n=== Deployment Successful! ===")
    print(f"Contract Address: {contract_address}")
    print(f"Block: {receipt.blockNumber}")
    print(f"Gas Used: {gas_used:,}")
    print(f"Gas Cost: {gas_cost_eth} ETH (~${gas_cost_eth * 2500:.4f} USD)")
    print(f"Tx Hash: {tx_hash.hex()}")
    print(f"Basescan: https://basescan.org/address/{contract_address}")

    # 保存部署信息
    deployment_info = {
        "contract": "SupplyChainWarRisk",
        "bridge": "Bridge 3 MVP",
        "network": "Base Mainnet",
        "chainId": CHAIN_ID,
        "contractAddress": contract_address,
        "deployer": deployer.address,
        "txHash": tx_hash.hex(),
        "blockNumber": receipt.blockNumber,
        "gasUsed": str(gas_used),
        "gasCostETH": str(gas_cost_eth),
        "deployedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "abi": abi
    }

    deploy_path = os.path.join(output_dir, 'deployment_bridge3.json')
    with open(deploy_path, 'w') as f:
        json.dump(deployment_info, f, indent=2)
    print(f"\nDeployment info saved to: {deploy_path}")

    return contract_address


if __name__ == '__main__':
    deploy()
