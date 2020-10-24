const { create } = require("combined-stream");
const { assert } = require("console");

const Groups = artifacts.require("Groups")

contract("Groups", async (accounts) => {
    let contractInstance;
    
    beforeEach(async () => {
    
        contractInstance = await Groups.new();
    
    });

 

    it("Should deploy the Treasury smart contracts", async () => {
        
        assert(contractInstance.address !== "");
    });

    

    it("should activate storage oracle", async () => {

        const instance = await Groups.new();

        const result = await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

       return assert(result.receipt.status == true, "tx reciept status is true")
        
    })

    it("should create a group", async () => {
        //arrange
        const instance = await Groups.new();

        await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

        //act
         await instance.createGroup("njokuAkawo", "N9", accounts[2], {from : accounts[1]})

        const getGroup = await instance.getGroupById(1, {from: accounts[1]});

        assert(getGroup[3] !== "")

        //assert
        const groupIndexerResult = await instance.getGroupIndexer(1);
        
        assert(groupIndexerResult.exist == true, "tx reciept status is true")

        assert(groupIndexerResult.index.length === 1, "tx reciept status is true")

    })

    it("should create a group member", async () => {

          //arrange
          const instance = await Groups.new();

          await instance.activateStorageOracle(accounts[1], {from :accounts[0]});
  
          //act
          await instance.createGroup("njokuAkawo", "N9", accounts[2], {from : accounts[1]})
  
          const createMemberResult = await instance.createGroupMember(1, accounts[3], {from: accounts[1]});
          
          const getGroupMemberResult = await instance.getGroupMember(0);

          let depositorAddress = getGroupMemberResult._address;
        
          const doesGroupMemberExistResult = await instance.doesGroupMemberExist(1, depositorAddress);

          assert(doesGroupMemberExistResult == true);

          assert(depositorAddress !== "");

          assert(createMemberResult.receipt.status == true, "tx reciept status is true");
  

    })

    it("should check length of token address used in deposit", async () => {
        const result = await contractInstance.getLengthOfTokenAddressesUsedInDeposit({from: accounts[1]});

        assert(result.length !== null);

        console.log("check length of token",  result)
    })

    it("should increment token deposit", async () => {

        const instance = await Groups.new();

        await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

        //act

        const result = await instance.incrementTokenDeposit(accounts[2], 10, {from : accounts[1]})

        assert(result.receipt.status == true);

    })

    it("should decrement token deposit", async () => {

        const instance = await Groups.new();

        await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

        //act
         await instance.incrementTokenDeposit(accounts[2], 10, {from : accounts[1]})

        const result = await instance.decrementTokenDeposit(accounts[2], 5, {from : accounts[1]})

        assert(result.receipt.status == true);

    })

    it("should increment ether deposit", async () => {

        const instance = await Groups.new();

        await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

        //act

        const result = await instance.incrementEtherDeposit(15, {from : accounts[1]})

        assert(result.receipt.status == true);

    })

    it("should decrement ether deposit", async () => {

        const instance = await Groups.new();

        await instance.activateStorageOracle(accounts[1], {from :accounts[0]});

        //act

        await instance.incrementEtherDeposit(15, {from : accounts[1]})

        const result = await instance.decrementEtherDeposit(5, {from : accounts[1]})

        assert(result.receipt.status == true);

    })



})