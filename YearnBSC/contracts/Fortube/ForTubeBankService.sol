pragma solidity >=0.6.6;

import "./ForTubeBankAdapter.sol";

contract ForTubeBankService {
    address _owner;
    
    ForTubeBankAdapter _bankAdapter;

    constructor() public {
        _owner = msg.sender;
    }

    function transferOwnership(address account) external onlyOwner() {
        if (_owner != address(0)) _owner = account;
    }

    function updateAdapter(address adapterAddress) external onlyOwner() {
        _bankAdapter = ForTubeBankAdapter(adapterAddress);
    }

    function UserShares() external view returns (uint256) {
        return _bankAdapter.GetFBUSDBalance(msg.sender);
    }

    function UserBUSDBalance() external view returns (uint256) {
        return _bankAdapter.GetBUSDBalance(msg.sender);
    }

    /*
        -   Before calling this function, ensure that the msg.sender or caller has given this contract address
            approval to transfer money on its behalf to another address
    */
    function Save(uint256 amount) external {
        _bankAdapter.Save(amount, msg.sender);
    }

    function Withdraw(uint256 amount) external {
        _bankAdapter.Withdraw(amount, msg.sender);
    }

    function WithdrawByShares(uint256 amount, uint256 sharesAmount) external {
        _bankAdapter.WithdrawByShares(amount, msg.sender, sharesAmount);
    }

    function WithdrawBySharesOnly(uint256 sharesAmount) external {
        _bankAdapter.WithdrawBySharesOnly(msg.sender, sharesAmount);
    }

    function GetForTubeAdapterAddress() external view returns (address) {
        return address(_bankAdapter);
    }

    function TransferAdapterContractOwnership(address payable newServiceContract) external onlyOwner {
        _bankAdapter.transferContractOwnership(newServiceContract);
    }
    
    function CalculateTotalBUSDEarned(address member) external view returns (uint256 exchangeRate){
        return _bankAdapter.CalculateTotalBUSDEarned(member);
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can make this call");
        _;
    }
}