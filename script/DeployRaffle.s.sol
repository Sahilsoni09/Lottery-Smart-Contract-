//SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";


contract DeployRaffle is Script{
    function run() external returns(Raffle,HelperConfig){
        
        HelperConfig helperConfig = new HelperConfig();
        
        AddConsumer addConsumer = new AddConsumer();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0){
            CreateSubscription createSubscription = new CreateSubscription();

            (config.subscriptionId,config.vrfCoordinatorV2_5) = createSubscription.createSubscription(config.vrfCoordinatorV2_5,config.account);

            FundSubscription fundSubscription = new FundSubscription();

            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, // VRF Coordinator address
                config.subscriptionId,    // Subscription ID
                config.link,              // LINK token address
                config.account            // Account jo fund karega
            );

            // Updated configuration ko HelperConfig me save karte hain
            helperConfig.setConfig(block.chainid, config);
        }

        // Deployment transaction broadcast karne ke liye Foundry ka `startBroadcast` use karte hain
        vm.startBroadcast(config.account);

        // Raffle contract ko deploy karte hain network-specific configurations ke saath
        Raffle raffle = new Raffle(
            config.subscriptionId,          // Subscription ID
            config.gasLane,                 // VRF gas lane
            config.automationUpdateInterval,// Automation update interval
            config.raffleEntranceFee,       // Raffle entrance fee
            config.callbackGasLimit,        // Callback gas limit
            config.vrfCoordinatorV2_5       // VRF Coordinator address
        );

        // Broadcast ko stop karte hain
        vm.stopBroadcast();

        // Deploy ki gayi Raffle contract ko subscription ka consumer banate hain
        addConsumer.addConsumer(
            address(raffle),           // Raffle contract address
            config.vrfCoordinatorV2_5, // VRF Coordinator address
            config.subscriptionId,     // Subscription ID
            config.account             // Account jo transaction execute karega
        );

        // Deploy ki gayi Raffle contract aur HelperConfig ka instance return karte hain
        return (raffle, helperConfig);
    }
}