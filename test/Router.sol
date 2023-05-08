// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Router.sol";
import "../src/OtcToken.sol";
import "./util.sol";

contract RouterTest is Test {
    address public deployer = address(new TestAddress());
    address public maker = address(new TestAddress());
    address public taker = address(new TestAddress());
    Router public router;
    OtcToken public token0;
    OtcToken public token1;
    uint public supplyToken0 = 1_000 * 1e18;
    uint public supplyToken1 = 1_000_000 * 1e6 * 1e18;

    function setUp() public {
        vm.startPrank(deployer);
        token0 = new OtcToken("Test WETH", "WETH", supplyToken0, 18);
        token1 = new OtcToken("Test DAI", "DAI", supplyToken1, 6);
        router = new Router();
        vm.stopPrank();
    }
}
