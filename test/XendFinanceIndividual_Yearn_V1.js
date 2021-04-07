const { assert } = require("console");

const Web3 = require('web3');

const web3 = new Web3("HTTP://127.0.0.1:8545");

const GroupsContract = artifacts.require("Groups");

const TreasuryContract = artifacts.require("Treasury");

const CyclesContract = artifacts.require("Cycles");

const utils = require("./helpers/utils");

const ClientRecordContract = artifacts.require("ClientRecord");

const SavingsConfigContract = artifacts.require("SavingsConfig");

const DaiLendingAdapterContract = artifacts.require("DaiLendingAdapter");

const DaiLendingServiceContract = artifacts.require("DaiLendingService");

const XendFinanceIndividual_Yearn_V1 = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);

const RewardConfigContract = artifacts.require("RewardConfig");

const XendTokenContract = artifacts.require("XendToken");


const EsusuServiceContract = artifacts.require("EsusuService");

const DaiContractABI = require('../abi/DaiContract.json');

const YDaiContractABI = require('../abi/YDaiContractABI.json');

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32";

const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);
    
const yDaiContract = new web3.eth.Contract(YDaiContractABI,yDaiContractAddress);

const unlockedAddress = "0xdcd024536877075bfb2ffb1db9655ae331045b4e";


//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveDai(spender,  owner,  amount){

  await daiContract.methods.approve(spender,amount).send({from: owner});

  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

};


   
//  Send Dai from our constant unlocked address to any recipient
async function sendDai(amount, recipient){
    
  var amountToSend = BigInt(amount); //  1000 Dai

  console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);

  await daiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

  let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
  
  console.log(`Recipient: ${recipient} DAI Balance: ${recipientBalance}`);


}
var account1;
var account2;
var account3;

var account1Balance;
var account2Balance;
var account3Balance;

   



contract("XendFinanceIndividual_Yearn_V1", () => {
  let contractInstance = null;
  let cycleContract = null;
  let groupsContract = null;
  let xendTokenContract = null;
  let daiLendingService = null;
  let rewardConfigContract = null;
  let clientRecordContract = null;
  let savingsConfigContract = null
 

  beforeEach(async () => {

    clientRecordContract = await ClientRecordContract.deployed();
    savingsConfigContract =  await SavingsConfigContract.deployed();
    xendTokenContract = await XendTokenContract.deployed();
    daiLendingService  = await DaiLendingServiceContract.deployed();  
    contractInstance = await XendFinanceIndividual_Yearn_V1.deployed();

      //  Get the addresses and Balances of at least 2 accounts to be used in the test
            //  Send DAI to the addresses
            web3.eth.getAccounts().then(function(accounts){

              account1 = accounts[0];
              account2 = accounts[1];
              account3 = accounts[2];

              //  send money from the unlocked dai address to accounts 1 and 2
              var amountToSend = BigInt(1000000000000000000000); //   10,000 Dai

              //  get the eth balance of the accounts
              web3.eth.getBalance(account1, function(err, result) {
                  if (err) {
                      console.log(err)
                  } else {

                      account1Balance = web3.utils.fromWei(result, "ether");
                      console.log("Account 1: "+ accounts[0] + "  Balance: " + account1Balance + " ETH");
                      sendDai(amountToSend,account1);

                  }
              });

              web3.eth.getBalance(account2, function(err, result) {
                  if (err) {
                      console.log(err)
                  } else {
                      account2Balance = web3.utils.fromWei(result, "ether");
                      console.log("Account 2: "+ accounts[1] + "  Balance: " + account2Balance + " ETH");
                      sendDai(amountToSend,account2);

                  }
              });

              web3.eth.getBalance(account3, function(err, result) {
                  if (err) {
                      console.log(err)
                  } else {
                      account3Balance = web3.utils.fromWei(result, "ether");
                      console.log("Account 3: "+ accounts[2] + "  Balance: " + account3Balance + " ETH");
                      sendDai(amountToSend,account3);

                  }
              });
          });

  });


  


      

  it("Should deploy the XendFinanceIndividual_Yearn_V1 smart contracts", async () => {
    assert(contractInstance.address !== "");
  });

  it("should throw error because no client records exist", async () => {
      
      await  utils.shouldThrow(contractInstance.getClientRecord(account2));
      
  })
  it("should check if client records exist", async () => {
      const doesClientRecordExistResult = await contractInstance.doesClientRecordExist(account2);

      assert(doesClientRecordExistResult == false);
  });

   it("should deposit and withdraw", async () => {

      //  Give allowance to the xend finance individual to spend DAI on behalf of account 1 and 2
        var approvedAmountToSpend = BigInt(1000000000000000000000); //   1,000 Dai

        let amountToWithdraw = BigInt(1000000000000000000000);
      
        await approveDai(contractInstance.address, account1, approvedAmountToSpend);

        //await clientRecord.createClientRecord(accounts[2], 0, 0, 0, 0, 0, {from : accounts[3]})

       await contractInstance.deposit({from : account1});

  

        const withdrawResult = await contractInstance.withdraw(amountToWithdraw);

        assert(withdrawResult.receipt.status == true, "tx receipt status is true")


   })


});
