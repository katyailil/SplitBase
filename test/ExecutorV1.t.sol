// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ExecutorV1} from "../src/ExecutorV1.sol";
import {SplitBaseV1} from "../src/SplitBaseV1.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ExecutorV1Test is Test {
    ExecutorV1 public executor;
    SplitBaseV1 public splitBase;
    MockUSDC public usdc;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public executor1 = address(0x10);
    address public executor2 = address(0x20);
    address public recipient1 = address(0x3);
    address public recipient2 = address(0x4);

    event ExecutionScheduled(uint256 indexed poolId, address indexed executor, uint256 amount, uint256 scheduledAt);
    event ExecutionCompleted(uint256 indexed poolId, uint256 amount, uint256 executedAt);
    event ExecutorAdded(uint256 indexed poolId, address indexed executor);
    event ExecutorRemoved(uint256 indexed poolId, address indexed executor);

    function setUp() public {
        usdc = new MockUSDC();

        SplitBaseV1 splitBaseImpl = new SplitBaseV1();
        ERC1967Proxy splitBaseProxy = new ERC1967Proxy(
            address(splitBaseImpl),
            abi.encodeCall(SplitBaseV1.initialize, (address(usdc)))
        );
        splitBase = SplitBaseV1(address(splitBaseProxy));

        ExecutorV1 executorImpl = new ExecutorV1();
        ERC1967Proxy executorProxy = new ERC1967Proxy(
            address(executorImpl),
            abi.encodeCall(ExecutorV1.initialize, (address(splitBase), address(usdc)))
        );
        executor = ExecutorV1(address(executorProxy));
    }

    function testInitialize() public view {
        assertEq(address(executor.splitBase()), address(splitBase));
        assertEq(address(executor.usdc()), address(usdc));
        assertEq(executor.owner(), owner);
    }

    function testRegisterPool() public {
        uint256 poolId = splitBase.createPool();

        executor.registerPool(poolId);

        assertEq(executor.poolOwners(poolId), owner);
    }

    function testRegisterPoolUnauthorized() public {
        uint256 poolId = splitBase.createPool();

        vm.prank(user1);
        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.registerPool(poolId);
    }

    function testAddExecutor() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);

        vm.expectEmit(true, true, false, false);
        emit ExecutorAdded(poolId, executor1);

        executor.addExecutor(poolId, executor1);

        assertTrue(executor.executors(poolId, executor1));
    }

    function testAddExecutorUnauthorized() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);

        vm.prank(user1);
        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.addExecutor(poolId, executor1);
    }

    function testRemoveExecutor() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);
        executor.addExecutor(poolId, executor1);

        assertTrue(executor.executors(poolId, executor1));

        vm.expectEmit(true, true, false, false);
        emit ExecutorRemoved(poolId, executor1);

        executor.removeExecutor(poolId, executor1);

        assertFalse(executor.executors(poolId, executor1));
    }

    function testExecute() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.addRecipient(poolId, recipient2, 200);

        executor.registerPool(poolId);
        executor.addExecutor(poolId, executor1);

        uint256 amount = 300_000000;
        usdc.mint(executor1, amount);

        vm.startPrank(executor1);
        usdc.approve(address(executor), amount);

        vm.expectEmit(true, false, false, true);
        emit ExecutionCompleted(poolId, amount, block.timestamp);

        executor.execute(poolId, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(recipient1), 100_000000);
        assertEq(usdc.balanceOf(recipient2), 200_000000);
        assertEq(usdc.balanceOf(executor1), 0);
    }

    function testExecuteUnauthorized() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);

        uint256 amount = 100_000000;
        usdc.mint(user1, amount);

        vm.startPrank(user1);
        usdc.approve(address(executor), amount);

        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.execute(poolId, amount);
        vm.stopPrank();
    }

    function testExecuteOwnerCanExecute() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.addRecipient(poolId, recipient2, 200);

        executor.registerPool(poolId);

        uint256 amount = 300_000000;
        usdc.mint(owner, amount);
        usdc.approve(address(executor), amount);

        executor.execute(poolId, amount);

        assertEq(usdc.balanceOf(recipient1), 100_000000);
        assertEq(usdc.balanceOf(recipient2), 200_000000);
    }

    function testScheduleExecution() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);
        executor.addExecutor(poolId, executor1);

        uint256 amount = 100_000000;

        vm.prank(executor1);
        vm.expectEmit(true, true, false, true);
        emit ExecutionScheduled(poolId, executor1, amount, block.timestamp);

        executor.scheduleExecution(poolId, amount);
    }

    function testScheduleExecutionUnauthorized() public {
        uint256 poolId = splitBase.createPool();
        executor.registerPool(poolId);

        uint256 amount = 100_000000;

        vm.prank(user1);
        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.scheduleExecution(poolId, amount);
    }

    function testUpgradeAuthorization() public {
        ExecutorV1 newImplementation = new ExecutorV1();

        executor.upgradeToAndCall(address(newImplementation), "");

        vm.prank(user1);
        vm.expectRevert();
        executor.upgradeToAndCall(address(newImplementation), "");
    }
}
