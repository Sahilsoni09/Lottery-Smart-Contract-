// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private

// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author Sahil Soni
 * @notice This contract is for creating a Sample Raffle
 * @dev It implement Chainlink VRF2.5 and Chainlink Automation
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /*Error */

    error Raffle__SendMoreToEnterRaffle();

    uint16 private constant REQUEST_CONFIRMATIONs = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /*Events */

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator,bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < i_interval) revert();

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest(
            {
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONs,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            }
        );

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        
    }
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{}

    /*Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}