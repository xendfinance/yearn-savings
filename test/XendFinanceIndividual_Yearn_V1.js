const { assert } = require("console");
const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury");
const CyclesContract = artifacts.require("Cycles");
const ClientRecordContract = artifacts.require("ClientRecord");
const SavingsConfigContract = artifacts.require("SavingsConfig");
const DaiLendingAdapterContract = artifacts.require("DaiLendingAdapter");
const DaiLendingServiceContract = artifacts.require("DaiLendingService");
const XendFinanceIndividual_Yearn_V1 = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);
const RewardConfigContract = artifacts.require("RewardConfig");
const xendTokenContract = artifacts.require("XendToken");
const yxendTokenContract = artifacts.require("YXendToken");
const EsusuServiceContract = artifacts.require("EsusuService");

contract("XendFinanceIndividual_Yearn_V1", async (accounts) => {
  let contractInstance;


  beforeEach(async () => {

  let clientRecord = await ClientRecordContract.deployed();

  let savingsConfig =  await SavingsConfigContract.deployed();

  let groups = await GroupsContract.deployed();

  let esusuService = await EsusuServiceContract.deployed();

  let rewardConfig = await RewardConfigContract.deployed(
    esusuService.address,
    groups.address
  );

  let xendToken = await xendTokenContract.deployed("Xend Token", "XTK", 18, 2000000);

  let yXend = await yxendTokenContract.deployed("YXend Token", "YXTK", 18, 2000000);

  let daiLendingService = await DaiLendingServiceContract.deployed();

  let daiLendingAdapter = await DaiLendingAdapterContract.deployed(DaiLendingServiceContract.address);

    contractInstance = await XendFinanceIndividual_Yearn_V1.new(
      daiLendingAdapter.address,
      daiLendingService.address,
      xendToken.address,
      clientRecord.address,
      rewardConfig.address,
      yXend.address
    );
  });

  it("Should deploy the XendFinanceIndividual_Yearn_V1 smart contracts", async () => {
    assert(contractInstance.address !== "");
  });

  it("should get client records", async () => {
      
      const getClientRecordResult = await contractInstance.getClientRecord(accounts[1]);

      console.log(getClientRecordResult)
  })
});
