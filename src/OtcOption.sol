// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OtcMath.sol";

error Option__InvalidUnderlyingToken();
error Option__InvalidQuoteToken();
error Option__InvalidStrike();
error Option__InvalidMaturity();
error Option__InvalidAmount();
error Option__InvalidPremium();

error Option__InvalidPriceFeed();
error Option__NotEnoughAllowance();
error Option__TransferFailed();
error Option__NotDealMaker();
error Option__DealNotOpen();
error Option__DealExpired();
error Option__DealNotExpired();
error Option__DealNotFound();
error Option__DealHasNoTaker();
error Option__InvalidSettler();

contract OtcOption is Ownable {
    event DealCreated(
        uint id,
        address underlyingToken,
        address quoteToken,
        uint strike,
        uint maturity,
        bool isCall,
        uint amount,
        uint quoteAmount,
        uint premium,
        bool isMakerBuyer,
        address maker
    );
    event DealTaken(uint id, address taker);
    event DealRemoved(uint id);
    event DealSettled(uint id, bool exercised);

    enum DealStatus {
        Open,
        Taken,
        Removed,
        Settled
    }

    struct Deal {
        uint id;
        address underlyingToken;
        address quoteToken;
        uint strike;
        uint maturity;
        bool isCall;
        uint amount;
        uint quoteAmount;
        uint premium;
        bool isMakerBuyer;
        DealStatus status;
        address maker;
        address taker;
    }

    // status variables
    mapping(address => mapping(address => address)) private _priceFeeds; // underlying => (quote => feed)
    uint public dealCounter = 1;
    mapping(uint => Deal) private _deals;

    function addPriceFeed(
        address _underlyingToken,
        address _quoteToken,
        address _priceFeedAddress
    ) public onlyOwner {
        if (_underlyingToken == address(0)) revert Option__InvalidUnderlyingToken();
        if (_quoteToken == address(0)) revert Option__InvalidQuoteToken();
        if (_priceFeedAddress == address(0)) revert Option__InvalidPriceFeed();
        _priceFeeds[_underlyingToken][_quoteToken] = _priceFeedAddress;
    }

    function getPriceFeed(
        address _underlyingToken,
        address _quoteToken
    ) public view returns (address) {
        address priceFeed = _priceFeeds[_underlyingToken][_quoteToken];
        if (priceFeed == address(0)) revert Option__InvalidPriceFeed();
        return priceFeed;
    }

    function _safeTransferFrom(address _token, address _from, address _to, uint _amount) internal {
        if (IERC20(_token).allowance(_from, address(this)) < _amount)
            revert Option__NotEnoughAllowance();
        bool success = IERC20(_token).transferFrom(_from, _to, _amount);
        if (!success) revert Option__TransferFailed();
    }

    function _safeTransfer(address _token, address _to, uint _amount) internal {
        bool success = IERC20(_token).transfer(_to, _amount);
        if (!success) revert Option__TransferFailed();
    }

    function getQuoteAmount(
        address _underlyingToken,
        address _quoteToken,
        uint _amount,
        uint _price
    ) public view returns (uint) {
        (uint8 ulyDec, uint8 quoteDec, uint8 priceDec) = getDecimals(_underlyingToken, _quoteToken);
        return OtcMath.getQuoteAmount(_amount, _price, ulyDec, quoteDec, priceDec);
    }

    function createDeal(
        address _underlyingToken,
        address _quoteToken,
        uint _strike,
        uint _maturity,
        bool _isCall,
        uint _amount,
        uint _premium,
        bool _isMakerBuyer
    ) external returns (uint) {
        if (_underlyingToken == address(0)) revert Option__InvalidUnderlyingToken();
        if (_quoteToken == address(0)) revert Option__InvalidQuoteToken();
        if (_strike == 0) revert Option__InvalidStrike();
        if (_maturity <= block.timestamp) revert Option__InvalidMaturity();
        if (_amount == 0) revert Option__InvalidAmount();
        if (_premium == 0) revert Option__InvalidPremium();
        getPriceFeed(_underlyingToken, _quoteToken); // check price feed exists

        uint quoteAmount = getQuoteAmount(_underlyingToken, _quoteToken, _amount, _strike);

        Deal memory deal = Deal(
            dealCounter,
            _underlyingToken,
            _quoteToken,
            _strike,
            _maturity,
            _isCall,
            _amount,
            quoteAmount,
            _premium,
            _isMakerBuyer,
            DealStatus.Open,
            msg.sender,
            address(0)
        );

        // store new deal
        _deals[deal.id] = deal;

        if (_isMakerBuyer) {
            // maker is buyer: deposit premium
            _safeTransferFrom(_quoteToken, msg.sender, address(this), _premium);
        } else {
            if (_isCall) {
                // maker is call seller: deposit underlying tokens
                _safeTransferFrom(_underlyingToken, msg.sender, address(this), _amount);
            } else {
                // maker is put seller: deposit quote tokens
                _safeTransferFrom(_quoteToken, msg.sender, address(this), quoteAmount);
            }
        }

        emit DealCreated(
            deal.id,
            deal.underlyingToken,
            deal.quoteToken,
            deal.strike,
            deal.maturity,
            deal.isCall,
            deal.amount,
            deal.quoteAmount,
            deal.premium,
            deal.isMakerBuyer,
            msg.sender
        );
        ++dealCounter;

        return deal.id;
    }

    function takeDeal(uint id) external {
        if (isDealExpired(id)) revert Option__DealExpired();

        Deal memory deal = getDeal(id);
        if (deal.status != DealStatus.Open) revert Option__DealNotOpen();

        if (!deal.isMakerBuyer) {
            // taker is buyer: transfer premium to the seller (maker)
            _safeTransferFrom(deal.quoteToken, msg.sender, deal.maker, deal.premium);
        } else {
            if (deal.isCall) {
                // taker is call seller: deposit margin
                _safeTransferFrom(deal.underlyingToken, msg.sender, address(this), deal.amount);
            } else {
                // taker is put seller: deposit quote tokens
                _safeTransferFrom(deal.quoteToken, msg.sender, address(this), deal.quoteAmount);
            }
            // transfer premium to the seller (taker)
            _safeTransfer(deal.quoteToken, msg.sender, deal.premium);
        }

        _deals[id].taker = msg.sender;
        _deals[id].status = DealStatus.Taken;
        emit DealTaken(id, msg.sender);
    }

    function _removeDeal(uint id) internal {
        Deal memory deal = getDeal(id);
        if (deal.isMakerBuyer) {
            _safeTransfer(deal.quoteToken, msg.sender, deal.premium);
        } else {
            if (deal.isCall) {
                _safeTransfer(deal.underlyingToken, msg.sender, deal.amount);
            } else {
                _safeTransfer(deal.quoteToken, msg.sender, deal.quoteAmount);
            }
        }
        _deals[id].status = DealStatus.Removed;
        emit DealRemoved(id);
    }

    function removeDeal(uint id) external {
        Deal memory deal = getDeal(id);
        if (deal.maker != msg.sender) revert Option__NotDealMaker();
        if (deal.status != DealStatus.Open) revert Option__DealNotOpen();
        _removeDeal(id);
    }

    function settleDeal(uint id) external {
        if (!isDealExpired(id)) revert Option__DealNotExpired();
        Deal memory deal = getDeal(id);

        // only maker or taker can settle
        if (msg.sender != deal.maker && msg.sender != deal.taker) revert Option__InvalidSettler();

        // if there is no taker or was not exercised after 24h, remove deal
        if (deal.taker == address(0) || block.timestamp - deal.maturity >= 24 hours) {
            _removeDeal(id);
            return;
        }

        // check if exercisable
        uint price = getPrice(deal.underlyingToken, deal.quoteToken);
        bool exercisable = (deal.isCall && price >= deal.strike) ||
            (!deal.isCall && price <= deal.strike);

        address seller = getDealSeller(id);
        if (msg.sender == seller) {
            // option is exercisable and seller cannot settle
            if (exercisable) revert Option__InvalidSettler();

            if (deal.isCall) {
                // call expires worthless and seller can settle: refund underlying token to the seller
                _safeTransfer(deal.underlyingToken, msg.sender, deal.amount);
            } else {
                // put expires worthless and seller can settle: refund quote token to the seller
                _safeTransfer(deal.quoteToken, msg.sender, deal.quoteAmount);
            }
        } else {
            // option is not exercisable and buyer cannot settle
            if (!exercisable) revert Option__InvalidSettler();

            if (deal.isCall) {
                // call is exercisable: buyer buys the margin with the quote token
                _safeTransferFrom(deal.quoteToken, msg.sender, seller, deal.quoteAmount);
                _safeTransfer(deal.underlyingToken, msg.sender, deal.amount);
            } else {
                // put is exercisable: buyer sells the underlying in exchange for the quote token
                _safeTransferFrom(deal.underlyingToken, msg.sender, seller, deal.amount);
                _safeTransfer(deal.quoteToken, msg.sender, deal.quoteAmount);
            }
        }

        _deals[id].status = DealStatus.Settled;
        emit DealSettled(id, exercisable);
    }

    function getDeal(uint id) public view returns (Deal memory) {
        Deal memory deal = _deals[id];
        if (deal.id == 0) revert Option__DealNotFound();
        return deal;
    }

    function isDealExpired(uint id) public view returns (bool) {
        Deal memory deal = getDeal(id);
        return (block.timestamp >= deal.maturity);
    }

    function getDealBuyer(uint id) public view returns (address) {
        Deal memory deal = getDeal(id);
        if (deal.isMakerBuyer) {
            return deal.maker;
        } else {
            if (deal.taker == address(0)) revert Option__DealHasNoTaker();
            return deal.taker;
        }
    }

    function getDealSeller(uint id) public view returns (address) {
        Deal memory deal = getDeal(id);
        if (!deal.isMakerBuyer) {
            return deal.maker;
        } else {
            if (deal.taker == address(0)) revert Option__DealHasNoTaker();
            return deal.taker;
        }
    }

    function getPrice(address _underlyingToken, address _quoteToken) public view returns (uint) {
        address priceFeedAddress = getPriceFeed(_underlyingToken, _quoteToken);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    /**
     * @notice Get decimals of underlying token, quote token and price feed for a given deal
     * @param id deal ID
     * @return decimals of (underlyingToken, quoteToken, priceFeed)
     */
    function getDealDecimals(uint id) external view returns (uint8, uint8, uint8) {
        Deal memory deal = getDeal(id);
        return getDecimals(deal.underlyingToken, deal.quoteToken);
    }

    function getDecimals(
        address _underlyingToken,
        address _quoteToken
    ) public view returns (uint8, uint8, uint8) {
        address priceFeedAddress = getPriceFeed(_underlyingToken, _quoteToken);

        return (
            ERC20(_underlyingToken).decimals(),
            ERC20(_quoteToken).decimals(),
            AggregatorV3Interface(priceFeedAddress).decimals()
        );
    }
}
