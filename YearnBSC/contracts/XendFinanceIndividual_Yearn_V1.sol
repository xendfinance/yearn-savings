// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IClientRecordShema.sol";
import "./IGroupSchema.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
// import "./IDaiLendingService.sol";
import "./IClientRecord.sol";
// import "./IERC20.sol";
import "./Address.sol";
import "./ISavingsConfig.sol";
import "./ISavingsConfigSchema.sol";
import "./ITreasury.sol";

import "./IBEP20.sol";
import "./IForTubeBankService.sol";
import "./IFToken.sol";


contract XendFinanceIndividual_Yearn_V1 is
    Ownable,
    IClientRecordSchema,
    ISavingsConfigSchema
{
    using SafeMath for uint256;

    using Address for address payable;

    event UnderlyingAssetDeposited(
        address payable user,
        uint256 underlyingAmount,
        uint256 derivativeAmount,
        uint256 balance
    );

    event DerivativeAssetWithdrawn(
        address payable user,
        uint256 underlyingAmount,
        uint256 derivativeAmount,
        uint256 balance
    );

    //IDaiLendingService lendingService;
    IForTubeBankService fortubeService;
    //IERC20 daiToken;
    IBEP20 busdToken;      //  BEP20 - ForTube BUSD Testnet TODO: change to live when moving to mainnet 
    IFToken fBusdToken;   //  BEP20 - fBUSD Testnet TODO: change to mainnet
    IClientRecord clientRecordStorage;
    ISavingsConfig savingsConfig;
    //IERC20 derivativeToken;
    ITreasury treasury;

    bool isDeprecated = false;

    //address LendingAdapterAddress;

    address FortubeBankAdapter;
    address TreasuryAddress;
    address TokenAddress;

    string constant XEND_FINANCE_COMMISION_DIVISOR = "XEND_FINANCE_COMMISION_DIVISOR";
    string constant XEND_FINANCE_COMMISION_DIVIDEND = "XEND_FINANCE_COMMISION_DIVIDEND";

    constructor(
        address fortubeBankAdapterAddress,
        address fortubeServiceAddress,
        address tokenAddress,
        address clientRecordStorageAddress,
        address savingsConfigAddress,
        address derivativeTokenAddress,
        address treasuryAddress
    ) public {
        fortubeService = IForTubeBankService(fortubeServiceAddress);
        busdToken = IBEP20(tokenAddress);
        clientRecordStorage = IClientRecord(clientRecordStorageAddress);
        FortubeBankAdapter = fortubeBankAdapterAddress;
        savingsConfig = ISavingsConfig(savingsConfigAddress);
        fBusdToken = IFToken(derivativeTokenAddress);
        treasury = ITreasury(treasuryAddress);
        TreasuryAddress = treasuryAddress;
        TokenAddress = tokenAddress;
    }

    function deprecateContract(address newServiceAddress)
        external
        onlyOwner
        onlyNonDeprecatedCalls
    {
        isDeprecated = true;
        clientRecordStorage.reAssignStorageOracle(newServiceAddress);
        uint256 derivativeTokenBalance = fBusdToken.balanceOf(
            address(this)
        );
        fBusdToken.transfer(newServiceAddress, derivativeTokenBalance);
    }

    function doesClientRecordExist(address depositor)
        external
        view
        onlyNonDeprecatedCalls
        returns (bool)
    {
        return clientRecordStorage.doesClientRecordExist(depositor);
    }

    function getClientRecord(address depositor)
        external
        view
        onlyNonDeprecatedCalls
        returns (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        )
    {
        ClientRecord memory clientRecord = _getClientRecordByAddress(depositor);
        return (
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }

    function getClientRecord()
        external
        view
        onlyNonDeprecatedCalls
        returns (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        )
    {
        ClientRecord memory clientRecord = _getClientRecordByAddress(
            msg.sender
        );

        return (
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }

    function getClientRecordByIndex(uint256 index)
        external
        view
        onlyNonDeprecatedCalls
        returns (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        )
    {
        ClientRecord memory clientRecord = _getClientRecordByIndex(index);
        return (
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }

    function _getClientRecordByIndex(uint256 index)
        internal
        view
        returns (ClientRecord memory)
    {
        (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        ) = clientRecordStorage.getClientRecordByIndex(index);
        return
            ClientRecord(
                true,
                _address,
                underlyingTotalDeposits,
                underlyingTotalWithdrawn,
                derivativeBalance,
                derivativeTotalDeposits,
                derivativeTotalWithdrawn
            );
    }

    function _getClientRecordByAddress(address member)
        internal
        view
        returns (ClientRecord memory)
    {
        (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        ) = clientRecordStorage.getClientRecordByAddress(member);

        return
            ClientRecord(
                true,
                _address,
                underlyingTotalDeposits,
                underlyingTotalWithdrawn,
                derivativeBalance,
                derivativeTotalDeposits,
                derivativeTotalWithdrawn
            );
    }

    function withdraw(uint256 derivativeAmount)
        external
        onlyNonDeprecatedCalls
    {
      address payable recipient = msg.sender;
      
      _withdraw(recipient, derivativeAmount);
    }

    function withdrawDelegate(
        address payable recipient,
        uint256 derivativeAmount
    ) external onlyNonDeprecatedCalls onlyOwner {
        _withdraw(recipient, derivativeAmount);
    }
    
    function withdrawByShares(uint256 derivativeAmount) external {
        
        fBusdToken.approve(FortubeBankAdapter, derivativeAmount);
        
        fortubeService.WithdrawBySharesOnly(derivativeAmount);
    }

    function _withdraw(address payable recipient, uint256 derivativeAmount)
        internal
    {
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = fortubeService.UserBUSDBalance(address(this));

         bool isApprovalSuccessful = fBusdToken.approve(FortubeBankAdapter,derivativeAmount);
         
         require(isApprovalSuccessful == true, 'could not approve fbusd token for adapter contract');
        
         fortubeService.WithdrawBySharesOnly(derivativeAmount);

        uint256 balanceAfterWithdraw = fortubeService.UserBUSDBalance(address(this));

        require(balanceAfterWithdraw>balanceBeforeWithdraw, "Balance before needs to be greater than balance after");

        uint256 amountOfUnderlyingAssetWithdrawn =  balanceAfterWithdraw.sub(
            balanceBeforeWithdraw
        );
        

        uint256 commissionFees = _computeXendFinanceCommisions(
            amountOfUnderlyingAssetWithdrawn
        );

        require(amountOfUnderlyingAssetWithdrawn>commissionFees, "Amount to be withdrawn must be greater than commision fees");
        uint256 amountToSendToDepositor = amountOfUnderlyingAssetWithdrawn.sub(
            commissionFees
        );
            
        //busdToken.approve(recipient, amountToSendToDepositor);

        bool isSuccessful = busdToken.transfer(
            recipient,
            amountToSendToDepositor
        );

        require(isSuccessful == true, "Could not complete withdrawal");

        if (commissionFees > 0) {
            busdToken.approve(TreasuryAddress, commissionFees);
            treasury.depositToken(TokenAddress);
        }

        ClientRecord memory clientRecord = _updateClientRecordAfterWithdrawal(
            recipient,
            amountOfUnderlyingAssetWithdrawn,
            derivativeAmount
        );
        _updateClientRecord(clientRecord);

        emit DerivativeAssetWithdrawn(
            recipient,
            amountOfUnderlyingAssetWithdrawn,
            derivativeAmount,
            clientRecord.derivativeBalance
        );
    }

    function _validateUserBalanceIsSufficient(
        address payable recipient,
        uint256 derivativeAmount
    ) internal view returns (uint256) {
        ClientRecord memory clientRecord = _getClientRecordByAddress(recipient);

        uint256 derivativeBalance = clientRecord.derivativeBalance;

        require(
            derivativeBalance >= derivativeAmount,
            "Withdrawal cannot be processes, reason: Insufficient Balance"
        );
    }

    function _computeXendFinanceCommisions(uint256 worthOfMemberDepositNow)
        internal
        returns (uint256)
    {
        uint256 dividend = _getDividend();
        uint256 divisor = _getDivisor();

        require(
            worthOfMemberDepositNow > 0,
            "member deposit really isn't worth much"
        );

        return worthOfMemberDepositNow.mul(dividend).div(divisor);
    }

    function _getDivisor() internal returns (uint256) {
        (
            uint256 minimumDivisor,
            uint256 maximumDivisor,
            uint256 exactDivisor,
            bool appliesDivisor,
            RuleDefinition ruleDefinitionDivisor
        ) = savingsConfig.getRuleSet(XEND_FINANCE_COMMISION_DIVISOR);

        require(
            appliesDivisor == true,
            "unsupported rule defintion for rule set"
        );

        require(
            ruleDefinitionDivisor == RuleDefinition.VALUE,
            "unsupported rule defintion for penalty percentage rule set"
        );
        return exactDivisor;
    }

    function _getDividend() internal returns (uint256) {
        (
            uint256 minimumDividend,
            uint256 maximumDividend,
            uint256 exactDividend,
            bool appliesDividend,
            RuleDefinition ruleDefinitionDividend
        ) = savingsConfig.getRuleSet(XEND_FINANCE_COMMISION_DIVIDEND);

        require(
            appliesDividend == true,
            "unsupported rule defintion for rule set"
        );

        require(
            ruleDefinitionDividend == RuleDefinition.VALUE,
            "unsupported rule defintion for penalty percentage rule set"
        );
        return exactDividend;
    }

    function deposit() external onlyNonDeprecatedCalls {
        address payable depositor = msg.sender;
        _deposit(depositor);
    }

    function depositDelegate(address payable depositorAddress)
        external
        onlyNonDeprecatedCalls
        onlyOwner
    {
        _deposit(depositorAddress);
    }

    function _deposit(address payable depositorAddress) internal {
        address recipient = address(this);
        uint256 amountTransferrable = busdToken.allowance(
            depositorAddress,
            recipient
        );

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful = busdToken.transferFrom(
            depositorAddress,
            recipient,
            amountTransferrable
        );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

       

        uint256 balanceBeforeDeposit = fBusdToken.balanceOf(address(this));

         busdToken.approve(FortubeBankAdapter, amountTransferrable);

        fortubeService.Save(amountTransferrable);

        uint256 balanceAfterDeposit = fBusdToken.balanceOf(address(this));

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord memory clientRecord = _updateClientRecordAfterDeposit(
            depositorAddress,
            amountTransferrable,
            amountOfyDai
        );

        bool exists = clientRecordStorage.doesClientRecordExist(
            depositorAddress
        );

        if (exists) _updateClientRecord(clientRecord);
        else {
            clientRecordStorage.createClientRecord(
                clientRecord._address,
                clientRecord.underlyingTotalDeposits,
                clientRecord.underlyingTotalWithdrawn,
                clientRecord.derivativeBalance,
                clientRecord.derivativeTotalDeposits,
                clientRecord.derivativeTotalWithdrawn
            );
        }

        emit UnderlyingAssetDeposited(
            depositorAddress,
            amountTransferrable,
            amountOfyDai,
            clientRecord.derivativeBalance
        );
    }

    function _updateClientRecordAfterDeposit(
        address payable client,
        uint256 underlyingAmountDeposited,
        uint256 derivativeAmountDeposited
    ) internal returns (ClientRecord memory) {
        bool exists = clientRecordStorage.doesClientRecordExist(client);
        if (!exists) {
            ClientRecord memory record = ClientRecord(
                true,
                client,
                underlyingAmountDeposited,
                0,
                derivativeAmountDeposited,
                derivativeAmountDeposited,
                0
            );

           
            return record;
        } else {
            ClientRecord memory record = _getClientRecordByAddress(client);

            record.underlyingTotalDeposits = record.underlyingTotalDeposits.add(
                underlyingAmountDeposited
            );
            record.derivativeTotalDeposits = record.derivativeTotalDeposits.add(
                derivativeAmountDeposited
            );
            record.derivativeBalance = record.derivativeBalance.add(
                derivativeAmountDeposited
            );

            return record;
        }
    }

    function _updateClientRecordAfterWithdrawal(
        address payable client,
        uint256 underlyingAmountWithdrawn,
        uint256 derivativeAmountWithdrawn
    ) internal returns (ClientRecord memory) {
        ClientRecord memory record = _getClientRecordByAddress(client);

        record.underlyingTotalWithdrawn = record.underlyingTotalWithdrawn.add(
            underlyingAmountWithdrawn
        );

        record.derivativeTotalWithdrawn = record.derivativeTotalWithdrawn.add(
            derivativeAmountWithdrawn
        );
        record.derivativeBalance = record.derivativeBalance.sub(
            derivativeAmountWithdrawn
        );

        return record;
    }

    function _updateClientRecord(ClientRecord memory clientRecord) internal {
        clientRecordStorage.updateClientRecord(
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }

    modifier onlyNonDeprecatedCalls() {
        require(isDeprecated == false, "Service contract has been deprecated");
        _;
    }
}