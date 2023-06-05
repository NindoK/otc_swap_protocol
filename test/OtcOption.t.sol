// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "./helpers/util.sol";
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

        vm.expectRevert(Option__InvalidPriceFeed.selector);
        otcOption.getPriceFeed(address(0), address(0));
    }

    function test_addPriceFeed(
        address _underlyingToken,
        address _quoteToken,
        address _priceFeedAddress
    ) public {
        vm.assume(_underlyingToken != address(0));
        vm.assume(_quoteToken != address(0));
        vm.assume(_priceFeedAddress != address(0));

        vm.startPrank(deployer);
        otcOption.addPriceFeed(_underlyingToken, _quoteToken, _priceFeedAddress);
        address priceFeed = otcOption.getPriceFeed(_underlyingToken, _quoteToken);
        assertEq(priceFeed, _priceFeedAddress);

        vm.expectRevert(Option__InvalidUnderlyingToken.selector);
        otcOption.addPriceFeed(address(0), _quoteToken, _priceFeedAddress);

        vm.expectRevert(Option__InvalidQuoteToken.selector);
        otcOption.addPriceFeed(_underlyingToken, address(0), _priceFeedAddress);

        vm.expectRevert(Option__InvalidPriceFeed.selector);
        otcOption.addPriceFeed(_underlyingToken, _quoteToken, address(0));
        vm.stopPrank();
    }

    function test_createDeal_failInvalidInput(
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
        bool isMakerBuyer = _isMakerBuyer;

        vm.startPrank(maker);
        vm.expectRevert(Option__InvalidUnderlyingToken.selector);
        otcOption.createDeal(
            address(0),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );

        vm.expectRevert(Option__InvalidQuoteToken.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(0),
            strike,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );

        vm.expectRevert(Option__InvalidStrike.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            0,
            maturity,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );

        vm.expectRevert(Option__InvalidMaturity.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            block.timestamp,
            isCall,
            amount,
            premium,
            isMakerBuyer
        );
        vm.stopPrank();

        vm.expectRevert(Option__InvalidAmount.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            0,
            premium,
            isMakerBuyer
        );

        vm.expectRevert(Option__InvalidPremium.selector);
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            maturity,
            isCall,
            amount,
            0,
            isMakerBuyer
        );
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
        vm.expectRevert(Option__DealNotFound.selector);
        otcOption.getDeal(0);

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
        assert(deal.status == OtcOption.DealStatus.Open);
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

    function test_removeDeal(
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

        vm.prank(taker);
        vm.expectRevert(Option__NotDealMaker.selector);
        otcOption.removeDeal(dealId);

        vm.prank(maker);
        otcOption.removeDeal(dealId);

        if (_isMakerBuyer) {
            assertEq(ERC20(quoteToken).balanceOf(address(maker)), premium); // refund premium
        } else {
            assertEq(ERC20(underlyingToken).balanceOf(address(maker)), amount); // refund margin
        }

        // the deal is no longer open and cannot be taken
        vm.prank(taker);
        vm.expectRevert(Option__DealNotOpen.selector);
        otcOption.takeDeal(dealId);
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
        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Taken);

        vm.startPrank(maker);
        vm.expectRevert(Option__DealNotOpen.selector);
        otcOption.removeDeal(dealId);

        vm.expectRevert(Option__DealNotExpired.selector);
        otcOption.settleDeal(dealId);
        vm.stopPrank();
    }

    function test_settleRemove(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer,
        int256 _settlePrice
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

        // forward
        vm.warp(maturity);

        // the deal is expired and cannot be taken
        vm.prank(taker);
        vm.expectRevert(Option__DealExpired.selector);
        otcOption.takeDeal(dealId);

        mockAggregator.updateAnswer(_settlePrice);

        vm.prank(maker);
        otcOption.settleDeal(dealId);

        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Removed);
    }

    function test_settleExercise(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer,
        uint64 _settlePrice
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

        // set settle price so that the option can be exercised
        if (isCall) {
            vm.assume(_settlePrice >= _strike);
        } else {
            vm.assume(_settlePrice <= _strike);
        }
        uint settlePrice = _settlePrice * 10 ** mockAggregator.decimals();
        mockAggregator.updateAnswer(int256(settlePrice));

        vm.prank(maker);
        otcOption.settleDeal(dealId);

        // deal is exercised: buyer receives the margin
        address buyer = otcOption.getDealBuyer(dealId);
        assertEq(ERC20(underlyingToken).balanceOf(buyer), amount);

        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Settled);
    }

    function test_settleNotExercise(
        uint64 _strike,
        uint64 _maturity,
        bool _isCall,
        uint128 _amount,
        uint128 _premium,
        bool _isMakerBuyer,
        uint64 _settlePrice
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

        // set settle price so that the option cannot be exercised
        if (isCall) {
            vm.assume(_settlePrice < _strike);
        } else {
            vm.assume(_settlePrice > _strike);
        }
        uint settlePrice = _settlePrice * 10 ** mockAggregator.decimals();
        mockAggregator.updateAnswer(int256(settlePrice));

        vm.prank(maker);
        otcOption.settleDeal(dealId);

        // deal is not exercised: seller receives the margin
        address seller = otcOption.getDealSeller(dealId);
        assertEq(ERC20(underlyingToken).balanceOf(seller), amount);

        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Settled);
    }
}
