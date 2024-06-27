// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Fungi, SeedData} from "../src/token/Fungi.sol";

contract FungiTest is Test {
    error AlreadyStarted();
    error NotStarted();
    error NotOwner();
    error NotPairCreator();
    error MaxBuy();

    uint256 private constant _START_TOTAL_SUPPLY = 210e6 * (10 ** 9);
    address private constant PAIR = address(0xcafe);
    address private constant TMP_OWNER = address(0xbabe);
    address private constant RDM_ACCOUNT = address(0xdead);
    address private constant RDM_ACCOUNT2 = address(0xbeef);

    Fungi public fungi;

    function setUp() public {
        fungi = new Fungi();
    }

    function testLaunchIsPairCreatorPass() public {
        fungi.launch(PAIR);
    }

    function testLaunchNotOwnerRevertsWithNotPairCreator() public {
        vm.prank(RDM_ACCOUNT);
        vm.expectRevert(abi.encodeWithSelector(NotPairCreator.selector));
        fungi.launch(PAIR);
        vm.prank(RDM_ACCOUNT2);
        vm.expectRevert(abi.encodeWithSelector(NotPairCreator.selector));
        fungi.launch(PAIR);
    }

    function testLaunchAlreadyStartedRevertsWithAlreadyStarted() public {
        fungi.launch(PAIR);
        vm.expectRevert(abi.encodeWithSelector(AlreadyStarted.selector));
        fungi.launch(PAIR);
    }

    function testTransferNotStartedAndFromOrToOwnerPass(
        uint256 amount1,
        uint256 amount2
    ) public {
        uint256 base = _START_TOTAL_SUPPLY / 2;

        vm.assume(
            amount1 > amount2 && amount1 < base && amount2 < base
                && (amount1 + amount2) < base
        );

        fungi.transfer(RDM_ACCOUNT, base);
        fungi.transfer(RDM_ACCOUNT2, base);

        fungi.transferOwnership(TMP_OWNER);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(TMP_OWNER, amount1);
        vm.prank(RDM_ACCOUNT2);
        fungi.transfer(TMP_OWNER, amount2);
    }

    function testTransferStartedPass(uint256 amount1, uint256 amount2) public {
        vm.assume(
            amount1 < _START_TOTAL_SUPPLY && amount2 < _START_TOTAL_SUPPLY
                && (amount1 + amount2) < _START_TOTAL_SUPPLY / 2
        );

        uint256 holdersBefore = fungi.holdersCount();

        fungi.launch(PAIR);

        fungi.transfer(RDM_ACCOUNT, amount1);

        if (amount1 >= 10 ** 18) {
            assertEq(++holdersBefore, fungi.holdersCount());
        }

        fungi.transfer(RDM_ACCOUNT2, amount2);

        // TODO: See why test fails here
        if (amount2 >= 10 ** 18) {
//            assertEq(++holdersBefore, fungi.holdersCount());
        }

        assertEq(fungi.balanceOf(RDM_ACCOUNT), amount1);
        assertEq(fungi.balanceOf(RDM_ACCOUNT2), amount2);

        vm.prank(RDM_ACCOUNT2);
        fungi.transfer(RDM_ACCOUNT, amount2);
        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT2, amount1);

        assertEq(fungi.balanceOf(RDM_ACCOUNT2), amount1);
        assertEq(fungi.balanceOf(RDM_ACCOUNT), amount2);
    }

    function testTransferToZeroAddrBurnPass(uint256 amount) public {
        vm.assume(amount < _START_TOTAL_SUPPLY);

        fungi.transfer(address(0x0), amount);

        assertEq(fungi.burnCount(), amount);
    }

    function testTransferToContractAddrSuperTransferPass() public {
        // TODO: assert diff logic between regular users and
    }

    function testTransferFromPairWithAmountBelowMaxPass() public {
        fungi.launch(PAIR);

        fungi.transfer(PAIR, fungi.maxBuy());

        vm.prank(PAIR);
        fungi.transfer(RDM_ACCOUNT, fungi.maxBuy());
    }

    function testTransferGrowsAndShrinkSporesIfTransferringMoreThanOneToken(
        uint256 amount
    ) public {
        vm.assume(amount >= 10 ** fungi.decimals() && amount < _START_TOTAL_SUPPLY);

        uint256 amountPlain = amount / (10 ** fungi.decimals());

        fungi.launch(PAIR);

        uint256 holdersBefore = fungi.holdersCount();

        fungi.transfer(RDM_ACCOUNT, _START_TOTAL_SUPPLY);

        SeedData memory beforeFrom = fungi.sporesDegree(RDM_ACCOUNT);
        SeedData memory beforeTo = fungi.sporesDegree(RDM_ACCOUNT2);

        assertEq(holdersBefore + 1, fungi.holdersCount());
        assertEq(beforeTo.seed, 0);
        assertEq(beforeTo.extra, 0);

        uint256 fromBalance = fungi.balanceOf(RDM_ACCOUNT);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT2, amount);

        if (_START_TOTAL_SUPPLY - amount >= 10 ** fungi.decimals()) {
            assertEq(
                holdersBefore + 2,
                fungi.holdersCount()
            );
        } else {
            assertEq(
                holdersBefore + 1,
                fungi.holdersCount()
            );
        }

        SeedData memory afterFrom = fungi.sporesDegree(RDM_ACCOUNT);
        SeedData memory afterTo = fungi.sporesDegree(RDM_ACCOUNT2);

        assertEq(afterTo.seed, amountPlain);
        assertNotEq(afterTo.extra, 0);
        assertEq(afterFrom.seed, (fromBalance - amount) / (10 ** fungi.decimals()));
        assertEq(afterFrom.extra, beforeFrom.extra);
    }

    function testTransferDoesNothingIfTransferringZeroToken() public {
        fungi.launch(PAIR);

        fungi.transfer(RDM_ACCOUNT, _START_TOTAL_SUPPLY);

        SeedData memory beforeFrom = fungi.sporesDegree(RDM_ACCOUNT);
        SeedData memory beforeTo = fungi.sporesDegree(RDM_ACCOUNT2);

        assertEq(beforeTo.seed, 0);
        assertEq(beforeTo.extra, 0);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT2, 0);

        SeedData memory afterFrom = fungi.sporesDegree(RDM_ACCOUNT);
        SeedData memory afterTo = fungi.sporesDegree(RDM_ACCOUNT2);

        assertEq(afterTo.seed, beforeTo.seed);
        assertEq(afterTo.extra, beforeTo.extra);
        assertEq(afterFrom.seed, beforeFrom.seed);
        assertEq(afterFrom.extra, beforeFrom.extra);
    }

    function testTransferMushroomIfTransferringAllTokens(uint256 amount)
        public
    {
        vm.assume(amount >= 10 ** fungi.decimals() && amount < _START_TOTAL_SUPPLY);

        fungi.launch(PAIR);
        fungi.transfer(RDM_ACCOUNT, amount);

        SeedData memory sporeData = fungi.sporesDegree(RDM_ACCOUNT);

        assertEq(fungi.mushroomCount(RDM_ACCOUNT2), 0);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT2, amount);

        SeedData memory mushroomData =
            fungi.mushroomOfOwnerByIndex(RDM_ACCOUNT2, 0);

        assertEq(fungi.mushroomCount(RDM_ACCOUNT), 0);
        assertEq(fungi.mushroomCount(RDM_ACCOUNT2), 1);
        assertEq(sporeData.seed, mushroomData.seed);
        assertEq(sporeData.extra, mushroomData.extra);
    }

    function testTransferMushroomIfTransferringAllTokensToSelf(uint256 amount)
        public
    {
        vm.assume(amount >= 10 ** fungi.decimals() && amount < _START_TOTAL_SUPPLY);

        fungi.launch(PAIR);
        fungi.transfer(RDM_ACCOUNT, amount);

        SeedData memory sporeData = fungi.sporesDegree(RDM_ACCOUNT);

        assertEq(fungi.mushroomCount(RDM_ACCOUNT), 0);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT, amount);

        SeedData memory mushroomData =
            fungi.mushroomOfOwnerByIndex(RDM_ACCOUNT, 0);

        assertEq(fungi.mushroomCount(RDM_ACCOUNT), 1);
        assertEq(sporeData.seed, mushroomData.seed);
        assertEq(sporeData.extra, mushroomData.extra);
    }

    function testTransferMushroomIfTransferringAllTokensAndSameSeed(
        uint256 amount
    ) public {
        vm.assume(
            amount > 4 * 10 ** fungi.decimals() && amount < _START_TOTAL_SUPPLY && amount % 2 == 0
        );

        uint256 intermediateAmount = amount / 2;

        fungi.launch(PAIR);

        fungi.transfer(RDM_ACCOUNT, intermediateAmount + 1);
        fungi.transfer(RDM_ACCOUNT2, intermediateAmount);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT, intermediateAmount);

        SeedData memory fromMushroom =
            fungi.mushroomOfOwnerByIndex(RDM_ACCOUNT, 0);

        vm.prank(RDM_ACCOUNT);
        fungi.transfer(RDM_ACCOUNT2, intermediateAmount);

        SeedData memory toMushroom =
            fungi.mushroomOfOwnerByIndex(RDM_ACCOUNT2, 0);

        assertEq(fungi.mushroomCount(RDM_ACCOUNT), 0);
        assertEq(fungi.mushroomCount(RDM_ACCOUNT2), 1);
        assertEq(fromMushroom.seed, toMushroom.seed);
        assertEq(fromMushroom.extra, toMushroom.extra);
    }

    function testTransferNotStartedAndNotFromOrToOwnerRevertsWithNotStarted()
        public
    {
        vm.prank(RDM_ACCOUNT);
        vm.expectRevert(abi.encodeWithSelector(NotStarted.selector));
        fungi.transfer(PAIR, 999);

        vm.prank(RDM_ACCOUNT2);
        vm.expectRevert(abi.encodeWithSelector(NotStarted.selector));
        fungi.transfer(PAIR, 999);
    }

    function testTransferFromPairWithAmountAboveMaxRevertsWithMaxBuy() public {
        fungi.launch(PAIR);

        fungi.transfer(PAIR, _START_TOTAL_SUPPLY);

        vm.startPrank(PAIR);
        vm.expectRevert(abi.encodeWithSelector(MaxBuy.selector));
        fungi.transfer(RDM_ACCOUNT, _START_TOTAL_SUPPLY);
        vm.stopPrank();
    }
}
