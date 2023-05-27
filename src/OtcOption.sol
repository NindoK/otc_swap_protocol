// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AggregatorV3Interface.sol";

error Option__DepositPremiumFailed();
error Option__DepositMarginFailed();
error Option__TransferPremiumFailed();
error Option__TransferMarginFailed();
error Option__DealNotOpen();
error Option__NotExpired();
error Option__DealNotFound();
error Option__DealHasNoTaker();

contract OtcOption {
    event DealCreated(
        uint id,
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
    address public immutable underlyingToken;
    address public immutable quoteToken;
    AggregatorV3Interface public immutable priceFeed;

    uint private _dealCounter = 1;
    mapping(uint => Deal) private _deals;

    constructor(address _underlyingToken, address _quoteToken, address _priceFeedAddress) {
        underlyingToken = _underlyingToken;
        quoteToken = _quoteToken;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function createDeal(
        uint _strike,
        uint _maturity,
        bool _isCall,
        uint _amount,
        uint _premium,
        bool _isMakerBuyer
    ) external returns (uint) {
        Deal memory deal = Deal(
            _dealCounter,
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
            bool success = IERC20(quoteToken).transferFrom(
                msg.sender,
                address(this),
                _premium * _amount
            );
            if (!success) revert Option__DepositPremiumFailed();
        } else {
            // maker is seller: deposit underlying tokens
            bool success = IERC20(underlyingToken).transferFrom(msg.sender, address(this), _amount);
            if (!success) revert Option__DepositMarginFailed();
        }

        emit DealCreated(
            deal.id,
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
        Deal memory deal = getDeal(id);
        if (deal.status != DealStatus.Open) revert Option__DealNotOpen();
        if (deal.isMakerBuyer) {
            // taker is seller: deposit margin
            bool success = IERC20(underlyingToken).transferFrom(
                msg.sender,
                address(this),
                deal.amount
            );
            if (!success) revert Option__DepositMarginFailed();

            // transfer premium to the seller (taker)
            success = IERC20(quoteToken).transfer(msg.sender, deal.premium * deal.amount);
            if (!success) revert Option__TransferPremiumFailed();
        } else {
            // taker is buyer: transfer premium to the seller (maker)
            bool success = IERC20(quoteToken).transferFrom(
                msg.sender,
                deal.maker,
                deal.premium * deal.amount
            );
            if (!success) revert Option__DepositPremiumFailed();
        }

        _deals[id].status = DealStatus.Taken;
        emit DealTaken(id, msg.sender);
    }

    function settleDeal(uint id) external {
        Deal memory deal = getDeal(id);
        if (block.timestamp < deal.maturity) revert Option__NotExpired();

        uint price = _getUnderlyingPrice();
        bool canBeExercised = (deal.isCall && price >= deal.strike) ||
            (!deal.isCall && price <= deal.strike);

        // if canBeExercised: transfer underlying tokens to the buyer
        // otherwise expired worthless: refund margin to the seller
        address receiver = canBeExercised ? _getDealBuyer(deal) : _getDealSeller(deal);

        bool success = IERC20(underlyingToken).transfer(receiver, deal.amount);
        if (!success) revert Option__TransferMarginFailed();

        _deals[id].status = DealStatus.Settled;
        emit DealSettled(id);
    }

    function getDeal(uint id) public view returns (Deal memory) {
        Deal memory deal = _deals[id];
        if (deal.id == 0) revert Option__DealNotFound();
        return deal;
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

    function _getUnderlyingPrice() private view returns (uint) {
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
