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

    function test_takeRfs_failTokekAmount(uint amount0, uint amount1, uint deadline) public {
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

        uint startMakertoken0Balance = token0.balanceOf(maker);
        uint startMakertoken1Balance = token1.balanceOf(maker);
        uint startTakertoken0Balance = token0.balanceOf(taker);
        uint startTakertoken1Balance = token1.balanceOf(taker);

        vm.prank(deployer);
        token1.transfer(address(taker), amount1);
        vm.startPrank(taker);
        token1.approve(address(router), amount1);

        bool success = router.takeRfsWithDeposit(rfsId, amount1);
        require(success);
        vm.stopPrank();

        assertEq(token0.balanceOf(maker), startMakertoken0Balance);
        assertEq(token1.balanceOf(maker), startMakertoken1Balance + amount1);
        assertEq(token0.balanceOf(taker), startTakertoken0Balance + amount0);
        assertEq(token1.balanceOf(taker), startTakertoken1Balance);
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

    // todo test partial fills
}
