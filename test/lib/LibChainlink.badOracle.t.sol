// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "src/lib/LibChainlink.sol";

/// @title LibChainlinkBadOracleTest
/// Tests what happens when the oracle itself misbehaves.
contract LibChainlinkBadOracleTest is Test {
    // /// If the bytecode of the oracle is empty then the oracle is not a contract
    // /// and so price must revert.
    // function testEmptyOracle(address feed, uint256 staleAfter, uint256 scalingFlags) external view {
    //     vm.assume(feed.code.length == 0);
    //     // vm.expectRevert();
    //     uint256 price = LibChainlink.price(feed, staleAfter, scalingFlags);
    //     (price);
    // }

    function testEmptyOracleSimple() external {
        vm.expectRevert();
        uint256 price = LibChainlink.price(address(0), type(uint256).max, 0);
        (price);
    }
}
