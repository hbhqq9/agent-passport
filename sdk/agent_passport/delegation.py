"""
DelegationManager - Create and verify agent delegation proofs.

Delegations allow agents to prove ownership and authorisation via
EIP-712 signatures verified through the AccessGateway contract.
"""
import time
from typing import Any, Dict, List, Optional, Tuple

from web3 import Web3

from .core import AgentPassportClient
from .contracts import ADDRESSES


# EIP-712 domain for AgentRegistry bindWallet
AGENT_REGISTRY_DOMAIN_TYPEHASH = Web3.keccak(
    text="EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
)


class DelegationManager:
    """
    Manage agent delegation proofs using EIP-712 signatures.

    Works with the AccessGateway.verifyProofOfAgent function to verify
    that an agent wallet is authorised to act on behalf of an agent.

    Args:
        client: An initialised AgentPassportClient instance.
    """

    def __init__(self, client: AgentPassportClient) -> None:
        self._client = client

    def create_delegation(
        self,
        agent_wallet: str,
        message: bytes,
        private_key: str,
        deadline: int = 0,
    ) -> Dict[str, Any]:
        """
        Create a delegation proof by signing a message with the agent's wallet key.

        This generates an EIP-712-compatible signature that can be verified
        by the AccessGateway.verifyProofOfAgent function.

        Args:
            agent_wallet: The agent's Ethereum address.
            message:      The bytes32 message to sign (proof of agent ownership).
            private_key:  The private key of the agent wallet.
            deadline:     Optional deadline timestamp (0 = no deadline).

        Returns:
            dict with keys:
                - agent_wallet (str)
                - message (bytes) — the signed message
                - signature (bytes) — the signature
                - deadline (int)
                - created_at (int)
        """
        wallet_addr = Web3.to_checksum_address(agent_wallet)

        # Ensure message is bytes32
        if len(message) < 32:
            message = message.ljust(32, b"\x00")
        elif len(message) > 32:
            message = message[:32]

        # Sign the message using Ethereum signed message (personal_sign)
        signable_message = message
        signed = self._client._w3.eth.account.sign_message(
            signable_message, private_key=private_key
        )
        signature = signed.signature

        return {
            "agent_wallet": wallet_addr,
            "message": message,
            "signature": signature,
            "deadline": deadline,
            "created_at": int(time.time()),
        }

    def create_bind_wallet_signature(
        self,
        agent_id: int,
        wallet_address: str,
        deadline: int,
        private_key: str,
    ) -> Dict[str, Any]:
        """
        Create an EIP-712 signature for the AgentRegistry.bindWallet function.

        This can be used to bind an additional wallet to an agent on-chain.

        Args:
            agent_id:       uint256 agent identifier.
            wallet_address: The Ethereum address to bind.
            deadline:       Unix timestamp deadline for the signature.
            private_key:    The private key of the agent owner.

        Returns:
            dict with keys:
                - agent_id (int)
                - wallet (str)
                - deadline (int)
                - signature (bytes)
                - ready_for_contract (bool) — True if ready to submit
        """
        aid = self._client._to_agent_id(agent_id)
        wallet_addr = Web3.to_checksum_address(wallet_address)

        # Build EIP-712 typed data for bindWallet
        # The domain and types should match the contract's implementation
        domain = {
            "name": "AgentRegistry",
            "version": "2",
            "chainId": 8453,
            "verifyingContract": Web3.to_checksum_address(
                ADDRESSES["AgentRegistry"]
            ),
        }
        message = {
            "agentId": aid,
            "wallet": wallet_addr,
            "deadline": deadline,
        }

        # Use web3's EIP-712 signing
        # Note: the exact struct types depend on the contract implementation
        # This is a standard EIP-712 sign
        signable = {
            "types": {
                "EIP712Domain": [
                    {"name": "name", "type": "string"},
                    {"name": "version", "type": "string"},
                    {"name": "chainId", "type": "uint256"},
                    {"name": "verifyingContract", "type": "address"},
                ],
                "BindWallet": [
                    {"name": "agentId", "type": "uint256"},
                    {"name": "wallet", "type": "address"},
                    {"name": "deadline", "type": "uint256"},
                ],
            },
            "primaryType": "BindWallet",
            "domain": domain,
            "message": message,
        }

        # Sign using eth_account's sign_typed_data
        from eth_account.messages import encode_typed_data

        encoded = encode_typed_data(full_message=signable)
        signed = self._client._w3.eth.account.sign_message(
            encoded, private_key=private_key
        )

        return {
            "agent_id": aid,
            "wallet": wallet_addr,
            "deadline": deadline,
            "signature": signed.signature,
            "ready_for_contract": True,
        }

    def verify_delegation(
        self,
        agent_wallet: str,
        message: bytes,
        signature: bytes,
    ) -> Tuple[bool, int]:
        """
        Verify a proof-of-agent delegation using AccessGateway.verifyProofOfAgent.

        Args:
            agent_wallet: The agent's Ethereum address.
            message:      The bytes32 message that was signed.
            signature:    The signature bytes.

        Returns:
            Tuple of (is_valid: bool, agent_id: int).
        """
        try:
            return self._client.verify_agent(agent_wallet, message, signature)
        except Exception:
            return (False, 0)

    def list_delegations(self, agent_id: int) -> List[Dict[str, Any]]:
        """
        List all attestations for an agent (delegation-like records).

        These represent the verifications/attributes that have been attested
        to the agent by verifiers with VERIFIER_ROLE.

        Args:
            agent_id: uint256 agent identifier (int).

        Returns:
            List of attestation detail dicts.
        """
        aid = self._client._to_agent_id(agent_id)
        delegations = []

        try:
            attestation_ids = self._client.get_agent_attestation_ids(aid)
            for att_id in attestation_ids:
                try:
                    att = self._client.get_attestation(att_id)
                    delegations.append({
                        "attestation_id": att.attestation_id,
                        "agent_id": att.agent_id,
                        "verifier": att.verifier,
                        "attribute_type": att.attribute_type,
                        "attribute_hash": att.attribute_hash.hex(),
                        "schema_uri": att.schema_uri,
                        "valid_until": att.valid_until,
                        "issued_at": att.issued_at,
                        "revoked": att.revoked,
                    })
                except Exception:
                    continue
        except Exception:
            pass

        return delegations
