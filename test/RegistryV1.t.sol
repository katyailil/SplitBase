// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {RegistryV1} from "../src/RegistryV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RegistryV1Test is Test {
    RegistryV1 public registry;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public poolContract1 = address(0x10);
    address public poolContract2 = address(0x20);

    event PoolRegistered(bytes32 indexed registryId, address indexed poolContract, uint256 indexed poolId);
    event PoolMetadataUpdated(bytes32 indexed registryId, string metadata);
    event PoolStatusUpdated(bytes32 indexed registryId, bool active);

    function setUp() public {
        RegistryV1 implementation = new RegistryV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(RegistryV1.initialize, ())
        );
        registry = RegistryV1(payable(address(proxy)));
    }

    function testInitialize() public view {
        assertEq(registry.owner(), owner);
        assertEq(registry.getPoolCount(), 0);
    }

    function testRegister() public {
        bytes32 expectedRegistryId = keccak256(abi.encodePacked(poolContract1, uint256(1)));

        vm.expectEmit(true, true, true, false);
        emit PoolRegistered(expectedRegistryId, poolContract1, 1);

        bytes32 registryId = registry.register(poolContract1, 1, "Test Pool");

        assertEq(registryId, expectedRegistryId);

        RegistryV1.PoolInfo memory info = registry.getPool(registryId);
        assertEq(info.poolContract, poolContract1);
        assertEq(info.poolId, 1);
        assertEq(info.owner, owner);
        assertEq(info.metadata, "Test Pool");
        assertTrue(info.active);
        assertGt(info.registeredAt, 0);

        assertEq(registry.getPoolCount(), 1);
    }

    function testRegisterDuplicate() public {
        registry.register(poolContract1, 1, "Test Pool");

        vm.expectRevert(RegistryV1.PoolAlreadyRegistered.selector);
        registry.register(poolContract1, 1, "Duplicate Pool");
    }

    function testUpdateMetadata() public {
        bytes32 registryId = registry.register(poolContract1, 1, "Original Metadata");

        vm.expectEmit(true, false, false, true);
        emit PoolMetadataUpdated(registryId, "Updated Metadata");

        registry.updateMetadata(registryId, "Updated Metadata");

        RegistryV1.PoolInfo memory info = registry.getPool(registryId);
        assertEq(info.metadata, "Updated Metadata");
    }

    function testUpdateMetadataUnauthorized() public {
        bytes32 registryId = registry.register(poolContract1, 1, "Test Pool");

        vm.prank(user1);
        vm.expectRevert(RegistryV1.Unauthorized.selector);
        registry.updateMetadata(registryId, "Unauthorized Update");
    }

    function testSetStatus() public {
        bytes32 registryId = registry.register(poolContract1, 1, "Test Pool");
        assertTrue(registry.getPool(registryId).active);

        vm.expectEmit(true, false, false, true);
        emit PoolStatusUpdated(registryId, false);

        registry.setStatus(registryId, false);
        assertFalse(registry.getPool(registryId).active);

        registry.setStatus(registryId, true);
        assertTrue(registry.getPool(registryId).active);
    }

    function testGetPool() public {
        bytes32 registryId = registry.register(poolContract1, 1, "Test Pool");

        RegistryV1.PoolInfo memory info = registry.getPool(registryId);

        assertEq(info.poolContract, poolContract1);
        assertEq(info.poolId, 1);
        assertEq(info.owner, owner);
        assertEq(info.metadata, "Test Pool");
        assertTrue(info.active);
        assertEq(info.registeredAt, block.timestamp);
    }

    function testGetOwnerPools() public {
        bytes32 id1 = registry.register(poolContract1, 1, "Pool 1");
        bytes32 id2 = registry.register(poolContract1, 2, "Pool 2");

        vm.prank(user1);
        bytes32 id3 = registry.register(poolContract2, 1, "Pool 3");

        bytes32[] memory ownerPools = registry.getOwnerPools(owner);
        assertEq(ownerPools.length, 2);
        assertEq(ownerPools[0], id1);
        assertEq(ownerPools[1], id2);

        bytes32[] memory user1Pools = registry.getOwnerPools(user1);
        assertEq(user1Pools.length, 1);
        assertEq(user1Pools[0], id3);
    }

    function testGetAllPools() public {
        bytes32 id1 = registry.register(poolContract1, 1, "Pool 1");

        vm.prank(user1);
        bytes32 id2 = registry.register(poolContract1, 2, "Pool 2");

        vm.prank(user2);
        bytes32 id3 = registry.register(poolContract2, 1, "Pool 3");

        bytes32[] memory allPools = registry.getAllPools();
        assertEq(allPools.length, 3);
        assertEq(allPools[0], id1);
        assertEq(allPools[1], id2);
        assertEq(allPools[2], id3);
    }

    function testGetPoolCount() public {
        assertEq(registry.getPoolCount(), 0);

        registry.register(poolContract1, 1, "Pool 1");
        assertEq(registry.getPoolCount(), 1);

        vm.prank(user1);
        registry.register(poolContract1, 2, "Pool 2");
        assertEq(registry.getPoolCount(), 2);

        vm.prank(user2);
        registry.register(poolContract2, 1, "Pool 3");
        assertEq(registry.getPoolCount(), 3);
    }

    function testPauseBlocksRegister() public {
        registry.pause();
        vm.expectRevert("Pausable: paused");
        registry.register(poolContract1, 1, "Pool 1");
    }

    function testUpgradeAuthorization() public {
        RegistryV1 newImplementation = new RegistryV1();

        registry.upgradeToAndCall(address(newImplementation), "");

        vm.prank(user1);
        vm.expectRevert();
        registry.upgradeToAndCall(address(newImplementation), "");
    }
}
