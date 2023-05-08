// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OtcMath.sol";

contract OtcMathTest is Test {
    function test_getTakerAmount0_quote1(uint makerAmount01, uint takerAmount1) public {
        uint takerAmount0 = OtcMath.getTakerAmount0(makerAmount01, makerAmount01, takerAmount1);
        assertEq(takerAmount0, takerAmount1);
    }

    function test_getTakerAmount0(
        uint8 makerAmount0,
        uint8 makerAmount1,
        uint8 takerAmount1
    ) public {
        vm.assume(makerAmount0 > 0);
        vm.assume(makerAmount1 > 0);
        vm.assume(makerAmount0 != makerAmount1);
        uint takerAmount0 = OtcMath.getTakerAmount0(makerAmount0, makerAmount1, takerAmount1);
        assertEq(takerAmount0, (uint(takerAmount1) * uint(makerAmount0)) / uint(makerAmount1));
    }
}
