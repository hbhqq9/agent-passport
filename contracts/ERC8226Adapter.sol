// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title ERC8226Adapter
 * @notice ERC-8226官方接口适配器 - Base主网部署版本
 * @dev 解决AGL ComplianceEngine与ERC-8226标准接口不兼容问题
 */
contract ERC8226Adapter {
    // ERC-8226 IComplianceProvider接口
    enum ReasonCode {
        COMPLIANT, KYC_EXPIRED, AML_FLAG, NOT_ACCREDITED,
        NOT_QUALIFIED, JURISDICTION_BLOCKED, IDENTITY_NOT_FOUND,
        ATTESTATION_REVOKED, OTHER
    }

    event PrincipalGranted(address indexed principal, bytes32 indexed identityRef);
    event PrincipalRevoked(address indexed principal, bytes32 indexed identityRef, ReasonCode reason);

    // AGL ComplianceEngine地址
    address public immutable complianceEngine;
    
    // Owner
    address public owner;
    
    // 映射
    mapping(address => bytes32) private _identityRefs;
    mapping(address => uint48) private _expiries;
    mapping(address => bool) private _revoked;
    mapping(address => ReasonCode) private _revokeReasons;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _engine) {
        require(_engine != address(0), "Engine is zero");
        complianceEngine = _engine;
        owner = msg.sender;
    }

    function grantPrincipal(address principal, bytes32 identityRef, uint48 expiresAt) external onlyOwner {
        require(identityRef != bytes32(0), "Zero identity");
        _identityRefs[principal] = identityRef;
        _expiries[principal] = expiresAt;
        _revoked[principal] = false;
        
        // 调用AGL引擎
        (bool success, ) = complianceEngine.call(
            abi.encodeWithSignature("updateComplianceStatus(address,uint8,uint256)", principal, 1, uint256(expiresAt))
        );
        require(success, "Engine call failed");
        
        emit PrincipalGranted(principal, identityRef);
    }

    function revokePrincipal(address principal, ReasonCode reason) external onlyOwner {
        require(_identityRefs[principal] != bytes32(0), "Not active");
        require(!_revoked[principal], "Already revoked");
        
        _revoked[principal] = true;
        _revokeReasons[principal] = reason;
        
        string memory reasonStr = "REVOKED";
        (bool success, ) = complianceEngine.call(
            abi.encodeWithSignature("revokeCompliance(address,string)", principal, reasonStr)
        );
        require(success, "Engine call failed");
        
        emit PrincipalRevoked(principal, _identityRefs[principal], reason);
    }

    function checkPrincipal(address principal, bytes32 identityRef) external view returns (bool, ReasonCode, uint48) {
        if (_identityRefs[principal] == bytes32(0)) return (false, ReasonCode.IDENTITY_NOT_FOUND, 0);
        if (_revoked[principal]) return (false, _revokeReasons[principal], 0);
        if (_identityRefs[principal] != identityRef) return (false, ReasonCode.IDENTITY_NOT_FOUND, 0);
        
        uint48 expiresAt = _expiries[principal];
        if (expiresAt != 0 && block.timestamp > uint256(expiresAt)) return (false, ReasonCode.KYC_EXPIRED, expiresAt);
        
        // 调用AGL引擎检查
        (bool success, bytes memory data) = complianceEngine.staticcall(
            abi.encodeWithSignature("checkCompliance(address,bytes)", principal, "")
        );
        
        if (!success) return (false, ReasonCode.OTHER, expiresAt);
        (bool compliant, ) = abi.decode(data, (bool, string));
        
        return compliant ? (true, ReasonCode.COMPLIANT, expiresAt) : (false, ReasonCode.OTHER, expiresAt);
    }

    // ERC165支持
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165
               interfaceId == type(IERC8226).interfaceId;
    }

    function getPrincipalInfo(address principal) external view returns (bytes32, uint48, bool, ReasonCode) {
        return (_identityRefs[principal], _expiries[principal], _revoked[principal], _revokeReasons[principal]);
    }
}

interface IERC8226 {
    function grantPrincipal(address, bytes32, uint48) external;
    function revokePrincipal(address, uint8) external;
    function checkPrincipal(address, bytes32) external view returns (bool, uint8, uint48);
}
