// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";



contract DeployRaffle is Script{
    function run() public {}

    function deployContract() external returns(Raffle,HelperConfig){
        
        HelperConfig helperConfig = new HelperConfig();
        
        

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

       

        // Deployment transaction broadcast karne ke liye Foundry ka `startBroadcast` use karte hain
        vm.startBroadcast();

        // Raffle contract ko deploy karte hain network-specific configurations ke saath
        Raffle raffle = new Raffle(
            config.entranceFee,        // Raffle entrance fee
            config.interval,
            config.vrfCoordinator,      // VRF Coordinator address
            config.gasLane,                 // VRF gas lane
            config.callbackGasLimit,       // Callback gas limit
            config.subscriptionId          // Subscription ID
        );

        // Broadcast ko stop karte hain
        vm.stopBroadcast();

        // Deploy ki gayi Raffle contract ko subscription ka consumer banate hain
       

        // Deploy ki gayi Raffle contract aur HelperConfig ka instance return karte hain
        return (raffle, helperConfig);
    }
}