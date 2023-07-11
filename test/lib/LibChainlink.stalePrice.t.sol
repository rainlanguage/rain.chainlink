// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import {WillOverflow} from "rain.math.fixedpoint/../test/WillOverflow.sol";

import "src/lib/LibChainlink.sol";

/// @title LibChainlinkStalePriceTest
/// Test that stale prices are not allowed and that all non-stale prices are
/// allowed.
contract LibChainlinkStalePriceTest is Test {
    /// All non-stale prices should be allowed. This test just doesn't revert.
    function testNonStalePrice(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external view {
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(!WillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }

    /// Stale prices should not be allowed.
    function testStalePrice(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external {
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt < currentTimestamp);
        staleAfter = bound(staleAfter, 0, currentTimestamp - updatedAt - 1);
        vm.assume(!WillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, updatedAt, staleAfter));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }

    /// Special case where the staleAfter is zero, the currentTimestamp must be
    /// exactly equal to the updatedAt time.
    function testStalePriceZeroStaleAfter(
        uint256 currentTimestamp,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external {
        uint256 staleAfter = 0;
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt < currentTimestamp);
        vm.assume(!WillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, updatedAt, staleAfter));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);

        updatedAt = currentTimestamp;
        price = LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }
}