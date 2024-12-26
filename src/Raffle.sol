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
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance, uint256 playersLenght, uint256 raffleState);


    /*Type Declarations*/
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    /*State Variables*/
    uint16 private constant REQUEST_CONFIRMATIONs = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /*Events */

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator,bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

   

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState!= RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

     /**
     * @dev This is the function that chainlink node will call to see 
     * if the lottery is ready to have a winner picked
     * The following should be true in oder to upKeedNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open 
     * 3. The contract has ETH
     * 4. Implicitly your subscription has LINK
     * @param  - ignored
     * @return upKeepNeeded - true is its time to reset the lottery 
     * @return - ignored
     */

    function checkUpKeep(bytes memory /* checkData */) public view returns(bool upKeepNeeded, bytes memory /*performData */){
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance >0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return(upKeepNeeded, "");
    }

    function performUpKeep(bytes calldata /* performData */) public {

        (bool upKeepNeeded,) = checkUpKeep("");
        if(!upKeepNeeded){
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        

        s_raffleState = RaffleState.CALCULATING;

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

        s_vrfCoordinator.requestRandomWords(request);
        
    }
    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override{
        //Checks 
        

        // Effect (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        // Interactios (External Contract Interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}("");

        if(!success){
            revert Raffle__TransferFailed();
        } 
        emit WinnerPicked(s_recentWinner);
    }

    /*Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
