const TreasuryContract = artifacts.require('Treasury');


contract('Treasury', () => {

  let contractInstance = null;

  before(async () => {
      
    contractInstance = await TreasuryContract.deployed();

    console.log("contract instance address", contractInstance.address)
     

  });
  
  // deploy the contract correctly
  it("Should deploy the Treasury smart contracts", async () => {

    assert(contractInstance.address !== "");

  });

  it("should deposit token", async () => {

    const result = await contractInstance.depositToken(accounts[0]);

    console.log(result);
  });

});
