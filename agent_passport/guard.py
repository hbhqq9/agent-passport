"""
@passport_guard decorator - Enforce Art.50 compliance at the function level.

Usage:
    @passport_guard(required_scope="data_access")
    def handle_request(agent_id, query):
        ...
"""
import functools
from typing import Optional

from .core import AgentPassportClient


# ── Exception ──────────────────────────────────────────────────────────────────

class ComplianceError(Exception):
    """Raised when an agent fails compliance verification."""
    pass


# ── Global default client ──────────────────────────────────────────────────────

_default_client: Optional[AgentPassportClient] = None


def set_default_client(client: AgentPassportClient) -> None:
    """
    Set a global default AgentPassportClient for the @passport_guard decorator.

    Args:
        client: An initialised AgentPassportClient instance.
    """
    global _default_client
    _default_client = client


def get_default_client() -> Optional[AgentPassportClient]:
    """Return the currently configured default client (may be None)."""
    return _default_client


# ── Decorator ──────────────────────────────────────────────────────────────────

def passport_guard(required_scope: str = "general", client: Optional[AgentPassportClient] = None):
    """
    Decorator that enforces Agent Passport compliance before executing the wrapped function.

    Args:
        required_scope: The attestation scope the agent must hold (default: "general").
        client:         Optional explicit AgentPassportClient. Falls back to the global default.

    Raises:
        ComplianceError: If the agent lacks the required attestation or no client is configured.
    """

    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Extract agent_id from kwargs or first positional arg
            agent_id = kwargs.get("agent_id") or (args[0] if args else None)
            if not agent_id:
                raise ComplianceError("agent_id is required as the first argument or as a keyword argument.")

            c = client or _default_client
            if not c:
                raise ComplianceError(
                    "No AgentPassportClient configured. "
                    "Either pass client= to @passport_guard or call set_default_client() first."
                )

            if not c.verify_agent(agent_id, required_scope):
                raise ComplianceError(
                    f"Agent {agent_id!r} lacks required attestation scope: {required_scope!r}. "
                    "Compliance verification failed - request blocked."
                )

            return func(*args, **kwargs)

        return wrapper

    return decorator
