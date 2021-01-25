pragma solidity ^0.6.0;


import "./IClientRecordShema.sol";
import "./SafeMath.sol";
import "./StorageOwners.sol";
pragma experimental ABIEncoderV2;

contract ClientRecord is IClientRecordSchema, StorageOwners {
    
    using SafeMath for uint256;
    
    
    
    FixedDepositRecord[] fixedDepositRecords;
    
    mapping(uint => FixedDepositRecord) DepositRecordMapping;
    
    
    mapping (address => mapping(uint => FixedDepositRecord)) DepositRecordToDepositorMapping; //depositor address to depositor cycle mapping
    
     mapping(address=>uint) DepositorToDepositorRecordIndexMapping; //  This tracks the number of records by index created by a depositor

    mapping(address=>mapping(uint=>uint)) DepositorToRecordIndexToRecordIDMapping; //  This maps the depositor to the record index and then to the record ID
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
    
     function GetRecordIndexFromDepositor(address member) external view returns(uint){

        return DepositorToDepositorRecordIndexMapping[member];
    }
    
     function GetRecordIdFromRecordIndexAndDepositorRecord(uint recordIndex, address depositor) external view returns(uint){

      mapping(uint=>uint) storage depositorCreatedRecordIndexToRecordId = DepositorToRecordIndexToRecordIDMapping[depositor];

      return depositorCreatedRecordIndexToRecordId[recordIndex];
    }
    
     function CreateDepositRecordMapping(uint recordId, uint amount, uint lockPeriodInSeconds,uint depositDateInSeconds, address payable depositor, bool hasWithdrawn) external onlyStorageOracle  {
         
         FixedDepositRecord storage _fixedDeposit = DepositRecordMapping[recordId];

        _fixedDeposit.recordId = recordId;
        _fixedDeposit.amount = amount;
        _fixedDeposit.lockPeriodInSeconds = lockPeriodInSeconds;
        _fixedDeposit.depositDateInSeconds = depositDateInSeconds;
        _fixedDeposit.hasWithdrawn = hasWithdrawn;
        _fixedDeposit.depositorId = depositor;
        
        fixedDepositRecords.push(_fixedDeposit);


    }
    
    // function _UpdateDepositRecordAfterWithdrawal(uint recordId, uint amount, uint lockPeriodInSeconds, uint depositDateInSeconds, address depositor, bool hasWithdrawn) internal returns(FixedDepositRecord memory) {
    //     FixedDepositRecord storage record = DepositRecordMapping[recordId];
    //     record.recordId = recordId;
    //     record.amount = amount;
    //     record.lockPeriodInSeconds = lockPeriodInSeconds;
    //     record.depositDateInSeconds = depositDateInSeconds;
    //     record.depositorId = depositor;
    //     record.hasWithdrawn = hasWithdrawn;
    //     return record;
    // }
    
    function GetRecordById(uint depositRecordId) external view returns(uint recordId, address payable depositorId, uint amount, uint depositDateInSeconds, uint lockPeriodInSeconds, bool hasWithdrawn) {
        
        FixedDepositRecord memory records = DepositRecordMapping[depositRecordId];
        
        return(records.recordId, records.depositorId, records.amount, records.depositDateInSeconds, records.lockPeriodInSeconds, records.hasWithdrawn);
    }
    
    function GetRecords() external view returns (FixedDepositRecord [] memory) {
        return fixedDepositRecords;
    }
    
     function CreateDepositorToDepositRecordIndexToRecordIDMapping(address payable depositor, uint recordId) external onlyStorageOracle {
      
      DepositorToDepositorRecordIndexMapping[depositor] = DepositorToDepositorRecordIndexMapping[depositor].add(1);

      uint DepositorCreatedRecordIndex = DepositorToDepositorRecordIndexMapping[depositor];
      mapping(uint=>uint) storage depositorCreatedRecordIndexToRecordId = DepositorToRecordIndexToRecordIDMapping[depositor];
      depositorCreatedRecordIndexToRecordId[DepositorCreatedRecordIndex] = recordId;
    }
    
    function CreateDepositorAddressToDepositRecordMapping (address payable depositor, uint recordId, uint amountDeposited, uint lockPeriodInSeconds, uint depositDateInSeconds, bool hasWithdrawn) external onlyStorageOracle {
        mapping(uint => FixedDepositRecord) storage depositorAddressMapping = DepositRecordToDepositorMapping[depositor];
        
        depositorAddressMapping[recordId].recordId = recordId;
        depositorAddressMapping[recordId].depositorId = depositor;
        depositorAddressMapping[recordId].amount = amountDeposited;
        depositorAddressMapping[recordId].depositDateInSeconds = depositDateInSeconds;
        depositorAddressMapping[recordId].lockPeriodInSeconds = lockPeriodInSeconds;
        depositorAddressMapping[recordId].hasWithdrawn = hasWithdrawn;
        
    }
}
