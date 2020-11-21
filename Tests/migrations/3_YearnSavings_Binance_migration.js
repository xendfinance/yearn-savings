const Web3 = require("web3");
const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury");
const CyclesContract = artifacts.require("Cycles");
const ClientRecordContract = artifacts.require("ClientRecord");
const SavingsConfigContract = artifacts.require("SavingsConfig");
const DaiLendingServiceContract = artifacts.require("DaiLendingService");
const DaiLendingAdapter = artifacts.require("DaiLendingAdapter");
const XendFinanceIndividual_Yearn_V1Contract = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);
const RewardConfigContract = artifacts.require("RewardConfig");
const xendTokenContract = artifacts.require("XendToken");
const EsusuServiceContract = artifacts.require("EsusuService");
const FortubeServiceContract = artifacts.require("ForTubeBankService");
const FortubeAdapterContract = artifacts.require("ForTubeBankAdapter");

// const BUSDContractABI = require('./BEP20ABI.json');
// const FBUSDContractABI = require('./BEP20ABI.json');    // FBUSD and BUSD can use the same ABI since we are just calling basic BEP20 functions for this test

const BUSDContractAddress = "0x3b1F033dD955f3BE8649Cc9825A2e3E194765a3F";  // This is a custom BUSD for ForTube, you will not find it on BSC Faucet
const FBUSDContractAddress = "0x6112a45160b2058C6402a5bfBE3A446c8fD4fb45";  // This is the FToken shares a user will receive when they deposit BUSD


// const web3 = new Web3("HTTP://127.0.0.1:8545");
// const daiContract = new web3.eth.Contract(DaiContractABI, DaiContractAddress);

module.exports = function (deployer) {
  deployer.then(async () => {
    await deployer.deploy(GroupsContract);

    await deployer.deploy(TreasuryContract);

    await deployer.deploy(CyclesContract);

    await deployer.deploy(ClientRecordContract);

    await deployer.deploy(SavingsConfigContract);

    await deployer.deploy(EsusuServiceContract);

    await deployer.deploy(
      RewardConfigContract,
      EsusuServiceContract.address,
      GroupsContract.address
    );

    await deployer.deploy(xendTokenContract, "Xend Token", "XTK", 18, 200000);

    // await deployer.deploy(
    //   DaiToken,
    //   "Dai Token",
    //   "DTK",
    //   18,
    //   200000
    // );

    // await deployer.deploy(
    //   YDaiToken,
    //   "YDai Token",
    //   "YDTK",
    //   18,
    //   200000
    // );



    await deployer.deploy(FortubeServiceContract);

    await deployer.deploy(FortubeAdapterContract, FortubeServiceContract.address);


    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      FortubeServiceContract.address,
      FortubeAdapterContract.address,
      BUSDContractAddress,
      ClientRecordContract.address,
      SavingsConfigContract.address,
      FBUSDContractAddress,
      TreasuryContract.address
    );
    console.log(
      "Xend finance individual",
      XendFinanceIndividual_Yearn_V1Contract.address
    );

    console.log(
      "fortube service Contract address: ", FortubeServiceContract.address
    );

    console.log("fortube adapter contract address", FortubeAdapterContract.address)

    console.log("xend token address", xendTokenContract.address);

    console.log("GroupsContract address: ",  GroupsContract.address);

    console.log("TreasuryContract address: ", TreasuryContract.address);

    console.log("CyclesContract address", CyclesContract.address);

    console.log("ClientRecordContract address", ClientRecordContract.address);

    console.log("Savings config address", SavingsConfigContract.address);

    console.log(
      "EsusuServiceContract address: " + EsusuServiceContract.address
    );

    console.log(
      "RewardConfigContract address: " + RewardConfigContract.address
    );

    let ClientRecord = await ClientRecordContract.deployed();

    let savingsConfig = await SavingsConfigContract.deployed()

    let fortubeService = await FortubeServiceContract.deployed();

    // let dai = await DaiToken.deployed();

    // let YDai = await YDaiToken.deployed();

    await ClientRecord.activateStorageOracle(XendFinanceIndividual_Yearn_V1Contract.address);

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVISOR", 0, 0, 100, 1)

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVIDEND", 0, 0, 1, 1)

    await savingsConfig.createRule("PERCENTAGE_PAYOUT_TO_USERS", 0, 0, 0, 1)

    await savingsConfig.createRule("PERCENTAGE_AS_PENALTY", 0, 0, 1, 1);

    await fortubeService.updateAdapter(FortubeAdapterContract.address);
     
    // await dai.mint('500000000000000000000');

    // //this is a replacement of the dai approval function
    // //await dai.approve(XendFinanceIndividual_Yearn_V1Contract.address, '30000000000000000000000');

    // await YDai.mint('30000000000000000000000')

    // //transfer to dai lending service
    // await YDai.transfer(DaiLendingServiceContract.address, '30000000000000000000000');
    

    // await deployer.deploy(
    //   XendFinanceGroup_Yearn_V1Contract,
    //   DaiLendingServiceContract.address,
    //   DaiLendingAdapter.address,
    //   YDaiToken.address,
    //   GroupsContract.address,
    //   CyclesContract.address,
    //   TreasuryContract.address,
    //   SavingsConfigContract.address,
    //   RewardConfigContract.address,
    //   xendTokenContract.address,
    //   DaiToken.address
    // );

   
  });
};
