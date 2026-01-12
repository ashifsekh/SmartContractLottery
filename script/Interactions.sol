// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint64 subId;
        (subId, vrfCoordinator) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64, address) {
        console.log("Creating subscription on ChainID: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id is: ", subId);
        console.log("Please update subscriptionId in HelperConfig!");
        return (subId, vrfCoordinator);
    }

    function addConsumer(address vrfCoordinator, address raffle, uint64 subId) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
        console.log("Consumer added successfully");
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, uint96 amount) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("Amount: ", amount);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, amount);
        vm.stopBroadcast();
        console.log("Subscription funded successfully");
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}
