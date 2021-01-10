 /**
     *  @todo
     *  Ensure to install web3 before running this test -> npm install web3
     *  Tests to write:
     *  1.  Create Group                        -   
     *  2.  Get Group By Name                   -   
     *  3.  Create Cooperative cycle & Get current ID       -   
     *  4.  Join Cooperative                          -   
     *  5.  Get Cooperative Cycle Info for a member              -   
     *  6.  Get Cooperative Cycle Info                -   
     *  7.  Start Cooperative Cycle                   -   
     *  8.  Withdraw From Cycle. ( Delay for sometime before this test is called)   -   
     *  9.  Withdraw From Cycle while it's ongoing ( Delay for sometime before this test is called ) - 
     *  10. Create Group with account 2         -   
     *  11. Create Cooperative with account 2         -   
     *  12. Join Cooperative with 3 accounts          -   
     *  13. Start the Cooperative Cycle with 3 accounts   -   
     *  14. Withdraw From Cycle while it's ongoing ( Delay for sometime before this test is called ) -             -   
             
     *  15. Test contract deprication               -   
     */

    console.log("********************** Running Esusu Test *****************************");
    const Web3 = require('web3');
    const { assert } = require('console');
    const web3 = new Web3("HTTP://127.0.0.1:8545");
    const utils = require("./helpers/Utils")