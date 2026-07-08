"""
DelegationManager - Create and verify agent delegation chains.

Delegations allow one agent to act on behalf of another within specified scopes.
"""
import time
from typing import Any, Dict, List, Tuple

from .core import AgentPassportClient


class DelegationManager:
    """
    Manage agent delegation chains for scoped access.

    Args:
        client: An initialised AgentPassportClient instance.
    """

    def __init__(self, client: AgentPassportClient) -> None:
        self._client = client

    def create_delegation(
        self,
        agent_id,
        delegate_address: str,
        scopes: List[str],
        expires_at: int,
    ) -> Dict[str, Any]:
        """
        Create a delegation record (off-chain signed + on-chain reference).

        Args:
            agent_id:          bytes32 delegating agent identifier.
            delegate_address:  Ethereum address of the delegate.
            scopes:            List of scope strings the delegate is authorised for.
            expires_at:        Unix timestamp when the delegation expires.

        Returns:
            dict with delegation details including a local signature hash.
        """
        aid = self._client._to_agent_id(agent_id)
        aid_str = aid.hex()

        # Build a local delegation record
        delegation = {
            "agent_id": aid_str,
            "delegate_address": delegate_address,
            "scopes": scopes,
            "expires_at": expires_at,
            "created_at": int(time.time()),
        }

        # Create a deterministic hash as a local signature placeholder
        # In production this would be an EIP-712 typed-data signature
        payload = f"{aid_str}:{delegate_address}:{','.join(scopes)}:{expires_at}".encode("utf-8")
        from web3 import Web3
        sig_hash = Web3.keccak(payload).hex()

        delegation["signature_hash"] = sig_hash
        delegation["valid"] = expires_at > int(time.time())

        return delegation

    def verify_delegation(self, agent_id, required_scope: str) -> Tuple[bool, str, int]:
        """
        Verify that an agent has a valid delegation for the required scope.

        Args:
            agent_id:       bytes32 agent identifier.
            required_scope: The scope the delegate must be authorised for.

        Returns:
            Tuple of (valid: bool, delegator: str, expires_at: int).
        """
        aid = self._client._to_agent_id(agent_id)
        try:
            valid, delegator, expires_at = (
                self._client._access_gateway.functions.verifyDelegation(aid, required_scope).call()
            )
            return (bool(valid), str(delegator), int(expires_at))
        except Exception:
            return (False, "0x0000000000000000000000000000000000000000", 0)

    def list_delegations(self, agent_id) -> List[Dict[str, Any]]:
        """
        List all attestations for an agent and infer delegation scope.

        Args:
            agent_id: bytes32 agent identifier.

        Returns:
            List of delegation-like dicts derived from on-chain attestations.
        """
        aid = self._client._to_agent_id(agent_id)
        delegations = []

        try:
            attestation_ids = (
                self._client._agent_passport.functions.getAttestationsByAgent(aid).call()
            )
            for att_id in attestation_ids:
                att = self._client.get_attestation(att_id)
                delegations.append({
                    "attestation_id": att_id,
                    "scope": att.scope,
                    "evidence_uri": att.evidence_uri,
                    "issuer": att.issuer,
                    "issued_at": att.issued_at,
                    "revoked": att.revoked,
                })
        except Exception:
            pass

        return delegations
