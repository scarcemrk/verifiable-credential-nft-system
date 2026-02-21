// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IIssuerRegistry} from "./interfaces/IIssuerRegistry.sol";
// import {IErrors} from "./interfaces/IErrors.sol";
import {Errors} from "./errors/Errors.sol";
import {IssuerRegistryStorage} from "./storage/IssuerRegistryStorage.sol";

/// @title IssuerRegistry
/// @author Karan Bharda (scarcemrk)
/// @notice Manages the registry of authorized credential issuers in the verifiable credential NFT system
/// @dev This contract uses UUPS proxy pattern for upgradeability and maintains a mapping of authorized issuers

contract IssuerRegistry is Initializable, UUPSUpgradeable, IssuerRegistryStorage, IIssuerRegistry {
    /// @notice Restricts function calls to the protocol administrator
    /// @dev Reverts if the caller is not the protocol admin
    modifier onlyProtocolAdmin() {
        require(msg.sender == _protocolAdmin, Errors.NotProtocolAdmin());
        _;
    }

    /// @notice Initializes the contract (disables direct initialization)
    /// @dev Constructor disables initializers to prevent initialization of the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the IssuerRegistry with an admin address
    /// @dev Can only be called once due to the initializer modifier
    /// @param admin_ The address of the protocol administrator
    function initialize(address admin_) external initializer {
        require(admin_ != address(0), Errors.InvalidAddress());
        _protocolAdmin = admin_;
    }

    /// @notice Registers a new authorized issuer
    /// @dev Only callable by the protocol admin. Prevents duplicate issuer registrations.
    /// @param _issuer The address of the issuer to be added to the authorized registry
    function addIssuer(address _issuer) external override onlyProtocolAdmin {
        require(_issuer != address(0), Errors.InvalidAddress());
        require(!_authorizedIssuer[_issuer], Errors.IssuerAlreadyExists());
        _authorizedIssuer[_issuer] = true;
        emit IssuerAdded(_issuer);
    }

    /// @notice Removes an authorized issuer from the registry
    /// @dev Only callable by the protocol admin. Reverts if the issuer is not currently authorized.
    /// @param _issuer The address of the issuer to be removed from the authorized registry
    function removeIssuer(address _issuer) external override onlyProtocolAdmin {
        require(_authorizedIssuer[_issuer], Errors.NotAuthorizedIssuer());
        _authorizedIssuer[_issuer] = false;
        emit IssuerRemoved(_issuer);
    }

    /// @notice Checks if an address is an authorized issuer
    /// @dev Read-only function that queries the issuer authorization status
    /// @param _issuer The address of the issuer to be validated
    /// @return bool True if the issuer is authorized, false otherwise
    function isAuthorizedIssuer(address _issuer) external view override returns (bool) {
        return _authorizedIssuer[_issuer];
    }

    /// @notice Authorizes an upgrade to a new implementation contract
    /// @dev Internal function called by the UUPS proxy pattern during upgrades
    /// @param newImplementation The address of the new implementation contract to upgrade to
    function _authorizeUpgrade(address newImplementation) internal override onlyProtocolAdmin {}
}
