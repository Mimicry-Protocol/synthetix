pragma solidity ^0.5.16;

// Libraries
import "./SafeDecimalMath.sol";
import "./Math.sol";

library DynamicFee {
    using SafeDecimalMath for uint;
    using Math for uint;
    using SafeMath for uint;

    /// @notice Calculate price differential -
    /// The difference between the current price and the previous price
    /// @param price Current round price
    /// @param previousPrice Previous round price
    /// @param threshold Threshold constant -
    /// A system constant for the price differential default to 40 bps
    /// @return uint price differential with 18 decimals
    /// only return if non-zero value, otherwise return 0
    function priceDeviation(
        uint price,
        uint previousPrice,
        uint threshold
    ) public pure returns (uint) {
        require(price > 0, "Price cannot be 0");
        require(previousPrice > 0, "Previous price cannot be 0");
        // abs difference between prices
        uint absDelta = price > previousPrice ? price - previousPrice : previousPrice - price;
        // relative to previous price
        uint deviationRatio = absDelta.divideDecimal(previousPrice);
        // must be over threshold
        return deviationRatio > threshold ? deviationRatio - threshold : 0;
    }

    /// @notice Calculate decay based on round
    /// @param round A round number that go back
    /// from the current round from 0 to N
    /// @param weightDecay Weight decay constant
    /// @return uint decay with 18 decimals
    function getRoundDecay(uint round, uint weightDecay) public pure returns (uint) {
        return weightDecay.powDecimal(round);
    }

    // /// @notice Calculate dynamic fee
    // /// @param prices A list of prices from the current round to the previous rounds
    // /// @param threshold A threshold to determine the price differential
    // /// @param weightDecay A weight decay constant
    // /// @return uint dynamic fee
    function getDynamicFee(
        uint[] calldata prices,
        uint threshold,
        uint weightDecay
    ) external pure returns (uint dynamicFee) {
        uint size = prices.length;
        // disable dynamic fee when price feeds less than 2 rounds
        if (size < 2) {
            return dynamicFee;
        }
        for (uint i = size - 1; i > 0; i--) {
            // apply decay from previous round (will be 0 for first round)
            dynamicFee = dynamicFee.multiplyDecimal(weightDecay);
            // calculate price deviation
            uint deviation = priceDeviation(prices[i - 1], prices[i], threshold);
            // add to total fee
            dynamicFee = dynamicFee.add(deviation);
        }
    }
}
