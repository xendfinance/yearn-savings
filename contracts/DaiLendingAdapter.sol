pragma solidity ^0.6.6;

import "./IDaiToken.sol";
import "./IYDaiToken.sol";
import "./Ownable.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DaiLendingAdapter is Ownable {
    using SafeMath for uint256;

    IDaiToken dai = IDaiToken(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    IYDaiToken yDai = IYDaiToken(0xC2cB1040220768554cf699b0d863A3cd4324ce32);

    mapping(address => uint256) userDaiDeposits;

    constructor(address payable serviceContract)
        public
        Ownable(serviceContract)
    {}

    function GetPricePerFullShare() public view returns (uint256) {
        return yDai.getPricePerFullShare();
    }

    function GetYDaiBalance(address account) public view returns (uint256) {
        return yDai.balanceOf(account);
    }

    function GetDaiBalance(address account) public view returns (uint256) {
        return dai.balanceOf(account);
    }

    /*
        account: this is the owner of the Dai token
    */
    function save(uint256 amount, address account)
        public
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
        dai.transferFrom(account, address(this), amount);

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

    function GetNetRevenue(address account) public view returns (uint256) {
        //  Get the price per full share
        uint256 price = yDai.getPricePerFullShare();

        //  Get the balance of yDai in this users address
        uint256 balanceShares = yDai.balanceOf(account);

        uint256 grossBalance = balanceShares.mul(price); //   value in 10 ^ 36

        uint256 userDaiDepositBalance = userDaiDeposits[account].mul(1e18); // multiply dai deposit by 1 * 10 ^ 18 to get value in 10 ^36

        return grossBalance.sub(userDaiDepositBalance);
    }

    function Withdraw(uint256 amount, address owner)
        public
        onlyOwnerAndServiceContract
    {
        //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token
        //  So we need to find our balance in yDAI

        uint256 balanceShares = yDai.balanceOf(owner);

        //  transfer yDai From owner to this contract address
        yDai.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        yDai.withdraw(balanceShares);

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        dai.transfer(owner, amount);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDaiDeposits[owner] >= amount) {
            userDaiDeposits[owner] = userDaiDeposits[owner].sub(amount);
        } else {
            userDaiDeposits[owner] = 0;
        }

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
    ) public onlyOwnerAndServiceContract {
        //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token

        uint256 balanceShares = sharesAmount;

        //  transfer yDai From owner to this contract address
        yDai.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        yDai.withdraw(balanceShares);

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        dai.transfer(owner, amount);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDaiDeposits[owner] >= amount) {
            userDaiDeposits[owner] = userDaiDeposits[owner].sub(amount);
        } else {
            userDaiDeposits[owner] = 0;
        }

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
        public
        onlyOwnerAndServiceContract
    {
        uint256 balanceShares = sharesAmount;

        //  transfer yDai From owner to this contract address
        yDai.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        yDai.withdraw(balanceShares);

        uint256 contractDaiBalance = dai.balanceOf(address(this));

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        dai.transfer(owner, contractDaiBalance);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDaiDeposits[owner] >= contractDaiBalance) {
            userDaiDeposits[owner] = userDaiDeposits[owner].sub(
                contractDaiBalance
            );
        } else {
            userDaiDeposits[owner] = 0;
        }

        //  We do not have any dai left in this contract so nothing to re-invest

        // //  If we have some DAI left after transferring a specified amount to a recipient, we can re-invest it in yearn finance
        // uint balanceDai = dai.balanceOf(address(this));

        // if(balanceDai > 0){
        //     //  This gives the yDAI contract approval to invest our DAI
        //     _save(balanceDai,owner);
        // }
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
        yDai.transfer(account, shares);

        //  add deposited dai to userDaiDeposits mapping
        userDaiDeposits[account] = userDaiDeposits[account].add(amount);
    }
}
