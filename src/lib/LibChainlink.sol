// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "rain.math.fixedpoint/FixedPointDecimalScale.sol";
import "../interface/AggregatorV3Interface.sol";

/// Thrown if a price is zero or negative as this is probably not anticipated or
/// useful for most users of a price feed. Of course there are use cases where
/// zero or negative _oracle values_ in general are useful, such as negative
/// temperatures from a thermometer, but these are unlikely to be useful _prices_
/// for assets. Zero value prices are likely to result in division by zero
/// downstream or giving away assets for free, negative price values could result
/// in even weirder behaviour due to token amounts being `uint256` and the
/// subtleties of signed vs. unsigned integer conversions.
/// @param price The price that is not a positive integer.
error NotPosIntPrice(int256 price);

/// Thrown when the updatedAt time from the Chainlink oracle is more than
/// staleAfter seconds prior to the current block timestamp. Prevents stale
/// prices from being used within the constraints set by the caller.
/// @param updatedAt The latest time the oracle was updated according to the
/// oracle.
/// @param staleAfter The maximum number of seconds the caller allows between
/// the block timestamp and the updated time.
error StalePrice(uint256 updatedAt, uint256 staleAfter);

/// @title LibChainlink
/// A library for interacting with Chainlink oracles. This library is designed
/// to be used with the `AggregatorV3Interface` interface, to be an opinionated
/// approach to using Chainlink oracles. The implementation is informed by both
/// the Chainlink documentation and real world experience using Chainlink.
/// Importantly it is designed for price feeds specifically, and not for
/// arbitrary oracle values. This is because price feeds are the most common
/// use case for Chainlink oracles, and the most common use case for Chainlink
/// oracles in the context of Rain Protocol.
library LibChainlink {
    using FixedPointDecimalScale for uint256;

    /// Returns a single price value from a Chainlink oracle. This wraps the
    /// `latestRoundData` function from the `AggregatorV3Interface` interface
    /// and adds some additional checks to ensure the price is valid. It also
    /// scales the price to 18 decimal fixed point, which is the standard for
    /// Rain Protocol, and more generally common for Ethereum tokens and ETH
    /// itself. By scaling everything to 18 decimal fixed point we can avoid
    /// having to deal with the complexities of different token decimals
    /// downstream.
    ///
    /// A "valid" price is nonzero and nonnegative, and not stale. This avoids
    /// division by zero and other weird behaviour downstream. Stale prices are
    /// avoided by checking the updatedAt time from the oracle is not more than
    /// `staleAfter` seconds prior to the current block timestamp. This is NOT
    /// a guarantee that the price is accurate, but it is a guarantee that the
    /// price is not stale according to the constraints set by the caller. The
    /// main issue with a time based check is that Chainlink doesn't report
    /// onchain when the price _should_ have changed, so there is no way to
    /// know if the price is truly stale or not. This is a limitation of
    /// Chainlink, and not this library. For example, Chainlink could silently
    /// pause the oracle according to constraints that A. can only be known by
    /// reading the oracle code and B. can change at any time due to the oracle
    /// being upgradeable and controlled by a third party. I.e. you need to
    /// re-read the oracle code every block, offchain, to really know what the
    /// rules are. This happened in the past with the LUNA price feed and wiped
    /// out several DeFi projects that relied on it. Chainlink documentation
    /// recommends 24/7 monitoring of oracle prices by defi teams, and that
    /// teams should pause their contracts if the oracle price is stale. At
    /// best this is a very high bar for defi teams to meet, and at worst it
    /// is impossible for protocols that are designed to be fully decentralized.
    ///
    /// Invalid/stale prices will REVERT so the caller needs to handle this. If
    /// somehow Chainlink returns a future updatedAt time, this will also REVERT.
    ///
    /// @param feed The address of the Chainlink oracle to read from.
    /// @param staleAfter The maximum number of seconds the caller allows
    /// between the block timestamp and the updated time.
    /// @param scalingFlags Flags to control the scaling of the price as per
    /// the `FixedPointDecimalScale` library. See that library for more details.
    /// @return The price from the oracle, scaled to 18 decimal fixed point.
    function price(address feed, uint256 staleAfter, uint256 scalingFlags) internal view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            AggregatorV3Interface(feed).latestRoundData();
        (roundId);
        (startedAt);
        (answeredInRound);

        return roundDataToPrice(
            block.timestamp, staleAfter, scalingFlags, answer, updatedAt, AggregatorV3Interface(feed).decimals()
        );
    }

    /// Internal logic for `price`. This is a separate function so it can be
    /// tested in isolation. Ideally we'd not need this, but there seems to be
    /// an issue when mocks and revert expectations are used together in
    /// Foundry. This is a workaround for that issue.
    /// https://github.com/foundry-rs/foundry/issues/5359
    /// IT IS NOT RECOMMENDED TO USE THIS DIRECTLY. It will be removed if/when
    /// the Foundry issue is resolved. Use `price` instead.
    /// @param currentTimestamp The current block timestamp.
    /// @param staleAfter The maximum number of seconds the caller allows
    /// between the block timestamp and the updated time.
    /// @param scalingFlags Flags to control the scaling of the price as per
    /// the `FixedPointDecimalScale` library. See that library for more details.
    /// @param answer The price from the oracle.
    /// @param updatedAt The time the oracle was last updated.
    /// @param decimals The number of decimals the oracle uses.
    function roundDataToPrice(
        uint256 currentTimestamp,
        uint256 staleAfter,
        uint256 scalingFlags,
        int256 answer,
        uint256 updatedAt,
        uint8 decimals
    ) internal pure returns (uint256) {
        // Check the price is positive. Nothing in the Chainlink docs says this
        // is guaranteed, and it is not guaranteed by the oracle code itself.
        // Still, we can't do anything with a negative price, so we revert.
        // This also makes the casting to uint256 below safe.
        if (answer <= 0) {
            revert NotPosIntPrice(answer);
        }

        // Checked time comparison ensures no updates from the future as that
        // would overflow, and no stale prices.
        // solhint-disable-next-line not-rely-on-time
        //slither-disable-next-line timestamp
        if (currentTimestamp - updatedAt > staleAfter) {
            revert StalePrice(updatedAt, staleAfter);
        }

        // Cast the answer to uint256 and scale it to 18 decimal FP.
        return uint256(answer).scale18(decimals, scalingFlags);
    }
}
