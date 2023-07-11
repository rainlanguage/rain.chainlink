# rain.chainlink

```solidity
/// @title LibChainlink
/// A library for interacting with Chainlink oracles. This library is designed
/// to be used with the `AggregatorV3Interface` interface, to be an opinionated
/// approach to using Chainlink oracles. The implementation is informed by both
/// the Chainlink documentation and real world experience using Chainlink.
/// Importantly it is designed for price feeds specifically, and not for
/// arbitrary oracle values. This is because price feeds are the most common
/// use case for Chainlink oracles, and the most common use case for Chainlink
/// oracles in the context of Rain Protocol.
```