"""
Agent Passport Python SDK V2.0
AI Agent compliance proof system for EU AI Act Art.50

Usage:
    from agent_passport import AgentPassportClient, passport_guard, set_default_client

    client = AgentPassportClient(rpc_url="https://mainnet.base.org")
    set_default_client(client)
"""
from .core import (
    AgentPassportClient,
    AgentInfo,
    AttestationInfo,
    CertificateInfo,
)
from .guard import passport_guard, set_default_client, get_default_client, ComplianceError
from .compliance import Art50ComplianceChecker
from .delegation import DelegationManager

__version__ = "0.4.0"
__all__ = [
    "AgentPassportClient",
    "AgentInfo",
    "AttestationInfo",
    "CertificateInfo",
    "passport_guard",
    "set_default_client",
    "get_default_client",
    "ComplianceError",
    "Art50ComplianceChecker",
    "DelegationManager",
]
