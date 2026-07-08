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

def passport_guard(required_scope: int = 0, client: Optional[AgentPassportClient] = None):
    """
    Decorator that enforces Agent Passport compliance before executing the wrapped function.

    In V2, compliance is verified by checking that the agent has at least one
    valid, non-revoked attestation matching the required attribute_type.

    Args:
        required_scope: The attribute_type (uint8) the agent must hold (default: 0 = any).
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
                raise ComplianceError(
                    "agent_id is required as the first argument or as a keyword argument."
                )

            c = client or _default_client
            if not c:
                raise ComplianceError(
                    "No AgentPassportClient configured. "
                    "Either pass client= to @passport_guard or call set_default_client() first."
                )

            aid = c._to_agent_id(agent_id)

            # Check that the agent is registered and active
            try:
                agent_info = c.get_agent(aid)
                if not agent_info.active:
                    raise ComplianceError(
                        f"Agent {aid} is registered but inactive."
                    )
            except ComplianceError:
                raise
            except Exception as e:
                raise ComplianceError(
                    f"Agent {aid} is not registered or unreachable: {e}"
                )

            # Check attestations
            try:
                attestation_ids = c.get_agent_attestation_ids(aid)
                if not attestation_ids:
                    raise ComplianceError(
                        f"Agent {aid} has no attestations."
                    )

                # If a specific attribute_type is required, check for it
                if required_scope is not None and required_scope != 0:
                    found = False
                    for att_id in attestation_ids:
                        try:
                            att = c.get_attestation(att_id)
                            if att.attribute_type == required_scope and not att.revoked:
                                found = True
                                break
                        except Exception:
                            continue
                    if not found:
                        raise ComplianceError(
                            f"Agent {aid} lacks required attestation "
                            f"attribute_type={required_scope}."
                        )
            except ComplianceError:
                raise
            except Exception as e:
                raise ComplianceError(
                    f"Compliance verification failed for agent {aid}: {e}"
                )

            return func(*args, **kwargs)

        return wrapper

    return decorator
