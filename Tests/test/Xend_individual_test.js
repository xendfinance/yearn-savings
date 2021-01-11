console.log(
  "********************** Running Individual Test *****************************"
);
const Web3 = require("web3");
const { assert } = require("console");
const web3 = new Web3("HTTP://127.0.0.1:8545");
const utils = require("./helpers/Utils");

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
const XendFinanceGroup_Yearn_V1Contract = artifacts.require(
  "XendFinanceGroup_Yearn_V1"
);
const RewardConfigContract = artifacts.require("RewardConfig");
const XendTokenContract = artifacts.require("XendToken");
const EsusuServiceContract = artifacts.require("EsusuService");

const DaiContractABI = require("./abi/DAIContract.json");
const YDaiContractABI = require("./abi/YDAIContractABI.json");

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32";

const unlockedAddress = "0xdcd024536877075bfb2ffb1db9655ae331045b4e"; //  Has lots of DAI

const daiContract = new web3.eth.Contract(DaiContractABI, DaiContractAddress);
const yDaiContract = new web3.eth.Contract(
  YDaiContractABI,
  yDaiContractAddress
);

var account1;
var account2;
var account3;

var account1Balance;
var account2Balance;
var account3Balance;

//  Send Dai from our constant unlocked address to any recipient
async function sendDai(amount, recipient) {
  var amountToSend = BigInt(amount); //  1000 Dai

  console.log(`Sending  ${amountToSend} x 10^-18 Dai to  ${recipient}`);

  await daiContract.methods
    .transfer(recipient, amountToSend)
    .send({ from: unlockedAddress });

  let recipientBalance = await daiContract.methods.balanceOf(recipient).call();

  console.log(`Recipient: ${recipient} DAI Balance: ${recipientBalance}`);
}

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveDai(spender, owner, amount) {
  await daiContract.methods.approve(spender, amount).send({ from: owner });

  console.log(
    `Address ${spender}  has been approved to spend ${amount} x 10^-18 Dai by Owner:  ${owner}`
  );
}

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveYDai(spender, owner, amount) {
  await yDaiContract.methods.approve(spender, amount).send({ from: owner });

  console.log(
    `Address ${spender}  has been approved to spend ${amount} x 10^-18 YDai by Owner:  ${owner}`
  );
}

contract("XendFinanceIndividual", () => {
  let daiLendingAdapterContract = null;
  let daiLendingServiceContract = null;
  let savingsConfigContract = null;
  let esusuServiceContract = null;
  let clientRecordContract = null;
  let xendTokenContract = null;
  let rewardConfigContract = null;
  let treasuryContract = null;
  let xendFinanceIndividualContract = null;

  before(async () => {
    daiLendingAdapterContract = await DaiLendingAdapterContract.deployed();
    daiLendingServiceContract = await DaiLendingServiceContract.deployed();
    savingsConfigContract = await SavingsConfigContract.deployed();
    esusuServiceContract = await EsusuServiceContract.deployed();
    clientRecordContract = await ClientRecordContract.deployed();
    xendTokenContract = await XendTokenContract.deployed();
    rewardConfigContract = await RewardConfigContract.deployed();
    treasuryContract = await TreasuryContract.deployed();
    xendFinanceIndividualContract = await XendFinanceIndividual_Yearn_V1Contract.deployed();

    await savingsConfigContract.createRule(
      "XEND_FINANCE_COMMISION_DIVISOR",
      0,
      0,
      100,
      1
    );

    await savingsConfigContract.createRule(
      "XEND_FINANCE_COMMISION_DIVIDEND",
      0,
      0,
      1,
      1
    );

    await savingsConfigContract.createRule(
      "PERCENTAGE_PAYOUT_TO_USERS",
      0,
      0,
      0,
      1
    );

    await savingsConfigContract.createRule("PERCENTAGE_AS_PENALTY", 0, 0, 1, 1);

    await daiLendingServiceContract.updateAdapter(
      daiLendingAdapterContract.address
    );

    await rewardConfigContract.SetRewardParams(
      "100000000000000000000000000",
      "10000000000000000000000000",
      "2",
      "7",
      "10",
      "15",
      "4",
      "60",
      "4"
    );

    await rewardConfigContract.SetRewardActive(true);

    await clientRecordContract.activateStorageOracle(
      xendFinanceIndividualContract.address
    );

    //  Get the addresses and Balances of at least 2 accounts to be used in the test
    //  Send DAI to the addresses
    web3.eth.getAccounts().then(function (accounts) {
      account1 = accounts[0];
      account2 = accounts[1];
      account3 = accounts[2];

      //  send money from the unlocked dai address to accounts 1 and 2
      var amountToSend = BigInt(10000000000000000000000); //   10,000 Dai

      //  get the eth balance of the accounts
      web3.eth.getBalance(account1, function (err, result) {
        if (err) {
          console.log(err);
        } else {
          account1Balance = web3.utils.fromWei(result, "ether");
          console.log(
            "Account 1: " +
              accounts[0] +
              "  Balance: " +
              account1Balance +
              " ETH"
          );
          sendDai(amountToSend, account1);
        }
      });

      web3.eth.getBalance(account2, function (err, result) {
        if (err) {
          console.log(err);
        } else {
          account2Balance = web3.utils.fromWei(result, "ether");
          console.log(
            "Account 2: " +
              accounts[1] +
              "  Balance: " +
              account2Balance +
              " ETH"
          );
          sendDai(amountToSend, account2);
        }
      });

      web3.eth.getBalance(account3, function (err, result) {
        if (err) {
          console.log(err);
        } else {
          account3Balance = web3.utils.fromWei(result, "ether");
          console.log(
            "Account 3: " +
              accounts[2] +
              "  Balance: " +
              account3Balance +
              " ETH"
          );
          sendDai(amountToSend, account3);
        }
      });
    });
  });

  it("should deposit in personal savings and get client record", async () => {
    
    var approvedAmountToSpend = BigInt(100000000000000000000); //   10,000 Dai
    
    approveDai(xendFinanceIndividualContract.address,account1,approvedAmountToSpend);

    var result = await xendFinanceIndividualContract.deposit();

    console.log(result, 'result')
  });
});
