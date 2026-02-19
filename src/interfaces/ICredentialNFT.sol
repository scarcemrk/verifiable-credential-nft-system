// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

/// @title Verifiable Credential NFT Interface
/// @notice External interface for a non-transferable, hash-anchored verifiable credential system.
/// @dev
/// - Credentials are ERC721-based but non-transferable.
/// - Credential validity is independent of token ownership.
/// - Revocation is irreversible.
/// - Upgrade and admin functions are intentionally excluded from this interface.
interface ICredentialNFT {
    /// @notice Emitted when a new credential is issued.
    /// @dev
    /// - Emitted exactly once per credential.
    /// - `credentialHash` must uniquely represent the off-chain credential document.
    /// - The issuer is implicitly msg.sender in the implementation.
    /// @param issuer Address of the issuer.
    /// @param recipient Address receiving the credential.
    /// @param tokenId Unique identifier assigned to the credential.
    /// @param credentialHash Hash of the off-chain credential document.
    event CredentialIssued(
        address indexed issuer, address indexed recipient, uint256 indexed tokenId, bytes32 credentialHash
    );

    /// @notice Emitted when a credential is revoked.
    /// @dev
    /// - Revocation is final and cannot be undone.
    /// - Revocation does not burn the token.
    /// - The issuer is responsible for providing a reason.
    /// @param tokenId Unique identifier of the credential.
    /// @param reason Human-readable explanation for revocation.
    event CredentialRevoked(uint256 indexed tokenId, string reason);

    /// @notice Issues a new credential to a recipient.
    /// @dev
    /// - Must only be callable by an authorized issuer.
    /// - `credentialHash` must be non-zero.
    /// - The credential becomes permanently bound to the issuing address.
    /// - The credential cannot be transferred after minting.
    /// @param recipient Address that will receive the credential.
    /// @param credentialHash Hash of the off-chain credential document.
    /// @return tokenId The unique identifier assigned to the newly minted credential.
    function mintCredential(address recipient, bytes32 credentialHash) external returns (uint256 tokenId);

    /// @notice Revokes an existing credential.
    /// @dev
    /// - Only the original issuing address may revoke.
    /// - Revocation is irreversible.
    /// - Does not affect token ownership.
    /// @param tokenId Unique identifier of the credential.
    /// @param reason Human-readable explanation for revocation.
    function revokeCredential(uint256 tokenId, string calldata reason) external;

    /// @notice Returns whether a credential is currently valid.
    /// @dev
    /// - Implementations MUST NOT revert for non-existent tokenIds.
    /// - Returns false if the credential has been revoked.
    /// @param tokenId Unique identifier of the credential.
    /// @return True if the credential exists and is not revoked.
    function isValid(uint256 tokenId) external view returns (bool);

    /// @notice Returns the hash of the credential document.
    /// @dev
    /// - Hash is immutable once set.
    /// - Returns zero if credential does not exist.
    /// @param tokenId Unique identifier of the credential.
    /// @return The credential document hash.
    function getCredentialHash(uint256 tokenId) external view returns (bytes32);

    /// @notice Returns the issuing address of a credential.
    /// @dev
    /// - Issuer is permanently bound at issuance.
    /// - Returns zero address if credential does not exist.
    /// @param tokenId Unique identifier of the credential.
    /// @return Address that issued the credential.
    function getIssuer(uint256 tokenId) external view returns (address);
}
