    /**
     *  @todo    
     *  Ensure to install web3 before running this test -> npm install web3
     *  Tests to write:
     *  1.  Create Group                        -   Done  
     *  2.  Get Group By Name                   -   Done
     *  3.  Create Esusu & Get current ID       -   Done
     *  4.  Join Esusu                          -   Done
     *  5.  Get Member Cycle Info               -   Done
     *  6.  Get Esusu Cycle Info                -   Done
     *  7.  Start Esusu Cycle                   -   Done
     *  8.  Withdraw ROI From Cycle. ( Delay for sometime before this test is called)   -   Done
     *  9.  Withdraw Capital From Cycle ( Delay for sometime before this test is called ) - Done
     *  10. Create Group with account 2         -   Done
     *  11. Create Esusu with account 2         -   Done
     *  12. Join Esusu with 3 accounts          -   Done
     *  13. Start the Esusu Cycle with 3 accounts   -   Done
     *  14. Withdraw ROI for 3 accounts             -   Done
     *  15. Withraw Capital for 3 accounts          -   Done
     *  16. Test contract deprication               -   Done
     */



    // if(true){
    //     return;
    // }
    console.log("********************** Running Esusu Test *****************************");
    const Web3 = require('web3');
    const { assert } = require('console');
    const web3 = new Web3("HTTP://127.0.0.1:8545");
    const utils = require("./helpers/Utils")
    
    const ForTubeBankAdapterContract = artifacts.require("ForTubeBankAdapter");
    const ForTubeBankServiceContract = artifacts.require("ForTubeBankService");
    const GroupsContract = artifacts.require('Groups');
    const TreasuryContract = artifacts.require('Treasury');
    const SavingsConfigContract = artifacts.require('SavingsConfig');
    const XendTokenContract = artifacts.require('XendToken');
    const EsusuServiceContract = artifacts.require('EsusuService');
    const RewardConfigContract = artifacts.require('RewardConfig');
    const EsusuAdapterContract = artifacts.require('EsusuAdapter'); 
    const EsusuAdapterWithdrawalDelegateContract = artifacts.require('EsusuAdapterWithdrawalDelegate');
    const EsusuStorageContract = artifacts.require('EsusuStorage');


  const BUSDContractABI = require('./abi/BEP20ABI.json');
  const FBUSDContractABI = require('./abi/BEP20ABI.json');    // FBUSD and BUSD can use the same ABI since we are just calling basic BEP20 functions for this test
const { default: BigNumber } = require('bignumber.js');

  const BUSDContractAddress = "0x3b1F033dD955f3BE8649Cc9825A2e3E194765a3F";  // This is a custom BUSD for ForTube, you will not find it on BSC Faucet
  const FBUSDContractAddress = "0x6112a45160b2058C6402a5bfBE3A446c8fD4fb45";  // This is the FToken shares a user will receive when they deposit BUSD

  const unlockedAddress = "0x9957887a260c7db1d4cb1fa67c0ce43d9b1d72c5";   //  Has lots of ForTube BUSD

  const BUSDContract = new web3.eth.Contract(BUSDContractABI,BUSDContractAddress);
  const FBUSDContract = new web3.eth.Contract(FBUSDContractABI,FBUSDContractAddress);
    
  var account1;   
  var account2;
  var account3;

  var account1Balance;
  var account2Balance;
  var account3Balance;

  
//  Send Fortube BUSD from our constant unlocked address
async function sendBUSD(amount, recipient){

  var amountToSend = BigInt(amount); //  1000 Dai

  console.log(`Sending  ${ amountToSend } x 10^-18 FortTube-BUSD to  ${recipient}`);

  await BUSDContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

  let recipientBalance = await BUSDContract.methods.balanceOf(recipient).call();
  
  console.log(`Recipient Balance: ${recipientBalance}`);


}

//  ForTube BUSD Balance
async function BUSDBalance(){

  let unlockedAddressBalance = await BUSDContract.methods.balanceOf(unlockedAddress).call();

  console.log("Unlocked Address Balance: " + unlockedAddressBalance);
};


//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveBUSD(spender,  owner,  amount){

  await BUSDContract.methods.approve(spender,amount).send({from: owner});

  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Fortube-BUSD by Owner:  ${owner}`);

};

async function approveFBUSD(spender,  owner,  amount){

  await FBUSDContract.methods.approve(spender,amount).send({from: owner});

  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 FBUSD by Owner:  ${owner}`);

};


