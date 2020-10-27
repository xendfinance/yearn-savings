const Web3 = require('web3');

const DaiContractABI = require('./test/abi/DaiContract.json');
const YDaiContractABI = require('./test/abi/YDaiContractABI.json');

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32";

const recipientAddress = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e";    // Unlocked recipient address
// const recipientAddress = "0x1dcf9AE235BbA490BA243a06197802dd9125D4aE"; // locked recipient address. NOTE: Ganache must unlock recipient address before it can receive tokens
const unlockedAddress = "0x1eC32Bfdbdbd40C0D3ec0fe420EBCfEEb2D56917";   //  Has lots of DAI
const unlockedYDaiSenderAddress = "0x9EF7b6Db1547ae9827a036838F633808FeB9e24D";
const yDaiRecipientAddress = "0x807A1E3FC22A9E77e97a1d4A0272DC49f8d57d61";

const web3 = new Web3("HTTP://127.0.0.1:8545");
const daiContract = new web3.eth.Contract(DaiContractABI, DaiContractAddress);
const yDaiContract = new web3.eth.Contract(YDaiContractABI, yDaiContractAddress);

const init = async () => {


    let unlockedAddressBalance = await daiContract.methods.balanceOf(unlockedAddress).call();
    let recipientBalance = await daiContract.methods.balanceOf(recipientAddress).call();
    console.log("Unlocked Address Balance: " + unlockedAddressBalance);
    console.log(`Recipient Adress Balance: ${recipientBalance}`);
}

async function run() {


    //  DAI Balance operations
    await daiBalance();

    //  YDai Balance operations
    await yDaiBalance();

    //  Dai Transfer Operation
    if (true) {
        var amountToSend = BigInt(10000000000000000000000); //   10000 Dai
        // sendDai(amountToSend, "0x7A3068a9fec005aF90E35DA2d8c8620Ebb7a1F39");
        sendDai(amountToSend, "0x4e07662BED487bB0426b85e466E51F3A3D9150c6");


    }

    //  Approve a contract-address or normal address to spend amount in dai
    if (true) {
        var approvedAmountToSpend = BigInt(5000000000000000000); //   100000 Dai
        //approve("0xF6B58F437C5E40a0817dB3c5570e06380b4f860B", "0xFf3BC1b5be0a717b02eb24DCd1DC8E9Eefe910B1", approvedAmountToSpend);
        approve("0x0F17DE5eaFc13BDe723e06Ad884936E40ee37f16", "0x4e07662BED487bB0426b85e466E51F3A3D9150c6", approvedAmountToSpend);

    }

    //  Approve a contract-address or normal address to spend amount in YDai
    if (false) {
        var approvedAmountToSpend = BigInt(100000000000000000000000); //   100000 YDai
        approveYDai("0x0F17DE5eaFc13BDe723e06Ad884936E40ee37f16", "0x4e07662BED487bB0426b85e466E51F3A3D9150c6", approvedAmountToSpend);

    }




    //  YDai Transfer Operation
    //   await yDaiContract.methods.transfer(yDaiRecipientAddress,4000).send({from: unlockedYDaiSenderAddress});

    //  Get YDai Balance
    //    await yDaiBalance();

};

//  Send Dai from our constant unlocked address
async function sendDai(amount, recipient) {

    var amountToSend = BigInt(amount); //  1000 Dai

    console.log(`Sending  ${amountToSend} x 10^-18 Dai to  ${recipient}`);

    await daiContract.methods.transfer(recipient, amountToSend).send({ from: unlockedYDaiSenderAddress });

    let recipientBalance = await daiContract.methods.balanceOf(recipient).call();

    console.log(`Recipient Balance: ${recipientBalance}`);


}

async function daiBalance() {

    let unlockedAddressBalance = await daiContract.methods.balanceOf(unlockedAddress).call();
    let recipientBalance = await daiContract.methods.balanceOf(recipientAddress).call();

    console.log("Unlocked Address Balance: " + unlockedAddressBalance);
    console.log(`Recipient Adress Balance: ${recipientBalance}`);
};

async function yDaiBalance() {
    let unlockedYDaiSenderBalance = await yDaiContract.methods.balanceOf(unlockedYDaiSenderAddress).call();
    let unlockedYDaiRecipientBalance = await yDaiContract.methods.balanceOf(yDaiRecipientAddress).call();

    console.log("Unlocked YDai Sender Address Balance: " + unlockedYDaiSenderBalance);
    console.log("Unlocked YDai Recipient Address Balance: " + unlockedYDaiRecipientBalance);
};

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approve(spender, owner, amount) {

    await daiContract.methods.approve(spender, amount).send({ from: owner });

    console.log(`Address ${spender}  has been approved to spend ${amount} x 10^-18 Dai by Owner:  ${owner}`);

};

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveYDai(spender, owner, amount) {

    await yDaiContract.methods.approve(spender, amount).send({ from: owner });

    console.log(`Address ${spender}  has been approved to spend ${amount} x 10^-18 YDai by Owner:  ${owner}`);

};
//init();
run();
