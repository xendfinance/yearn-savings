const Web3 = require("web3");
const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
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
const DaiContractABI = require("../test/abi/DaiContract.json");
const XendFinanceGroup_Yearn_V1Contract = artifacts.require(
  "XendFinanceGroup_Yearn_V1"
);
const RewardConfigContract = artifacts.require("RewardConfig");
const xendTokenContract = artifacts.require("XendToken");
const DaiToken = artifacts.require("YXendToken");
const YDaiToken = artifacts.require("YYXendToken")
const EsusuServiceContract = artifacts.require("EsusuService");

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

    await deployer.deploy(
      DaiToken,
      "Dai Token",
      "DTK",
      18,
      200000
    );

    await deployer.deploy(
      YDaiToken,
      "YDai Token",
      "YDTK",
      18,
      200000
    );



    await deployer.deploy(DaiLendingServiceContract);

    await deployer.deploy(DaiLendingAdapter, DaiLendingServiceContract.address);


    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      DaiLendingServiceContract.address,
      DaiLendingAdapter.address,
      DaiToken.address,
      ClientRecordContract.address,
      SavingsConfigContract.address,
      YDaiToken.address,
      TreasuryContract.address
    );
    console.log(
      "Xend finance individual",
      XendFinanceIndividual_Yearn_V1Contract.address
    );

    console.log(
      "DaiLendingService Contract address: ", DaiLendingServiceContract.address
    );

    console.log("y DAI token address", YDaiToken.address)


    console.log("dai token address", DaiToken.address);

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

    let lendingService = await DaiLendingServiceContract.deployed();

    // let dai = await DaiToken.deployed();

    // let YDai = await YDaiToken.deployed();

    await ClientRecord.activateStorageOracle(XendFinanceIndividual_Yearn_V1Contract.address);

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVISOR", 0, 0, 100, 1)

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVIDEND", 0, 0, 1, 1)

    await savingsConfig.createRule("PERCENTAGE_PAYOUT_TO_USERS", 0, 0, 0, 1)

    await savingsConfig.createRule("PERCENTAGE_AS_PENALTY", 0, 0, 1, 1);

    await lendingService.updateAdapter(DaiLendingAdapter.address);
     
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
