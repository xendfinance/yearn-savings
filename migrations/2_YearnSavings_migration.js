const GroupsContract = artifacts.require("Groups");
const TreasuryContract = artifacts.require("Treasury")

module.exports = async (deployer) => {
   
    await deployer.deploy(GroupsContract);

    // console.log("GroupsContract address: " + GroupsContract.address);

    await deployer.deploy(TreasuryContract);

  // console.log("TreasuryContract address: " + TreasuryContract.address);
    
}