contract PiggyBankForTwo {

    public payable address constant guarantor = 0x000000;
    public payable address constant address1 = 0x000001;
    public payable address constant address2 = 0x000002;

    public uint balance1, balance2;
    public uint earliestBreakingTime;

    constructor () payable {
        require (msg.sender == guarantor);
        require (msg.value >= 10 ether);

        balance1 = 0;
        balance2 = 0;
        earliestBreakingTime = block.timestamp + 1 years;

        piggybankBroken = false;
        guarantorPaid = false;
    } 

    public deposit() payable {
        if (msg.sender == address1) balance1 += msg.value;
        if (msg.sender == address2) balance2 += msg.value;
    }

    /* 
     * assume wellbehaved(address1)
     *   invariant
     *     net(address1) == balance1
     *     net(address2) == balance2
     */

    public smashPiggyBank() {
        /* assume wellbehaved(address1) 
         *   after success 
         *     net(address1) == 0
         */

        /* NOT PROVABLE */
        /* assume wellbehaved(address2) 
         *   after success 
         *     net(address2) == 0
         */

        require (block.timestamp >= earliestBreakingTime);
        require (msg.sender==address1 || msg.sender==address2);

        uint _balance1 = balance1;
        uint _balance2 = balance2;
        
        // OK
        // PROVABLE BY W
        // balance1 = 0; 
        // address1.transfer(_balance1);
        // balance2 = 0;
        // address2.transfer(_balance2);

        // OK
        // UNPROVABLE BY ANYONE
        // balance1 = 0; 
        // balance2 = 0;
        // address1.transfer(_balance1);
        // address2.transfer(_balance2);

        // OK
        // PROVABLE BY W+G
        // balance1 = 0; 
        // balance2 = 0;
        // address1.transfer(_balance1);
        // address2.transfer(_balance2);

        // NEED TO TRUST 1
        // PROVABLE BY W+G
        // address1.transfer(_balance1);
        // balance1 = 0; 
        // balance2 = 0;
        // address2.transfer(_balance2);

        // NEED TO TRUST 1
        // UNPROVABLE BY ANYONE
        // address1.transfer(_balance1);
        // balance2 = 0;
        // address2.transfer(_balance2);
        // balance1 = 0; 


        piggybankBroken = true;
    }

    public getGuarantee() {
        require (msg.sender == guarantor);
        require (piggybankBroken && !guarantorPaid);

        guarantorPaid = true;
        guarantor.transfer(10 ether);
    }


}