// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {Test} from "forge-std/Test.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";

import {LibChainlink} from "src/lib/LibChainlink.sol";
import {AggregatorV3Interface} from "src/interface/AggregatorV3Interface.sol";

/// @title LibChainlinkPriceTest
/// Test that the `price` function matches the `roundDataToPrice` function.
/// This is a bit redundant, but it's good to have a test that checks the
/// `price` function directly. We can't test error conditions here, because of
/// the issue that drove us to split the logic out in the first place. We can
/// check that success conditions bind the Chainlink oracle data to the
/// internal logic correctly.
contract LibChainlinkPriceTest is Test {
    /// As long as there are no errors, the price function should match the
    /// roundDataToPrice function.
    function testPrice(
        uint256 staleAfter,
        uint256 scalingFlags,
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound,
        uint8 decimals
    ) external {
        address feed = address(999);
        vm.etch(feed, hex"00");

        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt <= block.timestamp);
        staleAfter = bound(staleAfter, block.timestamp - updatedAt, type(uint256).max);
        vm.assume(!LibWillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        uint256 price =
            LibChainlink.roundDataToPrice(block.timestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        vm.mockCall(
            feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(roundId, answer, startedAt, updatedAt, answeredInRound)
        );
        vm.mockCall(feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(decimals));
        assertEq(price, LibChainlink.price(feed, staleAfter, scalingFlags));
    }
}
