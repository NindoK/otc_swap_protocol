// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "./helpers/util.sol";
import "../src/OtcOption.sol";
import "../src/OtcMath.sol";
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
        mockAggregator.updateAnswer(int256(42));
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
        uint32 _strike,
        uint32 _maturity,
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
        uint32 _strike,
        uint32 _maturity,
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
        vm.expectRevert(Option__NotEnoughAllowance.selector);
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
            assertEq(quoteToken.balanceOf(maker), _premium);
        } else {
            if (_isCall) {
                underlyingToken.mint(_amount);
                underlyingToken.approve(address(otcOption), _amount);
                assertEq(underlyingToken.balanceOf(maker), _amount);
            } else {
                (uint8 ulyDec, uint8 quoteDec, uint8 priceDec) = otcOption.getDecimals(
                    address(underlyingToken),
                    address(quoteToken)
                );
                uint quoteAmount = OtcMath.getQuoteAmount(
                    _amount,
                    _strike,
                    ulyDec,
                    quoteDec,
                    priceDec
                );

                quoteToken.mint(quoteAmount);
                quoteToken.approve(address(otcOption), quoteAmount);
                assertEq(quoteToken.balanceOf(maker), quoteAmount);
            }
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
        assertEq(quoteToken.balanceOf(maker), 0);
        assertEq(underlyingToken.balanceOf(maker), 0);

        vm.stopPrank();
        return dealId;
    }

    function test_getDeal(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();
        uint quoteAmount = otcOption.getQuoteAmount(
            address(underlyingToken),
            address(quoteToken),
            amount,
            strike
        );

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);

        OtcOption.Deal memory deal = otcOption.getDeal(dealId);
        assertEq(deal.strike, strike);
        assertEq(deal.maturity, _maturity);
        assertEq(deal.isCall, _isCall);
        assertEq(deal.amount, amount);
        assertEq(deal.quoteAmount, quoteAmount);
        assertEq(deal.premium, premium);
        assertEq(deal.isMakerBuyer, _isMakerBuyer);
        assert(deal.status == OtcOption.DealStatus.Open);
        assertEq(deal.maker, address(maker));
        assertEq(deal.taker, address(0));

        (uint8 underlyingTokenDec, uint8 quoteTokenDec, uint8 priceFeedDec) = otcOption
            .getDealDecimals(dealId);
        assertEq(underlyingTokenDec, underlyingToken.decimals());
        assertEq(quoteTokenDec, quoteToken.decimals());
        assertEq(priceFeedDec, mockAggregator.decimals());
    }

    function test_createDeal(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);

        assertFalse(otcOption.isDealExpired(dealId));
        vm.warp(_maturity);
        assertTrue(otcOption.isDealExpired(dealId));
    }

    function test_createDeal_failDeposit(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        vm.startPrank(maker);

        if (_isMakerBuyer) {
            quoteToken.approve(address(otcOption), premium);
        } else {
            if (_isCall) {
                underlyingToken.approve(address(otcOption), amount);
            } else {
                (uint8 ulyDec, uint8 quoteDec, uint8 priceDec) = otcOption.getDecimals(
                    address(underlyingToken),
                    address(quoteToken)
                );
                uint quoteAmount = OtcMath.getQuoteAmount(
                    amount,
                    strike,
                    ulyDec,
                    quoteDec,
                    priceDec
                );
                quoteToken.approve(address(otcOption), quoteAmount);
            }
        }

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcOption.createDeal(
            address(underlyingToken),
            address(quoteToken),
            strike,
            _maturity,
            _isCall,
            amount,
            premium,
            _isMakerBuyer
        );
        vm.stopPrank();
    }

    function test_removeDeal(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);
        OtcOption.Deal memory deal = otcOption.getDeal(dealId);

        if (!_isMakerBuyer && !_isCall) {
            assertEq(ERC20(quoteToken).balanceOf(address(otcOption)), deal.quoteAmount);
        }

        // taker cannot remove
        vm.prank(taker);
        vm.expectRevert(Option__NotDealMaker.selector);
        otcOption.removeDeal(dealId);
        // maker can remove
        vm.startPrank(maker);
        otcOption.removeDeal(dealId);

        if (_isMakerBuyer) {
            // refund premium
            assertEq(ERC20(quoteToken).balanceOf(address(otcOption)), 0);
            assertEq(ERC20(quoteToken).balanceOf(address(maker)), premium);
        } else {
            if (_isCall) {
                // refund underlying token
                assertEq(ERC20(underlyingToken).balanceOf(address(otcOption)), 0);
                assertEq(ERC20(underlyingToken).balanceOf(address(maker)), amount);
            } else {
                // refund quote token
                assertEq(ERC20(quoteToken).balanceOf(address(otcOption)), 0);
                assertEq(ERC20(quoteToken).balanceOf(address(maker)), deal.quoteAmount);
            }
        }
        vm.stopPrank();
        // the deal is no longer open and cannot be taken
        vm.prank(taker);
        vm.expectRevert(Option__DealNotOpen.selector);
        otcOption.takeDeal(dealId);
    }

    function _takeDeal(uint dealId) private {
        OtcOption.Deal memory deal = otcOption.getDeal(dealId);

        vm.startPrank(taker);
        if (!deal.isMakerBuyer) {
            // taker is buyer
            quoteToken.mint(deal.premium);
            quoteToken.approve(address(otcOption), deal.premium);
            otcOption.takeDeal(dealId);
            assertEq(ERC20(quoteToken).balanceOf(address(taker)), 0); // buyer deposited the premium
        } else {
            if (deal.isCall) {
                // taker is call seller
                underlyingToken.mint(deal.amount);
                underlyingToken.approve(address(otcOption), deal.amount);
                otcOption.takeDeal(dealId);
                assertEq(ERC20(underlyingToken).balanceOf(address(taker)), 0); // call seller deposited the margin
            } else {
                // taker is put seller
                quoteToken.mint(deal.quoteAmount);
                quoteToken.approve(address(otcOption), deal.quoteAmount);
                otcOption.takeDeal(dealId);
                assertEq(ERC20(quoteToken).balanceOf(address(taker)), deal.premium); // put seller deposited the quote token
            }
        }
        vm.stopPrank();
    }

    function test_takeDeal(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);

        _takeDeal(dealId);
        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Taken);

        vm.startPrank(maker);
        vm.expectRevert(Option__DealNotOpen.selector);
        otcOption.removeDeal(dealId);

        vm.expectRevert(Option__DealNotExpired.selector);
        otcOption.settleDeal(dealId);
        vm.stopPrank();
    }

    function test_settleRemove(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);

        // forward
        vm.warp(_maturity);

        // only maker or taker can settle
        address otherAddress = address(new TestAddress());
        vm.prank(otherAddress);
        vm.expectRevert(Option__InvalidSettler.selector);
        otcOption.settleDeal(dealId);

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
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);
        OtcOption.Deal memory deal = otcOption.getDeal(dealId);

        _takeDeal(dealId);

        // forward
        vm.warp(_maturity);

        // set settle price so that the option can be exercised
        if (_isCall) {
            vm.assume(_settlePrice >= _strike);
        } else {
            vm.assume(_settlePrice <= _strike);
        }
        uint settlePrice = _settlePrice * 10 ** mockAggregator.decimals();
        mockAggregator.updateAnswer(int256(settlePrice));

        address buyer = otcOption.getDealBuyer(dealId);
        address seller = otcOption.getDealSeller(dealId);

        // seller cannot settle
        vm.prank(seller);
        vm.expectRevert(Option__InvalidSettler.selector);
        otcOption.settleDeal(dealId);

        // buyer can settle
        vm.startPrank(buyer);
        if (deal.isCall) {
            quoteToken.mint(deal.quoteAmount);
            quoteToken.approve(address(otcOption), deal.quoteAmount);
        } else {
            underlyingToken.mint(deal.amount);
            underlyingToken.approve(address(otcOption), deal.amount);
        }
        otcOption.settleDeal(dealId);
        vm.stopPrank();

        if (deal.isCall) {
            // call is exercised: buyer received the underlying token
            assertEq(ERC20(underlyingToken).balanceOf(buyer), deal.amount);
            // call seller received the quote token
            assertEq(ERC20(quoteToken).balanceOf(seller), deal.quoteAmount + deal.premium);
        } else {
            // put buyer received the quote token
            assertEq(ERC20(quoteToken).balanceOf(buyer), deal.quoteAmount);
            // put seller received the underlying token
            assertEq(ERC20(underlyingToken).balanceOf(seller), deal.amount);
        }

        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Settled);
    }

    function test_settleNotExercise(
        uint32 _strike,
        uint32 _maturity,
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
        uint amount = _amount * 10 ** underlyingToken.decimals();
        uint premium = _premium * 10 ** quoteToken.decimals();

        uint dealId = _createDeal(strike, _maturity, _isCall, amount, premium, _isMakerBuyer);
        OtcOption.Deal memory deal = otcOption.getDeal(dealId);

        _takeDeal(dealId);

        // forward
        vm.warp(_maturity);

        // set settle price so that the option cannot be exercised
        if (_isCall) {
            vm.assume(_settlePrice < _strike);
        } else {
            vm.assume(_settlePrice > _strike);
        }
        uint settlePrice = _settlePrice * 10 ** mockAggregator.decimals();
        mockAggregator.updateAnswer(int256(settlePrice));

        address buyer = otcOption.getDealBuyer(dealId);
        address seller = otcOption.getDealSeller(dealId);

        // buyer cannot settle
        vm.prank(buyer);
        vm.expectRevert(Option__InvalidSettler.selector);
        otcOption.settleDeal(dealId);

        // seller can settle
        vm.prank(seller);
        otcOption.settleDeal(dealId);

        if (_isCall) {
            // call seller received back the underlying token
            assertEq(ERC20(underlyingToken).balanceOf(seller), deal.amount);
        } else {
            // put seller received back the quote token
            assertEq(ERC20(quoteToken).balanceOf(seller), deal.quoteAmount + deal.premium);
        }

        assert(otcOption.getDeal(dealId).status == OtcOption.DealStatus.Settled);
    }
}
