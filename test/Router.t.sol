// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Router.sol";
import "../src/OtcToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RouterTest is Test {
    address public deployer = address(0x1);
    address public maker = address(0x2);
    address public taker = address(0x3);
    Router public router;
    OtcToken public weth;
    OtcToken public dai;

    function setUp() public {
        vm.startPrank(deployer);
        weth = new OtcToken("Test WETH", "tWETH", 1_000 * 1e18, 18);
        dai = new OtcToken("Test DAI", "tDAI", 1_000_000 * 1e6, 6);
        router = new Router();
        vm.stopPrank();
    }
    
    function test_DeployTokens() public {
        assertEq(weth.name(), "Test WETH");
        assertEq(weth.symbol(), "tWETH");
        assertEq(weth.decimals(), 18);
        assertEq(weth.totalSupply(), 1_000 * 1e18);
        assertEq(IERC20(address(weth)).balanceOf(deployer), 1_000 * 1e18);

        assertEq(dai.name(), "Test DAI");
        assertEq(dai.symbol(), "tDAI");
        assertEq(dai.decimals(), 6);
        assertEq(dai.totalSupply(), 1_000_000 * 1e6);
        assertEq(IERC20(address(dai)).balanceOf(deployer), 1_000_000 * 1e6);
    }

    function test_createRfs_failTokenAmount() public {
        vm.startPrank(maker);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(weth), address(dai), 0, 1, block.timestamp);

        vm.expectRevert(Router__InvalidTokenAmount.selector);
        router.createRfsWithDeposit(address(weth), address(dai), 1, 0, block.timestamp);
        
        vm.stopPrank();
    }

    function test_createRfs_failDeadline() public {
        vm.prank(maker);
        vm.expectRevert(Router__InvalidDeadline.selector);
        router.createRfsWithDeposit(address(weth), address(dai), 1, 1, block.timestamp - 1);
    }

    function test_createRfs_failAllowance() public {
        vm.prank(maker);
        vm.expectRevert(Router__AllowanceToken0TooLow.selector);
        router.createRfsWithDeposit(address(weth), address(dai), 1, 1, block.timestamp);
    }

    function test_createRfs_failBalance() public {
        vm.startPrank(maker);
        weth.approve(address(router), 1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.createRfsWithDeposit(address(weth), address(dai), 1, 1, block.timestamp);
        vm.stopPrank();
    }

    function createRfq() private returns (uint rfsId) {
        vm.prank(deployer);
        weth.transfer(maker, 1);

        vm.startPrank(maker);
        weth.approve(address(router), 1);
        rfsId = router.createRfsWithDeposit(address(weth), address(dai), 1, 1, block.timestamp);
        vm.stopPrank();
    }

    function test_createRfs() public {
        uint rfsId = createRfq();
        require(rfsId == 1);
    }

    function test_removeRfs_failNotMaker() public {
        uint rfsId = createRfq();

        vm.prank(address(0x12345));
        vm.expectRevert(Router__NotMaker.selector);
        router.removeRfsWithDeposit(rfsId);
    }
    
    function test_removeRfs() public {
        uint rfsId = createRfq();
        vm.prank(maker);
        bool success = router.removeRfsWithDeposit(rfsId);
        require(success);
    }
    
    function test_takeRfs_failAllowance() public {
        uint rfsId = createRfq();
        vm.prank(taker);
        vm.expectRevert(Router__AllowanceToken1TooLow.selector);
        router.takeRfsWithDeposit(rfsId, 1);
    }

    function test_takeRfs_failBalance() public {
        uint rfsId = createRfq();
        vm.prank(taker);
        dai.approve(address(router), 1);
        vm.prank(taker);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        router.takeRfsWithDeposit(rfsId, 1);
    }

    function test_takeRfs() public {
        uint rfsId = createRfq();
        vm.prank(deployer);
        dai.transfer(address(taker), 1);
        vm.startPrank(taker);
        dai.approve(address(router), 1);
        
        bool success = router.takeRfsWithDeposit(rfsId, 1);
        require(success);
        vm.stopPrank();
    }

    function test_takeRfs_failRfsRemoved() public {
        uint rfsId = createRfq();
        vm.prank(deployer);
        dai.transfer(address(taker), 2);
        vm.startPrank(taker);
        dai.approve(address(router), 2);

        bool success = router.takeRfsWithDeposit(rfsId, 1);
        require(success);

        vm.expectRevert(Router__RfsRemoved.selector);
        router.takeRfsWithDeposit(rfsId, 1);
        vm.stopPrank();
    }

    // todo test partial fills
}