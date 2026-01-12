// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.sol";
import {VRFCoordinatorV2Mock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract DeployRaffle is Script {
    function run() external {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );

        // Add raffle as consumer for local chain
        if (block.chainid == 31337) {
            VRFCoordinatorV2Mock(networkConfig.vrfCoordinator)
                .addConsumer(networkConfig.subscriptionId, address(raffle));
        }

        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
