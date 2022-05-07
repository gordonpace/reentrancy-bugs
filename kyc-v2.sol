// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Transfer with Know-Your-Customer (KYC) supported through an intermediary oracle 
contract KYCTransfer {
    event TransferRecord(
        address payable _payer, 
        uint _payment_amount, uint _commission_amount,
        address payable _receiver, 
        bytes32 _KYC_information
    );

    enum Mode { AwaitingApproval, AwaitingWithdrawal, AwaitingKYCInformation, Done }

    /*@ class_invariant
          address(this) != payer &&
          address(this) != intermediary &&
          address(this) != receiver &&
          payer != intermediary &&
          intermediary != receiver &&
          receiver != payer;
      */

    /* Recall:
     * net(addr) := (funds sent from addr to this) - (funds sent from this to addr)
     */
    /*@ class_invariant
         this.balance == net(payer) + net(intermediary) + net(receiver) &&
         mode == Mode.AwaitingApproval -> 
           this.balance == payment_amount + commission_amount &&
         mode == Mode.AwaitingWithdrawal -> 
           this.balance == payment_amount + commission_amount - commission_amount/2 &&
         mode == Mode.AwaitingKYCInformation -> 
           this.balance == commission_amount - commission_amount/2 &&
         mode == Mode.Done -> 
           this.balance == 0;
      */

    // State to remember the parties involved
    address payable payer;
    address payable intermediary;
    address payable receiver;

    // State to remember the amounts involved
    uint payment_amount;
    uint commission_amount;

    // State to remember the mode of the contract
    Mode mode;

    // The constructor will be called by the person who wants to affect payment, (i) listing the receiver and amount to
    // send; (ii) the intermediary and the commission to be paid; and (iii) sending the funds for the payment and 
    // commission upfront.
    constructor (
        address payable _receiver, uint _payment_amount, 
        address payable _intermediary, uint _commission_amount
    ) payable {

      // Record the addresses of the parties involved
      receiver = _receiver;
      intermediary = _intermediary;
      payer = payable(msg.sender);

      // All involved should be different parties
      require (receiver != intermediary);
      require (receiver != payer);
      require (payer != intermediary);

      // Record information about transfer and commission amounts
      commission_amount = _commission_amount;
      payment_amount = _payment_amount;

      // Make sure we receive the right amount of funds
      require (msg.value == commission_amount + payment_amount);

      // Initialise the mode to wait for the intermediary's KYC approval or rejection of the transfer
      mode = Mode.AwaitingApproval;
    } 

    // Allow the intermediary to approve the transfer
    function approvePayment() public {
      // Only the intermediary can approve a payment
      require (msg.sender == intermediary);

      // Make sure that we are in the right mode and move on to the mode awaiting the withdrawal to take place
      require (mode == Mode.AwaitingApproval);
      mode = Mode.AwaitingWithdrawal;

      // The intermediary gets 50% of their commission (rounded down if necessary)
      intermediary.transfer(commission_amount / 2);
    }

    // Allow the intermediary to reject the transfer
    function rejectPayment() public {
      // Only the intermediary can reject a payment
      require (msg.sender == intermediary);

      // Make sure that we are in the right mode and move on to the mode awaiting for the KYC information
      // to be recorded in an event
      require (mode == Mode.AwaitingApproval);
      mode = Mode.AwaitingKYCInformation;

      // The intermediary gets 50% of their commission (rounded down if necessary)        
      intermediary.transfer(commission_amount / 2);

      // The payer gets his money back
      payer.transfer(payment_amount);
    }

    // In practice, here we would also have a function for the payer to invoke a timeout
    // if the intermediary takes too long to approve or reject the transfer, returning all 
    // funds to the payer. This is left out for simplicity.

    // The receiver can accept the transfer proposed through this function
    /*@ on_success 
      @ net(receiver) == - payment_amount;
     */
    function affectPayment() public {
      // Only the receiver can accept the funds
      require (msg.sender == receiver);

      // Make sure that the contract is awaiting payment to take place, and update the mode to 
      // the one in which the intermediary may record KYC information
      require (mode == Mode.AwaitingWithdrawal);
      mode = Mode.AwaitingKYCInformation;

      // Send the funds to the receiver
      receiver.transfer(payment_amount);
    }

    // In practice, here we would also have a function for the payer to invoke a timeout
    // if the receiver takes too long to affect the payment, returning the remaining 
    // funds to the payer (possibly the remaining commission going to the intermediary). 
    // This is left out for simplicity.

    // Allow the intermediary to register the KYC information after the transfer has been fully accepted or rejected
    // The intermediary will provide the KYC information in hashed form as a parameter to this function.
    function registerKYCInformation(bytes32 _KYC_information) public {
      // Only the intermediary can write KYC information
      require (msg.sender == intermediary);

      // Check that the contract is in the right mode awaiting for KYC information and move on to the 
      // final state where nothing is possible
      require (mode == Mode.AwaitingKYCInformation);
      mode = Mode.Done;

      // Emit an event with all the relevant information
      emit TransferRecord(payer, payment_amount, commission_amount, receiver, _KYC_information);

      // Reset payment and commission amounts for safety
      payment_amount = 0;
      commission_amount = 0;

      // Send the remaining commission funds to the intermediary (avoiding rounding calculations) 
      intermediary.transfer(address(this).balance);
    }
}
