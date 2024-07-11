// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PremiumFunction {
    uint256 public constant PRICE_INCREASE_PHASE = 80;
    uint256 public constant PRICE_DECREASE_PHASE = 240;
    uint256 public constant UNIT_BLOCKS = 10;
    uint256 public constant CYCLE_BLOCKS = PRICE_INCREASE_PHASE + PRICE_DECREASE_PHASE;
    uint256 public constant INCREASE_SLOPE = (103 - 101) * 1 ether / PRICE_INCREASE_PHASE; // 1.03 - 1.01
    uint256 public constant DECREASE_SLOPE = (103 - 100) * 1 ether / PRICE_DECREASE_PHASE; // 1.03 - 1.00

    function getPremium(uint256 blocksSinceDeploy, uint256 basePremium) public pure returns (uint256) {
        uint256 cyclePosition = blocksSinceDeploy % CYCLE_BLOCKS;
        uint256 premium;

        if (cyclePosition < PRICE_INCREASE_PHASE) {
            // Price increase phase
            premium = basePremium + (cyclePosition * INCREASE_SLOPE);
        } else {
            // Price decrease phase
            uint256 blocksInDecrease = cyclePosition - PRICE_INCREASE_PHASE;
            premium = basePremium + (PRICE_INCREASE_PHASE * INCREASE_SLOPE) - (blocksInDecrease * DECREASE_SLOPE);
        }

        return premium;
    }

    function maxPremium(uint256 basePremium) public pure returns (uint256) {
        return basePremium + (PRICE_INCREASE_PHASE * INCREASE_SLOPE);
    }
}
