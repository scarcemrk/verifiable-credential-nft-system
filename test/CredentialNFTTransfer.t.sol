// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {CredentialNFTBase} from "./base/CredentialNFTBase.t.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title CredentialNFTTransfer
/// @notice Comprehensive test suite for CredentialNFT transfer functionality
/// @dev Tests verify that credential NFTs cannot be transferred by any party under various conditions
contract CredentialNFTTransfer is CredentialNFTBase {
    /// @notice Sets up the test environment by minting a credential NFT
    /// @dev Called before each test to initialize a fresh credential for the holder
    function setUp() public override {
        super.setUp();
        vm.prank(issuer);
        nft.mintCredential(holder, keccak256("This is the test NFT hash"));
    }

    /// @notice Verifies that a credential holder cannot transfer their credential
    /// @dev Expects CredentialIsNotTransferable revert when holder attempts transferFrom
    function test__HolderCannotTransfer() public {
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that a credential holder cannot safely transfer their credential
    /// @dev Expects CredentialIsNotTransferable revert when holder attempts safeTransferFrom
    function test__HolderCannotSafeTransfer() public {
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.safeTransferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that a credential holder cannot safely transfer their credential with additional data
    /// @dev Expects CredentialIsNotTransferable revert when holder attempts safeTransferFrom with data parameter
    function test__HolderCannotSafeTransferWithData() public {
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.safeTransferFrom(holder, attacker, 1, bytes(" "));
    }

    /// @notice Verifies that an approved spender cannot transfer a credential on behalf of the holder
    /// @dev First approves attacker, then verifies CredentialIsNotTransferable revert on transfer attempt
    function test__ApprovedAddressCannotTransfer() public {
        vm.prank(holder);
        nft.approve(attacker, 1);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that an approved operator cannot transfer a credential on behalf of the holder
    /// @dev First sets operator approval for all tokens, then verifies CredentialIsNotTransferable revert
    function test__OperatorCannotTransfer() public {
        vm.prank(holder);
        nft.setApprovalForAll(attacker, true);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that the credential issuer cannot transfer a holder's credential
    /// @dev Even with issuer privileges, transfer should be blocked with CredentialIsNotTransferable
    function test__IssuerCannotTransfer() public {
        vm.prank(issuer);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that an admin cannot transfer a holder's credential
    /// @dev Even with admin privileges, transfer should be blocked with CredentialIsNotTransferable
    function test__AdminCannotTransfer() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that a revoked credential cannot be transferred
    /// @dev After revocation by issuer, any transfer attempt should revert with CredentialIsNotTransferable
    function test__RevokedTokenCannotBeTransferred() public {
        vm.prank(issuer);
        nft.revokeCredential(1, "Revoke for test");
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(Errors.CredentialIsNotTransferable.selector));
        nft.transferFrom(holder, attacker, 1);
    }

    /// @notice Verifies that a credential cannot be burned by transferring to zero address
    /// @dev Burning is prevented regardless of transfer restrictions
    function test__HolderCannotBurn() public {
        vm.prank(holder);
        vm.expectRevert();
        nft.transferFrom(holder, address(0), 1);
    }

    /// @notice Verifies that attempting to transfer a non-existent token reverts
    /// @dev Should fail when tokenId does not exist in the contract
    function test__TransferNonExistentTokenReverts() public {
        vm.prank(holder);
        vm.expectRevert();
        nft.transferFrom(holder, attacker, 2);
    }
}