contract('EsusuService', () => {
    let forTubeBankAdapterContract = null;
    let forTubeBankServiceContract = null;
    let savingsConfigContract = null;
    let esusuAdapterContract = null;
    let esusuServiceContract = null;
    let groupsContract = null;
    let xendTokenContract = null;
    let esusuAdapterWithdrawalDelegateContract = null;
    let esusuStorageContract = null;

    before(async () =>{

        savingsConfigContract = await SavingsConfigContract.deployed();
        forTubeBankAdapterContract = await ForTubeBankAdapterContract.deployed();
        forTubeBankServiceContract = await ForTubeBankServiceContract.deployed();
        esusuAdapterContract = await EsusuAdapterContract.deployed();
        esusuServiceContract = await EsusuServiceContract.deployed();
        groupsContract = await GroupsContract.deployed();
        xendTokenContract = await XendTokenContract.deployed();
        esusuAdapterWithdrawalDelegateContract = await EsusuAdapterWithdrawalDelegateContract.deployed();
        esusuStorageContract = await EsusuStorageContract.deployed();

        //1. Create SavingsConfig rules
        await savingsConfigContract.createRule("esusufee",0,0,1000,1);

        console.log("1->Savings Config Rule Created ...");

        //2. Update the forTubeAdapterContract Address in the forTubeBankingService Contract
        await forTubeBankServiceContract.updateAdapter(forTubeBankAdapterContract.address);
        console.log("2->forTubeAdapter Address Updated In forTubeBankingService ...");
        
        //3. Update the ForTubeBankService Address in the EsusuAdapter Contract
        await esusuAdapterContract.UpdateForTubeBankService(forTubeBankServiceContract.address);
        console.log("3->ForTubeBankService Address Updated In EsusuAdapter ...");

        //4. Update the EsusuAdapter Address in the EsusuService Contract
        await esusuServiceContract.UpdateAdapter(esusuAdapterContract.address);
        console.log("4->EsusuAdapter Address Updated In EsusuService ...");

        //5. Activate the storage oracle in Groups.sol with the Address of the EsusuApter
        await  groupsContract.activateStorageOracle(esusuAdapterContract.address);
        console.log("5->EsusuAdapter Address Updated In Groups contract ...");

        //6. Xend Token Should Grant access to the  Esusu Adapter Contract
        await xendTokenContract.grantAccess(esusuAdapterContract.address);
        console.log("6->Xend Token Has Given access To Esusu Adapter to transfer tokens ...");
        
        //7. Esusu Adapter should Update Esusu Adapter Withdrawal Delegate
        await esusuAdapterContract.UpdateEsusuAdapterWithdrawalDelegate(esusuAdapterWithdrawalDelegateContract.address);
        console.log("7->EsusuAdapter Has Updated Esusu Adapter Withdrawal Delegate Address ...");

        //8. Esusu Adapter Withdrawal Delegate should Update ForTubeBank Service
        await esusuAdapterWithdrawalDelegateContract.UpdateForTubeBankService(forTubeBankServiceContract.address);
        console.log("8->Esusu Adapter Withdrawal Delegate Has Updated ForTubeBank Service ...");

        //9. Esusu Service should update esusu adapter withdrawal delegate
        await esusuServiceContract.UpdateAdapterWithdrawalDelegate(esusuAdapterWithdrawalDelegateContract.address);
        console.log("9->Esusu Service Contract Has Updated  Esusu Adapter Withdrawal Delegate Address ...");

        //10. Esusu Storage should Update Adapter and Adapter Withdrawal Delegate 
        await esusuStorageContract.UpdateAdapterAndAdapterDelegateAddresses(esusuAdapterContract.address,esusuAdapterWithdrawalDelegateContract.address);
        console.log("10->Esusu Storage Contract Has Updated  Esusu Adapter and Esusu Adapter Withdrawal Delegate Address ...");
        
        //11. Xend Token Should Grant access to the  Esusu Adapter Withdrawal Delegate Contract
        await xendTokenContract.grantAccess(esusuAdapterWithdrawalDelegateContract.address);
        console.log("11->Xend Token Has Given access To Esusu Adapter Withdrawal Delegate to transfer tokens ...");


        //  Get the addresses and Balances of at least 2 accounts to be used in the test
        //  Send DAI to the addresses
        // web3.eth.getAccounts().then(function(accounts){

        //     account1 = accounts[0];
        //     account2 = accounts[1];
        //     account3 = accounts[2];

        //     //  send money from the unlocked dai address to accounts 1 and 2
        //     var amountToSend = BigInt(10000000000000000000000); //   10,000 Dai

        //     //  get the eth balance of the accounts
        //     web3.eth.getBalance(account1, function(err, result) {
        //         if (err) {
        //             console.log(err)
        //         } else {
        
        //             account1Balance = web3.utils.fromWei(result, "ether");
        //             console.log("Account 1: "+ accounts[0] + "  Balance: " + account1Balance + " BNB");
        //             sendBUSD(amountToSend,account1);

        //         }
        //     });
    
        //     web3.eth.getBalance(account2, function(err, result) {
        //         if (err) {
        //             console.log(err)
        //         } else {
        //             account2Balance = web3.utils.fromWei(result, "ether");
        //             console.log("Account 2: "+ accounts[1] + "  Balance: " + account2Balance + " BNB");
        //             sendBUSD(amountToSend,account2);                              

        //         }
        //     });

        //     web3.eth.getBalance(account3, function(err, result) {
        //         if (err) {
        //             console.log(err)
        //         } else {
        //             account3Balance = web3.utils.fromWei(result, "ether");
        //             console.log("Account 3: "+ accounts[2] + "  Balance: " + account3Balance + " BNB");
        //             sendBUSD(amountToSend,account3);                              

        //         }
        //     });
        // });


        //  Send 2,000 - BUSD to the EsusuAdapterContract, Invest the BUSD in ForTubeLendingService twice: 1,000 each time,
        //  withdraw the BUSD twice as well and then send the BUSD back to the sender





    });

    var groupName = "Omega Reality";
    var groupSymbol = "Ω";
    var groupId = null;
    var depositAmount = "2000000000000000000000";   //2,000 DAI 10000000000000000000000 
    var payoutIntervalSeconds = "30";  // 2 minutes
    var startTimeInSeconds = Math.floor((Date.now() + 120)/1000); // starts 2 minutes afer current time
    var maxMembers = "2";
    var currentEsusuCycleId = null;


    //1 & 2.  Create Group and Get Group Information By name

    it('EsusuService Contract: Should Create Group and Get the Group By Name', async () => {

        console.log("Hello");
        // await esusuServiceContract.CreateGroup(groupName, groupSymbol);

        // var groupInfo = await esusuServiceContract.GetGroupInformationByName(groupName);

        // console.log(`Group Id: ${BigInt(groupInfo[0])}, Name: ${groupInfo[1]}, Symbol: ${groupInfo[2]}, Owner: ${groupInfo[3]}`);

        // groupId = BigInt(groupInfo[0]);
        // assert(groupInfo[1] === groupName);
        // assert(groupInfo[2] === groupSymbol);

    });
    
    //3  & 6.Create An Esusu Cycle, Get Current ID and Get the Esusu Cycle Information
    // it('EsusuService Contract: Should Create Esusu Cycle and Get The Current Esusu Cycle', async () => {

    //     //  Create esusu cycle
    //     await esusuServiceContract.CreateEsusu(groupId.toString(),depositAmount, payoutIntervalSeconds,startTimeInSeconds.toString(),maxMembers);
    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    //     console.log(`Current Esusu Cycle ID: ${currentEsusuCycleId}`);
        
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // });

    // //4 Join Esusu
    // it('EsusuService Contract: Should Join The Current Esusu Cycle', async () => {
        
    //     //  Give allowance to the EsusuAdapter to spend DAI on behalf of account 1 and 2
    //     var approvedAmountToSpend = BigInt(10000000000000000000000); //   10,000 Dai
    //     approveBUSD(esusuAdapterContract.address,account1,approvedAmountToSpend);
    //     approveBUSD(esusuAdapterContract.address,account2,approvedAmountToSpend);
        
    //     var pricePerFullShareBUSDBeforeDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    //     console.log(`Price Per FullShare Before Joining Cycle: ${pricePerFullShareBUSDBeforeDeposit}`);

    //     //  Account 1 and 2 should Join esusu cycle
    //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account1);
    //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account2);

    //     var pricePerFullShareBUSDAfterDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    //     console.log(`Price Per FullShare After Joining Cycle: ${pricePerFullShareBUSDAfterDeposit}`);



    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    //     //  Price per full shares after joining should be higher than before joining since we are calling save function when joining Esusu
    //     assert(BigInt(pricePerFullShareBUSDAfterDeposit) > BigInt(pricePerFullShareBUSDBeforeDeposit));

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());
    //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // });

    // //5 Start Esusu Cycle after about (currentTimeInSeconds - startTimeInSeconds)  to ensure the start time has been reached
    // it('EsusuService Contract: Should Start The Current Esusu Cycle', async () => {

    //     var timeoutTimeInSeconds = 0;
    //     var currentTimeInSeconds = Math.floor(Date.now() / 1000);
    //     var timeDiff = currentTimeInSeconds - startTimeInSeconds;
        
    //     console.log(`currentTimeInSeconds: ${currentTimeInSeconds} ; startTimeInSeconds: ${startTimeInSeconds} `);
        
    //     if(timeDiff < 0){
    //         console.log(`Time is ${timeoutTimeInSeconds} Time never reach!!!`);
    //         timeoutTimeInSeconds = Math.abs(timeDiff);
    //     }else{

    //         console.log(`Time is ${timeoutTimeInSeconds} Time don reach!!!`);
    //         //  Just add wait of 5 seconds just to have some delay before Start cycle is called even when current time is greater than start time
    //         timeoutTimeInSeconds += 5; 

    //     }

    //     //  if currentTimeInSeconds is less than startTimeInSeconds, it means we have to wait for (startTimeInSeconds - currentTimeInSeconds)
    //     function timeout(s){
    //         return new Promise(resolve => setTimeout(resolve,s*1000));
    //     }

    //     console.log(`Waiting for ${timeoutTimeInSeconds} seconds for cycle to start`);

    //     await timeout(timeoutTimeInSeconds);
    //     console.log(`Done Waiting for ${timeoutTimeInSeconds} seconds. Starting Cycle ...`);

    //     var pricePerFullShareBUSDBeforeDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    //     console.log(`Price Per FullShare Before Deposit ${pricePerFullShareBUSDBeforeDeposit}`);

    //     //  Start esusu cycle
    //     await esusuServiceContract.StartEsusuCycle(currentEsusuCycleId.toString());

    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    //     var pricePerFullShareBUSDAfterDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    //     console.log(`Price Per FullShare After Deposit ${pricePerFullShareBUSDAfterDeposit}`);

    //     //  Price per full shares should be the same since we are no longer calling save function when cycle starts
    //     assert(BigInt(pricePerFullShareBUSDAfterDeposit) === BigInt(pricePerFullShareBUSDBeforeDeposit));

    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    //     var cycleState = BigInt(result[3]).toString();

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    //     //  Cycle state must be active 
    //     assert(cycleState === "1");

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);   

    // });

    // // //3  & 6.Create An Esusu Cycle, Get Current ID and Get the Esusu Cycle Information
    // // it('EsusuService Contract: Should Create Esusu Cycle and Get The Current Esusu Cycle', async () => {

    // //     //  Create esusu cycle
    // //     await esusuServiceContract.CreateEsusu(groupId.toString(),depositAmount, payoutIntervalSeconds,startTimeInSeconds.toString(),maxMembers);
    // //     //  get current cycle ID
    // //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    // //     console.log(`Current Esusu Cycle ID: ${currentEsusuCycleId}`);
        
    // //     //  Get esusu cycle information
    // //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    // //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    // //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    // //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    // //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    // //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // // });

    // // //4 Join Esusu
    // // it('EsusuService Contract: Should Join The Current Esusu Cycle', async () => {
        
    // //     //  Give allowance to the EsusuAdapter to spend DAI on behalf of account 1 and 2
    // //     var approvedAmountToSpend = BigInt(10000000000000000000000); //   10,000 Dai
    // //     approveBUSD(esusuAdapterContract.address,account1,approvedAmountToSpend);
    // //     approveBUSD(esusuAdapterContract.address,account2,approvedAmountToSpend);
        
    // //     //  Account 1 and 2 should Join esusu cycle
    // //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account1);
    // //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account2);

    // //     //  get current cycle ID
    // //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    // //     //  Get esusu cycle information
    // //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    // //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());
    // //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    // //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    // //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    // //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    // //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // // });

    // // //5 Start Esusu Cycle after about (currentTimeInSeconds - startTimeInSeconds)  to ensure the start time has been reached
    // // it('EsusuService Contract: Should Start The Current Esusu Cycle', async () => {

    // //     var timeoutTimeInSeconds = 0;
    // //     var currentTimeInSeconds = Math.floor(Date.now() / 1000);
    // //     var timeDiff = currentTimeInSeconds - startTimeInSeconds;
        
    // //     console.log(`currentTimeInSeconds: ${currentTimeInSeconds} ; startTimeInSeconds: ${startTimeInSeconds} `);
        
    // //     if(timeDiff < 0){
    // //         console.log(`Time is ${timeoutTimeInSeconds} Time never reach!!!`);
    // //         timeoutTimeInSeconds = Math.abs(timeDiff);
    // //     }else{

    // //         console.log(`Time is ${timeoutTimeInSeconds} Time don reach!!!`);
    // //         //  Just add wait of 5 seconds just to have some delay before Start cycle is called even when current time is greater than start time
    // //         timeoutTimeInSeconds += 5; 

    // //     }

    // //     //  if currentTimeInSeconds is less than startTimeInSeconds, it means we have to wait for (startTimeInSeconds - currentTimeInSeconds)
    // //     function timeout(s){
    // //         return new Promise(resolve => setTimeout(resolve,s*1000));
    // //     }

    // //     console.log(`Waiting for ${timeoutTimeInSeconds} seconds for cycle to start`);

    // //     await timeout(timeoutTimeInSeconds);
    // //     console.log(`Done Waiting for ${timeoutTimeInSeconds} seconds. Starting Cycle ...`);

    // //     var pricePerFullShareBUSDBeforeDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    // //     console.log(`Price Per FullShare Before Deposit ${pricePerFullShareBUSDBeforeDeposit}`);

    // //     //  Start esusu cycle
    // //     await esusuServiceContract.StartEsusuCycle(currentEsusuCycleId.toString());

    // //     //  get current cycle ID
    // //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    // //     var pricePerFullShareBUSDAfterDeposit = await forTubeBankAdapterContract.ExchangeRateStoredBUSD();  //  TODO: confirm this function's correctness
    // //     console.log(`Price Per FullShare After Deposit ${pricePerFullShareBUSDAfterDeposit}`);

    // //     assert(BigInt(pricePerFullShareBUSDAfterDeposit) > BigInt(pricePerFullShareBUSDBeforeDeposit));

    // //     //  Get esusu cycle information
    // //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    // //     var cycleState = BigInt(result[3]).toString();

    // //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    // //     //  Cycle state must be active 
    // //     assert(cycleState === "1");

    // //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    // //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    // //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    // //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);   

    // // });

    // // //  Get Member Cycle Info
    // // it('EsusuService Contract: Should Get Member Cycle Information', async () => {

    // //     var result = await esusuServiceContract.GetMemberCycleInfo(account1, currentEsusuCycleId.toString());

    // //     console.log(`CycleId: ${BigInt(result[0])},MemberId: ${result[1]}, TotalAmountDepositedInCycle: ${BigInt(result[2])},
    // //         TotalPayoutReceivedInCycle: ${BigInt(result[3])}, memberPosition: ${Number(BigInt(result[4]))}`);
        
    // //     var memberPosition = Number(BigInt(result[4]));

    // //     assert(memberPosition == 1);
    // // });


    // // Withdraw ROI From Esusu Cycle
    // it('EsusuService Contract: Should Withdraw ROI The Current Esusu Cycle', async () => {
    //     //  Get esusu cycle information
    //     var previousCycleId = currentEsusuCycleId;

    //     var result = await esusuServiceContract.GetEsusuCycle(previousCycleId.toString());

    //     //  get the member position from the cycle information  so we can determine the approx withdrawal wait time
    //     var memberCyclerInfo = await esusuServiceContract.GetMemberCycleInfo(account1, previousCycleId.toString());


    //     //  Get BUSDBalance before withdrawal
    //     var BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     console.log(`BUSD Balance Before Withdrawing Overall ROI: ${BUSDBalanceBeforeWithdrawing}`);

        
    //     //  Get the total cycle duration and start time
    //     var totalCycleDurationInSeconds = Number(BigInt(result[7]));
    //     var cycleStartTimeInSeconds = Number(BigInt(result[9]));
    //     var currentTimeInSeconds = (Math.floor(Date.now() / 1000));
    //     var withdrawalWaitTimeInSeconds = 0;
    //     if(currentTimeInSeconds > (cycleStartTimeInSeconds + totalCycleDurationInSeconds)){
    //         withdrawalWaitTimeInSeconds += 5;  //  Just add 5 seconds delay for no reason :D
    //     }else{
    //         var payoutIntervalSeconds = Number(BigInt(result[2]));
    //         var memberPosition = Number(BigInt(memberCyclerInfo[4]));

    //         withdrawalWaitTimeInSeconds = memberPosition * payoutIntervalSeconds;
    //     }
    //     console.log(`Withdrawal Wait Time In Seconds: ${withdrawalWaitTimeInSeconds}`);

    //     function timeout(s){
    //         return new Promise(resolve => setTimeout(resolve,s*1000));
    //     }

    //     await timeout(withdrawalWaitTimeInSeconds + 10);

    //     //  Withdraw overall ROI 
    //     await esusuServiceContract.WithdrawROIFromEsusuCycle(previousCycleId.toString());

    //     console.log(`fBUSD Balance of Esusu Adapter Withdrawal Delegate: ${await FBUSDContract.methods.balanceOf(esusuAdapterWithdrawalDelegateContract.address).call()}`);
    //     console.log(`BUSD Balance of Esusu Adapter Withdrawal Delegate: ${await BUSDContract.methods.balanceOf(esusuAdapterWithdrawalDelegateContract.address).call()}`);

    //     console.log(`Withdrawing...`);

    //     var BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     console.log(`BUSD Balance After Withdrawing Overall ROI: ${BUSDBalanceAfterWithdrawing}`);

    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    //     //  Get updated status of this cycle
    //     result = await esusuServiceContract.GetEsusuCycle(previousCycleId.toString());
    //     var totalBeneficiaries = BigInt(result[10]);
        
    //     //  TODO: get the treasury balance and ensure dai balance is greater than 0

    //     assert(BUSDBalanceAfterWithdrawing > BUSDBalanceBeforeWithdrawing);  
    //     assert(totalBeneficiaries > 0);   //    Total Beneficiaries must be greater than 0   
    //     assert(previousCycleId.toString() === BigInt(result[0]).toString());
    //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);                
    // });

    // // Withdraw Capital From Esusu Cycle
    // it('EsusuService Contract: Should Withdraw Capital From The Current Esusu Cycle', async () => {
    //     //  NOTE: To withdraw capital, the total cycle time must have elapsed, so we must wait for the cycle time to elapse

    //     var previousCycleId = BigNumber(currentEsusuCycleId) - BigNumber("0");

    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(previousCycleId.toString());

    //     //  Get BUSDBalance before withdrawal
    //     var BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     console.log(`BUSD Balance Before Withdrawing Capital : ${BUSDBalanceBeforeWithdrawing}`);

        
    //     //  Get the total cycle duration and start time
    //     var totalCycleDurationInSeconds = Number(BigInt(result[7]));
    //     var cycleStartTimeInSeconds = Number(BigInt(result[9]));
    //     var currentTimeInSeconds = (Math.floor(Date.now() / 1000));
    //     var withdrawalWaitTimeInSeconds = 0;
    //     if(currentTimeInSeconds > (cycleStartTimeInSeconds + totalCycleDurationInSeconds)){
    //         withdrawalWaitTimeInSeconds += 5;  //  Just add 5 seconds delay for no reason :D
    //     }else{
            
    //         withdrawalWaitTimeInSeconds = (cycleStartTimeInSeconds + totalCycleDurationInSeconds) - currentTimeInSeconds ;
    //     }
    //     console.log(`Withdrawal Wait Time In Seconds: ${withdrawalWaitTimeInSeconds}`);

    //     function timeout(s){
    //         return new Promise(resolve => setTimeout(resolve,s*1000));
    //     }

    //     await timeout(withdrawalWaitTimeInSeconds);

    //     //  Withdraw capital
    //     await esusuServiceContract.WithdrawCapitalFromEsusuCycle(previousCycleId.toString());

    //     console.log(`Withdrawing...`);

    //     var BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     console.log(`BUSD Balance After Withdrawing Capital: ${BUSDBalanceAfterWithdrawing}`);

    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    //     //  Get updated status of this cycle
    //     result = await esusuServiceContract.GetEsusuCycle(previousCycleId.toString());
    //     var totalBeneficiaries = BigInt(result[10]);
    //     var TotalCapitalWithdrawn = BigInt(result[8]);


    //     assert(BUSDBalanceAfterWithdrawing > BUSDBalanceBeforeWithdrawing);  
    //     assert(totalBeneficiaries > 0);     //  Total Beneficiaries must be greater than 0   
    //     assert(TotalCapitalWithdrawn > 0);  //  Total Capital Withdrawn must be greater than 0
    //     assert(previousCycleId.toString() === BigInt(result[0]).toString());
    //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);                
    // });


    // /**
    //  *  The tests below repeat core operations by using different accounts to make the function calls and 
    //  *  also increasing the number of members in each operation
    //  */

    // maxMembers = "4";
    // payoutIntervalSeconds = "60";  // 1 minute
    // it('EsusuService Contract: Should Create Group With Account 2', async () => {

    //     await esusuServiceContract.CreateGroup("Jedi Master", "JM",{from: account2});

    //     var groupInfo = await esusuServiceContract.GetGroupInformationByName("Jedi Master");

    //     console.log(`Group Id: ${BigInt(groupInfo[0])}, Name: ${groupInfo[1]}, Symbol: ${groupInfo[2]}, Owner: ${groupInfo[3]}`);

    //     groupId = BigInt(groupInfo[0]);
    //     assert(groupInfo[1] === "Jedi Master");
    //     assert(groupInfo[2] === "JM");

    // });

    // it('EsusuService Contract: Should Create Esusu Cycle With Account 2', async () => {

    //     //  Create esusu cycle
    //     await esusuServiceContract.CreateEsusu(groupId.toString(),depositAmount, payoutIntervalSeconds,startTimeInSeconds.toString(),maxMembers,{from:account2});
    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId(),{from:account2});

    //     console.log(`Current Esusu Cycle ID: ${currentEsusuCycleId}`);
        
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString(),{from:account2});

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // });

    // it('EsusuService Contract: Should Join The Current Esusu Cycle With 3 accounts', async () => {
        
    //     //  Give allowance to the EsusuAdapter to spend DAI on behalf of account 1, 2 & 3
    //     var approvedAmountToSpend = BigInt(10000000000000000000000); //   10,000 Dai
    //     approveBUSD(esusuAdapterContract.address,account1,approvedAmountToSpend);
    //     approveBUSD(esusuAdapterContract.address,account2,approvedAmountToSpend);
    //     approveBUSD(esusuAdapterContract.address,account3,approvedAmountToSpend);

    //     //  Account 1, 2 & 3 should Join esusu cycle
    //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account1, {from: account1});
    //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account2, {from: account2});
    //     await esusuServiceContract.JoinEsusu(currentEsusuCycleId.toString(), account3, {from: account3});

    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());
    //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);
    // });
    
    // it('EsusuService Contract: Should Start The Current Esusu Cycle With 3 accounts in the Cycle', async () => {

    //     var timeoutTimeInSeconds = 0;
    //     var currentTimeInSeconds = Math.floor(Date.now() / 1000);
    //     var timeDiff = currentTimeInSeconds - startTimeInSeconds;
        
    //     console.log(`currentTimeInSeconds: ${currentTimeInSeconds} ; startTimeInSeconds: ${startTimeInSeconds} `);
        
    //     if(timeDiff < 0){
    //         console.log(`Time is ${timeoutTimeInSeconds} Time never reach!!!`);
    //         timeoutTimeInSeconds = Math.abs(timeDiff);
    //     }else{

    //         console.log(`Time is ${timeoutTimeInSeconds} Time don reach!!!`);
    //         //  Just add wait of 5 seconds just to have some delay before Start cycle is called even when current time is greater than start time
    //         timeoutTimeInSeconds += 5; 

    //     }

    //     //  if currentTimeInSeconds is less than startTimeInSeconds, it means we have to wait for (startTimeInSeconds - currentTimeInSeconds)
    //     function timeout(s){
    //         return new Promise(resolve => setTimeout(resolve,s*1000));
    //     }

    //     console.log(`Waiting for ${timeoutTimeInSeconds} seconds for cycle to start`);

    //     await timeout(timeoutTimeInSeconds);
    //     console.log(`Done Waiting for ${timeoutTimeInSeconds} seconds. Starting Cycle ...`);

    //     //  Start esusu cycle
    //     await esusuServiceContract.StartEsusuCycle(currentEsusuCycleId.toString(), {from : account3});

    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());
        
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    //     var cycleState = BigInt(result[3]).toString();

    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());

    //     //  Cycle state must be active 
    //     assert(cycleState === "1");

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);   

    // });

    // it('EsusuService Contract: Should Withdraw ROI For Each Of The 3 Accounts In The Current Esusu Cycle', async () => {
    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());

    //     //  get the member position from the cycle information  so we can determine the approx withdrawal wait time
    //     var member1CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account1, currentEsusuCycleId.toString());
    //     var member2CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account2, currentEsusuCycleId.toString());
    //     var member3CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account3, currentEsusuCycleId.toString());

    //     //  Get BUSD Balance before withdrawal
    //     var member1BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     var member2BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account2));
    //     var member3BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account3));

    //     console.log(`Member 1 BUSD Balance Before Withdrawing Overall ROI: ${member1BUSDBalanceBeforeWithdrawing}`);
    //     console.log(`Member 2 BUSD Balance Before Withdrawing Overall ROI: ${member2BUSDBalanceBeforeWithdrawing}`);
    //     console.log(`Member 3 BUSD Balance Before Withdrawing Overall ROI: ${member3BUSDBalanceBeforeWithdrawing}`);

        
    //     //  Get the total cycle duration and start time
    //     var totalCycleDurationInSeconds = Number(BigInt(result[7]));
    //     var cycleStartTimeInSeconds = Number(BigInt(result[9]));
    //     var currentTimeInSeconds = (Math.floor(Date.now() / 1000));

    //     var member1WithdrawalWaitTimeInSeconds = 0;
    //     var member2WithdrawalWaitTimeInSeconds = 0;
    //     var member3WithdrawalWaitTimeInSeconds = 0;

    //     if(currentTimeInSeconds > (cycleStartTimeInSeconds + totalCycleDurationInSeconds)){
    //         member1WithdrawalWaitTimeInSeconds += 5;  //  Just add 5 seconds delay for no reason :D
    //         member2WithdrawalWaitTimeInSeconds += 5;
    //         member3WithdrawalWaitTimeInSeconds += 5;

    //     }else{
    //         var payoutIntervalSeconds = Number(BigInt(result[2]));
    //         var member1Position = Number(BigInt(member1CycleInfo[4]));
    //         var member2Position = Number(BigInt(member2CycleInfo[4]));
    //         var member3Position = Number(BigInt(member3CycleInfo[4]));

    //         member1WithdrawalWaitTimeInSeconds = member1Position * payoutIntervalSeconds;
    //         member2WithdrawalWaitTimeInSeconds = member2Position * payoutIntervalSeconds;
    //         member3WithdrawalWaitTimeInSeconds = member3Position * payoutIntervalSeconds;

    //     }
    //     console.log(`Member 1 Withdrawal Wait Time In Seconds: ${member1WithdrawalWaitTimeInSeconds}`);
    //     console.log(`Member 2 Withdrawal Wait Time In Seconds: ${member2WithdrawalWaitTimeInSeconds}`);
    //     console.log(`Member 3 Withdrawal Wait Time In Seconds: ${member3WithdrawalWaitTimeInSeconds}`);

    //     function timeout(s){
    //         return new Promise(resolve => setTimeout(resolve,s*1000));
    //     }

    //     //  Withdraw overall ROI For Member 1
    //     await timeout(payoutIntervalSeconds + 10);
    //     await esusuServiceContract.WithdrawROIFromEsusuCycle(currentEsusuCycleId.toString(), {from: account1});
    //     console.log(`Member 1 ROI withdrawal complete ...`);

    //     //  Withdraw overall ROI For Member 2
    //     await timeout(payoutIntervalSeconds + 10);
    //     await esusuServiceContract.WithdrawROIFromEsusuCycle(currentEsusuCycleId.toString(), {from: account2});
    //     console.log(`Member 2 ROI withdrawal complete ...`);
       
    //     //  Withdraw overall ROI For Member 3
    //     await timeout(payoutIntervalSeconds + 10);
    //     await esusuServiceContract.WithdrawROIFromEsusuCycle(currentEsusuCycleId.toString(), {from: account3});
    //     console.log(`Member 3 ROI withdrawal complete ...`);

    //     var member1BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //     var member2BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account2));
    //     var member3BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account3));

    //     console.log(`Member 1 BUSD Balance After Withdrawing Overall ROI: ${member1BUSDBalanceAfterWithdrawing}`);
    //     console.log(`Member 2 BUSD Balance After Withdrawing Overall ROI: ${member2BUSDBalanceAfterWithdrawing}`);
    //     console.log(`Member 3 BUSD Balance After Withdrawing Overall ROI: ${member3BUSDBalanceAfterWithdrawing}`);
        
    //     //  get current cycle ID
    //     currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    //     //  Get updated status of this cycle
    //     result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    //     var totalBeneficiaries = Number(BigInt(result[10]));
    //     var cycleState = BigInt(result[3]).toString();

    //     assert(member1BUSDBalanceBeforeWithdrawing < member1BUSDBalanceAfterWithdrawing);  
    //     assert(member2BUSDBalanceBeforeWithdrawing < member2BUSDBalanceAfterWithdrawing);  
    //     assert(member3BUSDBalanceBeforeWithdrawing < member3BUSDBalanceAfterWithdrawing);  
    //     assert(totalBeneficiaries === 3);               
    //     //  Cycle state must be expired after all ROI has been withdrawn because the Cycle time should have elapsed for last member to withdraw 
    //     assert(cycleState === "2");
    //     assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());
    //     assert(maxMembers.toString() === BigInt(result[11]).toString());

    //     console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //     CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //     TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //     TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);                
    // });

    // it('EsusuService Contract: Should Withdraw Capital For Each Of The 3 Accounts In The Current Esusu Cycle', async () => {
    //     //  NOTE: No need to have a withdrawal wait time since the cycle should be in expired state before this test is called

    //     //  Get esusu cycle information
    //     var result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    //     var cycleState = BigInt(result[3]).toString();

    //     //  Withdraw capitals when the cycle is in expired state
    //     if(cycleState === "2"){

    //         //  get the member position from the cycle information  so we can determine the approx withdrawal wait time
    //         var member1CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account1, currentEsusuCycleId.toString());
    //         var member2CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account2, currentEsusuCycleId.toString());
    //         var member3CycleInfo = await esusuServiceContract.GetMemberCycleInfo(account3, currentEsusuCycleId.toString());

    //         //  Get BUSD Balance before withdrawal
    //         var member1BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //         var member2BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account2));
    //         var member3BUSDBalanceBeforeWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account3));

    //         console.log(`Member 1 BUSD Balance Before Withdrawing Capital: ${member1BUSDBalanceBeforeWithdrawing}`);
    //         console.log(`Member 2 BUSD Balance Before Withdrawing Capital: ${member2BUSDBalanceBeforeWithdrawing}`);
    //         console.log(`Member 3 BUSD Balance Before Withdrawing Capital: ${member3BUSDBalanceBeforeWithdrawing}`);

    //         //  Withdraw Capital For Member 1
    //         await esusuServiceContract.WithdrawCapitalFromEsusuCycle(currentEsusuCycleId.toString(), {from: account1});
    //         console.log(`Member 1 Capital withdrawal complete ...`);

    //         //  Withdraw Capital For Member 2
    //         await esusuServiceContract.WithdrawCapitalFromEsusuCycle(currentEsusuCycleId.toString(), {from: account2});
    //         console.log(`Member 2 Capital withdrawal complete ...`);
        
    //         //  Withdraw Capital For Member 3
    //         await esusuServiceContract.WithdrawCapitalFromEsusuCycle(currentEsusuCycleId.toString(), {from: account3});
    //         console.log(`Member 3 Capital withdrawal complete ...`);

    //         var member1BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account1));
    //         var member2BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account2));
    //         var member3BUSDBalanceAfterWithdrawing = BigInt(await forTubeBankAdapterContract.GetBUSDBalance(account3));

    //         console.log(`Member 1 BUSD Balance After Withdrawing Capital: ${member1BUSDBalanceAfterWithdrawing}`);
    //         console.log(`Member 2 BUSD Balance After Withdrawing Capital: ${member2BUSDBalanceAfterWithdrawing}`);
    //         console.log(`Member 3 BUSD Balance After Withdrawing Capital: ${member3BUSDBalanceAfterWithdrawing}`);
            
    //         //  get current cycle ID
    //         currentEsusuCycleId = BigInt(await esusuServiceContract.GetCurrentEsusuCycleId());

    //         //  Get updated status of this cycle
    //         result = await esusuServiceContract.GetEsusuCycle(currentEsusuCycleId.toString());
    //         var totalBeneficiaries = Number(BigInt(result[10]));
    //         var cycleState = BigInt(result[3]).toString();

    //         assert(member1BUSDBalanceBeforeWithdrawing < member1BUSDBalanceAfterWithdrawing);  
    //         assert(member2BUSDBalanceBeforeWithdrawing < member2BUSDBalanceAfterWithdrawing);  
    //         assert(member3BUSDBalanceBeforeWithdrawing < member3BUSDBalanceAfterWithdrawing);  

    //         assert(totalBeneficiaries === 3);               
    //         //  Cycle state must be inactive after all Capital has been withdrawn
    //         assert(cycleState === "3");
    //         assert(currentEsusuCycleId.toString() === BigInt(result[0]).toString());
    //         assert(maxMembers.toString() === BigInt(result[11]).toString());

    //         console.log(`CycleId: ${BigInt(result[0])}, DepositAmount: ${BigInt(result[1])}, PayoutIntervalSeconds: ${BigInt(result[2])}, 
    //         CycleState: ${BigInt(result[3])}, TotalMembers: ${BigInt(result[4])}, TotalAmountDeposited: ${BigInt(result[5])},TotalShares: ${BigInt(result[6])}, 
    //         TotalCycleDurationInSeconds: ${BigInt(result[7])}, TotalCapitalWithdrawn: ${BigInt(result[8])}, CycleStartTimeInSeconds: ${BigInt(result[9])},
    //         TotalBeneficiaries: ${BigInt(result[10])}, MaxMembers: ${BigInt(result[11])}`);  
    //     }else{
    //         console.log("Cycle has not expired. Something is wrong !!!")
    //     }
          
    // });

    // //  Should depricate contract
    // it('EsusuAdapter Contract: Should Depricate Contract', async () => {

    //     let fBUSDBalanceForEsusuAdapterBeforeDeprication = await FBUSDContract.methods.balanceOf(esusuAdapterContract.address).call();

    //     console.log(`FBUSD Shares Balance Before Deprication: ${fBUSDBalanceForEsusuAdapterBeforeDeprication}`);

    //     await esusuAdapterContract.DepricateContract(esusuServiceContract.address, "the liquid metal");

    //     let fBUSDBalanceForEsusuAdapterAfterDeprication = await FBUSDContract.methods.balanceOf(esusuAdapterContract.address).call();

    //     console.log(`FBUSD Shares Balance After Deprication: ${fBUSDBalanceForEsusuAdapterAfterDeprication}`);

        
    //     //  The code below should fail

        
        
    //     // try {
    //          await utils.shouldThrow(esusuServiceContract.GetGroupInformationByName(groupName));

    //     // } catch (error) {
    //     //     assert(error, " Contract is depricated");
    //     //     console.log(`Group Id: ${BigInt(groupInfo[0])}, Name: ${groupInfo[1]}, Symbol: ${groupInfo[2]}, Owner: ${groupInfo[3]}`);
    //     // }


    // });

});