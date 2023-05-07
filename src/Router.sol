// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Router__InvalidDeadline();
error Router__AllowanceToken0TooLow();
error Router__AllowanceToken1TooLow();
error Router__DepositToken0Failed();
error Router__RfsRemoved();
error Router__Amount1TooHigh();
error Router__TransferToken0Failed();
error Router__TransferToken1Failed();
error Router__NotMaker();
error Router__RefundToken0Failed();

/**
 * @title Router
 * @notice core swap functionality
 */
contract Router is Ownable {
    uint private rfsIdCounter = 1;
    mapping(uint => RFS) private idToRfs;
    struct RFS {
        uint id;
        address maker;
        address token0;
        address token1;
        uint amount0;
        uint amount1;
        uint deadline;
        bool removed;
    }

    // todo event RfsUpdated(uint rfsId, uint amount0, uint amount1, uint deadline);
    event RfsFilled(uint rfsId, address taker, uint amount0, uint amount1);
    event RfsRemoved(uint rfsId);
    event RfsCreated(
        uint rfsId,
        address maker,
        address indexed token0,
        address indexed token1,
        uint amount0,
        uint amount1,
        uint deadline
    );

    /**
     * @notice create an RFS with deposit
     * @param _token0 token offered
     * @param _token1 token requested
     * @param _amount0 amount of token offered
     * @param _amount1 amount of token requested
     * @param _deadline timestamp after which the RFS expires
     * @return success
     */
    function createRfsWithDeposit(
        address _token0,
        address _token1,
        uint _amount0,
        uint _amount1,
        uint _deadline
    ) external returns (bool success) {
        ERC20 token0 = ERC20(_token0);

        // check deadline
        if (_deadline < block.timestamp) revert Router__InvalidDeadline();
        if (token0.allowance(msg.sender, address(this)) < _amount0)
            revert Router__AllowanceToken0TooLow();

        // transfer sell token to contract
        success = token0.transferFrom(msg.sender, address(this), _amount0);
        if (!success) revert Router__DepositToken0Failed();

        // create RFS
        idToRfs[rfsIdCounter] = RFS(
            rfsIdCounter,
            msg.sender,
            _token0,
            _token1,
            _amount0,
            _amount1,
            _deadline,
            false
        );

        emit RfsCreated(rfsIdCounter, msg.sender, _token0, _token1, _amount0, _amount1, _deadline);

        ++rfsIdCounter;
    }

    /**
     * @notice take an RFS with deposit
     * @param _id ID of the RFS
     * @param _amount1 amount of token1
     * @return success
     */
    function takeRfsWithDeposit(uint _id, uint _amount1) external returns (bool success) {
        RFS memory rfs = getRfs(_id);

        // check RFS is not removed
        if (rfs.removed) revert Router__RfsRemoved();

        // todo allow for _amount1 <= rfs.amount1
        if (_amount1 > rfs.amount1) revert Router__Amount1TooHigh();

        // check allowance
        if (ERC20(rfs.token1).allowance(msg.sender, address(this)) < rfs.amount1)
            revert Router__AllowanceToken1TooLow();

        // transfer token1 to the maker
        success = ERC20(rfs.token1).transferFrom(msg.sender, rfs.maker, _amount1);
        if (!success) revert Router__TransferToken1Failed();

        // todo compute _amount0 based on _amount1 and implied quote, and update RFS amounts
        uint _amount0 = rfs.amount0;

        // transfer token0 to the taker
        success = ERC20(rfs.token0).transfer(msg.sender, _amount0);
        if (!success) revert Router__TransferToken0Failed();

        // update RFS
        // todo use function updateRfs and emit RfsUpdated event
        rfs.amount0 -= _amount0;
        rfs.amount1 -= _amount1;
        if (rfs.amount0 == 0 || rfs.amount1 == 0) {
            rfs.removed = true;
        }
        idToRfs[_id] = rfs;

        emit RfsFilled(_id, msg.sender, _amount0, _amount1);
    }

    /**
     * @notice remove an RFS with deposit
     * @param _id ID of the RFS
     * @return success
     */
    function removeRfsWithDeposit(uint _id) external returns (bool success) {
        RFS memory rfs = idToRfs[_id];

        // only the maker can remove the RFS
        if (msg.sender != rfs.maker) revert Router__NotMaker();

        // refund deposited tokens to the maker
        success = ERC20(rfs.token0).transfer(rfs.maker, rfs.amount0);
        if (!success) revert Router__RefundToken0Failed();

        idToRfs[_id].removed = true;

        emit RfsRemoved(_id);
    }

    /**
     * @notice get an RFS
     * @param _id ID of the RFS
     * @return RFS
     */
    function getRfs(uint _id) public view returns (RFS memory) {
        return idToRfs[_id];
    }
}
