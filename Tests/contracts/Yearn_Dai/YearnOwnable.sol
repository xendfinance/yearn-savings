pragma solidity ^0.6.6;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract YearnOwnable {
    address payable public owner;
    address payable public serviceContract;

    constructor(address payable _serviceContract) internal {
        owner = msg.sender;
        serviceContract = _serviceContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access to contract");
        _;
    }

    modifier onlyOwnerAndServiceContract() {
        require(
            msg.sender == owner || msg.sender == serviceContract,
            "Unauthorized access to contract"
        );
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function transferContractOwnership(address payable newServiceContract)
        public
        onlyOwnerAndServiceContract
    {
        if (newServiceContract != address(0)) {
            serviceContract = newServiceContract;
        }
    }
}
