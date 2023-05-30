// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/util.sol";
import "./helpers/OtcNexusTestSetup.sol";

contract OtcNexusCreateRfsTest is OtcNexusTestSetup {
    function createDynamicApprovedRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
        return 0; //todo
    }
    
    function createDynamicDepositedRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
        return 0; //todo
    }
    function createFixedApprovedRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
        return 0; //todo
    }
    
    function createFixedDepositedRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
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

    function test_createFixedRfs_failTokenAmount(uint amount0, uint amount1) public {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.startPrank(maker);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, 0, amount1, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__InvalidTokenAmount.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, 0, amount1, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_APPROVED);

        vm.expectRevert(Router__AllowanceToken0TooLow.selector); // todo change logic
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, 0, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__AllowanceToken0TooLow.selector); // todo change logic
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, 0, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_APPROVED);

        vm.stopPrank();
    }
    function test_createDynamicRfs_failTokenAmount(uint amount0, uint amount1) public {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.startPrank(maker);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, 0, amount1, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__InvalidTokenAmount.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, 0, amount1, 0, block.timestamp, OtcNexus.TokenInteractionType.TOKEN_APPROVED);

        vm.stopPrank();
    }

    function test_createRfs_failDeadline(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline < block.timestamp);
        vm.startPrank(maker);
        
        vm.expectRevert(Router__InvalidDeadline.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, amount1, 0, deadline, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__InvalidDeadline.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, amount1, 0, deadline, OtcNexus.TokenInteractionType.TOKEN_APPROVED);
        
        vm.expectRevert(Router__InvalidDeadline.selector);
        otcNexus.createDynamicRfs(address(token0), _tokensAcceptedToken1, amount0, 1, deadline, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__InvalidDeadline.selector);
        otcNexus.createDynamicRfs(address(token0), _tokensAcceptedToken1, amount0, 1, deadline, OtcNexus.TokenInteractionType.TOKEN_APPROVED);
    
        vm.stopPrank();
    }

    function test_createRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);
        vm.startPrank(maker);
        
        vm.expectRevert(Router__AllowanceToken0TooLow.selector);
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, amount1, 0, deadline, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.expectRevert(Router__AllowanceToken0TooLow.selector);
        otcNexus.createDynamicRfs(address(token0), _tokensAcceptedToken1, amount0, 1, deadline, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        
        vm.stopPrank();
    }

    function test_createRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline >= block.timestamp);
        vm.startPrank(maker);
        token0.approve(address(otcNexus), amount0);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcNexus.createFixedRfs(address(token0), _tokensAcceptedToken1, amount0, amount1, 0, deadline, OtcNexus.TokenInteractionType.TOKEN_DEPOSITED);
        vm.stopPrank();
    }

    function test_createRfs(uint amount0, uint amount1, uint deadline, uint8 n) public {
        vm.assume(0 < n && n < 32);
        for (uint8 i = 1; i < n; ++i) {
            uint rfsId = createFixedDepositedRfs(amount0, amount1, deadline);
            require(rfsId == i);
            OtcNexus.RFS memory rfs = otcNexus.getRfs(rfsId);
            assertEq(rfs.token0, address(token0));
            assertEq(rfs.tokensAccepted[0], address(token1));
            assertEq(rfs.amount0, amount0);
            assertEq(rfs.amount1, amount1);
            assertEq(rfs.deadline, deadline);
        }
    }

    function test_removeRfs_failNotMaker(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createFixedDepositedRfs(amount0, amount1, deadline);
        vm.prank(address(new TestAddress()));
        vm.expectRevert(Router__NotMaker.selector);
        otcNexus.removeRfs(rfsId, false);
        assertFalse(otcNexus.getRfs(rfsId).removed);
    }

    function test_removeRfs(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createFixedDepositedRfs(amount0, amount1, deadline);
        uint startBalance = token0.balanceOf(maker);
        vm.prank(maker);
        bool success = otcNexus.removeRfs(rfsId, false);
        require(success);
        assertEq(token0.balanceOf(maker), startBalance + amount0);
        assertTrue(otcNexus.getRfs(rfsId).removed);
    }
}