// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error Option__InvalidUnderlyingToken();
error Option__InvalidQuoteToken();
error Option__InvalidStrike();
error Option__InvalidMaturity();
error Option__InvalidAmount();
error Option__InvalidPremium();

error Option__PriceFeedNotFound();
error Option__DepositPremiumFailed();
error Option__DepositMarginFailed();
error Option__TransferPremiumFailed();
error Option__TransferMarginFailed();
error Option__DealNotOpen();
error Option__DealExpired();
error Option__DealNotExpired();
error Option__DealNotFound();
error Option__DealHasNoTaker();

contract OtcOption is Ownable {
    event DealCreated(
        uint id,
        address underlyingToken,
        address quoteToken,
        uint strike,
        uint maturity,
        bool isCall,
        uint amount,
        uint premium,
        bool isMakerBuyer,
        address maker
    );
    event DealTaken(uint id, address taker);
    event DealRemoved(uint id);
    event DealSettled(uint id);

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
        uint premium;
        address maker;
        address taker;
        bool isMakerBuyer;
        DealStatus status;
    }

    // status variables
    mapping(address => mapping(address => address)) private _priceFeeds; // underlying => (quote => feed)
    uint private _dealCounter = 1;
    mapping(uint => Deal) private _deals;

    function addPriceFeed(
        address _underlyingToken,
        address _quoteToken,
        address _priceFeedAddress
    ) public onlyOwner {
        _priceFeeds[_underlyingToken][_quoteToken] = _priceFeedAddress;
    }

    function getPriceFeed(
        address _underlyingToken,
        address _quoteToken
    ) public view returns (address) {
        address priceFeed = _priceFeeds[_underlyingToken][_quoteToken];
        if (priceFeed == address(0)) revert Option__PriceFeedNotFound();
        return priceFeed;
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

        Deal memory deal = Deal(
            _dealCounter,
            _underlyingToken,
            _quoteToken,
            _strike,
            _maturity,
            _isCall,
            _amount,
            _premium,
            msg.sender,
            address(0),
            _isMakerBuyer,
            DealStatus.Open
        );

        // store new deal
        _deals[deal.id] = deal;

        if (deal.isMakerBuyer) {
            // maker is buyer: deposit premium
            bool success = IERC20(deal.quoteToken).transferFrom(
                msg.sender,
                address(this),
                _premium
            );
            if (!success) revert Option__DepositPremiumFailed();
        } else {
            // maker is seller: deposit underlying tokens
            bool success = IERC20(deal.underlyingToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            if (!success) revert Option__DepositMarginFailed();
        }

        emit DealCreated(
            deal.id,
            deal.underlyingToken,
            deal.quoteToken,
            deal.strike,
            deal.maturity,
            deal.isCall,
            deal.amount,
            deal.premium,
            deal.isMakerBuyer,
            msg.sender
        );
        ++_dealCounter;

        return deal.id;
    }

    function takeDeal(uint id) external {
        if (isDealExpired(id)) revert Option__DealExpired();

        Deal memory deal = getDeal(id);
        if (deal.status != DealStatus.Open) revert Option__DealNotOpen();
        if (deal.isMakerBuyer) {
            // taker is seller: deposit margin
            bool success = IERC20(deal.underlyingToken).transferFrom(
                msg.sender,
                address(this),
                deal.amount
            );
            if (!success) revert Option__DepositMarginFailed();

            // transfer premium to the seller (taker)
            success = IERC20(deal.quoteToken).transfer(msg.sender, deal.premium);
            if (!success) revert Option__TransferPremiumFailed();
        } else {
            // taker is buyer: transfer premium to the seller (maker)
            bool success = IERC20(deal.quoteToken).transferFrom(
                msg.sender,
                deal.maker,
                deal.premium
            );
            if (!success) revert Option__DepositPremiumFailed();
        }

        _deals[id].status = DealStatus.Taken;
        emit DealTaken(id, msg.sender);
    }

    function settleDeal(uint id) external {
        if (!isDealExpired(id)) revert Option__DealNotExpired();
        Deal memory deal = getDeal(id);

        uint price = getPrice(deal.underlyingToken, deal.quoteToken);
        bool canBeExercised = (deal.isCall && price >= deal.strike) ||
            (!deal.isCall && price <= deal.strike);

        // if canBeExercised: transfer underlying tokens to the buyer
        // otherwise expired worthless: refund margin to the seller
        address receiver = canBeExercised ? _getDealBuyer(deal) : _getDealSeller(deal);

        bool success = IERC20(deal.underlyingToken).transfer(receiver, deal.amount);
        if (!success) revert Option__TransferMarginFailed();

        _deals[id].status = DealStatus.Settled;
        emit DealSettled(id);
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

    function _getDealBuyer(Deal memory deal) private pure returns (address) {
        if (deal.isMakerBuyer) {
            return deal.maker;
        } else {
            if (deal.taker == address(0)) revert Option__DealHasNoTaker();
            return deal.taker;
        }
    }

    function _getDealSeller(Deal memory deal) private pure returns (address) {
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
}
