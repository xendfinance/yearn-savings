const { assert } = require("console");

const Web3 = require('web3');
const utils = require("./helpers/Utils")
const web3 = new Web3("HTTP://127.0.0.1:8545");

const GroupsContract = artifacts.require("Groups");

const TreasuryContract = artifacts.require("Treasury");

const CyclesContract = artifacts.require("Cycles");

const SavingsConfigContract = artifacts.require("SavingsConfig");

const DaiLendingAdapterContract = artifacts.require("DaiLendingAdapter");

const DaiLendingServiceContract = artifacts.require("DaiLendingService");

const XendFinanceGroup_Yearn_V1 = artifacts.require(
  "XendFinanceGroup_Yearn_V1"
);

const RewardConfigContract = artifacts.require("RewardConfig");

const xendTokenContract = artifacts.require("XendToken");

const EsusuServiceContract = artifacts.require("EsusuService");

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32";

const DaiContractABI = require('../abi/DaiContract.json');

const unlockedAddress = "0xB4176cF4F50e7BeF7183459582E235FA47DCc24A";

const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);

//  Send Dai from our constant unlocked address
async function sendDai(amount, recipient) {

  var amountToSend = BigInt(amount); //  1000 Dai

  console.log(`Sending  ${amountToSend} x 10^-18 Dai to  ${recipient}`);

  await daiContract.methods.transfer(recipient, amountToSend).send({ from: unlockedAddress });

  let recipientBalance = await daiContract.methods.balanceOf(recipient).call();

  console.log(`Recipient Balance: ${recipientBalance}`);


}

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveDai(spender,  owner,  amount){

  const approvalResult = await daiContract.methods.approve(spender,amount).send({from: owner});
 console.log({approvalResult});
  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

};

contract("XendFinanceGroup_Yearn_V1", async (accounts) => {
  let contractInstance;
  let cyclesContract;
 
  it("Dummy Test", async () => {
    assert(true);
  });

  beforeEach(async () => {

  contractInstance = await XendFinanceGroup_Yearn_V1.deployed();
  cyclesContract = await CyclesContract.deployed();
   
  });

  it("Should deploy the XendFinanceGroup_Yearn_V1 smart contracts", async () => {
    assert(contractInstance.address !== "");
  });

  it("should join a cycle", async () => {


    await contractInstance.createGroup("njokuAkawo", "N9");
    
    let startTimeStamp = 4 * 86400;

    let duration = 100 * 86400;

    let amountToApprove = BigInt(100000000000000000000000);

    let amountToSend = BigInt(100000000000000000000000);

    await sendDai(amountToSend, accounts[0]);

    let memberBalance = await daiContract.methods.balanceOf( accounts[0]).call();
    console.log({memberBalance})


   await approveDai(contractInstance.address, accounts[0], amountToApprove);
    
   let cycleCreationResult =  await contractInstance.createCycle(1, startTimeStamp, duration, 10, true, 100)
   console.log({cycleCreationResult})

    const joinCycleResult = await contractInstance.joinCycle(1, 2, {from: accounts[0]});
    console.log({joinCycleResult})

    let index = await cyclesContract.getCycleMemberIndex(1,accounts[0]);
    let cycleMember = await cyclesContract.getCycleMember(index);
    console.log({cycleMember})

    let cycle  = await cyclesContract.getCycleInfoById(1);
    console.log({cycle});

    let cycleFinancials  = await cyclesContract.getCycleFinancialsByCycleId(1);
    console.log({cycleFinancials});


    assert(joinCycleResult.receipt.status==true);
  });


  it("should activate a cycle ", async () => {

    await utils.shouldThrow(contractInstance.activateCycle(1, {from: accounts[0]}));

  });

  it("should withdraw from a cycle while it's ongoing", async () => {
   
      const withdrawFromCycleWhileItIsOngoingResult  = await contractInstance.withdrawFromCycleWhileItIsOngoing(1);

      assert(withdrawFromCycleWhileItIsOngoingResult.receipt.status == true, "tx receipt is true")


  })

  it("should withdraw from a cycle", async () => {
        
 
  
    //   await contractInstance.createGroup("njokuAkawo", "N9");
      
    //   let startTimeStamp = 60;
  
    //   let duration = 100 * 86400;
  
    //   let amountToApprove = BigInt(100000000000000000000000);
  
    //   let amountToSend = BigInt(100000000000000000000000);
  
    //   await sendDai(amountToSend, accounts[0]);
  
    //  const approveResult = await approveDai(contractInstance.address, accounts[0], amountToApprove);
  
    //  console.log(approveResult)
      
    //   await contractInstance.createCycle(1, startTimeStamp, duration, 10, true, 100);

    //   //should throw error cause cycle member does not exist
    //    await utils.shouldThrow(contractInstance.getCycleMember(1));

    //   await cycles.activateStorageOracle(contractInstance.address);

    //   // should Throw An Error If Cycle Duration Has Not Elapsed And Cycle Is Ongoing
    //   await utils.shouldThrow(contractInstance.endCycle(1));

    //   // withdraw from cycle

    //   // //should throw error because msg.send is not a member of the cycle
    //   // await utils.shouldThrow(contractInstance.withdrawFromCycle(1));
      
    //   await instance.joinCycle(1, numberOfStakes);

    //   //should throw error because no rule definitions found for rule key;
    //   await utils.shouldThrow(contractInstance.withdrawFromCycle(1));

    //   // let exact = 10/100;

    //   // let exactPenalty = 5/100;

    //   // //create savings rule config
    //   // await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVISOR", 0, 0, 5, 1);

    //   // await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVIDEND", 0, 0, 10, 1);

      const withdrawFromCycleResult  = await contractInstance.withdrawFromCycle(1);

      assert(withdrawFromCycleResult.receipt.status == true, 'tx receipt status is true')


  })

});
