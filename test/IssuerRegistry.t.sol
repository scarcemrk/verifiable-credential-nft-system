// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IssuerRegistry} from "../src/IssuerRegistry.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title IssuerRegistryTest
/// @author Karan Bharda (scarcemrk)
/// @notice Test suite for the IssuerRegistry contract
contract IssuerRegistryTest is Test {
    IssuerRegistry registry;
    IssuerRegistry implementation;
    ERC1967Proxy proxy;

    address public admin;
    address public issuer;
    address public attacker;
    address public newAdmin;

    /// @notice Sets up test environment with proxy, implementation, and test addresses
    function setUp() public {
        admin = makeAddr("admin");
        issuer = makeAddr("issuer");
        attacker = makeAddr("attacker");
        implementation = new IssuerRegistry();
        proxy = new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(IssuerRegistry.initialize.selector, admin)
        );
        registry = IssuerRegistry(address(proxy));
    }

    /// @notice Tests admin can successfully add a new issuer
    function test_AddIssuer_AsAdmin_Success() public {
        vm.prank(admin);
        registry.addIssuer(issuer);
        assertTrue(registry.isAuthorizedIssuer(issuer));
    }

    /// @notice Tests adding issuer with zero address reverts
    function test_AddIssuer_ZeroAddress_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector));
        registry.addIssuer(address(0));
    }

    /// @notice Tests adding duplicate issuer reverts
    function test_AddIssuer_Duplicate_Reverts() public {
        vm.startPrank(admin);
        registry.addIssuer(issuer);
        vm.expectRevert(abi.encodeWithSelector(Errors.IssuerAlreadyExists.selector));
        registry.addIssuer(issuer);
    }

    /// @notice Tests non-admin cannot add issuer
    function test_AddIssuer_AsNonAdmin_Reverts() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.addIssuer(issuer);
    }

    /// @notice Tests admin can successfully remove an issuer
    function test_RemoveIssuer_AsAdmin_Success() public {
        vm.startPrank(admin);
        registry.addIssuer(issuer);
        registry.removeIssuer(issuer);
        assertFalse(registry.isAuthorizedIssuer(issuer));
    }

    /// @notice Tests removing non-existent issuer reverts
    function test_RemoveIssuer_NonExistent_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotAuthorizedIssuer.selector));
        registry.removeIssuer(issuer);
    }

    /// @notice Tests non-admin cannot remove issuer
    function test_RemoveIssuer_AsNonAdmin_Reverts() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.removeIssuer(issuer);
    }

    /// @notice Tests isAuthorizedIssuer returns correct status
    function test_IsAuthorizedIssuer_ReturnsCorrectStatus() public {
        vm.prank(admin);
        registry.addIssuer(issuer);
        assertTrue(registry.isAuthorizedIssuer(issuer));
        assertFalse(registry.isAuthorizedIssuer(attacker));
    }

    /// @notice Tests admin can successfully upgrade to new implementation
    function test_UpgradeToAndCall_AsAdmin_Success() public {
        vm.prank(admin);
        registry.addIssuer(issuer);
        IssuerRegistryV2 newImplementation = new IssuerRegistryV2();
        vm.prank(admin);
        registry.upgradeToAndCall(address(newImplementation), "");
        assertTrue(registry.isAuthorizedIssuer(issuer));

        IssuerRegistryV2 upgraded = IssuerRegistryV2(address(registry));
        assertEq(upgraded.version(), "2.0.0");
    }

    /// @notice Tests non-admin cannot upgrade contract
    function test_UpgradeToAndCall_AsNonAdmin_Reverts() public {
        IssuerRegistryV2 newImplementation = new IssuerRegistryV2();
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.upgradeToAndCall(address(newImplementation), "");
    }
}

contract IssuerRegistryV2 is IssuerRegistry {
    function version() public pure returns (string memory) {
        return "2.0.0";
    }
}
