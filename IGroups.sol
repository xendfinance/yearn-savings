pragma solidity ^0.6.6;
import "./IGroupSchema.sol";

interface IGroups is IGroupSchema {
    function createGroup(string calldata name, string calldata symbol) external;

    function updateGroup(
        uint256 id,
        string calldata name,
        string calldata symbol
    ) external;

    function doesGroupExist(uint256 groupId) external view returns (bool);

    function doesGroupExist(string calldata groupName)
        external
        view
        returns (bool);

    function getGroupIndexer(uint256 groupId)
        external
        view
        returns (bool exist, uint256 index);

    function getRecordIndexLengthForCreator(address groupCreator)
        external
        view
        returns (uint256);

    function getGroupForCreatorIndexer(
        address groupCreator,
        int256 indexerLocation
    ) external view returns (bool exist, uint256 index);

    function getGroupIndexerByName(string calldata groupName)
        external
        view
        returns (bool exist, uint256 index);

    function getGroupById(uint256 groupId)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            address payable
        );

    function getGroupByIndex(uint256 index)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            address payable
        );

    function getGroupIndex(uint256 groupId) external view returns (uint256);
}
