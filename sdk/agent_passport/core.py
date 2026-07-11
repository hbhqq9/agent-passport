"""
AgentPassportClient - Core client for interacting with Agent Passport V3 smart contracts.

All ABI calls are matched to the actual deployed contracts on Base Mainnet.
V3 adds: EIP-712 nonce replay protection, chainId-bound signatures, consumeProofOfAgent.
"""
from dataclasses import dataclass
from typing import List, Optional, Tuple

from web3 import Web3
from web3.contract import Contract

from .contracts import (
    ADDRESSES,
    AGENT_REGISTRY_ABI,
    AGENT_PASSPORT_ABI,
    ACCESS_GATEWAY_ABI,
    COMPLIANCE_PASSPORT_ABI,
)


# ── Data Classes ───────────────────────────────────────────────────────────────

@dataclass
class AgentInfo:
    """Represents a registered AI Agent (from AgentRegistry.getAgentInfo)."""
    owner: str
    agent_wallet: str
    agent_uri: str
    registered_at: int
    active: bool


@dataclass
class AttestationInfo:
    """Represents an attestation issued by AgentPassport.getAttestation."""
    attestation_id: int
    agent_id: int
    verifier: str
    attribute_type: int
    attribute_hash: bytes
    schema_uri: str
    valid_until: int
    issued_at: int
    revoked: bool


@dataclass
class CertificateInfo:
    """Represents a compliance certificate from CompliancePassport.getCertificate."""
    cert_id: int
    agent_id: int
    risk_score: int
    compliance_level: int
    evidence_hash: bytes
    valid_until: int
    issued_at: int
    issuer: str
    revoked: bool


# ── Client ─────────────────────────────────────────────────────────────────────

DEFAULT_RPC_URL = "https://mainnet.base.org"
BASE_CHAIN_ID = 8453


