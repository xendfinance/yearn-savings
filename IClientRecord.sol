pragma solidity ^0.6.6;
import "./IClientRecordSchema.sol";

interface IClientRecord is IClientRecordSchema {
    function doesClientRecordExist(address depositor)
        external
        view
        returns (bool);

    function getRecordIndex(address depositor) external view returns (uint256);

    function createClientRecord(
        address payable _address,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 derivativeBalance,
        uint256 derivativeTotalDeposits,
        uint256 derivativeTotalWithdrawn
    ) external;

    function updateClientRecord(
        address payable _address,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 derivativeBalance,
        uint256 derivativeTotalDeposits,
        uint256 derivativeTotalWithdrawn
    ) external;

    function getLengthOfClientRecords() external view returns (uint256);

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
        );

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
        );

    function activateStorageOracle(address oracle) external;

    function deactivateStorageOracle(address oracle) external;

    function reAssignStorageOracle(address newOracle) external;
}
