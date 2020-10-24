const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury")
const CyclesContract = artifacts.require("Cycles")

module.exports = function (deployer) {
    
  deployer.then(async () => {
    
      await deployer.deploy(GroupsContract);

      console.log("GroupsContract address: " + GroupsContract.address);
  
      await deployer.deploy(TreasuryContract);
  
      console.log("TreasuryContract address: " + TreasuryContract.address);

      await deployer.deploy(CyclesContract);

      console.log(CyclesContract.address);

    
    })
  
}