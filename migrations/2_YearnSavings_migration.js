const GroupsContract = artifacts.require("Groups");

module.exports = async (deployer) => {
   
    await deployer.deploy(GroupsContract);

    console.log("GroupsContract address: " + GroupsContract.address);
    
}