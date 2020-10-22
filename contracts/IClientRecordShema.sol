pragma solidity ^0.6.6;

interface IClientRecordSchema {
    struct ClientRecord {
        bool exists;
        address payable _address;
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
}
