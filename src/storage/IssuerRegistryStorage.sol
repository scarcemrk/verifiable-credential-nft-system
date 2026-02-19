// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/// @title Issuer Registry Storage
/// @notice Storage layout for the IssuerRegistry contract.
/// @dev
/// -----------------------------------------------------------------------
/// STORAGE LAYOUT RULES
/// -----------------------------------------------------------------------
/// - Append-only storage.
/// - Do not reorder variables.
/// - Do not change variable types.
/// - Do not remove variables.
/// - Add new variables before the storage gap.
/// -----------------------------------------------------------------------

abstract contract IssuerRegistryStorage {
    /// @notice Address of the protocol admin.
    /// @dev Used to manage protocol-level settings and permissions.
    ///      This address has the authority to add and remove issuers from the registry.
    ///      Access control MUST be enforced in the implementation.
    address internal _protocolAdmin;

    /// @notice Mapping of addresses to their issuer authorization status.
    /// @dev Maps issuer addresses to a boolean indicating whether they are authorized.
    ///      True means the address is authorized to issue credentials.
    ///      False or unmapped addresses are not authorized.
    mapping(address => bool) internal _authorizedIssuer;

    /// @notice Reserved storage gap for future upgrades.
    /// @dev Storage gap of 50 slots to allow adding new state variables in future upgrades.
    ///      This prevents storage collisions when inheriting contracts add new variables.
    uint256[50] private __gap;
}
