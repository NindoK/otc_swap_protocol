// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Router.sol";
import "../src/OtcToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./util.sol";

contract RouterTest is Test {
    address public deployer = address(new TestAddress());
    address public maker = address(new TestAddress());
    address public taker = address(new TestAddress());
    Router public router;
    OtcToken public weth;
    OtcToken public dai;
    uint public wethSupply = 1_000 * 1e18;
    uint public daiSupply = 1_000_000 * 1e6 * 1e18;

    function setUp() public {
        vm.startPrank(deployer);
        weth = new OtcToken("Test WETH", "tWETH", wethSupply, 18);
        dai = new OtcToken("Test DAI", "tDAI", daiSupply, 6);
        router = new Router();
        vm.stopPrank();
    }

    function test_createRfs_failTokenAmount(uint amount0, uint amount1) public {
        vm.startPrank(maker);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(weth), address(dai), 0, amount1, block.timestamp);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(weth), address(dai), amount0, 0, block.timestamp);

        vm.stopPrank();
    }

    function test_createRfs_failDeadline(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline < block.timestamp);
        vm.prank(maker);
        vm.expectRevert(Router__InvalidDeadline.selector);
        router.createRfsWithDeposit(address(weth), address(dai), amount0, amount1, deadline);
    }

    function test_createRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline >= block.timestamp);
        vm.prank(maker);
        vm.expectRevert(Router__AllowanceToken0TooLow.selector);
        router.createRfsWithDeposit(address(weth), address(dai), amount0, amount1, deadline);
    }

    function test_createRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        vm.assume(amount0 > 0);
        vm.assume(amount1 > 0);
        vm.assume(deadline >= block.timestamp);
        vm.startPrank(maker);
        weth.approve(address(router), amount0);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.createRfsWithDeposit(address(weth), address(dai), amount0, amount1, deadline);
        vm.stopPrank();
    }

    function createRfs(uint amount0, uint amount1, uint deadline) private returns (uint rfsId) {
        vm.assume(0 < amount0 && amount0 <= wethSupply / 100);
        vm.assume(0 < amount1 && amount1 <= daiSupply / 100);
        vm.assume(deadline >= block.timestamp);

        vm.prank(deployer);
        weth.transfer(maker, amount0);

        vm.startPrank(maker);
        weth.approve(address(router), amount0);

        uint startBalance = weth.balanceOf(maker);

        // create RFS
        rfsId = router.createRfsWithDeposit(
            address(weth),
            address(dai),
            amount0,
            amount1,
            deadline
        );
        vm.stopPrank();

        // check final balance
        assertEq(weth.balanceOf(maker), startBalance - amount0);
    }

    function test_createRfs(uint amount0, uint amount1, uint deadline, uint8 n) public {
        vm.assume(0 < n && n < 32);
        for (uint8 i = 1; i < n; ++i) {
            require(createRfs(amount0, amount1, deadline) == i);
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
        uint startBalance = weth.balanceOf(maker);
        vm.prank(maker);
        bool success = router.removeRfsWithDeposit(rfsId);
        require(success);
        assertEq(weth.balanceOf(maker), startBalance + amount0);
    }

    function test_takeRfs_failAllowance(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(taker);
        vm.expectRevert(Router__AllowanceToken1TooLow.selector);
        router.takeRfsWithDeposit(rfsId, amount1);
    }

    function test_takeRfs_failBalance(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(taker);
        dai.approve(address(router), amount1);
        vm.prank(taker);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.takeRfsWithDeposit(rfsId, amount1);
    }

    function test_takeRfs(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);

        uint startMakerWethBalance = weth.balanceOf(maker);
        uint startMakerDaiBalance = dai.balanceOf(maker);
        uint startTakerWethBalance = weth.balanceOf(taker);
        uint startTakerDaiBalance = dai.balanceOf(taker);

        vm.prank(deployer);
        dai.transfer(address(taker), amount1);
        vm.startPrank(taker);
        dai.approve(address(router), amount1);

        bool success = router.takeRfsWithDeposit(rfsId, amount1);
        require(success);
        vm.stopPrank();

        assertEq(weth.balanceOf(maker), startMakerWethBalance);
        assertEq(dai.balanceOf(maker), startMakerDaiBalance + amount1);
        assertEq(weth.balanceOf(taker), startTakerWethBalance + amount0);
        assertEq(dai.balanceOf(taker), startTakerDaiBalance);
    }

    function test_takeRfs_failRfsRemoved(uint amount0, uint amount1, uint deadline) public {
        uint rfsId = createRfs(amount0, amount1, deadline);
        vm.prank(deployer);
        dai.transfer(address(taker), amount1);
        vm.startPrank(taker);
        dai.approve(address(router), amount1);

        bool success = router.takeRfsWithDeposit(rfsId, amount1);
        require(success);

        vm.expectRevert(Router__RfsRemoved.selector);
        router.takeRfsWithDeposit(rfsId, amount1);
        vm.stopPrank();
    }

    // todo test partial fills
}
