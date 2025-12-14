// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SplitBaseV2} from "../src/SplitBaseV2.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ISplitBaseV2} from "../src/interfaces/ISplitBaseV2.sol";
import {Types} from "../src/types/Types.sol";

contract SplitBaseV2Test is Test {
    SplitBaseV2 public splitBase;
    MockUSDC public usdc;

    address public owner = address(this);
    address public teamMember1 = address(0x10);
    address public teamMember2 = address(0x11);
    address public investor1 = address(0x20);
    address public investor2 = address(0x21);
    address public treasury = address(0x30);
    address public referral1 = address(0x40);

    event PoolCreatedV2(
        uint256 indexed poolId,
        address indexed owner,
        string name,
        string description
    );

    event RecipientAddedV2(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 shares,
        Types.BucketType indexed bucket
    );

    event PayoutExecutedV2(
        uint256 indexed poolId,
        uint256 indexed distributionId,
        uint256 totalAmount,
        Types.SourceType indexed source,
        string sourceIdentifier,
        uint256 timestamp
    );

    event BucketPayout(
        uint256 indexed poolId,
        uint256 indexed distributionId,
        Types.BucketType indexed bucket,
        uint256 amount,
        uint256 recipientCount
    );

    function setUp() public {
        usdc = new MockUSDC();

        SplitBaseV2 implementation = new SplitBaseV2();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(implementation.initialize, (address(usdc)))
        );
        splitBase = SplitBaseV2(payable(address(proxy)));
    }

    function testCreatePoolV2() public {
        vm.expectEmit(true, true, false, true);
        emit PoolCreatedV2(1, owner, "DAO Core Revenue", "Main revenue pool for DAO operations");

        uint256 poolId = splitBase.createPoolV2("DAO Core Revenue", "Main revenue pool for DAO operations");

        assertEq(poolId, 1);
        ISplitBaseV2.PoolV2 memory pool = splitBase.getPoolV2(poolId);
        assertEq(pool.owner, owner);
        assertEq(pool.name, "DAO Core Revenue");
        assertEq(pool.description, "Main revenue pool for DAO operations");
        assertEq(pool.totalShares, 0);
        assertEq(pool.recipientCount, 0);
        assertTrue(pool.active);
        assertEq(pool.distributionCount, 0);
    }

    function testAddRecipientV2WithBucket() public {
        uint256 poolId = splitBase.createPoolV2("Test Pool", "Test Description");

        vm.expectEmit(true, true, true, true);
        emit RecipientAddedV2(poolId, teamMember1, 100, Types.BucketType.TEAM);

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);

        ISplitBaseV2.RecipientV2 memory recipient = splitBase.getRecipientV2(poolId, teamMember1);
        assertEq(recipient.account, teamMember1);
        assertEq(recipient.shares, 100);
        assertEq(uint256(recipient.bucket), uint256(Types.BucketType.TEAM));
        assertTrue(recipient.active);
    }

    function testMultipleBuckets() public {
        uint256 poolId = splitBase.createPoolV2("Multi-Bucket Pool", "Pool with multiple bucket types");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, teamMember2, 150, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, investor1, 200, Types.BucketType.INVESTORS);
        splitBase.addRecipientV2(poolId, investor2, 100, Types.BucketType.INVESTORS);
        splitBase.addRecipientV2(poolId, treasury, 300, Types.BucketType.TREASURY);
        splitBase.addRecipientV2(poolId, referral1, 50, Types.BucketType.REFERRALS);

        address[] memory teamRecipients = splitBase.getBucketRecipients(poolId, Types.BucketType.TEAM);
        assertEq(teamRecipients.length, 2);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM), 250);

        address[] memory investorRecipients = splitBase.getBucketRecipients(poolId, Types.BucketType.INVESTORS);
        assertEq(investorRecipients.length, 2);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.INVESTORS), 300);

        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TREASURY), 300);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.REFERRALS), 50);
    }

    function testExecutePayoutV2WithSource() public {
        uint256 poolId = splitBase.createPoolV2("Revenue Pool", "Test pool");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, investor1, 200, Types.BucketType.INVESTORS);
        splitBase.addRecipientV2(poolId, treasury, 300, Types.BucketType.TREASURY);

        uint256 payoutAmount = 600_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        vm.expectEmit(true, true, true, false);
        emit PayoutExecutedV2(
            poolId,
            1,
            payoutAmount,
            Types.SourceType.BASE_PAY,
            "base-pay-tx-0x123",
            block.timestamp
        );

        uint256 distributionId =
            splitBase.executePayoutV2(poolId, payoutAmount, Types.SourceType.BASE_PAY, "base-pay-tx-0x123");

        assertEq(distributionId, 1);

        assertEq(usdc.balanceOf(teamMember1), 100_000000);
        assertEq(usdc.balanceOf(investor1), 200_000000);
        assertEq(usdc.balanceOf(treasury), 300_000000);

        Types.DistributionRecord memory distribution = splitBase.getDistribution(poolId, distributionId);
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.totalAmount, payoutAmount);
        assertEq(uint256(distribution.source), uint256(Types.SourceType.BASE_PAY));
        assertEq(distribution.sourceIdentifier, "base-pay-tx-0x123");
        assertEq(distribution.recipientCount, 3);
    }

    function testBucketPayoutEvents() public {
        uint256 poolId = splitBase.createPoolV2("Event Test Pool", "Test bucket payout events");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, teamMember2, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, investor1, 300, Types.BucketType.INVESTORS);
        splitBase.addRecipientV2(poolId, treasury, 500, Types.BucketType.TREASURY);

        uint256 payoutAmount = 1_000_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        vm.expectEmit(true, true, true, true);
        emit BucketPayout(poolId, 1, Types.BucketType.TEAM, 200_000000, 2);

        vm.expectEmit(true, true, true, true);
        emit BucketPayout(poolId, 1, Types.BucketType.INVESTORS, 300_000000, 1);

        vm.expectEmit(true, true, true, true);
        emit BucketPayout(poolId, 1, Types.BucketType.TREASURY, 500_000000, 1);

        splitBase.executePayoutV2(poolId, payoutAmount, Types.SourceType.PROTOCOL_FEES, "protocol-fees-month-1");
    }

    function testUpdateRecipientV2SameBucket() public {
        uint256 poolId = splitBase.createPoolV2("Update Test", "Test recipient updates");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, teamMember2, 200, Types.BucketType.TEAM);

        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM), 300);

        splitBase.updateRecipientV2(poolId, teamMember1, 150, Types.BucketType.TEAM);

        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM), 350);
        assertEq(splitBase.getRecipientV2(poolId, teamMember1).shares, 150);
    }

    function testUpdateRecipientV2DifferentBucket() public {
        uint256 poolId = splitBase.createPoolV2("Bucket Change Test", "Test bucket changes");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM), 100);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TREASURY), 0);

        splitBase.updateRecipientV2(poolId, teamMember1, 150, Types.BucketType.TREASURY);

        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TEAM), 0);
        assertEq(splitBase.getBucketTotalShares(poolId, Types.BucketType.TREASURY), 150);
        assertEq(uint256(splitBase.getRecipientV2(poolId, teamMember1).bucket), uint256(Types.BucketType.TREASURY));
    }

    function testMultipleDistributions() public {
        uint256 poolId = splitBase.createPoolV2("Multi-Distribution Pool", "Test multiple distributions");

        splitBase.addRecipientV2(poolId, teamMember1, 100, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, investor1, 200, Types.BucketType.INVESTORS);

        uint256 amount1 = 300_000000;
        usdc.mint(owner, amount1);
        usdc.approve(address(splitBase), amount1);
        uint256 dist1 = splitBase.executePayoutV2(poolId, amount1, Types.SourceType.BASE_PAY, "payment-1");

        uint256 amount2 = 600_000000;
        usdc.mint(owner, amount2);
        usdc.approve(address(splitBase), amount2);
        uint256 dist2 = splitBase.executePayoutV2(poolId, amount2, Types.SourceType.PROTOCOL_FEES, "fees-month-1");

        assertEq(dist1, 1);
        assertEq(dist2, 2);

        Types.DistributionRecord memory distribution1 = splitBase.getDistribution(poolId, dist1);
        assertEq(distribution1.totalAmount, amount1);
        assertEq(uint256(distribution1.source), uint256(Types.SourceType.BASE_PAY));
        assertEq(distribution1.sourceIdentifier, "payment-1");

        Types.DistributionRecord memory distribution2 = splitBase.getDistribution(poolId, dist2);
        assertEq(distribution2.totalAmount, amount2);
        assertEq(uint256(distribution2.source), uint256(Types.SourceType.PROTOCOL_FEES));
        assertEq(distribution2.sourceIdentifier, "fees-month-1");

        assertEq(splitBase.getPoolV2(poolId).distributionCount, 2);
    }

    function testBackwardCompatibilityV1Functions() public {
        uint256 poolId = splitBase.createPool();

        splitBase.addRecipient(poolId, teamMember1, 100);
        splitBase.addRecipient(poolId, investor1, 200);

        uint256 payoutAmount = 300_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        splitBase.executePayout(poolId, payoutAmount);

        assertEq(usdc.balanceOf(teamMember1), 100_000000);
        assertEq(usdc.balanceOf(investor1), 200_000000);
    }

    function testMixedV1AndV2Usage() public {
        uint256 poolId = splitBase.createPool();

        splitBase.addRecipient(poolId, teamMember1, 100);
        splitBase.addRecipientV2(poolId, investor1, 200, Types.BucketType.INVESTORS);

        uint256 payoutAmount = 300_000000;
        usdc.mint(owner, payoutAmount);
        usdc.approve(address(splitBase), payoutAmount);

        uint256 distributionId =
            splitBase.executePayoutV2(poolId, payoutAmount, Types.SourceType.GRANTS, "grant-round-1");

        assertEq(usdc.balanceOf(teamMember1), 100_000000);
        assertEq(usdc.balanceOf(investor1), 200_000000);
        assertEq(distributionId, 1);
    }

    function testFuzzPayoutWithBuckets(
        uint256 amount,
        uint256 teamShares,
        uint256 investorShares,
        uint256 treasuryShares
    ) public {
        amount = bound(amount, 1000, 1_000_000_000000);
        teamShares = bound(teamShares, 1, 1_000_000);
        investorShares = bound(investorShares, 1, 1_000_000);
        treasuryShares = bound(treasuryShares, 1, 1_000_000);

        uint256 poolId = splitBase.createPoolV2("Fuzz Pool", "Fuzz test pool");
        splitBase.addRecipientV2(poolId, teamMember1, teamShares, Types.BucketType.TEAM);
        splitBase.addRecipientV2(poolId, investor1, investorShares, Types.BucketType.INVESTORS);
        splitBase.addRecipientV2(poolId, treasury, treasuryShares, Types.BucketType.TREASURY);

        usdc.mint(owner, amount);
        usdc.approve(address(splitBase), amount);

        splitBase.executePayoutV2(poolId, amount, Types.SourceType.OTHER, "fuzz-test");

        uint256 totalShares = teamShares + investorShares + treasuryShares;
        uint256 expectedTeam = (amount * teamShares) / totalShares;
        uint256 expectedInvestor = (amount * investorShares) / totalShares;
        uint256 expectedTreasury = (amount * treasuryShares) / totalShares;

        assertEq(usdc.balanceOf(teamMember1), expectedTeam);
        assertEq(usdc.balanceOf(investor1), expectedInvestor);
        assertEq(usdc.balanceOf(treasury), expectedTreasury);

        assertLe(usdc.balanceOf(teamMember1) + usdc.balanceOf(investor1) + usdc.balanceOf(treasury), amount);
    }
}
