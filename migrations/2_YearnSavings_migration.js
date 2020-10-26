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
const RewardConfigContract = artifacts.require("RewardConfig");
const xendTokenContract = artifacts.require("XendToken");
const EsusuServiceContract = artifacts.require("EsusuService");


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

    await deployer.deploy(DaiLendingServiceContract);

    await deployer.deploy(
      DaiLendingAdapterContract,
      DaiLendingServiceContract.address,
      TestContractArtifact.address
    );

    await deployer.deploy(EsusuServiceContract);

    console.log("EsusuServiceContract address: " + EsusuServiceContract.address);

    await deployer.deploy(
      RewardConfigContract,
      EsusuServiceContract.address,
      GroupsContract.address
    );
  
    console.log("RewardConfigContract address: " + RewardConfigContract.address);
  
    await deployer.deploy(xendTokenContract, "Xend Token", "XTK", 18, 2000000);

    console.log(
      "DaiLendingService Contract address: " + DaiLendingServiceContract.address
    );

    console.log(
      "DaiLendingAdapterContract address: " + DaiLendingAdapterContract.address
    );

    await deployer.deploy(
      XendFinanceIndividual_Yearn_V1Contract,
      DaiLendingAdapterContract.address,
      DaiLendingServiceContract.address,
      DaiTokenContract.address,
      ClientRecordContract.address,
      RewardConfigContract.address,
      YDaiTokenContract.address
    );
  });
};
