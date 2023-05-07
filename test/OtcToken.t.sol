// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OtcToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RouterTest is Test {
    address public deployer = address(0x1);
    OtcToken public weth;
    OtcToken public dai;
    uint public wethSupply = 1_000 * 1e18;
    uint public daiSupply = 1_000_000 * 1e6;

    function setUp() public {
        vm.startPrank(deployer);
        weth = new OtcToken("Test WETH", "tWETH", wethSupply, 18);
        dai = new OtcToken("Test DAI", "tDAI", daiSupply, 6);
        vm.stopPrank();
    }

    function test_deployTokens() public {
        assertEq(weth.name(), "Test WETH");
        assertEq(weth.symbol(), "tWETH");
        assertEq(weth.decimals(), 18);
        assertEq(weth.totalSupply(), wethSupply);
        assertEq(IERC20(address(weth)).balanceOf(deployer), wethSupply);

        assertEq(dai.name(), "Test DAI");
        assertEq(dai.symbol(), "tDAI");
        assertEq(dai.decimals(), 6);
        assertEq(dai.totalSupply(), daiSupply);
        assertEq(IERC20(address(dai)).balanceOf(deployer), daiSupply);
    }
}
