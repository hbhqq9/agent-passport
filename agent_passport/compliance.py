"""
Art50ComplianceChecker - Art.50 compliance checking and disclosure generation.

Provides higher-level compliance utilities built on top of AgentPassportClient,
using the V2 CompliancePassport contract's certificate-based system.
"""
from typing import Any, Dict, List, Optional

from .core import AgentPassportClient, CertificateInfo


class Art50ComplianceChecker:
    """
    Art.50 compliance checker for AI agent interactions.

    Uses CompliancePassport certificates to determine compliance status
    and generate disclosure headers.

    Args:
        client: An initialised AgentPassportClient instance.
    """

    def __init__(self, client: AgentPassportClient) -> None:
        self._client = client

    def check_compliance(self, agent_id: int) -> Dict[str, Any]:
        """
        Return the compliance status for an agent based on its certificates.

        Args:
            agent_id: uint256 agent identifier (int).

        Returns:
            dict with keys:
                - agent_id (int)
                - has_certificate (bool)
                - certificates (list of CertificateInfo summaries)
                - is_compliant (bool) — True if at least one non-revoked, non-expired cert exists
                - highest_compliance_level (int or None)
                - latest_risk_score (int or None)
        """
        aid = self._client._to_agent_id(agent_id)
        import time

        try:
            cert_ids = self._client.get_agent_certificate_ids(aid)
        except Exception:
            return {
                "agent_id": aid,
                "has_certificate": False,
                "certificates": [],
                "is_compliant": False,
                "highest_compliance_level": None,
                "latest_risk_score": None,
            }

        certificates = []
        now = int(time.time())
        is_compliant = False
        highest_level = None
        latest_risk = None

        for cid in cert_ids:
            try:
                cert = self._client.get_certificate(cid)
                summary = {
                    "cert_id": cert.cert_id,
                    "compliance_level": cert.compliance_level,
                    "risk_score": cert.risk_score,
                    "valid_until": cert.valid_until,
                    "issued_at": cert.issued_at,
                    "issuer": cert.issuer,
                    "revoked": cert.revoked,
                    "is_valid": not cert.revoked and cert.valid_until > now,
                }
                certificates.append(summary)

                if not cert.revoked and cert.valid_until > now:
                    is_compliant = True
                    if highest_level is None or cert.compliance_level > highest_level:
                        highest_level = cert.compliance_level
                    latest_risk = cert.risk_score
            except Exception:
                continue

        return {
            "agent_id": aid,
            "has_certificate": len(certificates) > 0,
            "certificates": certificates,
            "is_compliant": is_compliant,
            "highest_compliance_level": highest_level,
            "latest_risk_score": latest_risk,
        }

    def generate_disclosure_header(
        self, agent_id: int, interaction_type: str = "chat"
    ) -> str:
        """
        Generate an HTTP response header string for Art.50 disclosure.

        The header format follows:
            X-AI-Disclosure: agent={agent_id}; compliant={true|false};
            compliance_level={level}; type={interaction_type}

        Args:
            agent_id:         uint256 agent identifier (int).
            interaction_type: Type of interaction ("chat", "voice", "email", etc.).

        Returns:
            Full header line including the header name.
        """
        aid = self._client._to_agent_id(agent_id)

        try:
            status = self.check_compliance(aid)
            compliant = str(status["is_compliant"]).lower()
            level = status.get("highest_compliance_level")
            level_str = str(level) if level is not None else "none"
        except Exception:
            compliant = "false"
            level_str = "none"

        header_value = (
            f"agent={aid}; compliant={compliant}; "
            f"compliance_level={level_str}; type={interaction_type}"
        )
        return f"X-AI-Disclosure: {header_value}"

    def self_check(self, agent_id: int) -> Dict[str, Any]:
        """
        Run a self-check and return a compliance report with recommendations.

        Args:
            agent_id: uint256 agent identifier (int).

        Returns:
            dict with keys:
                - agent_id (int)
                - checks (list of dicts with 'item', 'passed', 'detail')
                - overall_compliant (bool)
                - recommendations (list of str)
        """
        aid = self._client._to_agent_id(agent_id)
        checks = []
        recommendations = []

        # 1. Check agent registration
        try:
            agent_info = self._client.get_agent(aid)
            checks.append({
                "item": "Agent registered",
                "passed": agent_info.active,
                "detail": f"Owner: {agent_info.owner}, Wallet: {agent_info.agent_wallet}",
            })
            if not agent_info.active:
                recommendations.append(
                    "Agent is registered but currently inactive."
                )
        except Exception as e:
            checks.append({
                "item": "Agent registered",
                "passed": False,
                "detail": str(e),
            })
            recommendations.append(
                "Register your agent on-chain using client.register_agent()."
            )

        # 2. Check agent attestations
        try:
            attestation_ids = self._client.get_agent_attestation_ids(aid)
            checks.append({
                "item": "Attestations",
                "passed": len(attestation_ids) > 0,
                "detail": f"{len(attestation_ids)} attestation(s) found",
            })
            if len(attestation_ids) == 0:
                recommendations.append(
                    "No attestations found. Request an attestation from a verifier."
                )
        except Exception as e:
            checks.append({
                "item": "Attestations",
                "passed": False,
                "detail": str(e),
            })
            recommendations.append(
                "Unable to query attestations. Ensure AgentPassport contract is accessible."
            )

        # 3. Check compliance certificates
        compliance = self.check_compliance(aid)
        checks.append({
            "item": "Compliance certificate",
            "passed": compliance["is_compliant"],
            "detail": (
                f"{len(compliance['certificates'])} certificate(s), "
                f"compliant={compliance['is_compliant']}, "
                f"highest_level={compliance['highest_compliance_level']}"
            ),
        })
        if not compliance["is_compliant"]:
            recommendations.append(
                "No valid compliance certificate found. "
                "Request a certificate from a scorer with SCORER_ROLE."
            )

        # 4. Check risk score
        risk_score = compliance.get("latest_risk_score")
        if risk_score is not None:
            risk_ok = risk_score <= 50
            checks.append({
                "item": "Risk score",
                "passed": risk_ok,
                "detail": f"Risk score: {risk_score}/255",
            })
            if not risk_ok:
                recommendations.append(
                    f"Risk score is {risk_score}/255. "
                    "Consider reducing risk by providing more evidence."
                )

        overall = all(c["passed"] for c in checks)

        return {
            "agent_id": aid,
            "checks": checks,
            "overall_compliant": overall,
            "recommendations": recommendations,
        }
