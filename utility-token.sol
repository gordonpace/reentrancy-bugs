// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/* 
Either user knows that the invariant holds if they know that they will
not use reentrancy, so it is 'safe' from the users' perspective. However, 
for any other perspective (one that does not trust the two users not to
reenter the contract), the (third conjunct of the) invariant does not hold. 
*/

contract BrokenToken {
    enum Mode { Loading, TokenAcquisition, TokenUsage }

    /*@ class_invariant
        tokens_owned1 <= 2 &&
        tokens_owned2 <= 2 &&
        !(tokens_owned1 == 2 && tokens_owned2 == 2) 
      */

    address payable user1;
    address payable user2;

    uint tokens_owned1;
    uint tokens_owned2;
    
    Mode mode;

    // Constructor
    constructor (
        address payable _user1, address payable _user2
    ) {
        // Remember who the authorised token users are
        user1 = _user1;
        user2 = _user2;

        // Start the contract in load mode
        mode = Mode.Loading;
    } 

    // Function to allow adding funds to the smart contract and launch the token acquisition mode
    function loadAndLaunchTokens() public payable {
        // The contract must be in loading mode
        require (mode == Mode.Loading);

        // Reset token counts 
        tokens_owned1 = 0;
        tokens_owned2 = 0;

        // Move on to token acquisition mode
        mode = Mode.TokenAcquisition;
    }


    // Function to allow user1 to acquire a token
    function acquireToken1() public {
        // Only user1 may invoke this
        require (msg.sender == user1);

        // The contract must be in token acquisition mode
        require (mode == Mode.TokenAcquisition);

        // User 1 acquires one token
        tokens_owned1++;

        // Pay user 2 compensation for this token being acquired by the other user 
        user2.transfer(1 ether);

        // Move on to the token usage mode if enough tokens have been acquired
        // Note that we do not want to do this before the transfer to avoid user2 
        // from using their tokens before user 1 also has an opportunity to do so.
        if (tokens_owned1 + tokens_owned2 >= 2)
            mode = Mode.TokenUsage; 
    }

    // Function to allow user2 to acquire a token
    function acquireToken2() public {
        // Only user2 may invoke this
        require (msg.sender == user2);
        
        // The contract must be in token acquisition mode
        require (mode == Mode.TokenAcquisition);

        // User 2 acquires one token
        tokens_owned2++;

        // Pay user 1 compensation for this token being acquired by the other user 
        user1.transfer(1 ether);

        // Move on to the token usage mode if enough tokens have been acquired
        // Note that we do not want to do this before the transfer to avoid user1s 
        // from using their tokens before user 1 also has an opportunity to do so.
        if (tokens_owned1 + tokens_owned2 >= 2)
            mode = Mode.TokenUsage; 
    }

    // Functionality for a token owner to use one of their tokens
    function useToken() public {
        // Only the authorised users may use tokens
        require (msg.sender == user1 || msg.sender == user2);

        // Check that we are in token usage mode
        require (mode == Mode.TokenUsage);

        // Check that the caller has at least one token and consume it
        if (msg.sender == user1) {
            require (tokens_owned1 > 0);
            tokens_owned1--;
        }
        if (msg.sender == user2) {
            require (tokens_owned2 > 0);
            tokens_owned2--;
        }

        // ---------------------------------------------------------------
        // Add logic here to provide something in return for using token
        // ---------------------------------------------------------------

        // If no tokens remain, move back to contract loading mode
        if (tokens_owned1 + tokens_owned2 == 0)
            mode = Mode.Loading;

    }

}