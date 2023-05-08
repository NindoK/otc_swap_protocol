// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Router.sol";
import "./util.sol";

contract TakeRfsTest is RouterTest {
    function createRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= supplyToken0 / 100);
        vm.assume(0 < amount1 && amount1 <= supplyToken1 / 100);
        vm.assume(deadline >= block.timestamp);

        vm.prank(deployer);
        token0.transfer(maker, amount0);

        vm.startPrank(maker);
        token0.approve(address(router), amount0);

        uint startBalance = token0.balanceOf(maker);

        // create RFS
        rfsId = router.createRfsWithDeposit(
            address(token0),
            address(token1),
            amount0,
            amount1,
            deadline
        );
        vm.stopPrank();

        // check final balance
        assertEq(token0.balanceOf(maker), startBalance - amount0);
    }

    function test_takeRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(taker);
        vm.expectRevert(Router__AllowanceToken1TooLow.selector);
        router.takeRfsWithDeposit(rfsId, amount1);
    }

    function test_takeRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(router), amount1);
        vm.prank(taker);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.takeRfsWithDeposit(rfsId, amount1);
    }

    function test_takeRfs_failTokenAmount(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(taker);
        token1.approve(address(router), amount1);
        vm.prank(taker);
        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.takeRfsWithDeposit(rfsId, 0);
    }

    function test_takeRfs(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createRfs(amount0, amount1, deadline);

        uint startMakerToken0Balance = token0.balanceOf(maker);
        uint startMakerToken1Balance = token1.balanceOf(maker);
        uint startTakerToken0Balance = token0.balanceOf(taker);
        uint startTakerToken1Balance = token1.balanceOf(taker);

        vm.prank(deployer);
        token1.transfer(address(taker), amount1);
        vm.startPrank(taker);
        token1.approve(address(router), amount1);

        bool success = router.takeRfsWithDeposit(rfsId, amount1);
        require(success);
        vm.stopPrank();

        assertEq(token0.balanceOf(maker), startMakerToken0Balance);
        assertEq(token1.balanceOf(maker), startMakerToken1Balance + amount1);
        assertEq(token0.balanceOf(taker), startTakerToken0Balance + amount0);
        assertEq(token1.balanceOf(taker), startTakerToken1Balance);

        assertTrue(router.getRfs(rfsId).removed);
    }

    function test_takeRfs_failRfsRemoved(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount1 > 0);
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(deployer);
        token1.transfer(address(taker), amount1);
        vm.startPrank(taker);
        token1.approve(address(router), amount1);

        bool success = router.takeRfsWithDeposit(rfsId, amount1);
        require(success);

        vm.expectRevert(Router__RfsRemoved.selector);
        router.takeRfsWithDeposit(rfsId, amount1);
        vm.stopPrank();
    }

    function takeRfsPartial(uint rfsId, uint takerAmount1) private {
        uint startMakerToken0Balance = token0.balanceOf(maker);
        uint startMakerToken1Balance = token1.balanceOf(maker);
        uint startTakerToken0Balance = token0.balanceOf(taker);
        uint startTakerToken1Balance = token1.balanceOf(taker);

        Router.RFS memory rfs = router.getRfs(rfsId);
        uint makerAmount0 = rfs.amount0;
        uint makerAmount1 = rfs.amount1;

        vm.prank(taker);
        bool success = router.takeRfsWithDeposit(rfsId, takerAmount1);
        require(success);

        uint takerAmount0 = OtcMath.getTakerAmount0(makerAmount0, makerAmount1, takerAmount1);

        rfs = router.getRfs(rfsId);
        assertEq(rfs.amount0, makerAmount0 - takerAmount0);
        assertEq(rfs.amount1, makerAmount1 - takerAmount1);

        assertEq(token0.balanceOf(maker), startMakerToken0Balance);
        assertEq(token1.balanceOf(maker), startMakerToken1Balance + takerAmount1);
        assertEq(token0.balanceOf(taker), startTakerToken0Balance + takerAmount0);
        assertEq(token1.balanceOf(taker), startTakerToken1Balance - takerAmount1);
    }

    function test_takeRfs_partial(
        uint makerAmount0,
        uint makerAmount1,
        uint deadline,
        uint takerAmount1
    ) public {
        vm.assume(0 < takerAmount1 && takerAmount1 < makerAmount1);

        uint rfsId = createRfs(makerAmount0, makerAmount1, deadline);

        vm.prank(deployer);
        token1.transfer(address(taker), takerAmount1);
        vm.prank(taker);
        token1.approve(address(router), takerAmount1);

        takeRfsPartial(rfsId, takerAmount1);
        assertFalse(router.getRfs(rfsId).removed);
    }

    function test_takeRfs_partials(uint makerAmount0, uint makerAmount1, uint deadline) public {
        uint rfsId = createRfs(makerAmount0, makerAmount1, deadline);
        vm.assume(makerAmount0 >= 3);
        vm.assume(makerAmount1 >= 3);

        vm.prank(deployer);
        token1.transfer(address(taker), makerAmount1);
        vm.prank(taker);
        token1.approve(address(router), makerAmount1);

        uint takerAmountA = makerAmount1 / 3;
        uint takerAmountB = makerAmount1 / 3;
        uint takerAmountC = makerAmount1 - takerAmountA - takerAmountB;

        takeRfsPartial(rfsId, takerAmountA);
        assertFalse(router.getRfs(rfsId).removed);
        takeRfsPartial(rfsId, takerAmountB);
        assertFalse(router.getRfs(rfsId).removed);
        takeRfsPartial(rfsId, takerAmountC);
        assertTrue(router.getRfs(rfsId).removed);
    }
}
