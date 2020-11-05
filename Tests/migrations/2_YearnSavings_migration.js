const Web3 = require("web3");
const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
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
const xendTokenContract = artifacts.require("XendToken");
const yxendTokenContract = artifacts.require("YXendToken");
const yyxendTokenContract = artifacts.require("YYXendToken")
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
      yxendTokenContract,
      "YXend Token",
      "YXTK",
      18,
      2000000
    );

    await deployer.deploy(
      yyxendTokenContract,
      "YYXend Token",
      "YYXTK",
      18,
      2000000
    );

    await deployer.deploy(DaiLendingServiceContract);

    await deployer.deploy(
      DaiLendingAdapterContract,
      DaiLendingServiceContract.address
    );

    console.log(
      "DaiLendingService Contract address: " + DaiLendingServiceContract.address
    );

    console.log(
      "DaiLendingAdapterContract address: " + DaiLendingAdapterContract.address
    );

    console.log("yxend", yxendTokenContract.address);
    console.log("xendt", xendTokenContract.address);

    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      DaiLendingAdapterContract.address,
      DaiLendingServiceContract.address,
      xendTokenContract.address,
      ClientRecordContract.address,
      RewardConfigContract.address,
      yxendTokenContract.address
    );

    await deployer.deploy(
      XendFinanceGroup_Yearn_V1Contract,
      DaiLendingAdapterContract.address,
      DaiLendingServiceContract.address,
      yyxendTokenContract.address,
      GroupsContract.address,
      CyclesContract.address,
      TreasuryContract.address,
      SavingsConfigContract.address,
      RewardConfigContract.address,
      xendTokenContract.address,
      yxendTokenContract.address
    );

    // Activate the storage oracle in clientRecord.sol with the Address of the individual savings contract
    await  ClientRecordContract.activateStorageOracle(XendFinanceIndividual_Yearn_V1Contract.address);
    console.log("5->Xend finance Address Updated In client contract ...");

    console.log(
      "Xend finance individual",
      XendFinanceIndividual_Yearn_V1Contract.address
    );
  });
};
