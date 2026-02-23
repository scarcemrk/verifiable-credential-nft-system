// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {CredentialNFTBase} from "./base/CredentialNFTBase.t.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title CredentialNFTRevoke
/// @notice Test suite for CredentialNFT revocation functionality
/// @dev Comprehensive tests for both standard and emergency revocation mechanisms
contract CredentialNFTRevoke is CredentialNFTBase {
    /// @notice Emitted when a credential is revoked by the issuer
    event CredentialRevoked(uint256 indexed tokenId, string reason);

    /// @notice Emitted when a credential is revoked by the protocol admin
    event CredentialEmergencyRevoked(uint256 indexed tokenId, string reason);

    /// @dev Secondary issuer address used for testing authorization scenarios
    address internal issuer2;

    /// @notice Sets up test fixtures with multiple issuers
    /// @dev Calls parent setUp and registers a second issuer for authorization tests
    function setUp() public override {
        super.setUp();
        issuer2 = makeAddr("issuer2");
        vm.prank(admin);
        registry.addIssuer(issuer2);
    }

    // ============ revokeCredential Tests ============

    /// @notice Verifies that an authorized issuer can successfully revoke a credential
    function test__IssuerCanRevokeSuccessfully() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.startPrank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);
        vm.expectEmit(true, false, false, true);
        emit CredentialRevoked(tokenId, "Revoked for testing");
        nft.revokeCredential(tokenId, "Revoked for testing");
        vm.stopPrank();

        assertFalse(nft.isValid(tokenId));
    }

    /// @notice Verifies that revoking the same credential twice fails
    function test__RevertIfRevokeTwice() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.startPrank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);
        nft.revokeCredential(tokenId, "Revoked for testing");

        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialAlreadyRevoked.selector));
        nft.revokeCredential(tokenId, "Revoked for testing");
        vm.stopPrank();
    }

    /// @notice Verifies that only the credential's issuer can revoke it
    function test__RevertIfNonIssuerTriesToRevoke() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.prank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        vm.prank(issuer2);
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyIssuerCanRevoke.selector));
        nft.revokeCredential(tokenId, "Revoked for testing");
    }

    /// @notice Verifies that revoking a non-existent token ID fails
    function test__RevertIfRevokeNonExistentCredential() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialDoesNotExist.selector));
        nft.revokeCredential(999, "Revoked for testing");
    }

    /// @notice Verifies that a revoked issuer retains ability to revoke their own credentials
    function test__RemovedIssuerCanStillRevoke() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.prank(issuer2);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        vm.prank(admin);
        registry.removeIssuer(issuer2);

        vm.prank(issuer2);
        nft.revokeCredential(tokenId, "Revoked for testing");

        assertFalse(nft.isValid(tokenId));
    }

    /// @notice Verifies that revocation does not transfer token ownership
    function test__RevokeDoesNotChangeOwnership() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.startPrank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);
        nft.revokeCredential(tokenId, "Revoked for testing");
        vm.stopPrank();
        assertEq(nft.ownerOf(tokenId), holder);
    }

    // ============ emergencyRevoke Tests ============

    /// @notice Verifies that the protocol admin can emergency revoke any credential
    function test__AdminCanEmergencyRevoke() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.prank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit CredentialEmergencyRevoked(tokenId, "Revoked for testing");
        nft.emergencyRevoke(tokenId, "Revoked for testing");

        assertFalse(nft.isValid(tokenId));
    }

    /// @notice Verifies that non-admin addresses cannot perform emergency revocation
    function test__RevertIfNonAdminEmergencyRevoke() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.prank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        nft.emergencyRevoke(tokenId, "Revoked for testing");
    }

    /// @notice Verifies that emergency revoking the same credential twice fails
    function test__RevertIfEmergencyRevokeTwice() public {
        bytes32 _credentialhash = keccak256("This is the test NFT hash");
        vm.prank(issuer);
        uint256 tokenId = nft.mintCredential(holder, _credentialhash);

        vm.prank(admin);
        nft.emergencyRevoke(tokenId, "Revoked for testing");

        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialAlreadyRevoked.selector));
        vm.prank(admin);
        nft.emergencyRevoke(tokenId, "Revoked for testing");
    }

    /// @notice Verifies that emergency revoking a non-existent token ID fails
    function test__RevertIfEmergencyRevokeNonExistentCredential() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialDoesNotExist.selector));
        vm.prank(admin);
        nft.emergencyRevoke(999, "Revoked for testing");
    }
}
