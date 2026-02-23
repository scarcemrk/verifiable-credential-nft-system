// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {CredentialNFT} from "../src/CredentialNFT.sol";
import {CredentialNFTBase} from "./base/CredentialNFTBase.t.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @notice Test suite for CredentialNFT upgrade functionality
/// @dev This test file contains upgrade-related tests for the CredentialNFT contract,
/// verifying that the contract can be safely upgraded while maintaining state and functionality.
/// Tests include validation of proxy upgrades, storage layout preservation, and access control
/// during the upgrade process.
contract CredentialNFTUpgrade is CredentialNFTBase {
    /// @dev Test credential hash used across test cases
    bytes32 _credentialHash = keccak256("test");

    /// @notice Sets up test environment with an initial credential minted
    /// @dev Overrides parent setUp() and mints a credential to the holder before each test
    function setUp() public override {
        super.setUp();
        vm.prank(issuer);
        nft.mintCredential(holder, _credentialHash);
    }

    /// @notice Verifies that an admin can successfully upgrade the contract
    /// @dev Deploys CredentialNFTV2 and upgrades through the proxy, ensuring new version is accessible
    function test__AdminCanUpgrade() public {
        assertTrue(nft.isValid(1));

        CredentialNFTV2 newNFT = new CredentialNFTV2();
        vm.prank(admin);
        nft.upgradeToAndCall(address(newNFT), "");

        CredentialNFTV2 upgraded = CredentialNFTV2(address(nft));
        assertTrue(upgraded.isValid(1));
        assertEq(upgraded.version(), "2.0.0");
    }

    /// @notice Verifies that non-admin accounts cannot upgrade the contract
    /// @dev Expects NotProtocolAdmin revert when attacker attempts upgrade
    function test__RevertIfNonAdminUpgrade() public {
        CredentialNFTV2 newNFT = new CredentialNFTV2();
        vm.prank(attacker);
        vm.expectRevert(Errors.NotProtocolAdmin.selector);
        nft.upgradeToAndCall(address(newNFT), "");
    }

    /// @notice Verifies that contract state is preserved after upgrade
    /// @dev Validates that ownership, issuer, credential hash, and validity persist through upgrade
    function test__StatePersistsAfterUpgrade() public {
        uint256 tokenId = 1;

        assertEq(nft.ownerOf(tokenId), holder);
        assertEq(nft.getIssuer(tokenId), issuer);
        assertEq(nft.getCredentialHash(tokenId), _credentialHash);
        assertTrue(nft.isValid(tokenId));

        CredentialNFTV2 newNFT = new CredentialNFTV2();
        vm.prank(admin);
        nft.upgradeToAndCall(address(newNFT), "");

        CredentialNFTV2 upgraded = CredentialNFTV2(address(nft));

        assertEq(upgraded.ownerOf(tokenId), holder);
        assertEq(upgraded.getIssuer(tokenId), issuer);
        assertEq(upgraded.getCredentialHash(tokenId), _credentialHash);
        assertTrue(upgraded.isValid(tokenId));
    }
}

/// @notice Mock CredentialNFT implementation for testing upgrade functionality
/// @dev Extends CredentialNFT with a version function to demonstrate upgrade capability
contract CredentialNFTV2 is CredentialNFT {
    /// @notice Returns the version of this implementation
    /// @return Version string "2.0.0"
    function version() public pure returns (string memory) {
        return "2.0.0";
    }
}
