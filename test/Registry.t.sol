// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/legacy/Registry.sol";

contract RegistryTest is Test {
    Registry public registry;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public poolContract = address(0x100);

    function setUp() public {
        registry = new Registry();
    }

    function testRegisterPool() public {
        vm.prank(alice);
        bytes32 registryId = registry.register(poolContract, 1, "Test Pool");

        Registry.PoolInfo memory info = registry.getPool(registryId);
        assertEq(info.poolContract, poolContract);
        assertEq(info.poolId, 1);
        assertEq(info.owner, alice);
        assertEq(info.metadata, "Test Pool");
        assertTrue(info.active);
    }

    function testUpdateMetadata() public {
        vm.startPrank(alice);
        bytes32 registryId = registry.register(poolContract, 1, "Old Metadata");
        registry.updateMetadata(registryId, "New Metadata");
        vm.stopPrank();

        Registry.PoolInfo memory info = registry.getPool(registryId);
        assertEq(info.metadata, "New Metadata");
    }

    function testSetStatus() public {
        vm.startPrank(alice);
        bytes32 registryId = registry.register(poolContract, 1, "Test");
        registry.setStatus(registryId, false);
        vm.stopPrank();

        Registry.PoolInfo memory info = registry.getPool(registryId);
        assertFalse(info.active);
    }

    function testGetOwnerPools() public {
        vm.startPrank(alice);
        bytes32 id1 = registry.register(poolContract, 1, "Pool 1");
        bytes32 id2 = registry.register(poolContract, 2, "Pool 2");
        vm.stopPrank();

        bytes32[] memory pools = registry.getOwnerPools(alice);
        assertEq(pools.length, 2);
        assertEq(pools[0], id1);
        assertEq(pools[1], id2);
    }

    function testGetAllPools() public {
        vm.prank(alice);
        registry.register(poolContract, 1, "Pool 1");
        vm.prank(bob);
        registry.register(poolContract, 2, "Pool 2");

        bytes32[] memory allPools = registry.getAllPools();
        assertEq(allPools.length, 2);
    }
}
