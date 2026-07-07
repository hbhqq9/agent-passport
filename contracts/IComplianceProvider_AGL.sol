// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IComplianceProvider
 * @notice ERC-8226 Compliance Provider Interface
 * @dev AGL V2 - Compliance-as-a-Service
 *
 * This interface defines the standard methods for on-chain compliance
 * verification of AI agents. Implementations serve as trust anchors
 * that attest to agent compliance with regulatory requirements.
 */
interface IComplianceProvider {
    // ============ Events ============

    /// @notice Emitted when a compliance check is performed
    event ComplianceChecked(
        address indexed principal,
        bool compliant,
        string reason
    );

    /// @notice Emitted when compliance status is updated
    event ComplianceUpdated(
        address indexed principal,
        uint8 status,
        uint256 expiry,
        address indexed updater
    );

    /// @notice Emitted when compliance is revoked
    event ComplianceRevoked(
        address indexed principal,
        string reason,
        address indexed revokedBy
    );

    /// @notice Emitted when an audit entry is recorded
    event AuditRecorded(
        address indexed principal,
        bytes32 checkHash,
        uint8 decision,
        bytes32 indexed auditHash
    );

    // ============ View Functions ============

    /**
     * @notice Check compliance status for a principal (agent)
     * @param principal The address of the agent to check
     * @param mandate Optional authorization credential bytes
     * @return compliant Whether the agent is compliant
     * @return reason Human-readable reason code/message
     */
    function checkCompliance(
        address principal,
        bytes calldata mandate
    ) external view returns (bool compliant, string memory reason);

    /**
     * @notice Get compliance proof data for a principal
     * @param principal The address of the agent
     * @return proof ABI-encoded compliance proof containing status, expiry, and audit hash
     */
    function getComplianceProof(
        address principal
    ) external view returns (bytes memory proof);

    // ============ State-Changing Functions ============

    /**
     * @notice Update compliance status for a principal
     * @param principal The address of the agent
     * @param status Compliance status code (0=Unknown, 1=Compliant, 2=NonCompliant, 3=Revoked)
     * @param expiry Expiration timestamp (0 = no expiry)
     */
    function updateComplianceStatus(
        address principal,
        uint8 status,
        uint256 expiry
    ) external;

    /**
     * @notice Revoke compliance for a principal
     * @param principal The address of the agent
     * @param reason Human-readable revocation reason
     */
    function revokeCompliance(
        address principal,
        string calldata reason
    ) external;

    /**
     * @notice Record an audit entry in the HMAC audit chain
     * @param principal The address of the audited agent
     * @param checkHash Hash of the compliance check data
     * @param decision Decision code
     * @param data Additional audit data
     */
    function recordAudit(
        address principal,
        bytes32 checkHash,
        uint8 decision,
        bytes calldata data
    ) external;
}
