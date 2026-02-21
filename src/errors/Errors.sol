// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/// @title Errors
/// @notice Defines custom error messages for the verifiable credential NFT system

library Errors {
    /// @notice Error thrown when a caller is not the protocol admin
    error NotProtocolAdmin();

    /// @notice Error thrown when an issuer is not authorized
    error NotAuthorizedIssuer();

    /// @notice Error thrown when an invalid issuer registry address is provided
    error InvalidIssuerRegistryAddress();

    /// @notice Error thrown when an invalid address or zero address is provided
    error InvalidAddress();

    /// @notice Error thrown when an invalid credential hash is provided
    error InvalidCredentialHash();

    /// @notice Error thrown when a credential does not exist
    error CredentialDoesNotExist();

    /// @notice Error thrown when a credential is already revoked
    error CredentialAlreadyRevoked();

    /// @notice Error thrown when a non-issuer attempts to revoke a credential
    error OnlyIssuerCanRevoke();

    /// @notice Error thrown when someone tries to transfer a non-transferable credential
    error CredentialIsNotTransferable();

    /// @notice Error thrown when an issuer already exists
    error IssuerAlreadyExists();

    /// @notice Error thrown when authorization is already revoked
    error AuthorizationAlreadyRevoked();
}
