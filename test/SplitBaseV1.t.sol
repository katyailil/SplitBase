// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SplitBaseV1} from "../src/SplitBaseV1.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ISplitBase} from "../src/interfaces/ISplitBase.sol";

contract SplitBaseV1Test is Test {
    SplitBaseV1 public splitBase;
    MockUSDC public usdc;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public recipient1 = address(0x3);
    address public recipient2 = address(0x4);
    address public recipient3 = address(0x5);

    event PoolCreated(uint256 indexed poolId, address indexed owner);
    event RecipientAdded(uint256 indexed poolId, address indexed recipient, uint256 shares);
    event RecipientUpdated(uint256 indexed poolId, address indexed recipient, uint256 newShares);
    event RecipientRemoved(uint256 indexed poolId, address indexed recipient);
    event PayoutExecuted(
        uint256 indexed poolId,
        address indexed payer,
        address indexed token,
        uint256 requestedAmount,
        uint256 distributedAmount,
        uint256 recipientCount
    );
    event PoolStatusChanged(uint256 indexed poolId, bool active);

    function setUp() public {
        usdc = new MockUSDC();

        SplitBaseV1 implementation = new SplitBaseV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(SplitBaseV1.initialize, (address(usdc)))
        );
        splitBase = SplitBaseV1(payable(address(proxy)));
    }

    function testInitialize() public view {
        assertEq(address(splitBase.usdc()), address(usdc));
        assertEq(splitBase.owner(), owner);
    }

    function testCreatePool() public {
        vm.expectEmit(true, true, false, true);
        emit PoolCreated(1, owner);

        uint256 poolId = splitBase.createPool();

        assertEq(poolId, 1);
        ISplitBase.Pool memory pool = splitBase.getPool(poolId);
        assertEq(pool.owner, owner);
        assertEq(pool.totalShares, 0);
        assertEq(pool.recipientCount, 0);
        assertTrue(pool.active);
        assertEq(pool.lastExecutionTime, 0);
        assertEq(pool.totalDistributed, 0);
    }

    function testCreateMultiplePools() public {
        uint256 poolId1 = splitBase.createPool();

        vm.prank(user1);
        uint256 poolId2 = splitBase.createPool();

        vm.prank(user2);
        uint256 poolId3 = splitBase.createPool();

        assertEq(poolId1, 1);
        assertEq(poolId2, 2);
        assertEq(poolId3, 3);

        assertEq(splitBase.getPool(poolId1).owner, owner);
        assertEq(splitBase.getPool(poolId2).owner, user1);
        assertEq(splitBase.getPool(poolId3).owner, user2);
    }

    function testAddRecipient() public {
        uint256 poolId = splitBase.createPool();

        vm.expectEmit(true, true, false, true);
        emit RecipientAdded(poolId, recipient1, 100);

        splitBase.addRecipient(poolId, recipient1, 100);

        ISplitBase.Recipient memory r = splitBase.getRecipient(poolId, recipient1);
        assertEq(r.account, recipient1);
        assertEq(r.shares, 100);
        assertTrue(r.active);

        ISplitBase.Pool memory pool = splitBase.getPool(poolId);
        assertEq(pool.totalShares, 100);
        assertEq(pool.recipientCount, 1);
    }

    function testAddRecipientUnauthorized() public {
        uint256 poolId = splitBase.createPool();

        vm.prank(user1);
        vm.expectRevert(SplitBaseV1.Unauthorized.selector);
        splitBase.addRecipient(poolId, recipient1, 100);
    }

    function testAddRecipientZeroAddress() public {
        uint256 poolId = splitBase.createPool();

        vm.expectRevert(SplitBaseV1.InvalidRecipient.selector);
        splitBase.addRecipient(poolId, address(0), 100);
    }

    function testAddRecipientZeroShares() public {
        uint256 poolId = splitBase.createPool();

        vm.expectRevert(SplitBaseV1.InvalidShares.selector);
        splitBase.addRecipient(poolId, recipient1, 0);
    }

    function testAddRecipientDuplicate() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);

        vm.expectRevert(SplitBaseV1.InvalidRecipient.selector);
        splitBase.addRecipient(poolId, recipient1, 200);
    }

    function testUpdateRecipient() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.addRecipient(poolId, recipient2, 200);

        assertEq(splitBase.getPool(poolId).totalShares, 300);

        vm.expectEmit(true, true, false, true);
        emit RecipientUpdated(poolId, recipient1, 150);

        splitBase.updateRecipient(poolId, recipient1, 150);

        assertEq(splitBase.getRecipient(poolId, recipient1).shares, 150);
        assertEq(splitBase.getPool(poolId).totalShares, 350);
    }

    function testUpdateRecipientUnauthorized() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);

        vm.prank(user1);
        vm.expectRevert(SplitBaseV1.Unauthorized.selector);
        splitBase.updateRecipient(poolId, recipient1, 150);
    }

    function testRemoveRecipient() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.addRecipient(poolId, recipient2, 200);

        vm.expectEmit(true, true, false, false);
        emit RecipientRemoved(poolId, recipient1);

        splitBase.removeRecipient(poolId, recipient1);

        ISplitBase.Recipient memory r = splitBase.getRecipient(poolId, recipient1);
        assertFalse(r.active);
        assertEq(splitBase.getPool(poolId).totalShares, 200);
        assertEq(splitBase.getPool(poolId).recipientCount, 1);
    }

    function testExecutePayout() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.addRecipient(poolId, recipient2, 200);
        splitBase.addRecipient(poolId, recipient3, 300);

        uint256 payoutAmount = 600_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        vm.expectEmit(true, true, true, true);
        emit PayoutExecuted(poolId, owner, address(usdc), payoutAmount, payoutAmount, 3);

        uint256 distributed = splitBase.executePayout(poolId, payoutAmount);

        assertEq(usdc.balanceOf(recipient1), 100_000000);
        assertEq(usdc.balanceOf(recipient2), 200_000000);
        assertEq(usdc.balanceOf(recipient3), 300_000000);
        assertEq(distributed, payoutAmount);

        ISplitBase.Pool memory pool = splitBase.getPool(poolId);
        assertGt(pool.lastExecutionTime, 0);
        assertEq(pool.totalDistributed, payoutAmount);
    }

    function testExecutePayoutPrecision() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 333);
        splitBase.addRecipient(poolId, recipient2, 333);
        splitBase.addRecipient(poolId, recipient3, 334);

        uint256 payoutAmount = 1_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        uint256 distributed = splitBase.executePayout(poolId, payoutAmount);

        uint256 r1Balance = usdc.balanceOf(recipient1);
        uint256 r2Balance = usdc.balanceOf(recipient2);
        uint256 r3Balance = usdc.balanceOf(recipient3);

        assertEq(r1Balance, 333000);
        assertEq(r2Balance, 333000);
        assertEq(r3Balance, 334000);

        uint256 totalDistributed = r1Balance + r2Balance + r3Balance;
        assertEq(totalDistributed, 1_000000);
        assertEq(distributed, totalDistributed);
    }

    function testExecutePayoutInactivePool() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);
        splitBase.setPoolStatus(poolId, false);

        uint256 payoutAmount = 100_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        vm.expectRevert(SplitBaseV1.PoolInactive.selector);
        splitBase.executePayout(poolId, payoutAmount);
    }

    function testPauseBlocksPayout() public {
        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, 100);

        uint256 payoutAmount = 100_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        splitBase.pause();

        vm.expectRevert("Pausable: paused");
        splitBase.executePayout(poolId, payoutAmount);
    }

    function testSetPoolStatus() public {
        uint256 poolId = splitBase.createPool();
        assertTrue(splitBase.getPool(poolId).active);

        vm.expectEmit(true, false, false, true);
        emit PoolStatusChanged(poolId, false);

        splitBase.setPoolStatus(poolId, false);
        assertFalse(splitBase.getPool(poolId).active);

        splitBase.setPoolStatus(poolId, true);
        assertTrue(splitBase.getPool(poolId).active);
    }

    function testFuzzPayoutDistribution(uint256 amount, uint256 shares1, uint256 shares2) public {
        amount = bound(amount, 1000, 1_000_000_000000);
        shares1 = bound(shares1, 1, 1_000_000);
        shares2 = bound(shares2, 1, 1_000_000);

        uint256 poolId = splitBase.createPool();
        splitBase.addRecipient(poolId, recipient1, shares1);
        splitBase.addRecipient(poolId, recipient2, shares2);

        usdc.mint(owner, amount);
        usdc.approve(address(splitBase), amount);

        splitBase.executePayout(poolId, amount);

        uint256 r1Balance = usdc.balanceOf(recipient1);
        uint256 r2Balance = usdc.balanceOf(recipient2);

        uint256 expectedR1 = (amount * shares1) / (shares1 + shares2);
        uint256 expectedR2 = (amount * shares2) / (shares1 + shares2);

        assertEq(r1Balance, expectedR1);
        assertEq(r2Balance, expectedR2);
        assertLe(r1Balance + r2Balance, amount);
    }

    function testUpgradeAuthorization() public {
        SplitBaseV1 newImplementation = new SplitBaseV1();

        splitBase.upgradeToAndCall(address(newImplementation), "");

        vm.prank(user1);
        vm.expectRevert();
        splitBase.upgradeToAndCall(address(newImplementation), "");
    }
}
