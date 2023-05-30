// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OtcMath.sol";

error Router__InvalidTokenAmount();
error Router__InvalidPriceAmount();
error Router__InvalidPriceMultiplier();
error Router__InvalidDeadline();
error Router__InvalidTokenAddresses();
error Router__InvalidTokenAndAmountMismatch();
error Router__AllowanceToken0TooLow();
error Router__AllowanceToken1TooLow();
error Router__ApproveToken0Failed();
error Router__DepositToken0Failed();
error Router__RfsRemoved();
error Router__Amount1TooHigh();
error Router__TransferToken0Failed();
error Router__TransferToken1Failed();
error Router__NotMaker();
error Router__RefundToken0Failed();
error Router__OnlyFixedOrDynamicAllowed();
error Router__OnlyFixedPriceOrAmountAllowed();
error Router__OnlyOneTokenAccepted();
error Router__InvalidTokenIndex();
error Router__InvalidAggregatorAddress();

/**
 * @title OtcNexus
 * @notice core swap functionality
 */
contract OtcNexus is Ownable {
    uint256 public rfsIdCounter;

    mapping(uint256 => RFS) private idToRfs;
    mapping(address => RFS[]) private makerRfs;

    //Given a token, return the price feed aggregator (Skipping the second token since we only need to know the price in USD)
    mapping(address => address) public priceFeeds;

    enum RfsType {
        DYNAMIC,
        FIXED
    }
    enum TokenInteractionType {
        TOKEN_DEPOSITED,
        TOKEN_APPROVED
    }

    struct RFS {
        uint256 id;
        uint256 amount0;
        uint256 amount1;
        uint256 usdPrice; // Implies the fixed price per token0
        uint256 deadline;
        address maker;
        uint8 priceMultiplier;
        RfsType typeRfs;
        TokenInteractionType interactionType;
        bool removed;
        address token0;
        address[] tokensAccepted;
    }

    event RfsUpdated(uint256 rfsId, uint256 amount0, uint256 amount1, uint256 deadline);
    event RfsFilled(uint256 rfsId, address taker, uint256 amount0, uint256 amount1);
    event RfsRemoved(uint256 rfsId, bool permanentlyDeleted);
    event RfsCreated(
        uint256 rfsId,
        address maker,
        address indexed token0,
        address[] indexed tokensAccepted,
        uint256 amount0,
        uint256 usdPrice,
        uint8 priceMultiplier,
        uint256 deadline
    );

    /**
     * @notice create an RFS where the price is either fixed to a USD price or it requests only a specific amount of tokens
     * @param _token0 token offered
     * @param _tokensAccepted token requested
     * @param _amount0 amount of token offered
     * @param _amount1 amount of token requested
     * @param _usdPrice fixed price of the asset
     * @param _deadline timestamp after which the RFS expires
     * @param interactionType if the tokens are deposited or approved
     * @return rfsId
     */
    function createFixedRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _usdPrice,
        uint256 _deadline,
        TokenInteractionType interactionType
    ) external returns (uint256) {
        if ((_amount1 != 0 && _usdPrice != 0) || (_amount1 == 0 && _usdPrice == 0))
            revert Router__OnlyFixedPriceOrAmountAllowed();
        if (_amount1 != 0 && _tokensAccepted.length != 1) revert Router__OnlyOneTokenAccepted();
        return
            _createRfs(
                _token0,
                _tokensAccepted,
                _amount0,
                _amount1,
                _usdPrice,
                0,
                _deadline,
                RfsType.FIXED,
                interactionType
            );
    }

    /**
     * @notice create a dynamic RFS where the price is based on the current price of the asset and a multiplier
     * that is applied to the current price (either a discount or a premium)
     * @param _token0 token offered
     * @param _tokensAccepted token requested
     * @param _amount0 amount of token offered
     * @param _priceMultiplier priceMultiplier compared to the current price of the asset
     * @param _deadline timestamp after which the RFS expires
     * @param interactionType if the token is deposited or approved to be spent
     * @return rfsId
     */
    function createDynamicRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint8 _priceMultiplier,
        uint256 _deadline,
        TokenInteractionType interactionType
    ) external returns (uint256) {
        if (_priceMultiplier == 0) revert Router__InvalidPriceMultiplier();
        return
            _createRfs(
                _token0,
                _tokensAccepted,
                _amount0,
                0,
                0,
                _priceMultiplier,
                _deadline,
                RfsType.DYNAMIC,
                interactionType
            );
    }

    /**
     * @dev Internal function to create a new RFS.
     * @param _token0 The token offered by the maker.
     * @param _tokensAccepted The tokens accepted by the maker.
     * @param _amount0 The amount of token0 offered.
     * @param _amount1 The amount of token1 that might be requested.
     * @param _usdPrice The USD price of the asset if set.
     * @param _priceMultiplier The price multiplier to apply to the current price of the asset.
     * @param _deadline The timestamp after which the RFS expires.
     * @param typeRfs dynamic or fixed
     * @param interactionType if the token is deposited or approved to be spent
     * @return The ID of the newly created RFS.
     */
    function _createRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _usdPrice,
        uint8 _priceMultiplier,
        uint256 _deadline,
        RfsType typeRfs,
        TokenInteractionType interactionType
    ) private returns (uint256) {
        // sanity checks
        if (_deadline < block.timestamp) revert Router__InvalidDeadline();
        if (_amount0 == 0) revert Router__InvalidTokenAmount();
        if (_tokensAccepted.length == 0) revert Router__InvalidTokenAddresses();
        if (IERC20(_token0).allowance(msg.sender, address(this)) < _amount0)
            revert Router__AllowanceToken0TooLow();

        if (interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            // transfer sell token to contract
            bool success = IERC20(_token0).transferFrom(msg.sender, address(this), _amount0);
            if (!success) revert Router__DepositToken0Failed();
        }

        // create RFS
        idToRfs[rfsIdCounter] = RFS(
            rfsIdCounter, // id
            _amount0, // amount0
            _amount1, // amount1
            _usdPrice, // price
            _deadline, // deadline
            msg.sender, // maker
            _priceMultiplier, // priceMultiplier
            typeRfs, // is dynamic or fixed
            interactionType, // is deposited or approved to be spent
            false, // removed
            _token0, // token0
            _tokensAccepted // tokensAccepted
        );

        makerRfs[msg.sender].push(idToRfs[rfsIdCounter]);

        unchecked {
            emit RfsCreated(
                rfsIdCounter++,
                msg.sender,
                _token0,
                _tokensAccepted,
                _amount0,
                _usdPrice,
                _priceMultiplier,
                _deadline
            );
        }

        return rfsIdCounter;
    }

    /**
     * @notice take a fixed price RFS
     * @param _id id of the RFS
     * @param _paymentTokenAmount amount of tokens used to pay for the RFS
     * @param index index of the token used to buy
     * @return success
     */
    function takeFixedRfs(
        uint256 _id,
        uint256 _paymentTokenAmount,
        uint256 index
    ) external returns (bool success) {
        RFS memory rfs = getRfs(_id);

        // sanity checks
        if (rfs.removed) revert Router__RfsRemoved();
        if (_paymentTokenAmount == 0) revert Router__InvalidTokenAmount();
        if (index >= rfs.tokensAccepted.length) revert Router__InvalidTokenIndex();
        if (
            IERC20(rfs.tokensAccepted[index]).allowance(msg.sender, address(this)) <
            _paymentTokenAmount
        ) revert Router__AllowanceToken1TooLow();

        uint256 _amount0;
        if (rfs.usdPrice == 0) {
            // compute _amount0 based on _paymentTokenAmount and implied quote, and update RFS amounts
            _amount0 = OtcMath.getTakerAmount0(rfs.amount0, rfs.amount1, _paymentTokenAmount);
            if (_paymentTokenAmount > rfs.amount1) revert Router__Amount1TooHigh();
        } else {
            // compute _amount0 based on _paymentTokenAmount and usdPrice, and update RFS amounts using ChainLink by getting the price of the chosen token (So we can't have a RFS with a token that is not indexed by ChainLink)
            address aggregator = priceFeeds[rfs.tokensAccepted[index]];
            //If it is never been set, it will be 0x00...00
            if (aggregator == address(0)) revert Router__InvalidAggregatorAddress();
            (, int256 price, , , ) = AggregatorV3Interface(aggregator).latestRoundData();

            //since the pair X/USD has always 8 decimals, we can just multiply by 1e8 the requested price so we get a better precision
            //Reusing the same function as above, but even if the amount are different, math is the same
            _amount0 = OtcMath.getTakerAmount0(
                _paymentTokenAmount,
                rfs.usdPrice * 1e8,
                uint256(price)
            );
            if (_amount0 > rfs.amount0) revert Router__Amount1TooHigh();
        }

        // transfer token1 to the maker
        success = IERC20(rfs.tokensAccepted[index]).transferFrom(
            msg.sender,
            rfs.maker,
            _paymentTokenAmount
        );
        if (!success) revert Router__TransferToken1Failed();

        // transfer token0 to the taker
        address from;
        if (rfs.interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            from = address(this);
        } else {
            from = rfs.maker;
        }
        success = IERC20(rfs.token0).transferFrom(from, msg.sender, _amount0);
        if (!success) revert Router__TransferToken0Failed();

        // update RFS
        updateRfs(rfs, _amount0, _paymentTokenAmount, rfs.usdPrice != 0);
        emit RfsFilled(_id, msg.sender, _amount0, _paymentTokenAmount);
    }

    //TODO : Add a function to take a dynamic price RFS
    /*
  function takeDynamicRfs(
        uint256 _id,
        ... //TODO : Add the parameters
    ) external returns (bool success) {
}
    */

    function updateRfs(RFS memory rfs, uint256 _amount0, uint256 _amount1, bool usdPriced) private {
        rfs.amount0 -= _amount0;
        if (!usdPriced) {
            rfs.amount1 -= _amount1;
        }
        if (rfs.amount0 == 0 || (rfs.amount1 == 0 && !usdPriced)) {
            rfs.removed = true;
            delete idToRfs[rfs.id];
            emit RfsRemoved(rfs.id, true);
        } else {
            idToRfs[rfs.id] = rfs;
            emit RfsUpdated(rfs.id, rfs.amount0, rfs.amount1, rfs.deadline);
        }
    }

    /**
     * @notice remove an RFS
     * @param _id ID of the RFS
     * @param _permanentlyDelete if the RFS should be permanently deleted
     * @return success
     */
    function removeRfs(uint256 _id, bool _permanentlyDelete) external returns (bool success) {
        RFS memory rfs = idToRfs[_id];
        // only the maker can remove the RFS
        if (msg.sender != rfs.maker) revert Router__NotMaker();

        if (rfs.interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            // refund deposited tokens to the maker
            // No need to check for revert as transferFrom revert automatically
            success = IERC20(rfs.token0).transferFrom(address(this), rfs.maker, rfs.amount0);
            if (!success) revert Router__TransferToken0Failed();
        }
        idToRfs[_id].removed = true;

        //Privacy and gas refund

        if (_permanentlyDelete) delete idToRfs[_id];
        emit RfsRemoved(_id, _permanentlyDelete);
    }

    /**
     * @notice get an RFS
     * @param _id ID of the RFS
     * @return RFS
     */
    function getRfs(uint256 _id) public view returns (RFS memory) {
        return idToRfs[_id];
    }

    /**
     * @notice set the pricefeeds aggregator for a token
     * @dev this is used to get the price of a token in USD
     * @dev this is only callable by the owner, since after deployment
     * @dev we need to set the pricefeeds manually (algorithmically)
     */
    function setPriceFeeds(address _address1, address _aggregator) public onlyOwner {
        priceFeeds[_address1] = _aggregator;
    }
}
