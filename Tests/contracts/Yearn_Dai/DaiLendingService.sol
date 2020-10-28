pragma solidity ^0.6.6;

import "./DaiLendingAdapter.sol";

contract DaiLendingService {
    address _owner;
    DaiLendingAdapter _daiLendingAdapter;

    constructor() public {
        _owner = msg.sender;
    }

    function transferOwnership(address account) external onlyOwner() {
        if (_owner != address(0)) _owner = account;
    }

    function updateAdapter(address adapterAddress) external onlyOwner() {
        _daiLendingAdapter = DaiLendingAdapter(adapterAddress);
    }

    function getPricePerFullShare() external view returns (uint256) {
        return _daiLendingAdapter.GetPricePerFullShare();
    }

    /*
        -   Before calling this function, ensure that the msg.sender or caller has given this contract address
            approval to transfer money on its behalf to another address
    */
    function save(uint256 amount) external {
        _daiLendingAdapter.save(amount, msg.sender);
    }

    //  Get the user's shares or the yDai tokens
    function userShares() external view returns (uint256) {
        return _daiLendingAdapter.GetYDaiBalance(msg.sender);
    }

    //  Get the user's Dai balance
    function userDaiBalance() external view returns (uint256) {
        return _daiLendingAdapter.GetDaiBalance(msg.sender);
    }

    //  Get the gross revenue the user has made ( shares * current share price )
    function GetUserGrossRevenue() external view returns (uint256) {
        return _daiLendingAdapter.GetGrossRevenue(msg.sender);
    }

    //  Get the net revenue the user has made ( (shares * current share price) - total invested amount)
    function GetNetRevenue() external view returns (uint256) {
        return _daiLendingAdapter.GetNetRevenue(msg.sender);
    }

    function Withdraw(uint256 amount) external {
        _daiLendingAdapter.Withdraw(amount, msg.sender);
    }

    function WithdrawByShares(uint256 amount, uint256 sharesAmount) external {
        _daiLendingAdapter.WithdrawByShares(amount, msg.sender, sharesAmount);
    }

    function WithdrawBySharesOnly(uint256 sharesAmount) external {
        _daiLendingAdapter.WithdrawBySharesOnly(msg.sender, sharesAmount);
    }

    function GetDaiLendingAdapterAddress() external view returns (address) {
        return address(_daiLendingAdapter);
    }

    function TransferAdapterContractOwnership(
        address payable newServiceContract
    ) external onlyOwner {
        _daiLendingAdapter.transferContractOwnership(newServiceContract);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can make this call");
        _;
    }
}
