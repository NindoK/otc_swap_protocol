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

    function test_createDeal_failInvalidMaturity(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
    ) public {
        vm.assume(_strike > 0);
        vm.assume(_maturity <= block.timestamp);
        vm.assume(_amount > 0);
        vm.assume(_premium > 0);

        uint strike = _strike * 10 ** mockAggregator.decimals();
        uint maturity = _maturity;
        bool isCall = _isCall;
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        bool isMakerBuyer = _isMakerBuyer;

        vm.startPrank(maker);
        vm.expectRevert(Option__InvalidMaturity.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();
    }

    function test_createDealBuy_failDepositPremium(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium
    ) public {
        vm.assume(_strike > 0);
        vm.assume(_maturity > block.timestamp);
        vm.assume(_amount > 0);
        vm.assume(_premium > 0);

        uint strike = _strike * 10 ** mockAggregator.decimals();
        uint maturity = _maturity;
        bool isCall = _isCall;
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        bool isMakerBuyer = true;

        vm.startPrank(maker);
        quoteToken.approve(address(otcOption), premium);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();
    }

    function test_createDealBuy(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium
    ) public {
        vm.assume(_strike > 0);
        vm.assume(_maturity > block.timestamp);
        vm.assume(_amount > 0);
        vm.assume(_premium > 0);

        uint strike = _strike * 10 ** mockAggregator.decimals();
        uint maturity = _maturity;
        bool isCall = _isCall;
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        bool isMakerBuyer = true;

        vm.startPrank(maker);
        quoteToken.mint(premium);
        quoteToken.approve(address(otcOption), premium);
        uint dealId = otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();

        OtcOption.Deal memory deal = otcOption.getDeal(dealId);
        assertEq(deal.strike, strike);
        assertEq(deal.maturity, maturity);
        assertEq(deal.isCall, isCall);
        assertEq(deal.amount, amount);
        assertEq(deal.premium, premium);
        assertEq(deal.isMakerBuyer, isMakerBuyer);

        assertFalse(otcOption.isDealExpired(dealId));
        vm.warp(_maturity);
        assertTrue(otcOption.isDealExpired(dealId));
    }

    function test_createDealSell_failDepositMargin(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium
    ) public {
        vm.assume(_strike > 0);
        vm.assume(_maturity > block.timestamp);
        vm.assume(_amount > 0);
        vm.assume(_premium > 0);

        uint strike = _strike * 10 ** mockAggregator.decimals();
        uint maturity = _maturity;
        bool isCall = _isCall;
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        bool isMakerBuyer = false;

        vm.startPrank(maker);
        underlyingToken.approve(address(otcOption), amount);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();
    }

    function test_createDealSell(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium
    ) public {
        vm.assume(_strike > 0);
        vm.assume(_maturity > block.timestamp);
        vm.assume(_amount > 0);
        vm.assume(_premium > 0);

        uint strike = _strike * 10 ** mockAggregator.decimals();
        uint maturity = _maturity;
        bool isCall = _isCall;
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        bool isMakerBuyer = false;

        vm.startPrank(maker);
        underlyingToken.mint(amount);
        underlyingToken.approve(address(otcOption), amount);
        uint dealId = otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();

        OtcOption.Deal memory deal = otcOption.getDeal(dealId);
        assertEq(deal.strike, strike);
        assertEq(deal.maturity, maturity);
        assertEq(deal.isCall, isCall);
        assertEq(deal.amount, amount);
        assertEq(deal.premium, premium);
        assertEq(deal.isMakerBuyer, isMakerBuyer);

        assertFalse(otcOption.isDealExpired(dealId));
        vm.warp(_maturity);
        assertTrue(otcOption.isDealExpired(dealId));
    }
}
