// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./IDaiToken.sol";
import "./IYDaiToken.sol";
import "./SafeMath.sol";
import "./OwnableService.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";


contract DaiLendingAdapter is OwnableService, ReentrancyGuard {
    using SafeMath for uint256;
    
    using SafeERC20 for IDaiToken; 

    using SafeERC20 for IYDaiToken; 

    IDaiToken immutable dai = IDaiToken(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    IYDaiToken immutable yDai = IYDaiToken(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

    mapping(address => uint256) userDaiDeposits;

    constructor(address payable serviceContract)
        public
        OwnableService(serviceContract)
    {}

    function GetPricePerFullShare() external view returns (uint256) {
        return yDai.getPricePerFullShare();
    }

    function GetYDaiBalance(address account) external view returns (uint256) {
        return yDai.balanceOf(account);
    }

    function GetDaiBalance(address account) external view returns (uint256) {
        return dai.balanceOf(account);
    }

    /*
        account: this is the owner of the Dai token
    */
    function Save(uint256 amount, address account)
        external nonReentrant
        onlyOwnerAndServiceContract
    {
        //  Give allowance that a spender can spend on behalf of the owner. NOTE: This approve function has to be called from outside this smart contract because if you call
        //  it from the smart contract, it will use the smart contract address as msg.sender which is not what we want,
        //  we want the address with the DAI token to be the one that will be msg.sender. Hence the line below will not work and needs to be called
        //  from Javascript or C# environment
        //   dai.approve(address(this),amount); (Not work)

        //  See example with Node.js below
        //  await daiContract.methods.approve("recipient(in our case, this smart contract address)",1000000).send({from: "wallet address with DAI"});

        //  Transfer DAI from the account address to this smart contract address
        dai.safeTransferFrom(account, address(this), amount);

        //  This gives the yDAI contract approval to invest our DAI
        _save(amount, account);
    }

    //  This function returns your DAI balance + interest. NOTE: There is no function in Yearn finance that gives you the direct balance of DAI
    //  So you have to get it in two steps

    function GetGrossRevenue(address account) public view returns (uint256) {
        //  Get the price per full share
        uint256 price = yDai.getPricePerFullShare();

        //  Get the balance of yDai in this users address
        uint256 balanceShares = yDai.balanceOf(account);

        return balanceShares.mul(price);
    }

    function GetNetRevenue(address account) external view returns (uint256) {

        uint256 grossBalance = GetGrossRevenue(account);

        uint256 userDaiDepositBalance = userDaiDeposits[account].mul(1e18); // multiply dai deposit by 1 * 10 ^ 18 to get value in 10 ^36

        return grossBalance.sub(userDaiDepositBalance);
    }

    function Withdraw(uint256 amount, address owner) external nonReentrant onlyOwnerAndServiceContract
    {
        //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token
        //  So we need to find our balance in yDAI

        uint256 balanceShares = yDai.balanceOf(owner);

        //  transfer yDai From owner to this contract address
        yDai.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        _withdrawBySharesAndAmount(owner,balanceShares,amount);

        //  If we have some DAI left after transferring a specified amount to a recipient, we can re-invest it in yearn finance
        uint256 balanceDai = dai.balanceOf(address(this));

        if (balanceDai > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(balanceDai, owner);
        }
    }

    function WithdrawByShares(
        uint256 amount,
        address owner,
        uint256 sharesAmount
    ) external nonReentrant onlyOwnerAndServiceContract {
        //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token

        uint256 balanceShares = sharesAmount;

        //  transfer yDai From owner to this contract address
        yDai.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        _withdrawBySharesAndAmount(owner,balanceShares,amount);

        //  If we have some DAI left after transferring a specified amount to a recipient, we can re-invest it in yearn finance
        uint256 balanceDai = dai.balanceOf(address(this));

        if (balanceDai > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(balanceDai, owner);
        }
    }

    /*
        this function withdraws all the dai to this contract based on the sharesAmount passed
    */
    function WithdrawBySharesOnly(address owner, uint256 sharesAmount)
        external
        nonReentrant onlyOwnerAndServiceContract
    {
        uint256 balanceShares = sharesAmount;

        //  transfer yDai From owner to this contract address
        yDai.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        _withdrawBySharesOnly(owner,balanceShares);


    }

    //  This function is an internal function that enabled DAI contract where user has money to approve the yDai contract address to invest the user's DAI
    //  and to send the yDai shares to the user's address
    function _save(uint256 amount, address account) internal {
        //  Approve the yDAI contract address to spend amount of DAI
        dai.approve(address(yDai), amount);

        //  Now our yDAI contract has deposited our DAI and it is earning interest and this gives us yDAI token in this Wallet contract
        //  and we will use the yDAI token to redeem our DAI
        yDai.deposit(amount);

        //  call balanceOf and get the total balance of yDai in this contract
        uint256 shares = yDai.balanceOf(address(this));

        //  transfer the yDai shares to the user's address
        yDai.safeTransfer(account, shares);

        //  add deposited dai to userDaiDeposits mapping
        userDaiDeposits[account] = userDaiDeposits[account].add(amount);
    }

    function _withdrawBySharesOnly(address owner, uint256 balanceShares) internal {

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        yDai.withdraw(balanceShares);

        uint256 contractDaiBalance = dai.balanceOf(address(this));

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        dai.safeTransfer(owner, contractDaiBalance);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDaiDeposits[owner] >= contractDaiBalance) {
            userDaiDeposits[owner] = userDaiDeposits[owner].sub(
                contractDaiBalance
            );
        } else {
            userDaiDeposits[owner] = 0;
        }
    }

    function _withdrawBySharesAndAmount(address owner, uint256 balanceShares, uint256 amount) internal {

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        yDai.withdraw(balanceShares);

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        dai.safeTransfer(owner, amount);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDaiDeposits[owner] >= amount) {
            userDaiDeposits[owner] = userDaiDeposits[owner].sub(
                amount
            );
        } else {
            userDaiDeposits[owner] = 0;
        }
    }
}
