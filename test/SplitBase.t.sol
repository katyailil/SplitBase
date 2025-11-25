// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SplitBase} from "../src/legacy/SplitBase.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
}

contract SplitBaseTest is Test {
    SplitBase public splitBase;
    MockERC20 public usdc;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    function setUp() public {
        usdc = new MockERC20();
        splitBase = new SplitBase(address(usdc));
    }

    function testCreatePool() public {
        vm.prank(alice);
        uint256 poolId = splitBase.createPool();
        assertEq(poolId, 1);

        SplitBase.Pool memory pool = splitBase.getPool(poolId);
        assertEq(pool.owner, alice);
        assertEq(pool.totalShares, 0);
        assertEq(pool.recipientCount, 0);
        assertTrue(pool.active);
    }

    function testAddRecipient() public {
        vm.startPrank(alice);
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, bob, 5000);
        vm.stopPrank();

        SplitBase.Recipient memory recipient = splitBase.getRecipient(poolId, bob);
        assertEq(recipient.account, bob);
        assertEq(recipient.shares, 5000);
        assertTrue(recipient.active);
    }

    function testUpdateRecipient() public {
        vm.startPrank(alice);
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, bob, 5000);
        splitBase.updateRecipient(poolId, bob, 7500);
        vm.stopPrank();

        SplitBase.Recipient memory recipient = splitBase.getRecipient(poolId, bob);
        assertEq(recipient.shares, 7500);
    }

    function testRemoveRecipient() public {
        vm.startPrank(alice);
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, bob, 5000);
        splitBase.removeRecipient(poolId, bob);
        vm.stopPrank();

        SplitBase.Recipient memory recipient = splitBase.getRecipient(poolId, bob);
        assertFalse(recipient.active);
    }

    function testExecutePayout() public {
        vm.startPrank(alice);
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, bob, 5000);
        splitBase.addRecipient(poolId, charlie, 5000);
        vm.stopPrank();

        usdc.mint(alice, 10000);
        vm.prank(alice);
        usdc.approve(address(splitBase), 10000);

        vm.prank(alice);
        splitBase.executePayout(poolId, 10000);

        assertEq(usdc.balanceOf(bob), 5000);
        assertEq(usdc.balanceOf(charlie), 5000);
    }

    function testUnauthorizedAccess() public {
        vm.prank(alice);
        uint256 poolId = splitBase.createPool();

        vm.prank(bob);
        vm.expectRevert(SplitBase.Unauthorized.selector);
        splitBase.addRecipient(poolId, charlie, 5000);
    }
}
