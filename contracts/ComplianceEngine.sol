// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IComplianceProvider} from "./IComplianceProvider.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ComplianceEngine
 * @notice ERC-8226 IComplianceProvider implementation for AGL V2
 * @dev UUPS upgradeable, role-based access control, HMAC audit chain
 *
 * Core features:
 * - IComplianceProvider full interface implementation
 * - UUPS proxy pattern for upgradeability
 * - Role-based access: ORACLE / COMPLIANCE_OFFICER / EMERGENCY
 * - HMAC chain-based audit logging for tamper-proof records
 * - Pausable for emergency response
 * - ReentrancyGuard on state-changing functions
 */
contract ComplianceEngine is
    Initializable,
    IComplianceProvider,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuard,
    PausableUpgradeable
{
    // ============ Constants ============

    /// @notice Role identifier for oracle services (compliance check backend)
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /// @notice Role identifier for compliance officers (audit recording)
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    /// @notice Role identifier for emergency operations (pause, revoke)
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /// @notice Compliance status: Unknown
    uint8 public constant STATUS_UNKNOWN = 0;
    /// @notice Compliance status: Compliant
    uint8 public constant STATUS_COMPLIANT = 1;
    /// @notice Compliance status: Non-Compliant
    uint8 public constant STATUS_NON_COMPLIANT = 2;
    /// @notice Compliance status: Revoked
    uint8 public constant STATUS_REVOKED = 3;

    /// @notice Maximum allowed length for reason strings
    uint256 public constant MAX_REASON_LENGTH = 256;

    // ============ Structs ============

    /// @notice Per-principal compliance record
    struct ComplianceRecord {
        uint8 status;          // 0=Unknown, 1=Compliant, 2=NonCompliant, 3=Revoked
        uint256 updatedAt;     // Last update timestamp
        uint256 expiry;        // Expiration timestamp (0=no expiry)
        address updatedBy;     // Last updater address
        string revokeReason;   // Revocation reason (only when status=3)
    }

    /// @notice Single entry in the HMAC audit chain
    struct AuditEntry {
        address principal;     // Audited agent address
        uint256 timestamp;     // Audit timestamp
        bytes32 checkHash;     // Hash of check data
        bytes32 prevHash;      // Previous entry hash (chain link)
        uint8 decision;        // Decision code
        bytes data;            // Additional audit data
    }

    // ============ Custom Errors ============

    error InvalidPrincipal();
    error InvalidStatus(uint8 status);
    error ExpiryInPast(uint256 expiry);
    error ReasonTooLong(uint256 length);
    error ComplianceRecordNotFound(address principal);
    error AuditIndexOutOfBounds(uint256 index, uint256 count);
    error RoleConflict(address account);
    error MissingRevokeRole(address account);

    // ============ State Variables ============

    /// @notice Compliance records mapping (principal => record)
    mapping(address => ComplianceRecord) private _complianceRecords;

    /// @notice Ordered array of audit entries (the HMAC chain)
    AuditEntry[] private _auditChain;

    /// @notice Hash of the latest audit entry (chain tip)
    bytes32 private _latestAuditHash;

    /// @notice Total number of compliance checks performed
    uint256 private _totalChecks;

    /// @notice Total number of audit entries recorded
    uint256 private _totalAudits;

    // ============ Initialization ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract (called once via proxy)
     * @param admin The DEFAULT_ADMIN_ROLE holder (should be Gnosis Safe)
     * @param oracle The ORACLE_ROLE holder (compliance backend service)
     * @param officer The COMPLIANCE_OFFICER_ROLE holder (audit officer)
     * @param emergency The EMERGENCY_ROLE holder (emergency responder)
     */
    function initialize(
        address admin,
        address oracle,
        address officer,
        address emergency
    ) external initializer {
        // Validate addresses
        require(admin != address(0), "Admin is zero address");
        require(oracle != address(0), "Oracle is zero address");
        require(officer != address(0), "Officer is zero address");
        require(emergency != address(0), "Emergency is zero address");

        // Ensure no role conflicts (all 6 pairwise checks)
        require(admin != oracle, "Admin cannot be oracle");
        require(admin != officer, "Admin cannot be officer");
        require(admin != emergency, "Admin cannot be emergency");
        require(oracle != officer, "Oracle cannot be officer");
        require(oracle != emergency, "Oracle cannot be emergency");
        require(officer != emergency, "Officer cannot be emergency");

        // Initialize parent contracts
        __AccessControl_init();
        __Pausable_init();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ROLE, oracle);
        _grantRole(COMPLIANCE_OFFICER_ROLE, officer);
        _grantRole(EMERGENCY_ROLE, emergency);
    }

    // ============ View Functions ============

    /**
     * @notice Check compliance status for a principal
     * @dev Gas target: < 50K. Pure read, no state changes.
     * @param principal The agent address to check
     * @param mandate Optional authorization bytes (reserved for future use)
     * @return compliant Whether the agent passes compliance
     * @return reason Human-readable status description
     */
    function checkCompliance(
        address principal,
        bytes calldata mandate
    ) external view override returns (bool compliant, string memory reason) {
        if (principal == address(0)) revert InvalidPrincipal();

        // mandate parameter is reserved for future authorization checks
        // Silence unused variable warning
        mandate;

        ComplianceRecord storage record = _complianceRecords[principal];

        // No record found = unknown status
        if (record.updatedAt == 0) {
            return (false, "UNKNOWN: No compliance record");
        }

        // Check expiry
        if (record.expiry != 0 && block.timestamp > record.expiry) {
            return (false, "EXPIRED: Compliance record expired");
        }

        // Return status
        if (record.status == STATUS_COMPLIANT) {
            return (true, "COMPLIANT");
        } else if (record.status == STATUS_NON_COMPLIANT) {
            return (false, "NON_COMPLIANT");
        } else if (record.status == STATUS_REVOKED) {
            return (false, string(abi.encodePacked("REVOKED: ", record.revokeReason)));
        } else {
            return (false, "UNKNOWN");
        }
    }

    /**
     * @notice Get compliance proof data for a principal
     * @param principal The agent address
     * @return proof ABI-encoded proof: (status, updatedAt, expiry, updatedBy, latestAuditHash)
     */
    function getComplianceProof(
        address principal
    ) external view override returns (bytes memory proof) {
        if (principal == address(0)) revert InvalidPrincipal();

        ComplianceRecord storage record = _complianceRecords[principal];

        return abi.encode(
            record.status,
            record.updatedAt,
            record.expiry,
            record.updatedBy,
            _latestAuditHash
        );
    }

    /**
     * @notice Get a specific compliance record
     * @param principal The agent address
     * @return The compliance record struct
     */
    function getComplianceRecord(
        address principal
    ) external view returns (ComplianceRecord memory) {
        return _complianceRecords[principal];
    }

    /**
     * @notice Get an audit entry by index
     * @param index The index in the audit chain
     * @return The audit entry struct
     */
    function getAuditEntry(
        uint256 index
    ) external view returns (AuditEntry memory) {
        if (index >= _auditChain.length) {
            revert AuditIndexOutOfBounds(index, _auditChain.length);
        }
        return _auditChain[index];
    }

    /**
     * @notice Get the total number of audit entries
     * @return The audit chain length
     */
    function getAuditCount() external view returns (uint256) {
        return _auditChain.length;
    }

    /**
     * @notice Get the latest audit hash (chain tip)
     * @return The latest audit entry hash
     */
    function getLatestAuditHash() external view returns (bytes32) {
        return _latestAuditHash;
    }

    /**
     * @notice Get total compliance checks performed
     * @return The total check count
     */
    function getTotalChecks() external view returns (uint256) {
        return _totalChecks;
    }

    /**
     * @notice Get total audits recorded
     * @return The total audit count
     */
    function getTotalAudits() external view returns (uint256) {
        return _totalAudits;
    }

    // ============ State-Changing Functions ============

    /**
     * @notice Update compliance status for a principal
     * @dev Requires ORACLE_ROLE. Records audit entry automatically.
     * @param principal The agent address
     * @param status Status code (0-3)
     * @param expiry Expiration timestamp (0=no expiry)
     */
    function updateComplianceStatus(
        address principal,
        uint8 status,
        uint256 expiry
    ) external override onlyRole(ORACLE_ROLE) whenNotPaused nonReentrant {
        // Input validation
        if (principal == address(0)) revert InvalidPrincipal();
        if (status > STATUS_REVOKED) revert InvalidStatus(status);
        if (expiry != 0 && expiry < block.timestamp) revert ExpiryInPast(expiry);

        // Effects: update record
        ComplianceRecord storage record = _complianceRecords[principal];
        record.status = status;
        record.updatedAt = block.timestamp;
        record.expiry = expiry;
        record.updatedBy = msg.sender;

        // If not a revoke, clear the revoke reason
        if (status != STATUS_REVOKED) {
            record.revokeReason = "";
        }

        // Interaction: emit event
        emit ComplianceUpdated(principal, status, expiry, msg.sender);

        // Auto-record audit
        bytes32 checkHash = keccak256(
            abi.encodePacked(principal, status, expiry, block.timestamp)
        );
        _recordAuditEntry(principal, checkHash, status, abi.encode(expiry));
    }

    /**
     * @notice Revoke compliance for a principal
     * @dev Requires ORACLE_ROLE or EMERGENCY_ROLE
     * @param principal The agent address
     * @param reason Human-readable revocation reason
     */
    function revokeCompliance(
        address principal,
        string calldata reason
    ) external override whenNotPaused nonReentrant {
        // Check role: ORACLE or EMERGENCY
        if (
            !hasRole(ORACLE_ROLE, msg.sender) &&
            !hasRole(EMERGENCY_ROLE, msg.sender)
        ) {
            revert MissingRevokeRole(msg.sender);
        }

        // Input validation
        if (principal == address(0)) revert InvalidPrincipal();
        if (bytes(reason).length > MAX_REASON_LENGTH) {
            revert ReasonTooLong(bytes(reason).length);
        }

        // Effects: update record
        ComplianceRecord storage record = _complianceRecords[principal];
        record.status = STATUS_REVOKED;
        record.updatedAt = block.timestamp;
        record.updatedBy = msg.sender;
        record.revokeReason = reason;

        // Interaction: emit event
        emit ComplianceRevoked(principal, reason, msg.sender);

        // Auto-record audit
        bytes32 checkHash = keccak256(
            abi.encodePacked(principal, STATUS_REVOKED, reason, block.timestamp)
        );
        _recordAuditEntry(principal, checkHash, STATUS_REVOKED, bytes(reason));
    }

    /**
     * @notice Record an audit entry in the HMAC audit chain
     * @dev Requires COMPLIANCE_OFFICER_ROLE
     * @param principal The audited agent address
     * @param checkHash Hash of the compliance check data
     * @param decision Decision code
     * @param data Additional audit data
     */
    function recordAudit(
        address principal,
        bytes32 checkHash,
        uint8 decision,
        bytes calldata data
    ) external override onlyRole(COMPLIANCE_OFFICER_ROLE) whenNotPaused nonReentrant {
        if (principal == address(0)) revert InvalidPrincipal();

        _recordAuditEntry(principal, checkHash, decision, data);
    }

    // ============ Emergency Functions ============

    /**
     * @notice Pause the contract (emergency)
     * @dev Only EMERGENCY_ROLE. View functions remain accessible.
     */
    function pause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpause the contract
     * @dev Only EMERGENCY_ROLE.
     */
    function unpause() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ============ Internal Functions ============

    /**
     * @dev Internal function to record an audit entry with HMAC chain linkage
     */
    function _recordAuditEntry(
        address principal,
        bytes32 checkHash,
        uint8 decision,
        bytes memory data
    ) internal {
        bytes32 prevHash = _latestAuditHash;

        // Calculate entry hash (HMAC chain)
        bytes32 entryHash = keccak256(
            abi.encodePacked(
                principal,
                block.timestamp,
                checkHash,
                prevHash,
                decision,
                data
            )
        );

        // Store audit entry
        _auditChain.push(
            AuditEntry({
                principal: principal,
                timestamp: block.timestamp,
                checkHash: checkHash,
                prevHash: prevHash,
                decision: decision,
                data: data
            })
        );

        // Update chain tip
        _latestAuditHash = entryHash;
        _totalAudits++;

        // Emit event
        emit AuditRecorded(principal, checkHash, decision, entryHash);
    }

    /**
     * @dev Authorize upgrade - requires DEFAULT_ADMIN_ROLE
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        // newImplementation intentionally unused - authorization is role-based
        newImplementation;
    }

    /**
     * @dev Convert address to hex string for error messages
     */
    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes20 value = bytes20(addr);
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    // ============ Additional Events ============

    event ContractPaused(address account);
    event ContractUnpaused(address account);

    // ============ Reserved Storage Gap (for future upgrades) ============

    /// @dev Reserved storage slots for future variable additions
    uint256[40] private __gap;
}
