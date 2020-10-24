const { assert } = require("console");

const Cycles = artifacts.require("Cycles")

contract("Cycles", async (accounts) => {
    let contractInstance;
    
    beforeEach(async () => {
    
        contractInstance = await Cycles.new();
    
    });

 

    it("Should deploy the cycles smart contracts", async () => {
        
        assert(contractInstance.address !== "");
    });

})