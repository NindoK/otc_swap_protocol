// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title OtcToken
 * @notice Test token
 */
contract OtcToken is ERC20 {
    uint8 immutable _decimals;

    constructor(string memory _name, string memory _symbol, uint _initialSupply, uint8 _nDecimals) ERC20(_name, _symbol) {
        _decimals = _nDecimals;
        _mint(msg.sender, _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}