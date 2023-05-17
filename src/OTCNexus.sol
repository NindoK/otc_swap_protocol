// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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

/**
 * @title OTCNexus
 * @notice core swap functionality
 */
contract OTCNexus is Ownable {
    uint256 public rfsIdCounter;
    mapping(uint256 => RFS) private idToRfs;
    mapping(address => RFS[]) private makerRfs;

    struct RFS {
        uint256 id;
        address maker;
        address token0;
        address[] tokensAccepted;
        uint256 amount0;
        uint256 amount1;
        uint256 usdPrice; // Implies the fixed price per token0
        uint256 priceMultiplier;
        uint256 deadline;
        bool isDynamic;
        bool isDeposited;
        bool removed;
    }

    event RfsUpdated(uint256 rfsId, uint256 amount0, uint256 amount1, uint256 deadline);
    event RfsFilled(uint256 rfsId, address taker, uint256 amount0, uint256 amount1);
    event RfsRemoved(uint256 rfsId);
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
     * @param _isDeposited if the tokens are deposited or approved
     * @return rfsId
     */
    function createFixedRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _usdPrice,
        uint256 _deadline,
        bool _isDeposited
    ) external returns (uint256 rfsId) {
        if (_amount1 != 0 && _usdPrice != 0) revert Router__OnlyFixedPriceOrAmountAllowed();
        return
            _createRfs(
                _token0,
                _tokensAccepted,
                _amount0,
                _amount1,
                _usdPrice,
                0,
                _deadline,
                false,
                _isDeposited
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
     * @param _isDeposited if the token is deposited or approved
     * @return rfsId
     */
    function createDynamicRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint8 _priceMultiplier,
        uint256 _deadline,
        bool _isDeposited
    ) external returns (uint256 rfsId) {
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
                true,
                _isDeposited
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
     * @param _isDynamic If true, it's a dynamic RFS else it's fixed RFS.
     * @param _isDeposited If true, the tokens are deposited; if false, the tokens are approved to be spent.
     * @return rfsId The ID of the newly created RFS.
     */
    function _createRfs(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _usdPrice,
        uint8 _priceMultiplier,
        uint256 _deadline,
        bool _isDynamic,
        bool _isDeposited
    ) private returns (uint256 rfsId) {
        // sanity checks
        if (_deadline < block.timestamp) revert Router__InvalidDeadline();
        if (_amount0 == 0) revert Router__InvalidTokenAmount();
        if (_tokensAccepted.length == 0) revert Router__InvalidTokenAddresses();
        if (IERC20(_token0).allowance(msg.sender, address(this)) < _amount0)
            revert Router__AllowanceToken0TooLow();

        if (_isDeposited) {
            // transfer sell token to contract
            bool success = IERC20(_token0).transferFrom(msg.sender, address(this), _amount0);
            if (!success) revert Router__DepositToken0Failed();
        }

        // create RFS
        idToRfs[rfsIdCounter] = RFS(
            rfsIdCounter, // id
            msg.sender, // maker
            _token0, // token0
            _tokensAccepted, // tokensAccepted
            _amount0, // amount0
            _amount1, // amount1
            _usdPrice, // price
            _priceMultiplier, // discount
            _deadline, // deadline
            _isDynamic, // isDynamic
            _isDeposited, // isDeposited
            false // removed
        );

        makerRfs[msg.sender].push(idToRfs[rfsIdCounter]);

        emit RfsCreated(
            rfsIdCounter,
            msg.sender,
            _token0,
            _tokensAccepted,
            _amount0,
            _usdPrice,
            _priceMultiplier,
            _deadline
        );

        return rfsIdCounter++;
    }

    // //TODO TO BE UPDATED WITH NEW LOGIC
    // // /**
    // //  * @notice take an RFS with deposit
    // //  * @param _id ID of the RFS
    // //  * @param _amount1 amount of token1
    // //  * @return success
    // //  */
    // function takeFixedRfs(
    //     uint256 _id,
    //     uint256 _amount1,
    //     uint256 index
    // ) external returns (bool success) {
    //     RFS memory rfs = getRfs(_id);

    //     // sanity checks
    //     if (rfs.removed || rfs.token0 == address(0)) revert Router__RfsRemoved();
    //     if (_amount1 == 0) revert Router__InvalidTokenAmount();
    //     if (_amount1 > rfs.amount1) revert Router__Amount1TooHigh();

    //     //Maybe we can just switch and ask directly for approve instead of checking the allowance.
    //     if (IERC20(rfs.tokensAccepted[index]).allowance(msg.sender, address(this)) < _amount1)
    //         revert Router__AllowanceToken1TooLow();

    //     // transfer token1 to the maker
    //     success = IERC20(rfs.tokensAccepted[index]).transferFrom(msg.sender, rfs.maker, _amount1);
    //     if (!success) revert Router__TransferToken1Failed();

    //     // compute _amount0 based on _amount1 and implied quote, and update RFS amounts
    //     uint256 _amount0 = OtcMath.getTakerAmount0(rfs.amount0, rfs.amount1, _amount1);

    //     // transfer token0 to the taker
    //     success = IERC20(rfs.token0).transfer(msg.sender, _amount0);
    //     if (!success) revert Router__TransferToken0Failed();

    //     // update RFS
    //     // todo use function updateRfs and emit RfsUpdated event
    //     rfs.amount0 -= _amount0;
    //     rfs.amountsToPay[index] -= _amount1;
    //     if (rfs.amount0 == 0 || rfs.amountsToPay[index] == 0) {
    //         rfs.removed = true;
    //         emit RfsRemoved(_id);
    //     }
    //     idToRfs[_id] = rfs;

    //     emit RfsFilled(_id, msg.sender, _amount0, _amount1);
    // }

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

        if (rfs.isDeposited) {
            // refund deposited tokens to the maker
            success = IERC20(rfs.token0).transfer(rfs.maker, rfs.amount0);
            if (!success) revert Router__RefundToken0Failed();
        }
        idToRfs[_id].removed = true;
        emit RfsRemoved(_id);

        //Privacy and gas refund
        if (_permanentlyDelete) delete idToRfs[_id];
    }

    /**
     * @notice get an RFS
     * @param _id ID of the RFS
     * @return RFS
     */
    function getRfs(uint256 _id) public view returns (RFS memory) {
        return idToRfs[_id];
    }
}
