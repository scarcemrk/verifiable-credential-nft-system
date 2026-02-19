// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/// @title Credential NFT Storage
/// @notice Storage layout for the CredentialNFT contract.
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

abstract contract CredentialNFTStorage {
    /// @notice Address of the issuer registry contract.
    /// @dev Reference to the IssuerRegistry contract used to validate authorized issuers.
    ///      Must be set during initialization and should point to a contract implementing IIssuerRegistry.
    ///      Used to verify issuer authorization before minting credentials.
    address internal _issuerRegistry;

    /// @notice Counter for generating unique token IDs.
    /// @dev Monotonically increasing counter used to assign unique IDs to newly minted credentials.
    ///      Starts at 0 and increments with each new credential issuance.
    ///      Ensures each credential has a globally unique identifier within this contract.
    uint256 internal _tokenIdCounter;

    /// @notice Mapping of token IDs to their credential document hashes.
    /// @dev Maps each tokenId to the hash of its associated off-chain credential document.
    ///      The hash is set once at minting and is immutable thereafter.
    ///      Returns bytes32(0) for non-existent tokens.
    mapping(uint256 => bytes32) internal _credentialHash;

    /// @notice Mapping of token IDs to the address that issued them.
    /// @dev Maps each tokenId to the address of the issuer who minted the credential.
    ///      The issuer address is permanently bound at minting time.
    ///      Only the original issuer can revoke their issued credentials.
    mapping(uint256 => address) internal _credentialIssuer;

    /// @notice Mapping of token IDs to their revocation status.
    /// @dev Maps each tokenId to a boolean indicating whether the credential has been revoked.
    ///      True means the credential is revoked and no longer valid.
    ///      Revocation is irreversible once set to true.
    mapping(uint256 => bool) internal _revoked;

    /// @notice Address of the protocol administrator.
    /// @dev Address with elevated privileges for contract management and upgrades.
    ///      Should be protected by access control mechanisms in the implementation.
    ///      Responsible for protocol-level configuration and maintenance.
    address internal _protocolAdmin;

    /// @notice Reserved storage gap for future upgrades.
    /// @dev Storage gap of 50 slots to allow adding new state variables in future upgrades.
    ///      This prevents storage collisions when inheriting contracts add new variables.
    uint256[50] private __gap;
}
