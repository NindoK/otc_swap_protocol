// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library OtcMath {
    function getTakerAmount0(
        uint makerAmount0,
        uint makerAmount1,
        uint takerAmount1
    ) external pure returns (uint) {
        if (makerAmount0 == makerAmount1) {
            return takerAmount1;
        } else {
            return (takerAmount1 * makerAmount0) / makerAmount1;
        }
    }
}
