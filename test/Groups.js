const Groups = artifacts.require("Groups")

contract("Groups", (accounts) => {
    let contractInstance;
    
    beforeEach(async () => {
    
        contractInstance = await Groups.new();

        console.log(contract)
    
    });

    it("Should deploy the Treasury smart contracts", async () => {
        
        assert(contractInstance.address !== "");
    });

})