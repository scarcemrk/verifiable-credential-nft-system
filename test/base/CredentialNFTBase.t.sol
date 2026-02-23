// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {CredentialNFT} from "../../src/CredentialNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IssuerRegistry} from "../../src/IssuerRegistry.sol";
import {Errors} from "../../src/errors/Errors.sol";

/// @notice Base contract for CredentialNFT tests
/// @dev Provides common setup and fixtures for all CredentialNFT test suites
abstract contract CredentialNFTBase is Test {
    /// @notice Test accounts used across test scenarios
    address internal admin;
    address internal issuer;
    address internal holder;
    address internal holder2;
    address internal attacker;

    /// @notice Proxy instances of the main contracts under test
    IssuerRegistry internal registry;
    CredentialNFT internal nft;

    /// @notice Implementation contracts deployed behind proxies
    IssuerRegistry internal implementationRegistry;
    CredentialNFT internal implementationNFT;

    /// @notice ERC1967 proxy wrappers for upgradeable contracts
    ERC1967Proxy internal proxyRegistry;
    ERC1967Proxy internal proxyNFT;

    /// @notice Sets up the test environment with proxy contracts and test addresses
    /// @dev Initializes all test accounts, deploys implementation contracts, and wraps them
    /// in ERC1967 proxies. Sets up the issuer registry and adds the issuer account.
    /// This function is virtual to allow derived contracts to extend or override setup behavior.
    function setUp() public virtual {
        // Create test accounts
        admin = makeAddr("admin");
        issuer = makeAddr("issuer");
        holder = makeAddr("holder");
        holder2 = makeAddr("holder2");
        attacker = makeAddr("attacker");

        // Deploy implementation contracts
        implementationRegistry = new IssuerRegistry();
        implementationNFT = new CredentialNFT();

        // Deploy IssuerRegistry behind UUPS proxy and initialize with admin
        proxyRegistry = new ERC1967Proxy(
            address(implementationRegistry), abi.encodeWithSelector(IssuerRegistry.initialize.selector, admin)
        );
        registry = IssuerRegistry(address(proxyRegistry));

        // Register the issuer in the registry
        vm.prank(admin);
        registry.addIssuer(issuer);

        // Deploy CredentialNFT behind UUPS proxy with metadata and registry reference
        proxyNFT = new ERC1967Proxy(
            address(implementationNFT),
            abi.encodeWithSelector(CredentialNFT.initialize.selector, "Cred NFT", "CNFT", address(registry), admin)
        );
        nft = CredentialNFT(address(proxyNFT));
    }
}
