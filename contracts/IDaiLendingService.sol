pragma solidity 0.6.6;

interface IDaiLendingService {
    function GetPricePerFullShare() external view returns (uint256);

    function Save(uint256 amount) external;

    function UserShares() external view returns (uint256);

    function UserDaiBalance() external view returns (uint256);

    function GetUserGrossRevenue() external view returns (uint256);

    function GetNetRevenue() external view returns (uint256);

    function GetUserDepositedDaiBalance() external view returns (uint256);

    function Withdraw(uint256 amount) external;
    
    function WithdrawByShares(uint256 amount, uint256 sharesAmount) external;
    
    function GetDaiLendingAdapterAddress() external view returns (address);
    
    function WithdrawBySharesOnly(uint sharesAmount) external;
}