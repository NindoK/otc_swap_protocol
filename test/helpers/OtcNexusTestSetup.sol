// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/OtcNexus.sol";
import "../../src/OtcToken.sol";
import "./util.sol";

contract OtcNexusTestSetup is Test {
    address public deployer = address(new TestAddress());
    address public maker = address(new TestAddress());
    address public taker = address(new TestAddress());
    OtcNexus public otcNexus;
    OtcToken public token0;
    OtcToken public token1;
    OtcToken public otcFeeToken;
    uint public supplyToken0 = 1_000 * 1e18;
    uint public supplyToken1 = 1_000_000 * 1e6 * 1e18;
    uint public supplyOtcFeeToken = 1_000 * 1e18;
    address[] _tokensAcceptedToken1;

    function setUp() public {
        vm.startPrank(deployer);
        token0 = new OtcToken("Test WETH", "WETH", supplyToken0, 18);
        token1 = new OtcToken("Test DAI", "DAI", supplyToken1, 6);
        otcFeeToken = new OtcToken("Test Fee Token", "OTCFEE", supplyOtcFeeToken, 18);
        otcNexus = new OtcNexus(address(otcFeeToken));
        _tokensAcceptedToken1 = new address[](1);
        _tokensAcceptedToken1[0] = address(token1);
        
        // TODO
        otcNexus.setPriceFeeds(address(token0), address(0x0));
        otcNexus.setPriceFeeds(address(token1), address(0x0));
        otcNexus.setPriceFeeds(address(otcFeeToken), address(0x0));
        
        vm.stopPrank();
    }
}
