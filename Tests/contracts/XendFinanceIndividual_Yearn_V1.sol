// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IClientRecordShema.sol";
import "./IGroupSchema.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IDaiLendingService.sol";
import "./IClientRecord.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./ISavingsConfig.sol";
import "./ISavingsConfigSchema.sol";
import "./ITreasury.sol";
import "./IRewardConfig.sol";
import "./IXendToken.sol";

contract XendFinanceIndividual_Yearn_V1 is
    Ownable,
    IClientRecordSchema,
    ISavingsConfigSchema,
    ReentrancyGuard
{
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

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

    event XendTokenReward(
        uint256 date,
        address payable indexed member,
        uint256 amount
    );

    struct FixedDepositRecord {
        uint256 amount;
        uint256 depositDateInSeconds;
        uint256 lockPeriodInSeconds;
    }

    IDaiLendingService lendingService;
    IERC20 daiToken;
    IClientRecord clientRecordStorage;
    ISavingsConfig savingsConfig;
    IERC20 derivativeToken;
    ITreasury treasury;
    IRewardConfig rewardConfig;
    IXendToken xendToken;

    bool isDeprecated;

    address LendingAdapterAddress;

    string constant XEND_FINANCE_COMMISION_DIVISOR =
        "XEND_FINANCE_COMMISION_DIVISOR";
    string constant XEND_FINANCE_COMMISION_DIVIDEND =
        "XEND_FINANCE_COMMISION_DIVIDEND";

    mapping(address => uint256) MemberToXendTokenRewardMapping; //  This tracks the total amount of xend token rewards a member has received

    mapping(address => FixedDepositRecord) fixedDepositRecords; //This tracks the struct of Fixed Deposit record for a use

    constructor(
        address lendingServiceAddress,
        address tokenAddress,
        address clientRecordStorageAddress,
        address savingsConfigAddress,
        address derivativeTokenAddress,
        address rewardConfigAddress,
        address treasuryAddress,
        address xendTokenAddress
    ) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        clientRecordStorage = IClientRecord(clientRecordStorageAddress);
        savingsConfig = ISavingsConfig(savingsConfigAddress);
        derivativeToken = IERC20(derivativeTokenAddress);
        rewardConfig = IRewardConfig(rewardConfigAddress);
        treasury = ITreasury(treasuryAddress);
        xendToken = IXendToken(xendTokenAddress);
    }

    function setAdapterAddress() external onlyOwner {
        LendingAdapterAddress = lendingService.GetDaiLendingAdapterAddress();
    }

    function deprecateContract(address newServiceAddress)
        external
        onlyOwner
        onlyNonDeprecatedCalls
    {
        isDeprecated = true;
        clientRecordStorage.reAssignStorageOracle(newServiceAddress);
        uint256 derivativeTokenBalance =
            derivativeToken.balanceOf(address(this));
        derivativeToken.safeTransfer(newServiceAddress, derivativeTokenBalance);
    }

    function _UpdateMemberToXendTokeRewardMapping(
        address member,
        uint256 rewardAmount
    ) internal onlyNonDeprecatedCalls {
        MemberToXendTokenRewardMapping[member] = MemberToXendTokenRewardMapping[
            member
        ]
            .add(rewardAmount);
    }

    function GetMemberXendTokenReward(address member)
        external
        returns (uint256)
    {
        return MemberToXendTokenRewardMapping[member];
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
        ClientRecord memory clientRecord =
            _getClientRecordByAddress(msg.sender);

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

    function _withdraw(address payable recipient, uint256 derivativeAmount)
        internal
        nonReentrant
    {
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.WithdrawBySharesOnly(derivativeAmount);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn =
            balanceBeforeWithdraw.sub(balanceAfterWithdraw);

        uint256 commissionFees =
            _computeXendFinanceCommisions(amountOfUnderlyingAssetWithdrawn);

        uint256 amountToSendToDepositor =
            amountOfUnderlyingAssetWithdrawn.sub(commissionFees);

        daiToken.safeTransfer(recipient, amountToSendToDepositor);

        if (commissionFees > 0) {
            daiToken.approve(address(treasury), commissionFees);
            treasury.depositToken(address(daiToken));
        }

        ClientRecord memory clientRecord =
            _updateClientRecordAfterWithdrawal(
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
    ) internal {
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

        return worthOfMemberDepositNow.mul(dividend).div(divisor).div(100);
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
        _deposit(msg.sender);
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
        uint256 amountTransferrable =
            daiToken.allowance(depositorAddress, recipient);

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful =
            daiToken.transferFrom(
                depositorAddress,
                recipient,
                amountTransferrable
            );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        daiToken.approve(LendingAdapterAddress, amountTransferrable);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(amountTransferrable);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord memory clientRecord =
            _updateClientRecordAfterDeposit(
                depositorAddress,
                amountTransferrable,
                amountOfyDai
            );

        bool exists =
            clientRecordStorage.doesClientRecordExist(depositorAddress);

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
            ClientRecord memory record =
                ClientRecord(
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
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IClientRecordShema.sol";
import "./IGroupSchema.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IDaiLendingService.sol";
import "./IClientRecord.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./ISavingsConfig.sol";
import "./ISavingsConfigSchema.sol";
import "./ITreasury.sol";

contract XendFinanceIndividual_Yearn_V1 is
    Ownable,
    IClientRecordSchema,
    ISavingsConfigSchema,
    ReentrancyGuard
{
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

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

    IDaiLendingService lendingService;
    IERC20 daiToken;
    IClientRecord clientRecordStorage;
    ISavingsConfig savingsConfig;
    IERC20 derivativeToken;
    ITreasury treasury;

    bool isDeprecated;

    address LendingAdapterAddress;

    string constant XEND_FINANCE_COMMISION_DIVISOR =
        "XEND_FINANCE_COMMISION_DIVISOR";
    string constant XEND_FINANCE_COMMISION_DIVIDEND =
        "XEND_FINANCE_COMMISION_DIVIDEND";

    constructor(
        address lendingServiceAddress,
        address tokenAddress,
        address clientRecordStorageAddress,
        address savingsConfigAddress,
        address derivativeTokenAddress,
        address treasuryAddress
    ) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        clientRecordStorage = IClientRecord(clientRecordStorageAddress);
        savingsConfig = ISavingsConfig(savingsConfigAddress);
        derivativeToken = IERC20(derivativeTokenAddress);
        treasury = ITreasury(treasuryAddress);
    }

    function setAdapterAddress() external onlyOwner {
        LendingAdapterAddress = lendingService.GetDaiLendingAdapterAddress();
    }

    function deprecateContract(address newServiceAddress)
        external
        onlyOwner
        onlyNonDeprecatedCalls
    {
        isDeprecated = true;
        clientRecordStorage.reAssignStorageOracle(newServiceAddress);
        uint256 derivativeTokenBalance =
            derivativeToken.balanceOf(address(this));
        derivativeToken.safeTransfer(newServiceAddress, derivativeTokenBalance);
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
        ClientRecord memory clientRecord =
            _getClientRecordByAddress(msg.sender);

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

    function _withdraw(address payable recipient, uint256 derivativeAmount)
        internal
        nonReentrant
    {
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.WithdrawBySharesOnly(derivativeAmount);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn =
            balanceBeforeWithdraw.sub(balanceAfterWithdraw);

        uint256 commissionFees =
            _computeXendFinanceCommisions(amountOfUnderlyingAssetWithdrawn);

        uint256 amountToSendToDepositor =
            amountOfUnderlyingAssetWithdrawn.sub(commissionFees);

        daiToken.safeTransfer(recipient, amountToSendToDepositor);

        if (commissionFees > 0) {
            daiToken.approve(address(treasury), commissionFees);
            treasury.depositToken(address(daiToken));
        }

        ClientRecord memory clientRecord =
            _updateClientRecordAfterWithdrawal(
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

    function WithdrawFromFixedDeposit(
        uint256 derivativeAmount,
        uint256 lockPeriodInSeconds
    ) external onlyNonDeprecatedCalls nonReentrant {
        uint256 recipient = msg.sender;
        _validateLockTimeHasElapsed(recipient);
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.WithdrawBySharesOnly(derivativeAmount);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn =
            balanceBeforeWithdraw.sub(balanceAfterWithdraw);

        uint256 commissionFees =
            _computeXendFinanceCommisions(amountOfUnderlyingAssetWithdrawn);

        uint256 amountToSendToDepositor =
            amountOfUnderlyingAssetWithdrawn.sub(commissionFees);

        daiToken.safeTransfer(recipient, amountToSendToDepositor);

        if (commissionFees > 0) {
            daiToken.approve(address(treasury), commissionFees);
            treasury.depositToken(address(daiToken));
        }

        ClientRecord memory clientRecord =
            _updateClientRecordAfterWithdrawal(
                recipient,
                amountOfUnderlyingAssetWithdrawn,
                derivativeAmount
            );
        _updateClientRecord(clientRecord);
        _rewardUserWithTokens(lockPeriodInSeconds, derivativeAmount, recipient);

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
    ) internal {
        ClientRecord memory clientRecord = _getClientRecordByAddress(recipient);

        uint256 derivativeBalance = clientRecord.derivativeBalance;

        require(
            derivativeBalance >= derivativeAmount,
            "Withdrawal cannot be processes, reason: Insufficient Balance"
        );
    }

    function getIndividualDepositRecordByAddress(address _depositorAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            fixedDepositRecords[_depositorAddress].amount,
            fixedDepositRecords[_depositorAddress].depositDateInSeconds,
            fixedDepositRecords[_depositorAddress].lockPeriodInSeconds
        );
    }

    function _validateLockTimeHasElapsed(address payable recipient)
        internal
        view
        returns (uint256)
    {
        FixedDepositRecord memory individualRecord =
            fixedDepositRecords[recipient];

        uint256 lockPeriod = individualRecord.lockPeriodInSeconds;

        uint256 currentTimeStamp = now;

        require(
            currentTimeStamp >= lockPeriod,
            "Funds are still locked, wait until lock period expires"
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

        return worthOfMemberDepositNow.mul(dividend).div(divisor).div(100);
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
        _deposit(msg.sender);
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
        uint256 amountTransferrable =
            daiToken.allowance(depositorAddress, recipient);

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful =
            daiToken.transferFrom(
                depositorAddress,
                recipient,
                amountTransferrable
            );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        daiToken.approve(LendingAdapterAddress, amountTransferrable);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(amountTransferrable);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord memory clientRecord =
            _updateClientRecordAfterDeposit(
                depositorAddress,
                amountTransferrable,
                amountOfyDai
            );

        bool exists =
            clientRecordStorage.doesClientRecordExist(depositorAddress);

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

    function FixedDeposit(
        uint256 depositDateInSeconds,
        uint256 lockPeriodInSeconds
    ) external onlyNonDeprecatedCalls {
        address recipient = address(this);
        uint256 amountTransferrable =
            daiToken.allowance(depositorAddress, recipient);

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful =
            daiToken.transferFrom(
                depositorAddress,
                recipient,
                amountTransferrable
            );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        daiToken.approve(LendingAdapterAddress, amountTransferrable);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(amountTransferrable);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord memory clientRecord =
            _updateClientRecordAfterDeposit(
                depositorAddress,
                amountTransferrable,
                amountOfyDai
            );

        FixedDepositRecord memory depositRecord =
            fixedDepositRecords[depositorAddress];

        depositRecord.amount = amountTransferrable;
        depositRecord.depositDateInSeconds = depositDateInSeconds;
        depositRecord.lockPeriodInSeconds = lockPeriodInSeconds;

        bool exists =
            clientRecordStorage.doesClientRecordExist(depositorAddress);

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
            ClientRecord memory record =
                ClientRecord(
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

    function _emitXendTokenReward(address payable member, uint256 amount)
        internal
    {
        emit XendTokenReward(now, member, amount);
    }

    function _rewardUserWithTokens(
        uint256 totalLockPeriod,
        uint256 amountDeposited,
        address payable recipient
    ) internal {
        uint256 numberOfRewardTokens =
            rewardConfig.CalculateIndividualSavingsReward(
                totalLockPeriod,
                amountDeposited
            );

        if (numberOfRewardTokens > 0) {
            xendToken.mint(recipient, numberOfRewardTokens);
            _UpdateMemberToXendTokeRewardMapping(
                recipient,
                numberOfRewardTokens
            );
            _emitXendTokenReward(recipient, numberOfRewardTokens);
        }
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
