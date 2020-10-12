pragma solidity ^0.6.6;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract DaiLendingService {
    IERC20 ydaiToken;
    IERC20 daiToken;

    using SafeMath for uint256;

    constructor(address ydaiTokenAddress, address daiTokenAddress) public {
        ydaiToken = IERC20(ydaiTokenAddress);
        daiToken = IERC20(daiTokenAddress);
    }

    function getPricePerFullShare() external pure returns (uint256) {
        return _getPricePerFullShare();
    }

    function _getPricePerFullShare() internal pure returns (uint256) {
        uint256 base = 1;
        return base.mul(10**uint256(18));
    }

    function save(uint256 amount) external {
        uint256 allowance = daiToken.allowance(msg.sender, address(this));
        require(amount == allowance, "amount mismatch");

        bool isSuccessful = daiToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(isSuccessful == true, "dai token transfer failed");
        isSuccessful = ydaiToken.transfer(msg.sender, amount);
        require(isSuccessful == true, "ydai token transfer failed");
    }

    function userShares() external view returns (uint256) {
        return ydaiToken.balanceOf(msg.sender);
    }

    function getUserShares(address account) external view returns (uint256) {
        return ydaiToken.balanceOf(account);
    }

    function userDaiBalance() external pure returns (uint256) {
        uint256 base = 1;
        return base.mul(10**uint256(18));
    }

    function GetUserGrossRevenue() external pure returns (uint256) {
        return 0;
    }

    function GetNetRevenue() external pure returns (uint256) {
        return 0;
    }

    function GetUserDepositedDaiBalance() external pure returns (uint256) {
        return 0;
    }

    function Withdraw(uint256 amount) external {}

    function WithdrawBySharesOnly(uint256 sharesAmount) external {
        uint256 allowance = ydaiToken.allowance(msg.sender, address(this));

        require(sharesAmount == allowance, "amount mismatch");

        bool isSuccessful = ydaiToken.transferFrom(
            msg.sender,
            address(this),
            allowance
        );
        require(isSuccessful == true, "ydai token transfer failed");
        isSuccessful = daiToken.transfer(msg.sender, sharesAmount);
        require(isSuccessful == true, "dai token transfer failed");
    }
}
