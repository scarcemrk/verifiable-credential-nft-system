// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IssuerRegistry} from "../src/IssuerRegistry.sol";
import {Errors} from "../src/errors/Errors.sol";

/// @title IssuerRegistryTest
/// @author Karan Bharda (scarcemrk)
/// @notice Test suite for the IssuerRegistry contract
/// @dev Uses ERC1967Proxy pattern to test upgradeable contract functionality
contract IssuerRegistryTest is Test {
    // Contract instances
    IssuerRegistry registry; // Proxy instance (main interface)
    IssuerRegistry implementation; // Implementation contract
    ERC1967Proxy proxy; // ERC1967 proxy instance

    // Test addresses
    address public admin; // Protocol admin address
    address public issuer; // Authorized issuer address
    address public attacker; // Unauthorized address for testing access control
    address public newAdmin; // Reserved for future admin tests

    /// @notice Sets up test environment with proxy, implementation, and test addresses
    /// @dev Initializes the IssuerRegistry via proxy with admin as protocol admin
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

    /// @notice Tests that admin can successfully add a new issuer
    /// @dev Verifies issuer is authorized after addition
    function test_AddIssuer_AsAdmin_Success() public {
        vm.prank(admin);
        registry.addIssuer(issuer);
        assertTrue(registry.isAuthorizedIssuer(issuer));
    }

    /// @notice Tests that adding an issuer with zero address reverts
    /// @dev Ensures input validation prevents invalid addresses
    function test_AddIssuer_ZeroAddress_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector));
        registry.addIssuer(address(0));
    }

    /// @notice Tests that adding duplicate issuer reverts
    /// @dev Prevents registering the same issuer twice
    function test_AddIssuer_Duplicate_Reverts() public {
        vm.startPrank(admin);
        registry.addIssuer(issuer);
        vm.expectRevert(abi.encodeWithSelector(Errors.IssuerAlreadyExists.selector));
        registry.addIssuer(issuer);
    }

    /// @notice Tests that non-admin cannot add issuer
    /// @dev Verifies role-based access control on addIssuer function
    function test_AddIssuer_AsNonAdmin_Reverts() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.addIssuer(issuer);
    }

    /// @notice Tests that admin can successfully remove an issuer
    /// @dev Verifies issuer is no longer authorized after removal
    function test_RemoveIssuer_AsAdmin_Success() public {
        vm.startPrank(admin);
        registry.addIssuer(issuer);
        registry.removeIssuer(issuer);
        assertFalse(registry.isAuthorizedIssuer(issuer));
    }

    /// @notice Tests that removing non-existent issuer reverts
    /// @dev Ensures issuer must exist before removal
    function test_RemoveIssuer_NonExistent_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotAuthorizedIssuer.selector));
        registry.removeIssuer(issuer);
    }

    /// @notice Tests that non-admin cannot remove issuer
    /// @dev Verifies role-based access control on removeIssuer function
    function test_RemoveIssuer_AsNonAdmin_Reverts() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.removeIssuer(issuer);
    }

    /// @notice Tests that isAuthorizedIssuer returns correct authorization status
    /// @dev Verifies authorized and unauthorized issuer distinction
    function test_IsAuthorizedIssuer_ReturnsCorrectStatus() public {
        vm.prank(admin);
        registry.addIssuer(issuer);
        assertTrue(registry.isAuthorizedIssuer(issuer));
        assertFalse(registry.isAuthorizedIssuer(attacker));
    }

    /// @notice Tests that admin can successfully upgrade to new implementation
    /// @dev Verifies storage and functionality are preserved across upgrades
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

    /// @notice Tests that non-admin cannot upgrade contract
    /// @dev Verifies role-based access control on upgradeToAndCall function
    function test_UpgradeToAndCall_AsNonAdmin_Reverts() public {
        IssuerRegistryV2 newImplementation = new IssuerRegistryV2();
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotProtocolAdmin.selector));
        registry.upgradeToAndCall(address(newImplementation), "");
    }
}

/// @title IssuerRegistryV2
/// @notice Mock contract simulating an upgraded version of IssuerRegistry
/// @dev Used for testing proxy upgrade functionality
contract IssuerRegistryV2 is IssuerRegistry {
    /// @notice Returns the version of this implementation
    /// @return Version string "2.0.0"
    function version() public pure returns (string memory) {
        return "2.0.0";
    }
}
