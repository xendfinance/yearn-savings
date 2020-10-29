const { assert } = require("console");

const Web3 = require('web3');

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

const yxendTokenContract = artifacts.require("YXendToken");

const yyxendTokenContract = artifacts.require("YYXendToken");

const EsusuServiceContract = artifacts.require("EsusuService");

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

const DaiContractABI = require('./abi/DaiContract.json');

const unlockedAddress = "0x1eC32Bfdbdbd40C0D3ec0fe420EBCfEEb2D56917";

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

  await daiContract.methods.approve(spender,amount).send({from: owner});

  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

};

contract("XendFinanceGroup_Yearn_V1", async (accounts) => {
  let contractInstance;
 

  beforeEach(async () => {

  let treasury = await TreasuryContract.deployed();

  let cycles = await CyclesContract.deployed();

  let savingsConfig =  await SavingsConfigContract.deployed();

  let groups = await GroupsContract.deployed();

  let esusuService = await EsusuServiceContract.deployed();

  let rewardConfig = await RewardConfigContract.deployed(
    esusuService.address,
    groups.address
  );

  let xendToken = await xendTokenContract.deployed("Xend Token", "XTK", 18, 2000000);

  let yXend = await yxendTokenContract.deployed("YXend Token", "YXTK", 18, 2000000);

  let yyxend = await yyxendTokenContract.deployed("YYXend Token", "YYXTK", 18, 2000000)

  let daiLendingService = await DaiLendingServiceContract.deployed();

  let daiLendingAdapter = await DaiLendingAdapterContract.deployed(daiLendingService.address);

    contractInstance = await XendFinanceGroup_Yearn_V1.new(
      daiLendingAdapter.address,
      daiLendingService.address,
      DaiContractAddress,
      groups.address,
      cycles.address,
      treasury.address,
      savingsConfig.address,
      rewardConfig.address,
      xendToken.address,
      yXend.address

    );
  });

  it("Should deploy the XendFinanceIndividual_Yearn_V1 smart contracts", async () => {
    assert(contractInstance.address !== "");
  });

  it("should join a cycle", async () => {


    let treasury = await TreasuryContract.new();

  let cycles = await CyclesContract.new();

  let savingsConfig =  await SavingsConfigContract.new();

  let groups = await GroupsContract.new();

  let esusuService = await EsusuServiceContract.new();

  let rewardConfig = await RewardConfigContract.new(
    esusuService.address,
    groups.address
  );

  let xendToken = await xendTokenContract.new("Xend Token", "XTK", 18, 2000000);

  let yXend = await yxendTokenContract.new("YXend Token", "YXTK", 18, 2000000);

  let yyxend = await yyxendTokenContract.new("YYXend Token", "YYXTK", 18, 2000000)

  let daiLendingService = await DaiLendingServiceContract.new();

  let daiLendingAdapter = await DaiLendingAdapterContract.new(daiLendingService.address);

   const instance = await XendFinanceGroup_Yearn_V1.new(
      daiLendingAdapter.address,
      daiLendingService.address,
      DaiContractAddress,
      groups.address,
      cycles.address,
      treasury.address,
      savingsConfig.address,
      rewardConfig.address,
      xendToken.address,
      yXend.address

    );

    await groups.activateStorageOracle(instance.address);

    await cycles.activateStorageOracle(instance.address)

    await instance.createGroup("njokuAkawo", "N9");
    
    let startTimeStamp = 4 * 86400;

    let duration = 100 * 86400;

    let amountToApprove = BigInt(100000000000000000000000);

    let amountToSend = BigInt(100000000000000000000000);

    await sendDai(amountToSend, accounts[0]);

   const approveResult = await approveDai(instance.address, accounts[0], amountToApprove);

   console.log(approveResult)
    
    await instance.createCycle(1, startTimeStamp, duration, 10, true, 100)

    const joinCycleResult = await instance.joinCycle(1, 2, {from: accounts[0]});

    assert(joinCycleResult.logs[0].logIndex === 1);
  });

  it("should withdraw from cycle while it's ongoing", async () => {

    let treasury = await TreasuryContract.new();

  let cycles = await CyclesContract.new();

  let savingsConfig =  await SavingsConfigContract.new();

  let groups = await GroupsContract.new();

  let esusuService = await EsusuServiceContract.new();

  let rewardConfig = await RewardConfigContract.new(
    esusuService.address,
    groups.address
  );

  let xendToken = await xendTokenContract.new("Xend Token", "XTK", 18, 2000000);

  let yXend = await yxendTokenContract.new("YXend Token", "YXTK", 18, 2000000);

  let yyxend = await yyxendTokenContract.new("YYXend Token", "YYXTK", 18, 2000000)

  let daiLendingService = await DaiLendingServiceContract.new();

  let daiLendingAdapter = await DaiLendingAdapterContract.new(daiLendingService.address);

   const instance = await XendFinanceGroup_Yearn_V1.new(
      daiLendingAdapter.address,
      daiLendingService.address,
      DaiContractAddress,
      groups.address,
      cycles.address,
      treasury.address,
      savingsConfig.address,
      rewardConfig.address,
      xendToken.address,
      yXend.address

    );

    await groups.activateStorageOracle(instance.address);

    await cycles.activateStorageOracle(instance.address)

    await instance.createGroup("njokuAkawo", "N9");
    
    let startTimeStamp = 4 * 86400;

    let duration = 100 * 86400;

    let amountToApprove = BigInt(100000000000000000000000);

    let amountToSend = BigInt(100000000000000000000000);

    await sendDai(amountToSend, accounts[0]);

   const approveResult = await approveDai(instance.address, accounts[0], amountToApprove);

   console.log(approveResult)
    
    await instance.createCycle(1, startTimeStamp, duration, 10, true, 100)

    await instance.joinCycle(1, 2, {from: accounts[0]});

    const withdrawFromCycleWhileItIsOngoingResult = await instance.withdrawFromCycleWhileItIsOngoing(1, {from : accounts[0]});

    console.log(withdrawFromCycleWhileItIsOngoingResult);
  })

});
