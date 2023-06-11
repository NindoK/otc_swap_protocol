// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../lib/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "../src/OtcNexus.sol";
import "../src/OtcOption.sol";
import "../src/OtcToken.sol";
import "../src/Receiver.sol";
import "../src/ReceiverStable.sol";

///@notice Script to deploy contracts to local blockchain
/*
For local deployment use commands:
anvil
// pick from there private key and public key
export pk=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script ./script/DeployLocal.sol:DeployLocal --fork-url http://localhost:8545 --private-key $pk --broadcast --resume

--- Deployment on testnet:
source .env
forge script ./script/DeployLocal.sol:DeployLocal --fork-url $MUMBAI_RPC_URL --broadcast --verify -vvvv

verify cast is working:
cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "rfsIdCounter()"
0x0000000000000000000000000000000000000000000000000000000000000001



*/
contract DeployLocal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        OtcToken otcToken = new OtcToken("Test WETH", "tWETH", 1_000 * 1e18, 18);
        OtcNexus otcNexus = new OtcNexus(address(otcToken));
        // Receiver receiver = new Receiver();
        // ReceiverStable receiver = new ReceiverStable();
        OtcOption otcOption = new OtcOption();
        //        MockV3Aggregator mockChainlinkAggregator = new MockV3Aggregator(8, 2000*(10**8));
        // address[] memory tokensAccepted = new address[](1);
        // tokensAccepted[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        // otcNexus.createFixedRfs(
        //     0xd24DFf6117936B6ff97108CF26c1dD8865743d87,
        //     tokensAccepted,
        //     4400,
        //     500,
        //     0,
        //     1687505340,
        //     OtcNexus.TokenInteractionType.TOKEN_APPROVED
        // );

        // address[] memory tokensAcceptedFixedUsd = new address[](2);
        // tokensAcceptedFixedUsd[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        // tokensAcceptedFixedUsd[1] = 0x45804880De22913dAFE09f4980848ECE6EcbAf78;
        // otcNexus.createFixedRfs(
        //     0x355a824bEa1adc22733978A3748271E1bbB34130,
        //     tokensAcceptedFixedUsd,
        //     4400,
        //     0,
        //     1504,
        //     1687505340,
        //     OtcNexus.TokenInteractionType.TOKEN_APPROVED
        // );

        otcNexus.setPriceFeeds(
            0x93567d6B6553bDe2b652FB7F197a229b93813D3f,
            0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7
        ); //AVAX/USD
        otcNexus.setPriceFeeds(
            0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1,
            0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046
        ); //DAI/USD
        otcNexus.setPriceFeeds(
            0x714550C2C1Ea08688607D86ed8EeF4f5E4F22323,
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        ); //ETH/USD
        otcNexus.setPriceFeeds(
            0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025,
            0x9dd18534b8f456557d11B9DDB14dA89b2e52e308
        ); //SAND/USD
        otcNexus.setPriceFeeds(
            0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7,
            0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0
        ); //USDC/USD
        otcNexus.setPriceFeeds(
            0x3813e82e6f7098b9583FC0F33a962D02018B6803,
            0x92C09849638959196E976289418e5973CC96d645
        ); //USDT/USD
        otcNexus.setPriceFeeds(
            0x5B67676a984807a212b1c59eBFc9B3568a474F0a,
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        ); //MATIC/USD
        vm.stopBroadcast();
    }
}
