pragma solidity ^0.6.6;
import "./SafeMath.sol";
import "./Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

interface Treasury {
    function depositToken(address token) external;

    function getEtherBalance() external view returns (uint256);

    function getTokenBalance(address token) external view returns (uint256);

    function withdrawEthers(uint256 amount) external;

    function withdrawTokens(address tokenAddress, uint256 amount) external;
}
