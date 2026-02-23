// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {CredentialNFTBase} from "./base/CredentialNFTBase.t.sol";
import {CredentialNFT} from "../src/CredentialNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title CredentialNFTInit
/// @notice Test suite for CredentialNFT initialization
/// @dev This contract contains unit tests that verify the initialization behavior of the CredentialNFT contract,
///      including valid initialization parameters and error handling for invalid inputs
contract CredentialNFTInit is CredentialNFTBase {
    /// @notice Verifies that the initialize function correctly sets the NFT name and symbol
    /// @dev Asserts that name returns "Cred NFT" and symbol returns "CNFT"
    function test__InitializeSetsNameAndSymbol() public view {
        assertEq(nft.name(), "Cred NFT");
        assertEq(nft.symbol(), "CNFT");
    }

    /// @notice Verifies that calling initialize twice reverts
    /// @dev Ensures the contract prevents re-initialization via the Initializable pattern
    function test__DoubleInitializeCheck_Revert() public {
        vm.expectRevert();
        nft.initialize("New NFT", "CNFT", address(registry), admin);
    }

    /// @notice Verifies that initialization with a zero address as registry reverts with the correct error
    /// @dev Tests that InvalidIssuerRegistryAddress error is raised when registry parameter is address(0)
    function test__ZeroAddressRegistry_Revert() public {
        CredentialNFT implementation = new CredentialNFT();

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidIssuerRegistryAddress.selector));
        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(CredentialNFT.initialize.selector, "Cred NFT", "CNFT", address(0), admin)
        );
    }

    /// @notice Verifies that initialization with a zero address as admin reverts with the correct error
    /// @dev Tests that InvalidAddress error is raised when admin parameter is address(0)
    function test__ZeroAddressAdmin_Revert() public {
        CredentialNFT implementation = new CredentialNFT();

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector));
        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(CredentialNFT.initialize.selector, "Cred NFT", "CNFT", address(registry), address(0))
        );
    }
}
