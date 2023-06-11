// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OtcMath.sol";
import "./OtcToken.sol";
import "forge-std/console.sol";

error OtcNexus__InvalidTokenAmount();
error OtcNexus__InvalidPriceAmount();
error OtcNexus__InvalidPriceMultiplier();
error OtcNexus__InvalidDeadline();
error OtcNexus__InvalidTokenAddresses();
error OtcNexus__InvalidTokenAndAmountMismatch();
error OtcNexus__InvalidTokenIndex();
error OtcNexus__InvalidAggregatorAddress();
error OtcNexus__InvalidRfsType();
error OtcNexus__InvalidTakerAddress();
error OtcNexus__InvalidInteractionTypeForPaypal();

error OtcNexus__OnlyFixedOrDynamicAllowed();
error OtcNexus__OnlyFixedPriceOrAmountAllowed();
error OtcNexus__OnlyOneTokenAccepted();
error OtcNexus__OnlyRelayer();
error OtcNexus__NotMaker();

error OtcNexus__AllowanceToken0TooLow();
error OtcNexus__AllowanceToken1TooLow();
error OtcNexus__ApproveToken0Failed();
error OtcNexus__DepositToken0Failed();
error OtcNexus__Amount1TooHigh();
error OtcNexus__Amount0TooHigh();
error OtcNexus__TransferTokenFailed();
error OtcNexus__TransferToken0Failed();
error OtcNexus__TransferToken1Failed();
error OtcNexus__RefundToken0Failed();

error OtcNexus__RfsRemoved();
error OtcNexus__NoRewardsToClaim();
error OtcNexus__NoTokensToClaim();

/**
 * @title OtcNexus
 * @notice core swap functionality
 */
