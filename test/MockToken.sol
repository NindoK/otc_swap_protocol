// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockToken
 * @notice Test token
 */
contract MockToken is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _nDecimals
    ) ERC20(_name, _symbol) {
        _decimals = _nDecimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
}
