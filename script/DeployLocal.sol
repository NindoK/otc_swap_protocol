// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../lib/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "../src/OtcNexus.sol";
import "../src/OtcOption.sol";
import "../src/OtcToken.sol";

///@notice Script to deploy contracts to local blockchain
/*
For local deployment use commands:
anvil
// pick from there private key and public key
export pk=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script ./script/DeployLocal.sol:DeployLocal --fork-url http://localhost:8545 --private-key $pk --broadcast --resume

verify cast is working:
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "rfsIdCounter()"
0x0000000000000000000000000000000000000000000000000000000000000001



*/
contract DeployLocal is Script {
    function run() external {
        vm.startBroadcast();
        OtcToken otcToken = new OtcToken("Test WETH", "tWETH", 1_000 * 1e18, 18);
        OtcNexus otcNexus = new OtcNexus(address(otcToken));
        OtcOption otcOption = new OtcOption();
        //        MockV3Aggregator mockChainlinkAggregator = new MockV3Aggregator(8, 2000*(10**8));
        address[] memory tokensAccepted = new address[](1);
        tokensAccepted[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        otcNexus.createFixedRfs(
            0xd24DFf6117936B6ff97108CF26c1dD8865743d87,
            tokensAccepted,
            4400,
            500,
            0,
            1687505340,
            OtcNexus.TokenInteractionType.TOKEN_APPROVED
        );

        address[] memory tokensAcceptedFixedUsd = new address[](2);
        tokensAcceptedFixedUsd[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        tokensAcceptedFixedUsd[1] = 0x45804880De22913dAFE09f4980848ECE6EcbAf78;
        otcNexus.createFixedRfs(
            0x355a824bEa1adc22733978A3748271E1bbB34130,
            tokensAcceptedFixedUsd,
            4400,
            0,
            1504,
            1687505340,
            OtcNexus.TokenInteractionType.TOKEN_APPROVED
        );

        otcNexus.setPriceFeeds(
            0x93567d6B6553bDe2b652FB7F197a229b93813D3f,
            0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7
        ); //AVAX/USD
        otcNexus.setPriceFeeds(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0x3E7d1eAB13ad0104d2750B8863b489D65364e32D
        ); //USDT/USD
        vm.stopBroadcast();
    }
}
