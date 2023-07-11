// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import {WillOverflow} from "rain.math.fixedpoint/../test/WillOverflow.sol";

import "src/lib/LibChainlink.sol";

/// @title LibChainlinkNegativePrice
/// Test that negative prices are not allowed and that all positive prices are
/// allowed.
contract LibChainlinkNegativePriceTest is Test {
    /// All positive prices should be allowed. This test just doesn't revert.
    function testPositivePrice(
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

    /// Negative prices should not be allowed.
    function testNegativePrice(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external {
        answer = bound(answer, type(int256).min, -1);
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(!WillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        vm.expectRevert(abi.encodeWithSelector(NotPosIntPrice.selector, answer));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }

    /// Test zero price is not allowed.
    function testZeroPrice(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        uint256 updatedAt,
        uint8 decimals
    ) external {
        int256 answer = 0;
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(!WillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        vm.expectRevert(abi.encodeWithSelector(NotPosIntPrice.selector, answer));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }
}
