contract SplitPayment {
    enum State { AwaitingPayment, AwaitingWithdrawal, AwaitingGuarantorWithdrawal, Done }

    public payable address constant guarantor = 0x000000;
    public payable address constant payer = 0x000002;
    public payable address constant address1 = 0x000001;
    public payable address constant address2 = 0x000002;

    public uint payment_value, guarantee_value;
    public State mode;

    constructor () payable {
        require (msg.sender == guarantor);
        require (msg.value >= 10 ether);

        payment_value = 0;
        guarantee_value = msg.value;
        mode = State.AwaitingPayment;
    } 

    public makePayment() payable {
        require (msg.sender == payer);

        require (mode == State.AwaitingPayment);
        mode = State.AwaitingWithdrawal;
        
        payment_value = msg.value;
    }

    /* 
     *   invariant
     *     net(guarantor) + net(address1) + net(address2) + net(payer) == guarantee_value + payment_value
     *     this.balance == payment_value + guarantee_value
     */

    public dividePayment() {
        require (msg.sender==address1 || msg.sender==address2);

        require (mode == State.AwaitingWithdrawal);
        mode = State.AwaitingGuarantorWithdrawal;
        

        uint _amount = payment_value / 2;
        if (payment_value > 2*_amount) 
            guarantee_value ++;

        // UNSAFE
        payment_value = 0; 
        address1.transfer(_amount);
        address2.transfer(_amount);

        // SAFE
        // payment_value = _amount2; 
        // address1.transfer(_amount1);
        // payment_value = 0; 
        // address2.transfer(_amount2);

    }

    public screwUp() {
        if (this.balance != payment_value + guarantee_value) {
            address1.transfer(guarantee_value);
            // to maintain invariant: payment_value -= guarantee_value;
        }
    }
    
    public getGuarantee() {
        require (msg.sender == guarantor);

        require (mode == State.AwaitingGuarantorWithdrawal);
        mode = State.Done;

        guarantee_value = 0;
        guarantor.transfer(this.balance);
    }


}