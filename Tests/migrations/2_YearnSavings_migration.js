const Web3 = require("web3");
const DaiContractAddress = "0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658";
const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury");
const CyclesContract = artifacts.require("Cycles");
const ClientRecordContract = artifacts.require("ClientRecord");
const SavingsConfigContract = artifacts.require("SavingsConfig");
const DaiLendingAdapterContract = artifacts.require("DaiLendingAdapter");
const DaiLendingServiceContract = artifacts.require("DaiLendingService");
const XendFinanceIndividual_Yearn_V1Contract = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);
const DaiContractABI = require("../test/abi/DaiContract.json");
const XendFinanceGroup_Yearn_V1Contract = artifacts.require(
  "XendFinanceGroup_Yearn_V1"
);
const RewardConfigContract = artifacts.require("RewardConfig");
const XendTokenContract = artifacts.require("XendToken");
const EsusuServiceContract = artifacts.require("EsusuService");
const derivativeContract = "0xC2cB1040220768554cf699b0d863A3cd4324ce32"
const YDerivativeContract = "0xC2cB1040220768554cf699b0d863A3cd4324ce32"
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

    await deployer.deploy(XendTokenContract, "Xend Token", "$XEND", "18", "200000000000000000000000000")

    console.log("Xend Token Contract address", XendTokenContract.address);

    await deployer.deploy(DaiLendingServiceContract);

    console.log(
      "DaiLendingService Contract address: " + DaiLendingServiceContract.address
    );

    await deployer.deploy(
      DaiLendingAdapterContract,
      DaiLendingServiceContract.address
    );

    console.log(
      "DaiLendingAdapterContract address: " + DaiLendingAdapterContract.address
    );

    
    

    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      DaiLendingServiceContract.address,
      DaiContractAddress,
      ClientRecordContract.address,
      SavingsConfigContract.address,
      derivativeContract,
      RewardConfigContract.address,
      XendTokenContract.address,
      TreasuryContract.address
    );

    console.log(
      "Xend finance individual",
      XendFinanceIndividual_Yearn_V1Contract.address
    );
    // await deployer.deploy(
    //   XendFinanceGroup_Yearn_V1Contract,
    //   DaiLendingServiceContract.address,
    //   YDerivativeContract,
    //   GroupsContract.address,
    //   CyclesContract.address,
    //   TreasuryContract.address,
    //   SavingsConfigContract.address,
    //   RewardConfigContract.address,
    //   XendTokenContract.address,
    //   derivativeContract
    // );

   // console.log("Xend group contract", XendFinanceGroup_Yearn_V1Contract.address)

   
    let savingsConfigContract = null
    let esusuServiceContract = null;
    let cycleContract = null;
    let groupsContract = null;
    let xendTokenContract = null;
    let daiLendingService = null;
    let rewardConfigContract = null;
    let clientRecordContract = null;
    let xendGroupContract = null;

    savingsConfigContract = await SavingsConfigContract.deployed();
    esusuServiceContract = await EsusuServiceContract.deployed();
    groupsContract = await GroupsContract.deployed();
    xendTokenContract = await XendTokenContract.deployed();
    daiLendingService = await DaiLendingServiceContract.deployed();
    clientRecordContract = await ClientRecordContract.deployed();
    rewardConfigContract = await RewardConfigContract.deployed();
   // xendGroupContract = await XendFinanceGroup_Yearn_V1Contract.deployed();
    cycleContract = await CyclesContract.deployed();
  

    await xendTokenContract.grantAccess(XendFinanceIndividual_Yearn_V1Contract.address);
    console.log("11->Xend Token Has Given access To Xend individual contract to transfer tokens ...");

   // await xendTokenContract.grantAccess(XendFinanceGroup_Yearn_V1Contract.address);
    //console.log("11->Xend Token Has Given access To Xend group contract to transfer tokens ...");

    await clientRecordContract.activateStorageOracle(XendFinanceIndividual_Yearn_V1Contract.address);

    // await groupsContract.activateStorageOracle(XendFinanceGroup_Yearn_V1Contract.address);

    // await cycleContract.activateStorageOracle(XendFinanceGroup_Yearn_V1Contract.address);
     
    await savingsConfigContract.createRule("XEND_FINANCE_COMMISION_DIVISOR", 0, 0, 100, 1)

    await savingsConfigContract.createRule("XEND_FINANCE_COMMISION_DIVIDEND", 0, 0, 1, 1)

    await savingsConfigContract.createRule("PERCENTAGE_PAYOUT_TO_USERS", 0, 0, 0, 1)

    await savingsConfigContract.createRule("PERCENTAGE_AS_PENALTY", 0, 0, 1, 1);

    //0. update fortube adapter
    await daiLendingService.updateAdapter(DaiLendingAdapterContract.address)

     //12.
     await rewardConfigContract.SetRewardParams("100000000000000000000000000", "10000000000000000000000000", "2", "7", "10","15", "4","60", "4");

     //13. 
     await rewardConfigContract.SetRewardActive(true);
   

    
  });
};
