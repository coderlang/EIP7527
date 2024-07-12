// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PremiumFunction {
    uint256 public constant PRICE_INCREASE_PHASE = 80;
    uint256 public constant PRICE_DECREASE_PHASE = 240;
    uint256 public constant PRICE_PHASE = PRICE_INCREASE_PHASE + PRICE_DECREASE_PHASE + 1;
    uint256 public constant INCREASE_SLOPE = 250;
    uint256 public constant DECREASE_SLOPE = 125;
    uint256 public constant PRECISION = 1e6;

    function getPremium(uint256 blocksSinceDeploy, uint256 basePremium) public pure returns (uint256) {
        uint256 index = blocksSinceDeploy % PRICE_PHASE;
        uint256 premium;

        if (index < PRICE_INCREASE_PHASE) {
            premium = basePremium + (index * INCREASE_SLOPE) / PRECISION + 0.01 ether;
        } else {
            uint256 blocksInDecrease = index - PRICE_INCREASE_PHASE;
            premium = basePremium + (PRICE_INCREASE_PHASE * INCREASE_SLOPE) / PRECISION - (blocksInDecrease * DECREASE_SLOPE) / PRECISION + 0.01 ether;
        }

        return premium;
    }

    function maxPremium(uint256 basePremium) public pure returns (uint256) {
        return getPremium(PRICE_INCREASE_PHASE, basePremium);
    }
}
