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

    function test_getQuoteAmount(
        uint128 ulyAmount,
        uint64 price,
        uint8 ulyDec,
        uint8 quoteDec,
        uint8 priceDec
    ) public {
        vm.assume(ulyAmount > 10);
        vm.assume(price > 10);
        ulyDec = uint8(bound(ulyDec, 6, 18));
        quoteDec = uint8(bound(quoteDec, 6, 18));
        priceDec = uint8(bound(priceDec, 6, 11));
        uint quoteAmount = OtcMath.getQuoteAmount(
            uint(ulyAmount),
            uint(price),
            ulyDec,
            quoteDec,
            priceDec
        );
        assertEq(
            quoteAmount,
            (uint(ulyAmount) * uint(price) * 10 ** priceDec) / 10 ** ulyDec / 10 ** quoteDec
        );
    }
}
