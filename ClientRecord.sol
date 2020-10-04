pragma solidity ^0.6.0;

import "./IClientRecordSchema.sol";

contract StorageOwners {
    address owner;
    mapping(address => bool) private storageOracles;

    function activateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = true;
    }

    function deactivateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized access to contract");
        _;
    }

    modifier onlyStorageOracle() {
        bool hasAccess = storageOracles[msg.sender];
        require(hasAccess, "unauthorized access to contract");
        _;
    }
}

contract ClientRecord is IClientRecordSchema, StorageOwners {
    // list of CLient Records
    ClientRecord[] ClientRecords;
    //Mapping that enables ease of traversal of the Client Records
    mapping(address => RecordIndex) public ClientRecordIndexer;

    function doesClientRecordExist(address depositor)
        external
        view
        returns (bool)
    {
        RecordIndex memory recordIndex = ClientRecordIndexer[depositor];
        return recordIndex.exists;
    }

    function getRecordIndex(address depositor) external view returns (uint256) {
        RecordIndex memory recordIndex = ClientRecordIndexer[depositor];
        require(recordIndex.exists == true, "member record not found");
        return recordIndex.index;
    }

    function createClientRecord(
        address payable _address,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 derivativeBalance,
        uint256 derivativeTotalDeposits,
        uint256 derivativeTotalWithdrawn
    ) external onlyStorageOracle {
        RecordIndex memory recordIndex = ClientRecordIndexer[_address];
        require(
            recordIndex.exists == false,
            "depositor record alreaddy exists"
        );
        ClientRecord memory clientRecord = ClientRecord(
            true,
            _address,
            underlyingTotalDeposits,
            underlyingTotalWithdrawn,
            derivativeBalance,
            derivativeTotalDeposits,
            derivativeTotalWithdrawn
        );

        recordIndex = RecordIndex(true, ClientRecords.length);
        ClientRecords.push(clientRecord);
        ClientRecordIndexer[_address] = recordIndex;
    }

    function updateClientRecord(
        address payable _address,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 derivativeBalance,
        uint256 derivativeTotalDeposits,
        uint256 derivativeTotalWithdrawn
    ) external onlyStorageOracle {
        RecordIndex memory recordIndex = ClientRecordIndexer[_address];
        require(recordIndex.exists == true, "depositor record not found");
        ClientRecord memory clientRecord = ClientRecord(
            true,
            _address,
            underlyingTotalDeposits,
            underlyingTotalWithdrawn,
            derivativeBalance,
            derivativeTotalDeposits,
            derivativeTotalWithdrawn
        );

        uint256 index = recordIndex.index;

        ClientRecords[index].underlyingTotalDeposits = underlyingTotalDeposits;
        ClientRecords[index]
            .underlyingTotalWithdrawn = underlyingTotalWithdrawn;
        ClientRecords[index].derivativeBalance = derivativeBalance;
        ClientRecords[index].derivativeTotalDeposits = derivativeTotalDeposits;
        ClientRecords[index]
            .derivativeTotalWithdrawn = derivativeTotalWithdrawn;
    }

    function getLengthOfClientRecords() external returns (uint256) {
        return ClientRecords.length;
    }

    function getClientRecordByIndex(uint256 index)
        external
        view
        returns (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        )
    {
        ClientRecord memory clientRecord = ClientRecords[index];
        return (
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }

    function getClientRecordByAddress(address depositor)
        external
        view
        returns (
            address payable _address,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 derivativeBalance,
            uint256 derivativeTotalDeposits,
            uint256 derivativeTotalWithdrawn
        )
    {
        RecordIndex memory recordIndex = ClientRecordIndexer[depositor];
        require(recordIndex.exists == true, "depositor record not found");
        uint256 index = recordIndex.index;

        ClientRecord memory clientRecord = ClientRecords[index];
        return (
            clientRecord._address,
            clientRecord.underlyingTotalDeposits,
            clientRecord.underlyingTotalWithdrawn,
            clientRecord.derivativeBalance,
            clientRecord.derivativeTotalDeposits,
            clientRecord.derivativeTotalWithdrawn
        );
    }
}
