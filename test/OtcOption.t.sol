// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "./util.sol";
import "../src/OtcOption.sol";
import "./MockToken.sol";

// forge test --match-path test\OtcOption.t.sol -vvv

contract OtcOptionTest is Test {
    address public deployer = address(new TestAddress());
    address public maker = address(new TestAddress());
    address public taker = address(new TestAddress());
    OtcOption public otcOption;
    MockToken underlyingToken;
    MockToken quoteToken;
    MockV3Aggregator public mockAggregator;

    function setUp() public {
        vm.startPrank(deployer);
        underlyingToken = new MockToken("Mock WETH", "WETH", 18);
        quoteToken = new MockToken("Mock DAI", "DAI", 6);
        mockAggregator = new MockV3Aggregator(8, 0);
        otcOption = new OtcOption();

        otcOption.addPriceFeed(
            address(underlyingToken),
            address(quoteToken),
            address(mockAggregator)
        );
        vm.stopPrank();
    }

    function test_AggregatorV3Mock(uint answer) public {
        mockAggregator.updateAnswer(int256(answer));
        (, int256 price, , , ) = mockAggregator.latestRoundData();
        assert(uint(price) == answer);
        assert(otcOption.getPrice(address(underlyingToken), address(quoteToken)) == answer);
    }

    function test_getPriceFeed() public {
        address priceFeed = otcOption.getPriceFeed(address(underlyingToken), address(quoteToken));
        assertEq(priceFeed, address(mockAggregator));
    }

    // function test_createDeal() public {
    //     uint maturity = 10;
    //     bool isCall = true;
    //     uint strike = 2000 * 10 ** mockAggregator.decimals();
    //     uint amount = 1 * 10 ** underlyingToken.decimals();
    //     uint premium = 1 * 10 ** quoteToken.decimals();
    //     bool isMakerBuyer = true;

    //     vm.startPrank(maker);
    //     quoteToken.mint(premium);
    //     quoteToken.approve(address(otcOption), premium);
    //     uint dealId = otcOption.createDeal(strike, maturity, isCall, amount, premium, isMakerBuyer);
    //     vm.stopPrank();

    //     assertEq(token0.balanceOf(maker), startBalance - amount0);

    //     // console.log("block timestamp");
    //     // console.log("block timestamp: %s", block.timestamp);
    //     // vm.warp(3);
    //     // console.log("block timestamp: %s", block.timestamp);
    // }
}
