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
      yyxend.address,
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

   const instance = await XendFinanceGroup_Yearn_V1.new(
      daiLendingAdapter.address,
      daiLendingService.address,
      yyxend.address,
      groups.address,
      cycles.address,
      treasury.address,
      savingsConfig.address,
      rewardConfig.address,
      xendToken.address,
      yXend.address

    );

    await groups.activateStorageOracle(accounts[1], {from :accounts[0]});

    await groups.createGroup("njokuAkawo", "N9", accounts[2], {from : accounts[1]});
    
    let startTimeStamp = 4 * 86400;

    let duration = 100 * 86400;

    await instance.createCycle(1, 0, startTimeStamp, duration, 10, true, 100, {from:accounts[1]})

    const joinCycleResult = await instance.joinCycle(1, 2, {from : accounts[1]});

    console.log(joinCycleResult);
  })

});
