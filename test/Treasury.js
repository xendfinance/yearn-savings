const TreasuryContract = artifacts.require("Treasury")

let treasuryContract;

contract("TreasuryContract", (accounts) => {
    beforeEach(async () => {
        console.log(TreasuryContract)
        treasuryContract = await TreasuryContract.deployed();
    });


   // deploy the contract correctly
    it("Should deploy the Treasury smart contracts", async () => {
        console.log(treasuryContract)
        // assert(treasuryContract.address !== "");
    });

    it("should deposit token", async () => {
        const result = await treasuryContract.depositToken(accounts[0]);

        console.log(result)
    })

})