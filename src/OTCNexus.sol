// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OtcMath.sol";

error Router__InvalidTokenAmount();
error Router__InvalidPriceAmount();
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
        uint256 price;
        uint256 discount;
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
        uint256 price,
        uint256 discount,
        uint256 deadline
    );

    /**
     * @notice create an RFS with deposit
     * @param _token0 token offered
     * @param _tokensAccepted token requested
     * @param _amount0 amount of token offered
     * @param _price fixed price of the asset
     * @param _discount discount compared to the current price of the asset
     * @param _deadline timestamp after which the RFS expires
     * @param _isDynamic if the price is dynamic or fixed
     * @param _isDeposited if the token is deposited or approved
     * @return rfsId
     */
    function createRfsWithDeposit(
        address _token0,
        address[] calldata _tokensAccepted,
        uint256 _amount0,
        uint256 _price,
        uint256 _discount,
        uint256 _deadline,
        bool _isDynamic,
        bool _isDeposited
    ) external returns (uint256 rfsId) {
        // sanity checks
        if (_deadline < block.timestamp) revert Router__InvalidDeadline();
        if (_amount0 == 0) revert Router__InvalidTokenAmount();
        if (_tokensAccepted.length == 0) revert Router__InvalidTokenAddresses();
        if (!_isDynamic && _price == 0) revert Router__InvalidPriceAmount();

        if (IERC20(_token0).allowance(msg.sender, address(this)) < _amount0)
            revert Router__AllowanceToken0TooLow();

        //Allow only if amount0 is greater than 10% of total supply? Does it make sense?
        // if(_amount0 < IERC20(_token0).totalSupply()/10) revert Router__AllowanceToken0TooLow();

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
            _isDynamic ? 0 : _price, // price
            _isDynamic ? _discount : 0, // discount
            _deadline, // deadline
            _isDynamic, // isDynamic
            _isDeposited, // isDeposited
            false // removed
        );

        emit RfsCreated(
            rfsIdCounter,
            msg.sender,
            _token0,
            _tokensAccepted,
            _amount0,
            _isDynamic ? 0 : _price,
            _isDynamic ? _discount : 0,
            _deadline
        );

        return rfsIdCounter++;
    }

    //TODO TO BE UPDATED WITH NEW LOGIC
    // /**
    //  * @notice take an RFS with deposit
    //  * @param _id ID of the RFS
    //  * @param _amount1 amount of token1
    //  * @return success
    //  */
    // function takeRfsWithDeposit(
    //     uint256 _id,
    //     uint256 _amount1,
    //     uint256 index
    // ) external returns (bool success) {
    //     RFS memory rfs = getRfs(_id);

    //     // sanity checks
    //     if (rfs.removed) revert Router__RfsRemoved();
    //     if (_amount1 == 0) revert Router__InvalidTokenAmount();
    //     // if (_amount1 > ) revert Router__Amount1TooHigh();
    //     if (IERC20(rfs.tokensAccepted[index]).allowance(msg.sender, address(this)) < _amount1)
    //         revert Router__AllowanceToken1TooLow();

    //     // transfer token1 to the maker
    //     success = IERC20(rfs.tokensAccepted[index]).transferFrom(msg.sender, rfs.maker, _amount1);
    //     if (!success) revert Router__TransferToken1Failed();

    //     // compute _amount0 based on _amount1 and implied quote, and update RFS amounts
    //     uint256 _amount0 = OtcMath.getTakerAmount0(rfs.amount0, price, _amount1);

    //     // transfer token0 to the taker
    //     success = IERC20(rfs.token0).transfer(msg.sender, _amount0);
    //     if (!success) revert Router__TransferToken0Failed();

    //     // update RFS
    //     // todo use function updateRfs and emit RfsUpdated event
    //     rfs.amount0 -= _amount0;
    //     rfs.amountsToPay[index] -= _amount1;
    //     if (rfs.amount0 == 0 || rfs.amountsToPay[index] == 0) {
    //         rfs.removed = true;
    //     }
    //     idToRfs[_id] = rfs;

    //     emit RfsFilled(_id, msg.sender, _amount0, _amount1);
    // }

    /**
     * @notice remove an RFS with deposit
     * @param _id ID of the RFS
     * @return success
     */
    function removeRfsWithDeposit(uint256 _id) external returns (bool success) {
        RFS memory rfs = idToRfs[_id];

        // only the maker can remove the RFS
        if (msg.sender != rfs.maker) revert Router__NotMaker();

        // refund deposited tokens to the maker
        success = IERC20(rfs.token0).transfer(rfs.maker, rfs.amount0);
        if (!success) revert Router__RefundToken0Failed();

        idToRfs[_id].removed = true;

        emit RfsRemoved(_id);
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