class AgentPassportClient:
    """
    Main SDK client for interacting with the Agent Passport V3 protocol on Base mainnet.

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
                f"Connected to wrong chain (id={chain_id}). "
                f"Base mainnet expected (id={BASE_CHAIN_ID})."
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
        signed = self._w3.eth.account.sign_transaction(
            tx, private_key=self._private_key
        )
        tx_hash = self._w3.eth.send_raw_transaction(signed.raw_transaction)
        receipt = self._w3.eth.wait_for_transaction_receipt(tx_hash)
        return receipt

    @staticmethod
    def _to_agent_id(agent_id) -> int:
        """
        Normalise agent_id to uint256 (Python int).

        Accepts int directly, or numeric strings (decimal / hex).
        Agent IDs are uint256 starting from 1.
        """
        if isinstance(agent_id, int):
            return agent_id
        if isinstance(agent_id, str):
            if agent_id.startswith("0x") or agent_id.startswith("0X"):
                return int(agent_id, 16)
            return int(agent_id)
        raise TypeError(
            f"Unsupported agent_id type: {type(agent_id)}. "
            "Expected int or numeric string."
        )

    # ── Write Operations ─────────────────────────────────────────────────────

    def register_agent(
        self, agent_uri: str
    ) -> int:
        """
        Register a new AI Agent on-chain via AgentRegistry.register(string).

        Args:
            agent_uri: URI pointing to agent metadata (e.g., Codeberg raw URL).

        Returns:
            int: The new agentId (uint256, starting from 1).
        """
        self._require_account()
        receipt = self._send_tx(
            self._agent_registry.functions.register(agent_uri)
        )
        # Parse agentId from logs
        logs = receipt.get("logs", [])
        if logs:
            for log in logs:
                topics = log.get("topics", [])
                if len(topics) >= 2:
                    candidate = int.from_bytes(topics[1], "big")
                    if candidate > 0:
                        return candidate
        # Fallback: read totalAgents
        return self._agent_registry.functions.totalAgents().call()

    def issue_attestation(
        self,
        agent_id: int,
        attribute_type: int,
        attribute_value: str,
        schema_uri: str = "",
        valid_until: int = 0,
    ) -> None:
        """
        Issue an attestation for an agent via AgentPassport.issueAttestation.
        Requires VERIFIER_ROLE on the contract.

        Args:
            agent_id:        uint256 agent identifier (starts from 1).
            attribute_type:  uint8 attribute type code.
            attribute_value: The attribute value string.
            schema_uri:      Optional URI pointing to the schema definition.
            valid_until:     Unix timestamp when the attestation expires (0 = no expiry).
        """
        self._require_account()
        aid = self._to_agent_id(agent_id)
        self._send_tx(
            self._agent_passport.functions.issueAttestation(
                aid, attribute_type, attribute_value, schema_uri, valid_until
            )
        )

    def issue_certificate(
        self,
        agent_id: int,
        compliance_level: int,
        evidence_hash: bytes,
        valid_until: int,
    ) -> None:
        """
        Issue a compliance certificate via CompliancePassport.issueCertificate.
        Requires SCORER_ROLE on the contract.

        Args:
            agent_id:          uint256 agent identifier.
            compliance_level:  uint8 compliance level (0-255).
            evidence_hash:     bytes32 evidence hash.
            valid_until:       Unix timestamp when the certificate expires.
        """
        self._require_account()
        aid = self._to_agent_id(agent_id)
        self._send_tx(
            self._compliance_passport.functions.issueCertificate(
                aid, compliance_level, evidence_hash, valid_until
            )
        )

    def record_risk_score(
        self,
        agent_id: int,
        score: int,
        valid_until: int,
        evidence_hash: bytes,
        scorer_uri: str = "",
    ) -> None:
        """
        Record a risk score for an agent via CompliancePassport.recordRiskScore.
        Requires SCORER_ROLE on the contract.

        Args:
            agent_id:      uint256 agent identifier.
            score:         uint8 risk score (0-255).
            valid_until:   Unix timestamp when the score expires.
            evidence_hash: bytes32 evidence hash.
            scorer_uri:    Optional URI pointing to scorer metadata.
        """
        self._require_account()
        aid = self._to_agent_id(agent_id)
        self._send_tx(
            self._compliance_passport.functions.recordRiskScore(
                aid, score, valid_until, evidence_hash, scorer_uri
            )
        )

    # ── Read Operations ──────────────────────────────────────────────────────

    def get_agent(self, agent_id: int) -> AgentInfo:
        """
        Query agent information from the registry via getAgentInfo(uint256).

        Args:
            agent_id: uint256 agent identifier (int, starting from 1).

        Returns:
            AgentInfo dataclass.
        """
        aid = self._to_agent_id(agent_id)
        result = self._agent_registry.functions.getAgentInfo(aid).call()
        # Contract returns a struct (tuple), unpack from result[0]
        info = result[0] if isinstance(result[0], tuple) else result
        return AgentInfo(
            owner=info[0],
            agent_wallet=info[1],
            agent_uri=info[2],
            registered_at=info[3],
            active=info[4],
        )

    def get_attestation(self, attestation_id: int) -> AttestationInfo:
        """
        Query attestation details via getAttestation(uint256).

        Args:
            attestation_id: uint256 attestation identifier.

        Returns:
            AttestationInfo dataclass.
        """
        result = self._agent_passport.functions.getAttestation(attestation_id).call()
        # Contract returns a struct (tuple), unpack from result[0]
        info = result[0] if isinstance(result[0], tuple) else result
        return AttestationInfo(
            attestation_id=info[0],
            agent_id=info[1],
            verifier=info[2],
            attribute_type=info[3],
            attribute_hash=info[4],
            schema_uri=info[5],
            valid_until=info[6],
            issued_at=info[7],
            revoked=info[8],
        )

    def get_agent_attestation_ids(self, agent_id: int) -> List[int]:
        """
        Get all attestation IDs for an agent via getAgentAttestationIds(uint256).

        Args:
            agent_id: uint256 agent identifier.

        Returns:
            List of attestation IDs (uint256).
        """
        aid = self._to_agent_id(agent_id)
        return list(
            self._agent_passport.functions.getAgentAttestationIds(aid).call()
        )

    def verify_agent(
        self,
        agent_wallet: str,
        message: bytes,
        nonce: int,
        signature: bytes,
    ) -> Tuple[bool, int]:
        """
        Verify proof of agent ownership via AccessGateway.verifyProofOfAgent (V3).

        Args:
            agent_wallet: The agent's Ethereum address.
            message:      bytes32 message that was signed.
            nonce:        Current nonce for this wallet (from proofOfAgentNonces).
            signature:    EIP-712 signature bytes.

        Returns:
            Tuple of (is_valid: bool, agent_id: int).
        """
        wallet_addr = Web3.to_checksum_address(agent_wallet)
        if len(message) < 32:
            message = message.ljust(32, b"\x00")
        elif len(message) > 32:
            message = message[:32]
        is_valid, agent_id = (
            self._access_gateway.functions.verifyProofOfAgent(
                wallet_addr, message, nonce, signature
            ).call()
        )
        return (bool(is_valid), int(agent_id))

    def get_proof_nonce(self, agent_wallet: str) -> int:
        """Get the current proof-of-agent nonce for a wallet."""
        wallet_addr = Web3.to_checksum_address(agent_wallet)
        return self._access_gateway.functions.proofOfAgentNonces(wallet_addr).call()

    def sign_proof_of_agent(
        self,
        agent_wallet: str,
        message: bytes,
        nonce: int,
    ) -> bytes:
        """
        Sign a ProofOfAgent message using EIP-712 (V3).

        Args:
            agent_wallet: The agent's Ethereum address.
            message:      bytes32 message to sign.
            nonce:        Current nonce for this wallet.

        Returns:
            Signature bytes.
        """
        from eth_account.messages import encode_typed_data
        self._require_account()
        wallet_addr = Web3.to_checksum_address(agent_wallet)
        if len(message) < 32:
            message = message.ljust(32, b"\x00")
        elif len(message) > 32:
            message = message[:32]

        agent_id = self._agent_registry.functions.getAgentByWallet(wallet_addr).call()

        domain = {
            'name': 'AGLAccessGateway',
            'version': '1',
            'chainId': BASE_CHAIN_ID,
            'verifyingContract': self._access_gateway.address,
        }
        msg_types = {
            'ProofOfAgent': [
                {'name': 'agentWallet', 'type': 'address'},
                {'name': 'agentId', 'type': 'uint256'},
                {'name': 'message', 'type': 'bytes32'},
                {'name': 'nonce', 'type': 'uint256'},
            ]
        }
        msg_data = {
            'agentWallet': wallet_addr,
            'agentId': agent_id,
            'message': message,
            'nonce': nonce,
        }
        signable = encode_typed_data(domain, msg_types, msg_data)
        signed = self._account.sign_message(signable)
        return signed.signature

    def consume_proof_of_agent(
        self,
        agent_wallet: str,
        message: bytes,
        signature: bytes,
        deadline: int = 0,
    ) -> Tuple[bool, int]:
        """
        Consume a proof-of-agent (state-changing, increments nonce).

        V3.1-Final: Added deadline parameter for time-bound access control.
        The deadline is NOT part of the EIP-712 signature (backward compatible),
        but is validated on-chain by the gateway service.

        Args:
            agent_wallet: The agent's Ethereum address.
            message:      bytes32 message that was signed.
            signature:    EIP-712 signature bytes.
            deadline:     Unix timestamp deadline (0 = no deadline / use default).

        Returns:
            Tuple of (is_valid: bool, agent_id: int).
        """
        self._require_account()
        wallet_addr = Web3.to_checksum_address(agent_wallet)
        if len(message) < 32:
            message = message.ljust(32, b"\x00")
        elif len(message) > 32:
            message = message[:32]
        receipt = self._send_tx(
            self._access_gateway.functions.consumeProofOfAgent(
                wallet_addr, message, deadline, signature
            )
        )
        # Parse return from logs or use view call to get current state
        return (receipt.status == 1, 0)  # actual values in receipt logs

    def get_certificate(self, cert_id: int) -> CertificateInfo:
        """
        Query certificate details via getCertificate(uint256).

        Args:
            cert_id: uint256 certificate identifier.

        Returns:
            CertificateInfo dataclass.
        """
        result = (
            self._compliance_passport.functions.getCertificate(cert_id).call()
        )
        return CertificateInfo(
            cert_id=result[0],
            agent_id=result[1],
            risk_score=result[2],
            compliance_level=result[3],
            evidence_hash=result[4],
            valid_until=result[5],
            issued_at=result[6],
            issuer=result[7],
            revoked=result[8],
        )

    def get_agent_certificate_ids(self, agent_id: int) -> List[int]:
        """
        Get all certificate IDs for an agent via getAgentCertificateIds(uint256).

        Args:
            agent_id: uint256 agent identifier.

        Returns:
            List of certificate IDs (uint256).
        """
        aid = self._to_agent_id(agent_id)
        return list(
            self._compliance_passport.functions.getAgentCertificateIds(aid).call()
        )

    def get_compliance_status(self, agent_id: int) -> List[CertificateInfo]:
        """
        Get all compliance certificates for an agent.

        Args:
            agent_id: uint256 agent identifier.

        Returns:
            List of CertificateInfo dataclasses.
        """
        cert_ids = self.get_agent_certificate_ids(agent_id)
        certificates = []
        for cid in cert_ids:
            try:
                cert = self.get_certificate(cid)
                certificates.append(cert)
            except Exception:
                continue
        return certificates

    def get_max_risk_score_records(self) -> int:
        """
        Get the maximum number of risk score records per agent (V3.1-Final).

        Returns:
            int: Maximum records allowed (default: 100).
        """
        return self._compliance_passport.functions.MAX_RISK_SCORE_RECORDS().call()

    def is_registered_agent(self, wallet: str) -> bool:
        """
        Check if a wallet belongs to a registered and active agent (V3.1-Final).

        This is a lightweight check that avoids returning string data,
        making it safe for cross-contract calls under --via-ir optimization.

        Args:
            wallet: Ethereum address to check.

        Returns:
            bool: True if the wallet is registered and active.
        """
        wallet_addr = Web3.to_checksum_address(wallet)
        return self._agent_registry.functions.isRegisteredAgent(wallet_addr).call()
