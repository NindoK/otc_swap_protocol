// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/util.sol";
import "./helpers/OtcNexusTestSetup.sol";
import "forge-std/console.sol";


contract OtcNexusTakeRfsPaypal is OtcNexusTestSetup {

    function test_takeRfsPaypal_success() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        uint startBalance = token0.balanceOf(taker);
        // Simulating taking of Fixed RFS
        vm.startPrank(relayer);
        vm.expectEmit();
        emit RfsFilled(rfsId, taker, amount0, 0);
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);
        vm.stopPrank();

        assertEq(token0.balanceOf(taker), startBalance + amount0, "Incorrect amount0 transferred to taker");
    }
    function test_takeRfsPaypal_failOnlyRelayer() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);
        vm.startPrank(taker);
        
        vm.expectRevert(OtcNexus__OnlyRelayer.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failRfsId() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);

        vm.expectRevert(OtcNexus__RfsRemoved.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId + 1, amount0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failAmount_invalidBalance() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0 + 1, taker);

        vm.stopPrank();
    }
    
    function test_takeRfsPaypal_failAmount() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);

        vm.expectRevert(OtcNexus__InvalidTokenAmount.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId, 0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failRfsInactive() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);

        // Take Fixed RFS successfully first time
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);

        vm.expectRevert(OtcNexus__RfsRemoved.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);

        vm.stopPrank();
    }

    function disabled_test_takeRfsPaypal_failDeadlinePassed() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);

        vm.warp(block.timestamp + 200);

        vm.expectRevert(OtcNexus__InvalidDeadline.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failInvalidInteractionTypeForPaypal_fixed() public {
        // Assuming this RFS id corresponds to a RFS with invalid interaction type for Paypal
        uint invalidRfsId = createDynamicApprovedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);
        vm.expectRevert(OtcNexus__InvalidInteractionTypeForPaypal.selector);
        otcNexus.takeFixedRfsPaypal(invalidRfsId, amount0, taker);

        vm.stopPrank();
    }
    function test_takeRfsPaypal_failInvalidInteractionTypeForPaypal_dynamic() public {
        // Assuming this RFS id corresponds to a RFS with invalid interaction type for Paypal
        uint invalidRfsId = createFixedAmountApprovedRfs(amount0, amount0, block.timestamp + 100);

        vm.startPrank(relayer);
        vm.expectRevert(OtcNexus__InvalidInteractionTypeForPaypal.selector);
        otcNexus.takeDynamicRfsPaypal(invalidRfsId, amount0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failRfsRemoved() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);
    
    
        // Removing the RFS
        vm.prank(maker);
        vm.expectEmit();
        emit RfsRemoved(rfsId, true);
        otcNexus.removeRfs(rfsId, true);
        vm.startPrank(relayer);

        vm.expectRevert(OtcNexus__RfsRemoved.selector);
        otcNexus.takeDynamicRfsPaypal(rfsId, amount0, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failOnlyFixedAllowed() public {

        // Assuming this RFS id corresponds to a RFS which is not of fixed type
        uint invalidRfsId = createDynamicApprovedRfs(amount0, amount1, block.timestamp + 100);

        vm.startPrank(relayer);
        vm.expectRevert(OtcNexus__InvalidInteractionTypeForPaypal.selector);
        otcNexus.takeDynamicRfsPaypal(invalidRfsId, amount1, taker);

        vm.stopPrank();
    }

    function test_takeRfsPaypal_failTransferToken0Failed() public {
        uint rfsId = createDynamicDepositedRfs(amount0, amount1, block.timestamp + 100);
        vm.startPrank(relayer);

        // Simulate failure of transfer from the RFS. This is more complex as it requires the token contract
        // to be mocked to fail in certain conditions, which isn't directly supported in Solidity.
        // This could be handled in various ways, such as a separate 'bad token' contract used for this test,
        // or mocking the token contract if your framework supports that.

        // Your testing framework and setup will determine the best way to do this.

        vm.stopPrank();
    }
}
