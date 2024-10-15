// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.28;

import {Test, stdError} from "forge-std/Test.sol";

import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";

import {LibChainlink} from "src/lib/LibChainlink.sol";

/// @title LibChainlinkScalingTest
/// Test that scaling works as expected. This just has to check that the scaling
/// matches the upstream rain fixed math lib, for whatever decimals Chainlink
/// reports.
contract LibChainlinkScalingTest is Test {
    using LibFixedPointDecimalScale for uint256;

    /// Test that the scaling matches the upstream rain fixed math lib, for
    /// whatever decimals Chainlink reports. This test checks with saturation
    /// enabled so we don't need to worry about overflow.
    /// Other error conditions are handled by other tests.
    function testScaling(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external pure {
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(!LibWillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        assertEq(price, uint256(answer).scale18(decimals, scalingFlags));
    }

    /// Test the case where saturation is disabled, and the scaling does NOT
    /// overflow.
    function testScalingNoSaturation(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external pure {
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(!LibWillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        assertEq(price, uint256(answer).scale18(decimals, scalingFlags));
    }

    /// Test the case where saturation is disabled, and the scaling DOES
    /// overflow.
    function testScalingNoSaturationOverflow(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) external {
        answer = bound(answer, 1, type(int256).max);
        vm.assume(updatedAt <= currentTimestamp);
        staleAfter = bound(staleAfter, currentTimestamp - updatedAt, type(uint256).max);
        vm.assume(LibWillOverflow.scale18WillOverflow(uint256(answer), decimals, scalingFlags));
        vm.expectRevert(stdError.arithmeticError);
        uint256 price =
            LibChainlink.roundDataToPrice(currentTimestamp, staleAfter, scalingFlags, answer, updatedAt, decimals);
        (price);
    }
}
