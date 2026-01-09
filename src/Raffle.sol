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
pragma solidity ^0.8.19;

/**
 * @title A Simple Raffle Contract
 * @author Ashif Sekh
 * @notice This contract is for creating a simple raffle system.
 * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
 */

contract Raffle {

    // Errors
    error Raffle__NotEnoughEthSent();

    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;


    event EnteredRaffle(address indexed player);

    constructor (uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
        s_players.push(payable(msg.sender));
        //1.Makes migration easier
        //2.Makes frontend indexing easier
        emit EnteredRaffle(msg.sender);

    }

    function pickWinner() public {
        // 1.Get a random number 
        // 2.Use the random number to the pick the pickWinner
        // 3.Automatically called 
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) revert();

    }

    /** Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

}


