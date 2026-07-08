"""
Unit tests for Agent Passport SDK core components.
"""
import pytest
from unittest.mock import MagicMock, patch
from dataclasses import dataclass


# ── Data Class Tests ───────────────────────────────────────────────────────────

class TestAgentInfo:
    def test_create_agent_info(self):
        from agent_passport.core import AgentInfo
        info = AgentInfo(
            name="TestAgent",
            operator="0x1234567890abcdef1234567890abcdef12345678",
            active=True,
            metadata_uri="https://example.com/meta.json",
            registered_at=1700000000,
        )
        assert info.name == "TestAgent"
        assert info.active is True
        assert info.registered_at == 1700000000

    def test_agent_info_defaults(self):
        from agent_passport.core import AgentInfo
        info = AgentInfo(name="A", operator="0x0", active=False, metadata_uri="", registered_at=0)
        assert info.metadata_uri == ""
        assert info.registered_at == 0


class TestAttestationInfo:
    def test_create_attestation_info(self):
        from agent_passport.core import AttestationInfo
        info = AttestationInfo(
            agent_id=b"\x00" * 32,
            scope="art50",
            evidence_uri="https://evidence.example.com/1",
            issuer="0xabc",
            issued_at=1700000000,
            revoked=False,
        )
        assert info.scope == "art50"
        assert info.revoked is False
        assert len(info.agent_id) == 32


class TestComplianceInfo:
    def test_create_compliance_info(self):
        from agent_passport.core import ComplianceInfo
        info = ComplianceInfo(
            art50_compliant=True,
            risk_score=25,
            disclosure_level="standard",
            last_audit=1700000000,
        )
        assert info.art50_compliant is True
        assert info.risk_score == 25
        assert info.disclosure_level == "standard"


# ── Guard / Decorator Tests ───────────────────────────────────────────────────

class TestPassportGuard:
    def test_compliance_error_importable(self):
        from agent_passport.guard import ComplianceError
        assert issubclass(ComplianceError, Exception)

    def test_set_default_client(self):
        from agent_passport.guard import set_default_client, get_default_client
        mock_client = MagicMock()
        set_default_client(mock_client)
        assert get_default_client() is mock_client
        # Reset
        set_default_client(None)

    def test_guard_raises_without_agent_id(self):
        from agent_passport.guard import passport_guard, ComplianceError, set_default_client
        mock_client = MagicMock()
        set_default_client(mock_client)

        @passport_guard(required_scope="general")
        def handler(agent_id, query):
            return "ok"

        # Should raise when called without agent_id via kwargs and empty args
        # But since agent_id is first arg, passing None should trigger the error
        with pytest.raises(ComplianceError, match="agent_id is required"):
            handler()  # no args at all

    def test_guard_raises_without_client(self):
        from agent_passport.guard import passport_guard, ComplianceError, set_default_client
        set_default_client(None)

        @passport_guard(required_scope="general")
        def handler(agent_id):
            return "ok"

        with pytest.raises(ComplianceError, match="No AgentPassportClient"):
            handler("some_agent_id")

    def test_guard_calls_verify_agent(self):
        from agent_passport.guard import passport_guard, ComplianceError, set_default_client
        mock_client = MagicMock()
        mock_client.verify_agent.return_value = True
        set_default_client(mock_client)

        @passport_guard(required_scope="data_access")
        def handler(agent_id, data=None):
            return f"processed {agent_id}"

        result = handler("agent_123", data="test")
        assert result == "processed agent_123"
        mock_client.verify_agent.assert_called_once_with("agent_123", "data_access")

    def test_guard_blocks_non_compliant_agent(self):
        from agent_passport.guard import passport_guard, ComplianceError, set_default_client
        mock_client = MagicMock()
        mock_client.verify_agent.return_value = False
        set_default_client(mock_client)

        @passport_guard(required_scope="art50")
        def handler(agent_id):
            return "should not reach"

        with pytest.raises(ComplianceError, match="lacks required attestation scope"):
            handler("agent_456")

    def test_guard_with_explicit_client(self):
        from agent_passport.guard import passport_guard, ComplianceError, set_default_client
        set_default_client(None)  # No global default

        explicit_client = MagicMock()
        explicit_client.verify_agent.return_value = True

        @passport_guard(required_scope="general", client=explicit_client)
        def handler(agent_id):
            return "ok"

        result = handler("agent_789")
        assert result == "ok"
        explicit_client.verify_agent.assert_called_once()


# ── Module Import Tests ───────────────────────────────────────────────────────

class TestImports:
    def test_version(self):
        from agent_passport import __version__
        assert __version__ == "0.1.0"

    def test_all_exports(self):
        import agent_passport
        expected = [
            "AgentPassportClient",
            "AgentInfo",
            "AttestationInfo",
            "ComplianceInfo",
            "passport_guard",
            "set_default_client",
            "ComplianceError",
            "Art50ComplianceChecker",
            "DelegationManager",
        ]
        for name in expected:
            assert hasattr(agent_passport, name), f"Missing export: {name}"


# ── Agent ID Normalization Tests ──────────────────────────────────────────────

class TestAgentIdNormalization:
    def test_bytes_passthrough(self):
        from agent_passport.core import AgentPassportClient
        raw = b"\xab" * 32
        result = AgentPassportClient._to_agent_id(raw)
        assert result == raw

    def test_bytes_padding(self):
        from agent_passport.core import AgentPassportClient
        raw = b"\x01\x02"
        result = AgentPassportClient._to_agent_id(raw)
        assert len(result) == 32
        assert result[-1] == 0x02

    def test_hex_string(self):
        from agent_passport.core import AgentPassportClient
        hex_str = "0x" + "ab" * 4
        result = AgentPassportClient._to_agent_id(hex_str)
        assert len(result) == 32

    def test_utf8_string(self):
        from agent_passport.core import AgentPassportClient
        result = AgentPassportClient._to_agent_id("myagent")
        assert len(result) == 32
        assert result.endswith(b"myagent")

    def test_invalid_type_raises(self):
        from agent_passport.core import AgentPassportClient
        with pytest.raises(TypeError):
            AgentPassportClient._to_agent_id(12345)
