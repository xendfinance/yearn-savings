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

    it("should create a group", async () => {
        const result = contractInstance.createGroup("njokuSpending", "NS", accounts[1])

        console.log(result)
        
    })

    it("should check if group exists", async () => {
        const result = contractInstance.doesGroupExist("njokuSpending");

        console.log("check if group exists",  result)
    })

})