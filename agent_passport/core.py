"""
AgentPassportClient - Core client for interacting with Agent Passport smart contracts.
"""
from dataclasses import dataclass
from typing import Optional

from web3 import Web3
from web3.contract import Contract

from .contracts import ADDRESSES, AGENT_REGISTRY_ABI, AGENT_PASSPORT_ABI, ACCESS_GATEWAY_ABI, COMPLIANCE_PASSPORT_ABI


# ── Data Classes ───────────────────────────────────────────────────────────────

@dataclass
class AgentInfo:
    """Represents a registered AI Agent."""
    name: str
    operator: str
    active: bool
    metadata_uri: str
    registered_at: int


@dataclass
class AttestationInfo:
    """Represents an attestation (compliance proof) issued to an agent."""
    agent_id: bytes
    scope: str
    evidence_uri: str
    issuer: str
    issued_at: int
    revoked: bool


@dataclass
class ComplianceInfo:
    """Represents the Art.50 compliance status of an agent."""
    art50_compliant: bool
    risk_score: int
    disclosure_level: str
    last_audit: int


# ── Client ─────────────────────────────────────────────────────────────────────

DEFAULT_RPC_URL = "https://mainnet.base.org"
BASE_CHAIN_ID = 8453


class AgentPassportClient:
    """
    Main SDK client for interacting with the Agent Passport protocol on Base mainnet.

    Args:
        rpc_url:      Base mainnet RPC endpoint (default: https://mainnet.base.org).
        private_key:  Optional private key for write operations (register, attest).
    """

    def __init__(self, rpc_url: str = DEFAULT_RPC_URL, private_key: Optional[str] = None) -> None:
        self._rpc_url = rpc_url
        self._w3 = Web3(Web3.HTTPProvider(rpc_url))

        if not self._w3.is_connected():
            raise ConnectionError(f"Cannot connect to Base mainnet at {rpc_url}")

        # Ensure we're on the correct chain
        chain_id = self._w3.eth.chain_id
        if chain_id != BASE_CHAIN_ID:
            raise ConnectionError(
                f"Connected to wrong chain (id={chain_id}). Base mainnet expected (id={BASE_CHAIN_ID})."
            )

        self._private_key = private_key
        self._account = None

        if private_key:
            self._account = self._w3.eth.account.from_key(private_key)

        # Instantiate contract objects
        self._agent_registry: Contract = self._w3.eth.contract(
            address=Web3.to_checksum_address(ADDRESSES["AgentRegistry"]),
            abi=AGENT_REGISTRY_ABI,
        )
        self._agent_passport: Contract = self._w3.eth.contract(
            address=Web3.to_checksum_address(ADDRESSES["AgentPassport"]),
            abi=AGENT_PASSPORT_ABI,
        )
        self._access_gateway: Contract = self._w3.eth.contract(
            address=Web3.to_checksum_address(ADDRESSES["AccessGateway"]),
            abi=ACCESS_GATEWAY_ABI,
        )
        self._compliance_passport: Contract = self._w3.eth.contract(
            address=Web3.to_checksum_address(ADDRESSES["CompliancePassport"]),
            abi=COMPLIANCE_PASSPORT_ABI,
        )

    # ── Helpers ──────────────────────────────────────────────────────────────

    def _require_account(self) -> None:
        """Raise if no private key was provided."""
        if not self._account:
            raise ValueError(
                "A private_key is required for write operations. "
                "Initialize AgentPassportClient with private_key='0x...'"
            )

    def _send_tx(self, contract_function) -> dict:
        """Build, sign, and send a transaction, returning the receipt."""
        self._require_account()
        tx = contract_function.build_transaction({
            "from": self._account.address,
            "nonce": self._w3.eth.get_transaction_count(self._account.address),
            "chainId": BASE_CHAIN_ID,
        })
        signed = self._w3.eth.account.sign_transaction(tx, private_key=self._private_key)
        tx_hash = self._w3.eth.send_raw_transaction(signed.raw_transaction)
        receipt = self._w3.eth.wait_for_transaction_receipt(tx_hash)
        return receipt

    @staticmethod
    def _to_agent_id(agent_id) -> bytes:
        """Normalise agent_id to bytes32."""
        if isinstance(agent_id, bytes):
            if len(agent_id) < 32:
                agent_id = agent_id.rjust(32, b"\x00")
            return agent_id
        if isinstance(agent_id, str):
            if agent_id.startswith("0x"):
                raw = bytes.fromhex(agent_id[2:])
            else:
                raw = agent_id.encode("utf-8")
            if len(raw) < 32:
                raw = raw.rjust(32, b"\x00")
            return raw
        raise TypeError(f"Unsupported agent_id type: {type(agent_id)}")

    # ── Write Operations ─────────────────────────────────────────────────────

    def register_agent(self, name: str, operator: str, metadata_uri: str = "") -> bytes:
        """
        Register a new AI Agent on-chain.

        Args:
            name:         Human-readable agent name.
            operator:     Ethereum address of the agent operator.
            metadata_uri: Optional URI pointing to agent metadata.

        Returns:
            bytes32: The agent's on-chain identifier.
        """
        self._require_account()
        operator_addr = Web3.to_checksum_address(operator)
        receipt = self._send_tx(
            self._agent_registry.functions.registerAgent(name, operator_addr, metadata_uri)
        )
        # Parse agentId from logs
        logs = receipt.get("logs", [])
        if logs:
            # First topic after event signature is often the agentId
            topics = logs[0].get("topics", [])
            if len(topics) >= 2:
                return bytes(topics[1])
        # Fallback: derive from name
        agent_id = Web3.keccak(text=f"{name}:{operator}")[:32]
        return agent_id

    def issue_attestation(self, agent_id, scope: str, evidence_uri: str) -> int:
        """
        Issue a compliance attestation for an agent.

        Args:
            agent_id:    bytes32 agent identifier.
            scope:       Scope string (e.g. "art50", "general", "data_access").
            evidence_uri: URI pointing to attestation evidence.

        Returns:
            int: The attestation ID.
        """
        self._require_account()
        aid = self._to_agent_id(agent_id)
        receipt = self._send_tx(
            self._agent_passport.functions.issueAttestation(aid, scope, evidence_uri)
        )
        logs = receipt.get("logs", [])
        if logs:
            topics = logs[0].get("topics", [])
            if len(topics) >= 2:
                return int.from_bytes(topics[1], "big")
        # Fallback: derive from inputs
        att_id = int.from_bytes(Web3.keccak(aid + scope.encode())[:32], "big")
        return att_id

    # ── Read Operations ──────────────────────────────────────────────────────

    def get_agent(self, agent_id) -> AgentInfo:
        """
        Query agent information from the registry.

        Args:
            agent_id: bytes32 agent identifier.

        Returns:
            AgentInfo dataclass.
        """
        aid = self._to_agent_id(agent_id)
        name, operator, active, metadata_uri, registered_at = (
            self._agent_registry.functions.getAgent(aid).call()
        )
        return AgentInfo(
            name=name,
            operator=operator,
            active=active,
            metadata_uri=metadata_uri,
            registered_at=registered_at,
        )

    def get_attestation(self, attestation_id: int) -> AttestationInfo:
        """
        Query attestation details.

        Args:
            attestation_id: uint256 attestation identifier.

        Returns:
            AttestationInfo dataclass.
        """
        agent_id, scope, evidence_uri, issuer, issued_at, revoked = (
            self._agent_passport.functions.getAttestation(attestation_id).call()
        )
        return AttestationInfo(
            agent_id=agent_id,
            scope=scope,
            evidence_uri=evidence_uri,
            issuer=issuer,
            issued_at=issued_at,
            revoked=revoked,
        )

    def verify_agent(self, agent_id, required_scope: str = "general") -> bool:
        """
        Verify that an agent holds a valid attestation with the given scope.

        Args:
            agent_id:       bytes32 agent identifier.
            required_scope: The scope the agent must be attested for.

        Returns:
            True if the agent has a valid, non-revoked attestation for the scope.
        """
        aid = self._to_agent_id(agent_id)
        try:
            has_scope = self._agent_passport.functions.hasAttestation(aid, required_scope).call()
            if not has_scope:
                return False
            # Check the agent is still active
            is_registered = self._agent_registry.functions.isRegistered(aid).call()
            if not is_registered:
                return False
            agent_info = self.get_agent(aid)
            return agent_info.active
        except Exception:
            return False

    def get_compliance_status(self, agent_id) -> ComplianceInfo:
        """
        Get the Art.50 compliance status for an agent.

        Args:
            agent_id: bytes32 agent identifier.

        Returns:
            ComplianceInfo dataclass.
        """
        aid = self._to_agent_id(agent_id)
        art50_compliant, risk_score, disclosure_level, last_audit = (
            self._compliance_passport.functions.getComplianceStatus(aid).call()
        )
        return ComplianceInfo(
            art50_compliant=art50_compliant,
            risk_score=risk_score,
            disclosure_level=disclosure_level,
            last_audit=last_audit,
        )

    def generate_disclosure(self, agent_id, interaction_type: str = "chat") -> dict:
        """
        Generate an Art.50 disclosure header for an agent interaction.

        Args:
            agent_id:         bytes32 agent identifier.
            interaction_type: Type of interaction (e.g. "chat", "voice", "email").

        Returns:
            dict with 'header_value' and 'metadata' keys.
        """
        aid = self._to_agent_id(agent_id)
        header_value, metadata = (
            self._compliance_passport.functions.generateDisclosure(aid, interaction_type).call()
        )
        return {
            "header_value": header_value,
            "metadata": metadata,
            "interaction_type": interaction_type,
            "agent_id": agent_id.hex() if isinstance(agent_id, bytes) else str(agent_id),
        }
