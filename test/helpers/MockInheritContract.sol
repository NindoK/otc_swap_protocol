// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/OtcNexus.sol";

contract MockInheritContract is OtcNexus {
    constructor(address _otcFeeToken) OtcNexus(_otcFeeToken) {}

    function computeAmount0Visible(
        uint256 _id,
        uint256 _paymentTokenAmount,
        uint256 index,
        RfsType expectedRfsType
    ) public view returns (uint256) {
        return super.computeAmount0(_id, _paymentTokenAmount, index, expectedRfsType);
    }

    function calculateFeeVisible(
        uint8 applicableFeePercentage,
        uint256 _paymentTokenAmount
    ) public pure returns (uint256 feeAmount, uint256 amountAfterFee) {
        return super.calculateFee(applicableFeePercentage, _paymentTokenAmount);
    }

    function computeRewardsVisible(
        address maker,
        address taker,
        uint256 _amount0Bought,
        uint256 _amount0Total
    ) public {
        super.computeRewards(maker, taker, _amount0Bought, _amount0Total);
    }
}
