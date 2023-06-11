// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/OtcNexus.sol";
import "../../src/OtcToken.sol";
import "./util.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract OtcNexusTestSetup is Test {
    event RfsFilled(uint256 rfsId, address taker, uint256 amount0, uint256 amount1);
    event RfsRemoved(uint256 rfsId, bool permanentlyDeleted);
    
    address public deployer = address(new TestAddress());
    address public maker = address(new TestAddress());
    address public taker = address(new TestAddress());
    address public relayer = address(new TestAddress());
    OtcNexus public otcNexus;
    OtcToken public token0;
    OtcToken public token1;
    OtcToken public otcFeeToken;
    uint public supplyToken0 = 1_000 * 1e18;
    uint public supplyToken1 = 1_000_000 * 1e6 * 1e18;
    uint public supplyOtcFeeToken = 1_000 * 1e18;
    address[] _tokensAcceptedToken1;
    uint amount0 = supplyToken0 / 100;
    uint amount1 = supplyToken1 / 100;

    function setUp() public {
        vm.startPrank(deployer);
        token0 = new OtcToken("Test WETH", "WETH", supplyToken0, 18);
        token1 = new OtcToken("Test DAI", "DAI", supplyToken1, 6);
        otcFeeToken = new OtcToken("Test Fee Token", "OTCFEE", supplyOtcFeeToken, 18);
        otcNexus = new OtcNexus(address(otcFeeToken));
        otcNexus.setRelayerAddress(relayer);
        _tokensAcceptedToken1 = new address[](1);
        _tokensAcceptedToken1[0] = address(token1);

        MockV3Aggregator token0MockChainlinkAggregator = new MockV3Aggregator(
            18,
            1000 * (10 ** 18)
        );
        MockV3Aggregator token1MockChainlinkAggregator = new MockV3Aggregator(6, 2000 * (10 ** 6));
        MockV3Aggregator otcFeeTokenMockChainlinkAggregator = new MockV3Aggregator(
            18,
            3000 * (10 ** 18)
        );

        otcNexus.setPriceFeeds(address(token0), address(token0MockChainlinkAggregator));
        otcNexus.setPriceFeeds(address(token1), address(token1MockChainlinkAggregator));
        otcNexus.setPriceFeeds(address(otcFeeToken), address(otcFeeTokenMockChainlinkAggregator));

        vm.stopPrank();
    }
    
    function calculateFee(
        uint8 applicableFeePercentage,
        uint256 _paymentTokenAmount
    ) public pure returns (uint256 feeAmount, uint256 amountAfterFee) {
        unchecked {
            feeAmount = (_paymentTokenAmount * applicableFeePercentage) / 10000;
            amountAfterFee = _paymentTokenAmount - feeAmount;
        }
    }
    
    function createDynamicApprovedRfs(
        uint amount0,
        uint amount1,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createDynamicRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            1,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_APPROVED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance);
        assertEq(token0.allowance(maker, address(otcNexus)), amount0);
    }
    
    function createDynamicDepositedRfs(
        uint amount0,
        uint amount1,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createDynamicRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            1,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_DEPOSITED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance - amount0);
    }
    
    function createFixedAmountApprovedRfs(
        uint amount0,
        uint amount1,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createFixedRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            amount1,
            0,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_APPROVED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance);
        assertEq(token0.allowance(maker, address(otcNexus)), amount0);
    }
    
    function createFixedAmountDepositedRfs(
        uint amount0,
        uint amount1,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createFixedRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            amount1,
            0,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_DEPOSITED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance - amount0);
    }
    function createFixedUsdApprovedRfs(
        uint amount0,
        uint usdPrice,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < usdPrice);
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createFixedRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            0,
                usdPrice,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_APPROVED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance);
        assertEq(token0.allowance(maker, address(otcNexus)), amount0);
    }
    
    function createFixedUsdDepositedRfs(
        uint amount0,
        uint usdPrice,
        uint deadline
    ) public returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < usdPrice && usdPrice <10); // to not exceed balance
        vm.assume(deadline >= block.timestamp);
        
        vm.prank(deployer);
        token0.transfer(maker, amount0);
        
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        
        uint startBalance = token0.balanceOf(maker);
        
        // create RFS
        rfsId = otcNexus.createFixedRfs(
            address(token0),
            _tokensAcceptedToken1,
            amount0,
            0,
                usdPrice,
            deadline,
            OtcNexus.TokenInteractionType.TOKEN_DEPOSITED
        );
        vm.stopPrank();
        
        // check final balance
        assertEq(token0.balanceOf(maker), startBalance - amount0);
    }
}
