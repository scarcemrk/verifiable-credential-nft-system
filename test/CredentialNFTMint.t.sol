// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {CredentialNFTBase} from "./base/CredentialNFTBase.t.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title CredentialNFTMint
/// @notice Test suite for CredentialNFT minting functionality
/// @dev Comprehensive tests for the minting mechanism of the CredentialNFT contract,
///      covering authorization, storage, validation, and error cases
contract CredentialNFTMint is CredentialNFTBase {
    /// @notice Emitted when a credential is successfully issued
    /// @param issuer The address of the authorized issuer
    /// @param recipient The address receiving the credential NFT
    /// @param tokenId The unique identifier of the minted token
    /// @param credentialHash The hash representing the credential data
    event CredentialIssued(
        address indexed issuer, address indexed recipient, uint256 indexed tokenId, bytes32 credentialHash
    );

    /// @notice Verifies that an authorized issuer can successfully mint a credential
    /// @dev Validates that the minting process correctly:
    ///      - Emits the CredentialIssued event with proper parameters
    ///      - Stores the issuer address
    ///      - Transfers ownership to the holder
    ///      - Assigns the correct token ID
    ///      - Stores the credential hash
    ///      - Marks the credential as valid
    function test__AuthorizedMint() public {
        vm.prank(issuer);
        bytes32 _credentialhash = keccak256("This is the test NFT1 hash");

        vm.expectEmit(true, true, true, true);
        emit CredentialIssued(issuer, holder, 1, _credentialhash);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        assertEq(nft.getIssuer(tokenId), issuer);
        assertEq(nft.ownerOf(tokenId), holder);
        assertEq(tokenId, 1);
        assertEq(nft.getCredentialHash(tokenId), _credentialhash);
        assertTrue(nft.isValid(tokenId));
    }

    /// @notice Verifies that the issuer address is correctly stored during minting
    /// @dev Ensures the issuer mapping maintains the correct relationship between token and issuer
    function test__MintStoresCorrectIssuer() public {
        vm.prank(issuer);
        bytes32 _credentialhash = keccak256("This is the test NFT1 hash");

        uint256 tokenId = nft.mintCredential(holder, _credentialhash);
        assertEq(nft.getIssuer(tokenId), issuer);
    }

    /// @notice Verifies that token IDs increment sequentially with each new mint
    /// @dev Ensures proper counter management for unique token identification
    function test__TokenIdIncrements() public {
        vm.startPrank(issuer);

        bytes32 _credentialhash1 = keccak256("This is the test NFT1 hash");
        uint256 tokenId1 = nft.mintCredential(holder, _credentialhash1);
        assertEq(tokenId1, 1);

        bytes32 _credentialhash2 = keccak256("This is the test NFT2 hash");
        uint256 tokenId2 = nft.mintCredential(holder, _credentialhash2);
        assertEq(tokenId2, 2);

        vm.stopPrank();
    }

    /// @notice Verifies that the credential hash is correctly stored during minting
    /// @dev Ensures credential data integrity and proper hash mapping
    function test__MintStoresCorrectHash() public {
        vm.prank(issuer);
        bytes32 _credentialhash = keccak256("This is the test NFT1 hash");

        uint256 tokenId = nft.mintCredential(holder, _credentialhash);
        assertEq(nft.getCredentialHash(tokenId), _credentialhash);
    }

    /// @notice Verifies that minting reverts when called by an unauthorized account
    /// @dev Ensures proper access control by rejecting non-issuer callers
    function test__RevertIfNotIssuer() public {
        vm.prank(attacker);
        bytes32 _credentialhash = keccak256("This is the test NFT1 hash");

        vm.expectRevert(Errors.NotAuthorizedIssuer.selector);
        nft.mintCredential(holder, _credentialhash);
    }

    /// @notice Verifies that minting reverts when the recipient is the zero address
    /// @dev Ensures proper input validation to prevent NFT transfers to invalid addresses
    function test__RevertIfZeroRecipient() public {
        vm.prank(issuer);
        bytes32 _credentialhash = keccak256("This is the test NFT1 hash");

        vm.expectRevert(Errors.InvalidAddress.selector);
        nft.mintCredential(address(0), _credentialhash);
    }

    /// @notice Verifies that minting reverts when the credential hash is zero
    /// @dev Ensures proper input validation to prevent empty credentials
    function test__RevertIfZeroHash() public {
        vm.prank(issuer);
        bytes32 _credentialhash = bytes32(0);

        vm.expectRevert(Errors.InvalidCredentialHash.selector);
        nft.mintCredential(holder, _credentialhash);
    }

    /// @notice Verifies that multiple distinct credentials can be minted for a single holder
    /// @dev Ensures the system supports multiple credentials per recipient without conflicts
    function test__MintAllowsMultipleForSameHolder() public {
        vm.startPrank(issuer);

        uint256 tokenId1 = nft.mintCredential(holder, keccak256("NFT1"));
        uint256 tokenId2 = nft.mintCredential(holder, keccak256("NFT2"));
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);

        vm.stopPrank();
    }
}
