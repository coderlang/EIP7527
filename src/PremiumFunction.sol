// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PremiumFunction {
    uint256 public constant PRICE_INCREASE_PHASE = 80;
    uint256 public constant PRICE_DECREASE_PHASE = 240;
    uint256 public constant PRICE_PHASE = PRICE_INCREASE_PHASE + PRICE_DECREASE_PHASE + 1;
    uint256 public constant PRECISION = 1e6;
    uint256 public constant INCREASE_SLOPE = 250;
    uint256 public constant DECREASE_SLOPE = 125;

    function getPremium(uint256 blocksSinceDeploy, uint256 basePremium) public pure returns (uint256) {
        return basePremium + basePremium * getPremium(blocksSinceDeploy % PRICE_PHASE)/PRECISION;
    }

    function getPremium(uint256 blocksSinceDeploy) public pure returns (uint256) {
        uint256 index = blocksSinceDeploy % PRICE_PHASE;
        uint256 adjustment = 10000;

        if (index < PRICE_INCREASE_PHASE) {
            return (index * INCREASE_SLOPE) + adjustment;
        } else {
            uint256 blocksInDecrease = index - PRICE_INCREASE_PHASE;
            return (PRICE_INCREASE_PHASE * INCREASE_SLOPE) - (blocksInDecrease * DECREASE_SLOPE) + adjustment;
        }
    }

    function maxPremium(uint256 basePremium) public pure returns (uint256) {
        return getPremium(PRICE_INCREASE_PHASE, basePremium);
    }
}
