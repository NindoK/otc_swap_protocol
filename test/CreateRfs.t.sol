// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Router.sol";
import "./util.sol";

contract CreateRfsTest is RouterTest {
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

    function test_createRfs_failTokenAmount(uint amount0, uint amount1) public {
        vm.startPrank(maker);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(token0), address(token1), 0, amount1, block.timestamp);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(token0), address(token1), amount0, 0, block.timestamp);

        vm.stopPrank();
    }

    function test_createRfs_failDeadline(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline < block.timestamp);
        vm.prank(maker);
        vm.expectRevert(Router__InvalidDeadline.selector);
        router.createRfsWithDeposit(address(token0), address(token1), amount0, amount1, deadline);
    }

    function test_createRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline >= block.timestamp);
        vm.prank(maker);
        vm.expectRevert(Router__AllowanceToken0TooLow.selector);
        router.createRfsWithDeposit(address(token0), address(token1), amount0, amount1, deadline);
    }

    function test_createRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline >= block.timestamp);
        vm.startPrank(maker);
        token0.approve(address(router), amount0);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.createRfsWithDeposit(address(token0), address(token1), amount0, amount1, deadline);
        vm.stopPrank();
    }

    function test_createRfs(uint amount0, uint amount1, uint deadline, uint8 n) public {
        vm.assume(0 < n && n < 32);
        for (uint8 i = 1; i < n; ++i) {
            uint rfsId = createRfs(amount0, amount1, deadline);
            require(rfsId == i);
            Router.RFS memory rfs = router.getRfs(rfsId);
            assertEq(rfs.token0, address(token0));
            assertEq(rfs.token1, address(token1));
            assertEq(rfs.amount0, amount0);
            assertEq(rfs.amount1, amount1);
            assertEq(rfs.deadline, deadline);
        }
    }

    function test_removeRfs_failNotMaker(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);

        vm.prank(address(new TestAddress()));
        vm.expectRevert(Router__NotMaker.selector);
        router.removeRfsWithDeposit(rfsId);
    }

    function test_removeRfs(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);
        uint startBalance = token0.balanceOf(maker);
        vm.prank(maker);
        bool success = router.removeRfsWithDeposit(rfsId);
        require(success);
        assertEq(token0.balanceOf(maker), startBalance + amount0);
    }
}
