// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StagedTransfer {
    enum Mode { AwaitingApproval, AwaitingWithdrawal, Done }

    address payable payer;
    address payable intermediary;
    address payable receiver;

    uint payment_amount;
    uint commission_amount;

    Mode mode;

    constructor (
        address payable _receiver, uint _payment_amount, 
        address payable _intermediary, uint _commission_amount) payable {
        require (msg.value == _commission_amount + _payment_amount);

        receiver = _receiver;
        intermediary = _intermediary;
        payer = payable(msg.sender);

        commission_amount = _commission_amount;
        payment_amount = _payment_amount;

        mode = Mode.AwaitingApproval;
    } 

    function approvePayment() public {
        require (msg.sender == intermediary);

        require (mode == Mode.AwaitingApproval);
        mode = Mode.AwaitingWithdrawal;

        intermediary.transfer(commission_amount / 2);
    }

    function rejectPayment() public {
        require (msg.sender == intermediary);

        require (mode == Mode.AwaitingApproval);
        mode = Mode.Done;

        intermediary.transfer(commission_amount / 2);
        payer.transfer(address(this).balance);
    }

    function affectPayment() public {
        require (mode == Mode.AwaitingWithdrawal);
        mode = Mode.Done;

        receiver.transfer(payment_amount);
    }

    function payRemainingCommission() public {
        require (mode == Mode.Done);

        intermediary.transfer(address(this).balance);
    }
}