// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/util.sol";
import "./helpers/OtcNexusTestSetup.sol";

contract OtcNexusTest is OtcNexusTestSetup {
    function test_computeAmount0_dynamic_with_valid_usd_price() public {
        uint256 rfsId = createDynamicApprovedRfs(amount0, amount1, block.timestamp + 100);
        uint256 amount0 = otcNexus.computeAmount0(rfsId, 1000, 0, OtcNexus.RfsType.DYNAMIC);
        assertEq(amount0, amount0, "Incorrect amount0 for dynamic RFS with valid USD price");
    }

    function test_computeAmount0_dynamic_with_invalid_usd_price() public {
        uint256 rfsId = createDynamicApprovedRfs(amount0, amount1, block.timestamp + 100);
        uint256 amount0 = otcNexus.computeAmount0(rfsId, 1000, 0, OtcNexus.RfsType.DYNAMIC);
        assertEq(amount0, 0, "Incorrect amount0 for dynamic RFS with invalid USD price");
    }
    
    function test_computeAmount0_fixed_with_valid_amounts() public {
        // Create fixed RFS with valid amounts
        uint256 rfsId = createFixedAmountApprovedRfs(100, 100, block.timestamp + 1);
        
        // Compute amount0 for the fixed RFS with valid amounts
        uint256 amount0Temp = otcNexus.computeAmount0(rfsId, 100, 0, OtcNexus.RfsType.FIXED);
        
        // Assert the correct amount0
        assertEq(amount0Temp, 100, "Incorrect amount0 for fixed RFS with valid amounts");
    }
    
    function test_computeAmount0_fixed_with_invalid_token_index() public {
        uint256 rfsId = createFixedAmountApprovedRfs(amount0, amount1, block.timestamp + 100);
        uint256 amount0 = otcNexus.computeAmount0(rfsId, 500, 1, OtcNexus.RfsType.FIXED);
        assertEq(amount0, 0, "Incorrect amount0 for fixed RFS with invalid token index");
    }
    
}

