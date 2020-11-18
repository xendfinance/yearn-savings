const Web3 = require("web3");
const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury");
const CyclesContract = artifacts.require("Cycles");
const ClientRecordContract = artifacts.require("ClientRecord");
const SavingsConfigContract = artifacts.require("SavingsConfig");
const DaiLendingServiceContract = artifacts.require("DaiLendingService");
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

    console.log("GroupsContract address: " + GroupsContract.address);

    await deployer.deploy(TreasuryContract);

    console.log("TreasuryContract address: " + TreasuryContract.address);

    await deployer.deploy(CyclesContract);

    console.log("CyclesContract address", CyclesContract.address);

    await deployer.deploy(ClientRecordContract);

    console.log("ClientRecordContract address", ClientRecordContract.address);

    await deployer.deploy(SavingsConfigContract);

    console.log("Savings config address", SavingsConfigContract.address);

    await deployer.deploy(EsusuServiceContract);

    console.log(
      "EsusuServiceContract address: " + EsusuServiceContract.address
    );

    await deployer.deploy(
      RewardConfigContract,
      EsusuServiceContract.address,
      GroupsContract.address
    );

    console.log(
      "RewardConfigContract address: " + RewardConfigContract.address
    );

    await deployer.deploy(xendTokenContract, "Xend Token", "XTK", 18, 2000000);

    await deployer.deploy(
      DaiToken,
      "Dai Token",
      "DTK",
      18,
      2000000
    );

    await deployer.deploy(
      YDaiToken,
      "YDai Token",
      "YDTK",
      18,
      2000000
    );



    await deployer.deploy(DaiLendingServiceContract, YDaiToken.address, DaiToken.address);

    // await deployer.deploy(
    //   DaiLendingAdapterContract,
    //   DaiLendingServiceContract.address
    // );

    console.log(
      "DaiLendingService Contract address: " + DaiLendingServiceContract.address
    );

    console.log(YDaiToken.address, "y DAI token address")


    console.log("dai token", DaiToken.address);

    console.log("xendt", xendTokenContract.address);

    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      DaiLendingServiceContract.address,
      DaiLendingServiceContract.address,
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

    let ClientRecord = await ClientRecordContract.deployed();

    let savingsConfig = await SavingsConfigContract.deployed()

    let dai = await DaiToken.deployed();

    let YDai = await YDaiToken.deployed();

    await ClientRecord.activateStorageOracle(XendFinanceIndividual_Yearn_V1Contract.address);

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVISOR", 0, 0, 100, 1)

    await savingsConfig.createRule("XEND_FINANCE_COMMISION_DIVIDEND", 0, 0, 1, 1)
     
    await dai.mint('500000000000000000000');

    //this is a replacement of the dai approval function
    //await dai.approve(XendFinanceIndividual_Yearn_V1Contract.address, '30000000000000000000000');

    await YDai.mint('30000000000000000000000')

    //transfer to dai lending service
    await YDai.transfer(DaiLendingServiceContract.address, '30000000000000000000000');
    

    await deployer.deploy(
      XendFinanceGroup_Yearn_V1Contract,
      DaiLendingServiceContract.address,
      DaiLendingServiceContract.address,
      YDaiToken.address,
      GroupsContract.address,
      CyclesContract.address,
      TreasuryContract.address,
      SavingsConfigContract.address,
      RewardConfigContract.address,
      xendTokenContract.address,
      DaiToken.address
    );

   
  });
};
