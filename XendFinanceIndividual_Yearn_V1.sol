// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IDaiLendingService.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract XendFinanceIndividual_Yearn_V1 is Ownable {
    using SafeMath for uint256;

    using Address for address payable;

    // list of CLient Records
    ClientRecord[] ClientRecords;
    //Mapping that enables ease of traversal of the Client Records
    mapping(address => RecordIndex) public ClientRecordIndexer;

    address LendingServiceAddress;

    struct ClientRecord {
        bool exists;
        address payable _address;
        string email;
        uint256 underlyingTotalDeposits;
        uint256 underlyingTotalWithdrawn;
        uint256 derivativeBalance;
        uint256 derivativeTotalDeposits;
        uint256 derivativeTotalWithdrawn;
    }

    struct RecordIndex {
        bool exists;
        uint256 index;
    }

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

    constructor(address lendingServiceAddress, address tokenAddress) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        LendingServiceAddress = lendingServiceAddress;
    }

    function withdraw(uint256 derivativeAmount) external {
        address payable recipient = msg.sender;
        _withdraw(recipient, derivativeAmount);
    }

    function withdrawDelegate(
        address payable recipient,
        uint256 derivativeAmount
    ) external onlyOwner {
        _withdraw(recipient, derivativeAmount);
    }

    function _withdraw(address payable recipient, uint256 derivativeAmount)
        internal
    {
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.Withdraw(derivativeAmount);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn = balanceBeforeWithdraw.sub(
            balanceAfterWithdraw
        );

        ClientRecord clientRecord = _updateClientRecordAfterWithdrawal(
            recipient,
            amountOfUnderlyingAssetWithdrawn,
            derivativeAmount
        );
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
        RecordIndex memory recordIndex = ClientRecordIndexer[recipient];
        ClientRecord storage record = ClientRecords[recordIndex.index];

        uint256 derivativeBalance = record.derivativeBalance;

        require(
            derivativeBalance >= derivativeAmount,
            "Withdrawal cannot be processes, reason: Insufficient Balance"
        );
    }

    function deposit(string calldata email) external {
        address payable depositor = msg.sender;
        _deposit(depositor, email);
    }

    function depositDelegate(
        address payable depositorAddress,
        string calldata email
    ) external onlyOwner {
        _deposit(depositorAddress, email);
    }

    function _deposit(address payable depositorAddress, string memory email)
        internal
    {
        address recipient = address(this);
        uint256 amountTransferrable = daiToken.allowance(
            depositorAddress,
            recipient
        );

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful = daiToken.transferFrom(
            depositorAddress,
            recipient,
            amountTransferrable
        );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        daiToken.approve(LendingServiceAddress, amountTransferrable);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(amountTransferrable);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord clientRecord = _updateClientRecordAfterDeposit(
            depositorAddress,
            email,
            amountTransferrable,
            amountOfyDai
        );

        emit DerivativeAssetWithdrawn(
            recipient,
            amountTransferrable,
            amountOfyDai,
            clientRecord.derivativeBalance
        );
    }

    function _updateClientRecordAfterDeposit(
        address payable client,
        string memory email,
        uint256 underlyingAmountDeposited,
        uint256 derivativeAmountDeposited
    ) internal returns (ClientRecord memory) {
        bool exists = ClientRecordIndexer[client].exists;
        if (!exists) {
            uint256 arrayLength = ClientRecords.length;

            ClientRecord memory record = ClientRecord(
                true,
                client,
                email,
                underlyingAmountDeposited,
                underlyingAmountDeposited,
                derivativeAmountDeposited,
                derivativeAmountDeposited,
                0
            );

            record.underlyingTotalDeposits.add(underlyingAmountDeposited);

            record.derivativeTotalDeposits.add(derivativeAmountDeposited);
            record.derivativeBalance.add(derivativeAmountDeposited);

            RecordIndex memory recordIndex = RecordIndex(true, arrayLength);

            ClientRecords.push(record);
            ClientRecordIndexer[client] = recordIndex;
            return record;
        } else {
            RecordIndex memory recordIndex = ClientRecordIndexer[client];

            ClientRecord storage record = ClientRecords[recordIndex.index];

            record.underlyingTotalDeposits.add(underlyingAmountDeposited);

            record.derivativeTotalDeposits.add(derivativeAmountDeposited);
            record.derivativeBalance.add(derivativeAmountDeposited);
            return record;
        }
    }

    function _updateClientRecordAfterWithdrawal(
        address payable client,
        uint256 underlyingAmountWithdrawn,
        uint256 derivativeAmountWithdrawn
    ) internal returns (ClientRecord memory) {
        bool exists = ClientRecordIndexer[client].exists;

        require(exists == true, "User record not found in contract");

        RecordIndex memory recordIndex = ClientRecordIndexer[client];

        ClientRecord storage record = ClientRecords[recordIndex.index];

        record.underlyingTotalWithdrawn.add(underlyingAmountWithdrawn);

        record.derivativeTotalDeposits.add(derivativeAmountWithdrawn);
        record.derivativeBalance.add(derivativeAmountWithdrawn);

        return record;
    }
}
