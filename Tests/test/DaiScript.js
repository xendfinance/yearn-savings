

const Web3 = require('web3');

const DaiContractABI = require('./abi/DaiContract.json');

const YDaiContractAbi = require("./abi/YDaiContractABI.json")

const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

const daiService = '0xA0394ef8f483c63766862FC50f0696793203C9D3'

const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32";


const recipientAddress = "0x19db654947aB4aaA6d080625E2aDCc0A82fA80f3";    // Unlocked recipient address
// const recipientAddress = "0x1dcf9AE235BbA490BA243a06197802dd9125D4aE"; // locked recipient address. NOTE: Ganache must unlock recipient address before it can receive tokens
const unlockedAddress = "0xdcd024536877075bfb2ffb1db9655ae331045b4e" //  Has lots of DAI


const web3 = new Web3("HTTP://127.0.0.1:8545");
const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);

const yDaiContract = new web3.eth.Contract(YDaiContractAbi, yDaiContractAddress)

const init = async () => {

    
    let unlockedAddressBalance = await daiContract.methods.balanceOf(unlockedAddress).call();
    let recipientBalance = await daiContract.methods.balanceOf(recipientAddress).call();
    console.log("Unlocked Address Balance: " + unlockedAddressBalance);
    console.log(`Recipient Adress Balance: ${recipientBalance}`);
}

async function run (){


    //  DAI Balance operations
    await daiBalance();


   
    //  Dai Transfer Operation
    if(true){
        var amountToSend = BigInt(10000000000000000000000); //   10000 Dai
        sendDai(amountToSend,recipientAddress);
    }


    // //  YDai Transfer Operation
    var amountToSend = BigInt(100000000000000000)
    //await yDaiContract.methods.transfer(daiService,amountToSend).send({from: unlockedAddress});



         let Balance = await yDaiContract.methods.balanceOf(daiService).call();

         console.log(Balance)

      
    //  Get YDai Balance
     // await yDaiBalance();

    YsendDai(amountToSend, daiService)

};




//  Send Dai from our constant unlocked address
async function YsendDai(amount, recipient){

    var amountToSend = BigInt(amount); //  1000 Dai

    console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);

    await yDaiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

    let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
    
    console.log(`y Recipient Balance: ${recipientBalance}`);


}

//  Send Dai from our constant unlocked address
async function sendDai(amount, recipient){

    var amountToSend = BigInt(amount); //  1000 Dai

    console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);

    await daiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

    let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
    
    console.log(`Recipient Balance: ${recipientBalance}`);


}

async function daiBalance(){

    let unlockedAddressBalance = await daiContract.methods.balanceOf(unlockedAddress).call();
    let recipientBalance = await daiContract.methods.balanceOf(recipientAddress).call();

    console.log("Unlocked Address Balance: " + unlockedAddressBalance);
    console.log(`Recipient Adress Balance: ${recipientBalance}`);
};


//  Approve a smart contract address or normal address to spend on behalf of the owner
// async function approve(spender,  owner,  amount){

//     await daiContract.methods.approve(spender,amount).send({from: owner});

//     console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

// };

//init();
run();