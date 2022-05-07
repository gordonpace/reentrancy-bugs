# reentrancy-bugs
Code from the paper:

~~to add bib entry~~

Biggy Pank: biggy-pank.sol
This is a savings smart contract for two hard-coded parties and a guarantor (we do not include logic for what they are guaranteeing) in which (i) the guarantor starts by putting 10 ether in the smart contract as a guarantee; (ii) the other two parties may then deposit funds, and (iii) after at least one year has elapsed since the smart contract was started (the constructor was called), either party can break the piggy bank, getting their funds back, after which (iv) the guarantor can get their 10 ether back. The smashPiggyBank() function has five different orderings of transferring funds and updating the variables, and comments are included as to which satisfy the invariant (that the net of the two saving parties is equal to the variables balance1 and balance2) depending on presumption of benevolence of which parties.

Split Payment: split-payment.sol
Just like the Biggy Pank, this has a guarantor, but now only one payment is allowed, after which the funds can be split between the two main parties. The function dividePayment() handles this, and sets the balance variables before the actual transfers are done (as is usually recommended), but another function screwUp() provides a means of the first main party stealing the guarantee through a callback.

KYC: kyc-v?.sol
These are based on the KYC example in the paper.

Utility Token: utility-token.sol
This is based on the example in the paper, in which two parties may acquire tokens, but reentrency may break the invariant if either party is willing to do so.


