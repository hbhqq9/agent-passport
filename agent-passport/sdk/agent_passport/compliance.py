"""
Art50ComplianceChecker - Art.50 compliance checking and disclosure generation.

Provides higher-level compliance utilities built on top of AgentPassportClient.
"""
from typing import Any, Dict

from .core import AgentPassportClient


class Art50ComplianceChecker:
    """
    Art.50 compliance checker for AI agent interactions.

    Args:
        client: An initialised AgentPassportClient instance.
    """

    def __init__(self, client: AgentPassportClient) -> None:
        self._client = client

    def check_compliance(self, agent_id) -> Dict[str, Any]:
        """
        Return the full Art.50 compliance status for an agent.

        Args:
            agent_id: bytes32 agent identifier (or hex string).

        Returns:
            dict with keys:
                - art50_compliant (bool)
                - risk_score (int)
                - disclosure_level (str)
                - last_audit (int)
                - agent_id (str)
        """
        status = self._client.get_compliance_status(agent_id)
        aid_str = agent_id.hex() if isinstance(agent_id, bytes) else str(agent_id)
        return {
            "agent_id": aid_str,
            "art50_compliant": status.art50_compliant,
            "risk_score": status.risk_score,
            "disclosure_level": status.disclosure_level,
            "last_audit": status.last_audit,
        }

    def generate_disclosure_header(self, agent_id, interaction_type: str = "chat") -> str:
        """
        Generate an HTTP response header string for Art.50 disclosure.

        The header format follows:
            X-AI-Disclosure: agent={agent_id}; compliant={true|false}; scope=art50; type={interaction_type}

        Args:
            agent_id:         bytes32 agent identifier (or hex string).
            interaction_type: Type of interaction ("chat", "voice", "email", etc.).

        Returns:
            Full header line including the header name.
        """
        aid_str = agent_id.hex() if isinstance(agent_id, bytes) else str(agent_id)
        if aid_str.startswith("0x"):
            aid_short = aid_str[:10] + "..."
        else:
            aid_short = aid_str[:10] + "..." if len(aid_str) > 10 else aid_str

        try:
            status = self._client.get_compliance_status(agent_id)
            compliant = str(status.art50_compliant).lower()
        except Exception:
            compliant = "false"

        header_value = (
            f"agent={aid_str}; compliant={compliant}; scope=art50; type={interaction_type}"
        )
        return f"X-AI-Disclosure: {header_value}"

    def self_check(self, agent_id) -> Dict[str, Any]:
        """
        Run a self-check and return a compliance report with recommendations.

        Args:
            agent_id: bytes32 agent identifier (or hex string).

        Returns:
            dict with keys:
                - checks (list of dicts with 'item', 'passed', 'detail')
                - overall_compliant (bool)
                - recommendations (list of str)
        """
        aid_str = agent_id.hex() if isinstance(agent_id, bytes) else str(agent_id)
        checks = []
        recommendations = []

        # 1. Check agent registration
        try:
            agent_info = self._client.get_agent(agent_id)
            registered = True
            checks.append({"item": "Agent registered", "passed": True, "detail": f"Name: {agent_info.name}"})
            if not agent_info.active:
                recommendations.append("Agent is registered but inactive. Reactivate to maintain compliance.")
        except Exception as e:
            registered = False
            checks.append({"item": "Agent registered", "passed": False, "detail": str(e)})
            recommendations.append("Register your agent on-chain using client.register_agent().")

        # 2. Check Art.50 attestation
        try:
            has_art50 = self._client.verify_agent(agent_id, "art50")
            checks.append({"item": "Art.50 attestation", "passed": has_art50, "detail": ""})
            if not has_art50:
                recommendations.append("Obtain an Art.50 attestation via client.issue_attestation(agent_id, 'art50', evidence_uri).")
        except Exception as e:
            has_art50 = False
            checks.append({"item": "Art.50 attestation", "passed": False, "detail": str(e)})
            recommendations.append("Obtain an Art.50 attestation via client.issue_attestation(agent_id, 'art50', evidence_uri).")

        # 3. Check general scope
        try:
            has_general = self._client.verify_agent(agent_id, "general")
            checks.append({"item": "General scope attestation", "passed": has_general, "detail": ""})
            if not has_general:
                recommendations.append("Consider adding a 'general' scope attestation for broader compatibility.")
        except Exception as e:
            has_general = False
            checks.append({"item": "General scope attestation", "passed": False, "detail": str(e)})

        # 4. Compliance status
        try:
            compliance = self._client.get_compliance_status(agent_id)
            checks.append({
                "item": "Compliance status",
                "passed": compliance.art50_compliant,
                "detail": f"Risk score: {compliance.risk_score}, Level: {compliance.disclosure_level}",
            })
            if compliance.risk_score > 50:
                recommendations.append(
                    f"Risk score is {compliance.risk_score}/100. Consider reducing risk by adding more attestations."
                )
            if compliance.last_audit == 0:
                recommendations.append("No audit has been recorded. Schedule a compliance audit.")
        except Exception as e:
            checks.append({"item": "Compliance status", "passed": False, "detail": str(e)})
            recommendations.append("Ensure the CompliancePassport contract is accessible.")

        overall = all(c["passed"] for c in checks)

        return {
            "agent_id": aid_str,
            "checks": checks,
            "overall_compliant": overall,
            "recommendations": recommendations,
        }
