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
const EsusuServiceContract = artifacts.require("EsusuService");
const derivativeContract = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
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

    await deployer.deploy(xendTokenContract, "Xend Token", "$XEND", "18", "200000000000000000000000000")

    console.log("Xend Token Contract address", xendTokenContract.address);

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
      xendTokenContract.address,
      ClientRecordContract.address,
      RewardConfigContract.address,
      derivativeContract,
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
    //   xendTokenContract.address,
    //   derivativeContract
    // );

    //console.log("Xend group contract", XendFinanceGroup_Yearn_V1Contract.address)
  });
};
