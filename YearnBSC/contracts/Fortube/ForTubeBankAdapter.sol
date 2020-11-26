pragma solidity >=0.6.6;

import "../IBank.sol";
import "../IFToken.sol";
import "../IBankController.sol";
import "../IBEP20.sol";
import "../SafeMath.sol";
import "./OwnableService.sol";
import "./Exponential.sol";

contract ForTubeBankAdapter is OwnableService, Exponential {
    
    using SafeMath for uint256;


    IBank _bank;
    IFToken _fBUSD;  //  BUSD shares
    IBankController _bankController;
    IBEP20 _BUSD = IBEP20(0x3b1F033dD955f3BE8649Cc9825A2e3E194765a3F);  // This is a custom BUSD for ForTube, you will not find it on BSC Faucet
    
    

    constructor(address payable serviceContract) public OwnableService(serviceContract){
        _bank = IBank(0xbFFEdF7F10fcD4255F1F622aDBc8CCDC9D5bAd9e);
        _fBUSD = IFToken(0x6112a45160b2058C6402a5bfBE3A446c8fD4fb45);
        _bankController = IBankController(0x92fcF9F805AAF8e97482B86995C4e9EA16D9e2Bb);
    }
    

    /*
        account: this is the owner of the BUSD token
    */
    function Save(uint256 amount, address account)
        public
        onlyOwnerAndServiceContract
    {

        //  Ensure the account has given this contract approval to spend on his/her behalf
        //  Transfer from the account to this contract
        _BUSD.transferFrom(account, address(this),amount);

        //  This gives the Bank contract approval to invest our BUSD
        _save(amount, account);
    }


    /**
        This is an internal function that invests the user's token into ForTube Bank 
    */
    function _save(uint256 amount, address account) internal {
        
        //  Approve Bank Controller Contract to be able to spend BUSD in this contract
        _BUSD.approve(address(_bankController),amount);
        
        //  deposit the BUSD on ForTube's Bank contract
        _bank.deposit(address(_BUSD),amount);

        //  call balanceOf and get the total balance of fBUSD in this contract
        uint256 shares = _fBUSD.balanceOf(address(this));

        //  transfer the fBUSD shares to the user's address
        _fBUSD.transfer(account, shares);

    }
    
    


    function Withdraw(uint256 amount, address owner) public onlyOwnerAndServiceContract
    {
        //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token
        //  So we need to find our balance in yDAI

        uint256 balanceShares = _fBUSD.balanceOf(owner);

        //  Ensure the owner has given this contract approval to spend his/her fBUSD
        //  transfer fBUSD From owner to this contract address
        _fBUSD.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total BUSD based on the fBUSD amount passed. This withdrawal is sent to this smart contract
        _bank.withdraw(address(_BUSD),balanceShares);

        //  Now all the BUSD we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        _BUSD.transfer(owner, amount);


        //  If we have some BUSD left after transferring a specified amount to a recipient, we can re-invest it in ForTube Bank
        uint256 BUSDBalance = _BUSD.balanceOf(address(this));

        if (BUSDBalance > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(BUSDBalance, owner);
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

        //  transfer fBUSD From owner to this contract address
        _fBUSD.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total BUSD we have. This withdrawal is sent to this smart contract
        _bank.withdraw(address(_BUSD),balanceShares);

        uint256 contractBUSDBalance = _BUSD.balanceOf(address(this));

        //  Now all the BUSD we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        _BUSD.transfer(owner, contractBUSDBalance);

        //  We do not have any dai left in this contract so nothing to re-invest

    }
   
    function WithdrawByShares(
        uint256 amount,
        address owner,
        uint256 sharesAmount
    ) public onlyOwnerAndServiceContract {
        //  To withdraw our BUSD amount, the amount argument is in BUSD but the withdraw function of the fBUSD expects amount in fBUSD token

        uint256 balanceShares = sharesAmount;

        //  transfer fBUSD From owner to this contract address
        _fBUSD.transferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total BUSD we have. This withdrawal is sent to this smart contract
        _bank.withdraw(address(_BUSD),balanceShares);

        //  Now all the BUSD we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        _BUSD.transfer(owner, amount);


        //  If we have some BUSD left after transferring a specified amount to a recipient, we can re-invest it in ForTube Bank
        uint256 BUSDBalance = _BUSD.balanceOf(address(this));

        if (BUSDBalance > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(BUSDBalance, owner);
        }
    }
    
    function GetBUSDBalance(address member) external view returns(uint){
        return _BUSD.balanceOf(member);
    }
    
    function GetFBUSDBalance(address member) external view returns(uint){
        return _fBUSD.balanceOf(member);
    }
    
    /**
        Gets the total BUSD the user has earned 
        
        Total BUSD = price per fBUSD * _fBUSD.balanceOf(address)
        
        This gives us the amount we deposited plus interest accrued
    */
    function CalculateTotalBUSDEarned(address member) external view returns (uint256 exchangeRate){
        uint fBUSDBalance = _fBUSD.balanceOf(member);
        uint currentPricePerFullShareOfFBUSD = _fBUSD.exchangeRateStored();
        return mulScalarTruncate(fBUSDBalance,currentPricePerFullShareOfFBUSD);
    }
       
    /**
        Gets the price per full share for the respective fToken 
    */
    function ExchangeRateCurrentBUSD() external view returns (uint exchangeRate){
        return _fBUSD.exchangeRateCurrent();
    }

    function ExchangeRateStoredBUSD() external view returns (uint exchangeRate){
        return _fBUSD.exchangeRateStored();
    }
}