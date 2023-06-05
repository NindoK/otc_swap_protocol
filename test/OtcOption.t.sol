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

    function _createDeal(
        uint256 _strike,
        uint256 _maturity,
        bool _isCall,
        uint256 _amount,
        uint256 _premium,
        bool _isMakerBuyer
    ) private returns (uint256) {
        vm.startPrank(maker);

        if (_isMakerBuyer) {
            quoteToken.mint(_premium);
            quoteToken.approve(address(otcOption), _premium);
        } else {
            underlyingToken.mint(_amount);
            underlyingToken.approve(address(otcOption), _amount);
        }

        uint dealId = otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            _strike,
            _maturity,
            _isCall,
            _amount,
            _premium,
            _isMakerBuyer
        );

        vm.stopPrank();
        return dealId;
    }

    function test_getDeal(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
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

        uint dealId = _createDeal(strike, maturity, isCall, amount, premium, _isMakerBuyer);

        OtcOption.Deal memory deal = otcOption.getDeal(dealId);
        assertEq(deal.strike, strike);
        assertEq(deal.maturity, maturity);
        assertEq(deal.isCall, isCall);
        assertEq(deal.amount, amount);
        assertEq(deal.premium, premium);
        assertEq(deal.isMakerBuyer, _isMakerBuyer);
        // todo assertEq(deal.status, OtcOption.DealStatus.Open);
        assertEq(deal.maker, address(maker));
        assertEq(deal.taker, address(0));

        (uint8 underlyingTokenDec, uint8 quoteTokenDec, uint8 priceFeedDec) = otcOption.getDecimals(
            dealId
        );
        assertEq(underlyingTokenDec, underlyingToken.decimals());
        assertEq(quoteTokenDec, quoteToken.decimals());
        assertEq(priceFeedDec, mockAggregator.decimals());
    }

    function test_createDeal(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
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

        uint dealId = _createDeal(strike, maturity, isCall, amount, premium, _isMakerBuyer);

        if (_isMakerBuyer) {
            assertEq(ERC20(quoteToken).balanceOf(address(maker)), 0); // buyer deposited the premium
        } else {
            assertEq(ERC20(underlyingToken).balanceOf(address(maker)), 0); // seller deposited the margin
        }

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

    function test_takeDeal(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
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

        uint dealId = _createDeal(strike, maturity, isCall, amount, premium, _isMakerBuyer);

        vm.startPrank(taker);
        if (_isMakerBuyer) {
            underlyingToken.mint(amount);
            underlyingToken.approve(address(otcOption), amount);
            otcOption.takeDeal(dealId);
            assertEq(ERC20(underlyingToken).balanceOf(address(taker)), 0); // seller deposited the margin
        } else {
            quoteToken.mint(premium);
            quoteToken.approve(address(otcOption), premium);
            otcOption.takeDeal(dealId);
            assertEq(ERC20(quoteToken).balanceOf(address(taker)), 0); // buyer deposited the premium
        }
        vm.stopPrank();
        // todo assertEq(otcOption.getDeal(dealId).status, OtcOption.DealStatus.Taken);
    }

    function test_takeDeal_exercise(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
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

        uint dealId = _createDeal(strike, maturity, isCall, amount, premium, _isMakerBuyer);

        vm.startPrank(taker);
        if (_isMakerBuyer) {
            underlyingToken.mint(amount);
            underlyingToken.approve(address(otcOption), amount);
            otcOption.takeDeal(dealId);
        } else {
            quoteToken.mint(premium);
            quoteToken.approve(address(otcOption), premium);
            otcOption.takeDeal(dealId);
        }
        vm.stopPrank();

        // forward
        vm.warp(maturity);

        mockAggregator.updateAnswer(int256(strike));

        vm.prank(maker);
        otcOption.settleDeal(dealId);

        // deal is exercised: buyer receives the margin
        address buyer = otcOption.getDealBuyer(dealId);
        assertEq(ERC20(underlyingToken).balanceOf(buyer), amount);

        // todo assertEq(otcOption.getDeal(dealId).status, OtcOption.DealStatus.Settled);
    }

    function test_takeDeal_notExercise(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer
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

        uint dealId = _createDeal(strike, maturity, isCall, amount, premium, _isMakerBuyer);

        vm.startPrank(taker);
        if (_isMakerBuyer) {
            underlyingToken.mint(amount);
            underlyingToken.approve(address(otcOption), amount);
            otcOption.takeDeal(dealId);
        } else {
            quoteToken.mint(premium);
            quoteToken.approve(address(otcOption), premium);
            otcOption.takeDeal(dealId);
        }
        vm.stopPrank();

        // forward
        vm.warp(maturity);

        if (isCall) {
            mockAggregator.updateAnswer(int256(strike - 1));
        } else {
            mockAggregator.updateAnswer(int256(strike + 1));
        }

        vm.prank(maker);
        otcOption.settleDeal(dealId);

        // deal is not exercised: seller receives the margin
        address seller = otcOption.getDealSeller(dealId);
        assertEq(ERC20(underlyingToken).balanceOf(seller), amount);

        // todo assertEq(otcOption.getDeal(dealId).status, OtcOption.DealStatus.Settled);
    }
}
