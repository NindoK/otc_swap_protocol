// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/util.sol";
import "./helpers/OtcNexusTestSetup.sol";
import "forge-std/console.sol";


contract OtcNexusTakeRfsTest is OtcNexusTestSetup {
    
    
    function takeRfsPartial(uint rfsId, uint takerAmount1, uint256 index) private {
        uint startMakerToken0Balance = token0.balanceOf(maker);
        uint startMakerToken1Balance = token1.balanceOf(maker);
        uint startTakerToken0Balance = token0.balanceOf(taker);
        uint startTakerToken1Balance = token1.balanceOf(taker);
        
        OtcNexus.RFS memory rfs = otcNexus.getRfs(rfsId);
        uint makerAmount0 = rfs.currentAmount0;
        uint makerAmount1 = rfs.amount1;
        
        vm.prank(taker);
        bool success = otcNexus.takeFixedRfs(rfsId, takerAmount1, index);
        require(success);
        
        uint takerAmount0 = OtcMath.getTakerAmount0(makerAmount0, makerAmount1, takerAmount1);
        
        rfs = otcNexus.getRfs(rfsId);
        //        todo think about how to calculate fees; compare amount 0 in RfsFilled event using vm.expect emit
    
        //        assertEq(rfs.currentAmount0, makerAmount0 - takerAmount0);
        //        assertEq(rfs.amount1, makerAmount1 - takerAmount1);
        
        //        assertEq(token0.balanceOf(maker), startMakerToken0Balance);
        //        assertEq(token1.balanceOf(maker), startMakerToken1Balance + takerAmount1);
        //        assertEq(token0.balanceOf(taker), startTakerToken0Balance + takerAmount0);
        //        assertEq(token1.balanceOf(taker), startTakerToken1Balance - takerAmount1);
    }
    
    function test_takeRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createFixedAmountDepositedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        vm.expectRevert(OtcNexus__AllowanceToken1TooLow.selector);
        otcNexus.takeFixedRfs(rfsId, amount1, 0);
    }

    function test_takeRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createFixedAmountDepositedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(otcNexus), amount1);
        vm.prank(taker);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcNexus.takeFixedRfs(rfsId, amount1, 0);
    }

    function test_takeRfs_failTokenAmount_fixed_deposited(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createFixedAmountDepositedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(otcNexus), amount1);
        vm.prank(taker);
        vm.expectRevert(OtcNexus__InvalidTokenAmount.selector);
        otcNexus.takeFixedRfs(rfsId, 0, 0);
    }
    
    function test_takeRfs_failTokenAmount_fixed_approved(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createFixedAmountApprovedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(otcNexus), amount1);
        vm.prank(taker);
        vm.expectRevert(OtcNexus__InvalidTokenAmount.selector);
        otcNexus.takeFixedRfs(rfsId, 0, 0);
    }
    
    function test_takeRfs_failTokenAmount_dynamic_deposited(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(otcNexus), amount1);
        vm.prank(taker);
        vm.expectRevert(OtcNexus__InvalidTokenAmount.selector);
        otcNexus.takeDynamicRfs(rfsId, 0, 0);
    }
    
    function test_takeRfs_failTokenAmount_dynamic_approved(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createDynamicApprovedRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(otcNexus), amount1);
        vm.prank(taker);
        vm.expectRevert(OtcNexus__InvalidTokenAmount.selector);
        otcNexus.takeDynamicRfs(rfsId, 0, 0);
    }


    function test_takeRfs_success(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsIdFd = createFixedAmountDepositedRfs(amount0, amount1, deadline);
//        uint rfsIdFa = createFixedAmountApprovedRfs(amount0, amount1, deadline);
//        uint rfsIdDd = createDynamicDepositedRfs(amount0, amount1, deadline);
//        uint rfsIdDa = createDynamicApprovedRfs(amount0, amount1, deadline);

        takeRfs_success_forRfsId(amount0, amount1, deadline, rfsIdFd);
//        takeRfs_success_forRfsId(amount0, amount1, deadline, rfsIdFa);
//        takeRfs_success_forRfsId(amount0, amount1, deadline, rfsIdDd);
//        takeRfs_success_forRfsId(amount0, amount1, deadline, rfsIdDa);
    }
    
    function takeRfs_success_forRfsId(uint amount0, uint amount1, uint deadline, uint rfsId) public {
    
        uint startMakerToken0Balance = token0.balanceOf(maker);
        uint startMakerToken1Balance = token1.balanceOf(maker);
        uint startTakerToken0Balance = token0.balanceOf(taker);
        uint startTakerToken1Balance = token1.balanceOf(taker);
    
        vm.prank(deployer);
        token1.transfer(address(taker), amount1);
        vm.startPrank(taker);
        token1.approve(address(otcNexus), amount1);
    
        vm.expectEmit(address(otcNexus));
        emit RfsRemoved(rfsId, true);
        bool success = otcNexus.takeFixedRfs(rfsId, amount1, 0);
        require(success);
        assertEq(otcNexus.getRfs(rfsId).id, 0);
        vm.stopPrank();
    
        assertEq(token0.balanceOf(maker), startMakerToken0Balance);
        //        todo think about how to calculate fees; compare amount 0 in RfsFilled event using vm.expect emit
        //        assertEq(token1.balanceOf(maker), startMakerToken1Balance + amount1);
        //        assertEq(token0.balanceOf(taker), startTakerToken0Balance + amount0);
        assertEq(token1.balanceOf(taker), startTakerToken1Balance);
    }
    
    
    function test_takeRfs_failRfsRemoved(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createFixedAmountDepositedRfs(amount0, amount1, deadline);
        vm.prank(deployer);
        token1.transfer(address(taker), amount1);
        vm.startPrank(taker);
        token1.approve(maker, amount1);
        token1.approve(address(otcNexus), amount1);
    
        vm.expectEmit(address(otcNexus));
        emit RfsRemoved(rfsId, true);
        bool success = otcNexus.takeFixedRfs(rfsId, amount1, 0);
        require(success);
        assertEq(otcNexus.getRfs(rfsId).id, 0);

        vm.expectRevert(OtcNexus__RfsRemoved.selector);
        otcNexus.takeFixedRfs(rfsId, amount1, 0);
        vm.stopPrank();
    }


    function test_takeRfs_partial_oneStep(
        uint makerAmount0,
        uint makerAmount1,
        uint deadline,
        uint takerAmount1
    ) public {
        vm.assume(0 < takerAmount1 && takerAmount1 < makerAmount1);

        uint rfsId = createFixedAmountDepositedRfs(makerAmount0, makerAmount1, deadline);

        vm.prank(deployer);
        token1.transfer(address(taker), takerAmount1);
        vm.prank(taker);
        token1.approve(address(otcNexus), takerAmount1);

        takeRfsPartial(rfsId, takerAmount1, 0);
        assertFalse(otcNexus.getRfs(rfsId).removed);
    }

    function test_takeRfs_partials_threeSteps(uint makerAmount0, uint makerAmount1, uint deadline) public {
        uint rfsId = createFixedAmountDepositedRfs(makerAmount0, makerAmount1, deadline);
        vm.assume(makerAmount0 >= 3);
        vm.assume(makerAmount1 >= 3);

        vm.prank(deployer);
        token1.transfer(address(taker), makerAmount1);
        vm.prank(taker);
        token1.approve(address(otcNexus), makerAmount1);

        uint takerAmountA = makerAmount1 / 3;
        uint takerAmountB = makerAmount1 / 3;
        uint takerAmountC = makerAmount1 - takerAmountA - takerAmountB;

        takeRfsPartial(rfsId, takerAmountA, 0);
        assertFalse(otcNexus.getRfs(rfsId).removed);
        takeRfsPartial(rfsId, takerAmountB, 0);
        assertFalse(otcNexus.getRfs(rfsId).removed);
        // will not assert true as rfs will not be there
        vm.expectEmit(address(otcNexus));
        emit RfsRemoved(rfsId, true);
        takeRfsPartial(rfsId, takerAmountC, 0);
        assertEq(otcNexus.getRfs(rfsId).id, 0);
    }
}
