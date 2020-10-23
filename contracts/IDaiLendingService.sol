pragma solidity ^0.6.6;

interface IDaiLendingService {
    function getPricePerFullShare() external view returns (uint256);

    function save(uint256 amount) external;

    function userShares() external view returns (uint256);

    function userDaiBalance() external view returns (uint256);

    function GetUserGrossRevenue() external view returns (uint256);

    function GetNetRevenue() external view returns (uint256);

    function GetUserDepositedDaiBalance() external view returns (uint256);

    function Withdraw(uint256 amount) external;
    
    function WithdrawByShares(uint amount, uint sharesAmount) external;
    
    function GetDaiLendingAdapterAddress() external view returns (address);
    
    function WithdrawBySharesOnly(uint sharesAmount) external;
}