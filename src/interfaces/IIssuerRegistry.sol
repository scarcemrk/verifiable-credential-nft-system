// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/// @title Issuer Registry Interface
/// @notice Interface for managing authorized issuers in a verifiable credential system.
/// @dev This interface provides functionality to add and remove issuers who are authorized to mint credentials.
///      Implementations should ensure proper access control to prevent unauthorized modifications.
///      The registry maintains a list of trusted issuer addresses that can interact with the credential system.

interface IIssuerRegistry {
    /// @notice Emitted when a new issuer is added to the registry.
    /// @dev This event should be emitted after successfully adding an issuer.
    ///      Indexed parameter allows efficient filtering of events by issuer address.
    /// @param issuer Address of the newly added issuer.
    event IssuerAdded(address indexed issuer);

    /// @notice Emitted when an issuer is removed from the registry.
    /// @dev This event should be emitted after successfully removing an issuer.
    ///      Indexed parameter allows efficient filtering of events by issuer address.
    ///      Removed issuers should no longer be able to mint new credentials.
    /// @param issuer Address of the removed issuer.
    event IssuerRemoved(address indexed issuer);

    /// @notice Adds a new issuer to the registry.
    /// @dev Implementations should:
    /// - Validate that the issuer address is not zero.
    /// - Ensure the issuer is not already registered.
    /// - Restrict access to authorized administrators only.
    /// - Emit IssuerAdded event upon success.
    /// @param issuer Address of the issuer to be added.
    function addIssuer(address issuer) external;

    /// @notice Removes an issuer from the registry.
    /// @dev Implementations should:
    /// - Validate that the issuer exists in the registry.
    /// - Restrict access to authorized administrators only.
    /// - Emit IssuerRemoved event upon success.
    /// - Removing an issuer affects future issuance only.
    /// @param issuer Address of the issuer to be removed.
    function removeIssuer(address issuer) external;

    /// @notice Checks if an issuer is authorized.
    /// @dev This is a read-only function that queries the registry to verify issuer status.
    /// - Returns false for zero address and for addresses not in the registry.
    /// - This function should be called by the credential contract before allowing minting operations.
    /// @param issuer Address of the issuer to be checked.
    /// @return True if the issuer is authorized, false otherwise.
    function isAuthorizedIssuer(address issuer) external view returns (bool);
}