contract OtcNexus is Ownable {
    // rfs with id 0 will mean null in the context: getRfs(_id).id == 0 => RFS is not found
    uint256 public rfsIdCounter = 1;
    address private relayer;
    uint8 public makerFeeIfDeposited;
    uint8 public makerFeeIfNotDeposited;
    uint8 public takerFee;
    OtcToken public otcToken;

    mapping(uint256 => RFS) private idToRfs;
    mapping(address => RFS[]) private makerRfs;
    mapping(address => uint256) private userRewards;

    //Given a token, return the price feed aggregator (Skipping the second token since we only need to know the price in USD)
    mapping(address => address) private priceFeeds;

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
        uint256 currentAmount0;
        uint256 initialAmount0;
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

    modifier onlyRelayer() {
        if (msg.sender != relayer) revert OtcNexus__OnlyRelayer();
        _;
    }

    constructor(address _otcTokenAddress) {
        makerFeeIfDeposited = 25; // 0.25%
        makerFeeIfNotDeposited = 50; // 0.5%
        takerFee = 25; // 0.25%
        otcToken = OtcToken(_otcTokenAddress);
    }

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
            revert OtcNexus__OnlyFixedPriceOrAmountAllowed();
        if (_amount1 != 0 && _tokensAccepted.length != 1) revert OtcNexus__OnlyOneTokenAccepted();
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
     *
     * It should allow only tokens that have a price feed aggregator, otherwise we can't dynamically calculate the price
     *
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
        if (_priceMultiplier == 0) revert OtcNexus__InvalidPriceMultiplier();
        if (priceFeeds[_token0] == address(0)) revert OtcNexus__InvalidAggregatorAddress();
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
        if (_deadline < block.timestamp) revert OtcNexus__InvalidDeadline();
        if (_amount0 == 0) revert OtcNexus__InvalidTokenAmount();
        if (_tokensAccepted.length == 0 || _tokensAccepted.length > 5)
            revert OtcNexus__InvalidTokenAddresses();
        //Comment for easier local testing
        if (IERC20(_token0).allowance(msg.sender, address(this)) < _amount0)
            revert OtcNexus__AllowanceToken0TooLow();
        if (_usdPrice != 0) {
            for (uint i = 0; i < _tokensAccepted.length; i++) {
                if (priceFeeds[_tokensAccepted[i]] == address(0))
                    revert OtcNexus__InvalidAggregatorAddress();
            }
        }
        if (interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            // transfer sell token to contract
            bool success = IERC20(_token0).transferFrom(msg.sender, address(this), _amount0);
            if (!success) revert OtcNexus__DepositToken0Failed();
        }

        // create RFS
        idToRfs[rfsIdCounter] = RFS(
            rfsIdCounter, // id
            _amount0, // currentAmount0
            _amount0, // totalAmount0
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

        return rfsIdCounter - 1;
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
        return takeRfs(_id, _paymentTokenAmount, index, RfsType.FIXED);
    }

    /**
     * @notice take a dynamic price RFS
     * @param _id id of the RFS
     * @param _paymentTokenAmount amount of tokens used to pay for the RFS
     * @param index index of the token used to buy
     * @return success
     */
    function takeDynamicRfs(
        uint256 _id,
        uint256 _paymentTokenAmount,
        uint256 index
    ) external returns (bool success) {
        return takeRfs(_id, _paymentTokenAmount, index, RfsType.DYNAMIC);
    }

    /**
     * @notice take a fixed price RFS
     * @param _id id of the RFS
     * @param _paymentTokenAmount amount of tokens used to pay for the RFS
     * @param index index of the token used to buy
     * @param expectedRfsType type of the Rfs: FIXED or DYNAMIC
     * @return success
     */
    function takeRfs(
        uint256 _id,
        uint256 _paymentTokenAmount,
        uint256 index,
        RfsType expectedRfsType
    ) internal returns (bool success) {
        RFS memory rfs = getRfs(_id);

        // sanity checks
        if (rfs.removed || rfs.id == 0) revert OtcNexus__RfsRemoved();
        if (rfs.deadline < block.timestamp) revert OtcNexus__InvalidDeadline();
        if (rfs.typeRfs != expectedRfsType) revert OtcNexus__InvalidRfsType();
        if (_paymentTokenAmount == 0) revert OtcNexus__InvalidTokenAmount();
        if (index >= rfs.tokensAccepted.length) revert OtcNexus__InvalidTokenIndex();
        if (
            IERC20(rfs.tokensAccepted[index]).allowance(msg.sender, address(this)) <
            _paymentTokenAmount
        ) revert OtcNexus__AllowanceToken1TooLow();

        //0.25% fee on the payment token of the taker FLAT FEE
        (uint256 feeAmount1, uint256 _paymentTokenAmountAfterTakerFee) = calculateFee(
            takerFee,
            _paymentTokenAmount
        );
        // compute _amount0 (depends on rfs.typeRfs, so this is left to takeFixedRfs/takeDynamicRfs)
        uint256 _amountBuying = computeAmount0(
            _id,
            _paymentTokenAmountAfterTakerFee,
            index,
            expectedRfsType
        );
        if (_amountBuying > rfs.currentAmount0) revert OtcNexus__Amount0TooHigh();

        //0.25% fee on the token0 of the maker FLAT FEE if DEPOSITED, otherwise 0.5% if APPROVED
        (uint256 feeAmount2, uint256 _paymentTokenAmountAfterMakerFee) = calculateFee(
            rfs.interactionType == TokenInteractionType.TOKEN_DEPOSITED
                ? makerFeeIfDeposited
                : makerFeeIfNotDeposited,
            _paymentTokenAmountAfterTakerFee
        );
        // transfer token1 to the maker
        success = IERC20(rfs.tokensAccepted[index]).transferFrom(
            msg.sender,
            rfs.maker,
            _paymentTokenAmountAfterMakerFee
        );
        if (!success) revert OtcNexus__TransferToken1Failed();

        success = IERC20(rfs.tokensAccepted[index]).transferFrom(
            msg.sender,
            address(this),
            feeAmount1 + feeAmount2
        );
        if (!success) revert OtcNexus__TransferToken1Failed();

        // transfer token0 to the taker
        if (rfs.interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            success = IERC20(rfs.token0).transfer(msg.sender, _amountBuying);
        } else {
            success = IERC20(rfs.token0).transferFrom(rfs.maker, msg.sender, _amountBuying);
        }

        if (!success) revert OtcNexus__TransferToken0Failed();

        // update RFS
        updateRfs(rfs, _amountBuying, _paymentTokenAmount);
        computeRewards(rfs.maker, msg.sender, _amountBuying, rfs.initialAmount0);

        emit RfsFilled(_id, msg.sender, _amountBuying, _paymentTokenAmount);
    }

    /**
     * @notice take a fixed price RFS when the taker pays with paypal
     * @param _id id of the RFS
     * @param _token0Bought amount of tokens that are bought
     * @param _takerAddress address of the taker
     * @return success
     *
     *  Requirements:
     *
     * - The caller must be the relayer.
     */
    function takeFixedRfsPaypal(
        uint256 _id,
        uint256 _token0Bought,
        address _takerAddress
    ) external onlyRelayer returns (bool success) {
        return takeRfsPaypal(_id, _token0Bought, _takerAddress, RfsType.FIXED);
    }

    /**
     * @notice take a dynamic price RFS when the taker pays with paypal
     * @param _id id of the RFS
     * @param _token0Bought amount of tokens that are bought
     * @param _takerAddress address of the taker
     * @return success
     *
     *  Requirements:
     *
     * - The caller must be the relayer.
     */
    function takeDynamicRfsPaypal(
        uint256 _id,
        uint256 _token0Bought,
        address _takerAddress
    ) external onlyRelayer returns (bool success) {
        return takeRfsPaypal(_id, _token0Bought, _takerAddress, RfsType.DYNAMIC);
    }

    /**
     * @notice take a fixed price RFS when the taker pays with paypal
     * @param _id id of the RFS
     * @param _token0Bought amount of tokens that are bought
     * @param _takerAddress address of the taker
     * @param expectedRfsType type of the Rfs: FIXED or DYNAMIC
     * @return success
     *
     *  Requirements:
     *
     * - The caller must be the relayer.
     */
    function takeRfsPaypal(
        uint256 _id,
        uint256 _token0Bought,
        address _takerAddress,
        RfsType expectedRfsType
    ) internal returns (bool success) {
        RFS memory rfs = getRfs(_id);

        // sanity checks
        if (rfs.interactionType != TokenInteractionType.TOKEN_DEPOSITED)
            revert OtcNexus__InvalidInteractionTypeForPaypal();
        if (rfs.removed || rfs.id == 0) revert OtcNexus__RfsRemoved();
        if (rfs.deadline < block.timestamp) revert OtcNexus__InvalidDeadline();
        if (rfs.typeRfs != expectedRfsType) revert OtcNexus__InvalidRfsType();
        if (_token0Bought == 0) revert OtcNexus__InvalidTokenAmount();
        if (rfs.typeRfs == RfsType.FIXED && rfs.usdPrice == 0)
            revert OtcNexus__OnlyFixedOrDynamicAllowed();

        // transfer token0 to the taker
        success = IERC20(rfs.token0).transfer(_takerAddress, _token0Bought);

        if (!success) revert OtcNexus__TransferToken0Failed();

        // update RFS
        updateRfs(rfs, _token0Bought, 0);
        computeRewards(rfs.maker, _takerAddress, _token0Bought, rfs.initialAmount0);

        emit RfsFilled(_id, _takerAddress, _token0Bought, 0);
    }

    /**
     * @dev This function updates the RFS structure, decreasing the amounts
     * of token0 and (in case of the presence of token1) token1.
     *
     * If after this operation amount of token0 becomes zero, or amount of token1 becomes zero, the RFS is marked as removed.
     *
     * If RFS is not removed, it is updated in the mapping and an event is emitted.
     *
     * @param rfs the RFS structure to update
     * @param _amount0 the amount of token0 to subtract from the RFS structure
     * @param _amount1 the amount of token1 to subtract from the RFS structure
     *
     * Emits an {RfsUpdated} event with current state of the RFS in case it was not removed.
     * Emits an {RfsRemoved} event with RFS id and status (true) in case it was removed.
     *
     * Requirements:
     *
     * - `rfs` must not be removed.
     * - `_amount0` must be less or equal to `rfs.amount0`.
     * - `_amount1` must be less or equal to `rfs.amount1` in case of fixed amount1.
     */
    function updateRfs(RFS memory rfs, uint256 _amount0, uint256 _amount1) private {
        rfs.currentAmount0 -= _amount0;
        if (rfs.usdPrice == 0 && rfs.typeRfs == RfsType.FIXED) {
            rfs.amount1 -= _amount1;
        }
        if (
            rfs.currentAmount0 == 0 ||
            (rfs.amount1 == 0 && rfs.usdPrice == 0 && rfs.typeRfs == RfsType.FIXED)
        ) {
            rfs.removed = true;
            delete idToRfs[rfs.id];
            emit RfsRemoved(rfs.id, true);
        } else {
            idToRfs[rfs.id] = rfs;
            emit RfsUpdated(rfs.id, rfs.currentAmount0, rfs.amount1, rfs.deadline);
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
        if (msg.sender != rfs.maker) revert OtcNexus__NotMaker();

        if (rfs.interactionType == TokenInteractionType.TOKEN_DEPOSITED) {
            // refund deposited tokens to the maker
            // No need to check for revert as transferFrom revert automatically
            success = IERC20(rfs.token0).transfer(rfs.maker, rfs.currentAmount0);
            if (!success) revert OtcNexus__TransferToken0Failed();
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
    function setPriceFeeds(address _address1, address _aggregator) external onlyOwner {
        priceFeeds[_address1] = _aggregator;
    }

    /**
     * @dev This function allows the owner of the contract to set the fee rates for different scenarios.
     *
     * This function can only be called by the owner of the contract. It sets the rates for three types of fees:
     * 1) `takerFee`: the fee rate for the taker of an RFS (Request For Service)
     * 2) `makerFeeIfDeposited`: the fee rate for the maker of an RFS if the maker has deposited their tokens
     * 3) `makerFeeIfNotDeposited`: the fee rate for the maker of an RFS if the maker has not deposited their tokens
     * @param _takerFee the fee rate for the taker, in basis points
     * @param _makerFeeIfDeposited the fee rate for the maker if they have deposited their tokens, in basis points
     * @param _makerFeeIfNotDeposited the fee rate for the maker if they have not deposited their tokens, in basis points
     *
     * Requirements:
     *
     * - The caller must be the owner of the contract.
     */
    function setFee(
        uint8 _takerFee,
        uint8 _makerFeeIfDeposited,
        uint8 _makerFeeIfNotDeposited
    ) external onlyOwner {
        takerFee = _takerFee;
        makerFeeIfDeposited = _makerFeeIfDeposited;
        makerFeeIfNotDeposited = _makerFeeIfNotDeposited;
    }

    /**
     * @dev This function allows the owner of the contract to set the address of the token used for rewards
     *
     * This function can only be called by the owner of the contract.
     * @param _otcTokenAddress the address of the token
     * Requirements:
     *
     * - The caller must be the owner of the contract.
     */
    function setOtcTokenAddress(address _otcTokenAddress) external onlyOwner {
        otcToken = OtcToken(_otcTokenAddress);
    }

    /**
     * @dev This function allows the owner of the contract to set the address of the relayer
     *
     * This function can only be called by the owner of the contract.
     * @param _relayerAddress the address of the relayer
     * Requirements:
     *
     * - The caller must be the owner of the contract.
     */
    function setRelayerAddress(address _relayerAddress) external onlyOwner {
        relayer = _relayerAddress;
    }

    /**
     * @notice Transfer all tokens of a specific ERC20 token from the contract to the contract's owner.
     * @dev This function can only be called by the contract owner.
     * @param _tokenAddr The address of the ERC20 token to be transferred.
     */
    function claimProtocolFees(address _tokenAddr) external onlyOwner {
        uint256 balance = IERC20(_tokenAddr).balanceOf(address(this));
        if (balance == 0) revert OtcNexus__NoTokensToClaim();

        if (!IERC20(_tokenAddr).transfer(owner(), balance)) revert OtcNexus__TransferTokenFailed();
    }

    /**
     * @dev This function allows users to claim their rewards.
     *
     * Users can call this function to claim any rewards that they have accumulated.
     * The amount of rewards that a user can claim is stored in the `userRewards` mapping.
     * If the user has no rewards to claim, the function will revert.
     * Otherwise, the amount of rewards is transferred to the user from this contract's balance of `otcToken`.
     *
     * Requirements:
     *
     * - The user must have non-zero rewards to claim.
     */
    function claimRewards() external {
        if (userRewards[msg.sender] == 0) revert OtcNexus__NoRewardsToClaim();
        uint256 rewards = userRewards[msg.sender];
        userRewards[msg.sender] = 0;
        otcToken.transfer(msg.sender, rewards);
    }

    /**
     * @notice compute the amount0 to be sent to the taker
     * @param _id id of the RFS
     * @param _paymentTokenAmount amount of tokens used to pay for the RFS
     * @param index index of the token used to buy
     * @param expectedRfsType type of the Rfs: FIXED or DYNAMIC
     * @dev helper function to compute the amount0 to be sent to the taker
     * @return _amount0 amount of token0 to be sent to the taker
     */
    function computeAmount0(
        uint256 _id,
        uint256 _paymentTokenAmount,
        uint256 index,
        RfsType expectedRfsType
    ) internal view returns (uint256 _amount0) {
        RFS memory rfs = getRfs(_id);

        if (expectedRfsType == RfsType.FIXED) {
            if (rfs.usdPrice == 0) {
                _amount0 = OtcMath.getTakerAmount0(
                    rfs.currentAmount0,
                    rfs.amount1,
                    _paymentTokenAmount
                );
                if (_paymentTokenAmount > rfs.amount1) revert OtcNexus__Amount1TooHigh();
            } else {
                address aggregator = priceFeeds[rfs.tokensAccepted[index]];
                if (aggregator == address(0)) revert OtcNexus__InvalidAggregatorAddress();
                (, int256 price, , , ) = AggregatorV3Interface(aggregator).latestRoundData();
                _amount0 = OtcMath.getTakerAmount0(
                    _paymentTokenAmount,
                    rfs.usdPrice * 1e8,
                    uint256(price)
                );
            }
        } else if (expectedRfsType == RfsType.DYNAMIC) {
            address aggregatorTaker = priceFeeds[rfs.tokensAccepted[index]];
            if (aggregatorTaker == address(0)) revert OtcNexus__InvalidAggregatorAddress();
            (, int256 priceTaker, , , ) = AggregatorV3Interface(aggregatorTaker).latestRoundData();

            address aggregatorMaker = priceFeeds[rfs.token0];
            if (aggregatorMaker == address(0)) revert OtcNexus__InvalidAggregatorAddress();
            (, int256 priceMaker, , , ) = AggregatorV3Interface(aggregatorMaker).latestRoundData();
            _amount0 = OtcMath.getTakerAmount0(
                _paymentTokenAmount,
                (uint256(priceMaker) * rfs.priceMultiplier) / 100,
                uint256(priceTaker)
            );
        } else {
            revert OtcNexus__InvalidRfsType();
        }
    }

    function computeRewards(
        address maker,
        address taker,
        uint256 _amount0Bought,
        uint256 _amount0Total
    ) internal {
        uint256 percentageBought = (_amount0Bought * OtcToken(otcToken).decimals()) / _amount0Total; //Calculate the percentage of the total amount bought with the decimals of the token so less computations and we can just send this amount
        unchecked {
            userRewards[taker] = percentageBought;
            userRewards[maker] = percentageBought * 3; //3x the amount of the buyer
        }
    }

    /**
     * @dev This function calculates the fee to be taken from a specified amount based on a
     * given fee percentage. It also calculates the amount left after the fee is taken.
     *
     * The fee is calculated as a percentage of the input amount, where the percentage is
     * expressed as a value out of 10,000 (i.e., basis points). For example, if the
     * `applicableFeePercentage` is 50, then the fee will be 0.5% of the input amount.
     *
     * @param applicableFeePercentage the fee rate expressed as basis points (i.e., hundredths of a percent)
     * @param _paymentTokenAmount the amount from which the fee is to be taken
     * @return feeAmount the calculated fee amount
     * @return amountAfterFee the amount that remains after the fee is subtracted
     *
     * Requirements:
     *
     * - `applicableFeePercentage` must be less than or equal to 10,000 (100%).
     */
    function calculateFee(
        uint8 applicableFeePercentage,
        uint256 _paymentTokenAmount
    ) internal pure returns (uint256 feeAmount, uint256 amountAfterFee) {
        unchecked {
            feeAmount = (_paymentTokenAmount * applicableFeePercentage) / 10000;
            amountAfterFee = _paymentTokenAmount - feeAmount;
        }
    }
}
