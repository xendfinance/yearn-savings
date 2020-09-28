pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IDaiLendingService.sol";
import "./IERC20.sol";
import "./IGroupSchema.sol";

contract GroupStorageOwners {
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
        require(msg.sender == owner, "unauthorized access to contract");
        _;
    }
}

contract Groups is IGroupSchema, GroupStorageOwners {
    // list of group records
    Group[] Groups;
    //Mapping that enables ease of traversal of the group records
    mapping(uint256 => RecordIndex) private GroupIndexer;

    // Mapping that enables ease of traversal of groups created by an addressor
    mapping(address => RecordIndex[]) private GroupForCreatorIndexer;

    // indexes a group location using the group name
    mapping(string => RecordIndex) private GroupIndexerByName;

    uint256 lastGroupId;

    function createGroup(string calldata name, string calldata symbol)
        external
        onlyStorageOracle
    {
        lastGroupId += 1;
        Group memory group = Group(true, lastGroupId, name, symbol, msg.sender);
        uint256 index = Groups.length;
        RecordIndex memory recordIndex = RecordIndex(true, index);
        Groups.push(group);
        GroupIndexer[lastGroupId] = recordIndex;
        GroupIndexerByName[name] = recordIndex;
        GroupForCreatorIndexer[msg.sender].push(recordIndex);
    }

    function updateGroup(
        uint256 id,
        string calldata name,
        string calldata symbol
    ) external onlyStorageOracle {
        uint256 index = getGroupIndex(id);
        Groups[index].name = name;
        Groups[index].symbol = symbol;
    }

    function doesGroupExist(uint256 groupId) public view returns (bool) {
        bool groupExist = GroupIndexer[groupId].exists;

        if (groupExist) return true;
        else return false;
    }

    function doesGroupExist(string memory groupName)
        public
        view
        returns (bool)
    {
        bool groupExist = GroupIndexerByName[groupName].exists;

        if (groupExist) return true;
        else return false;
    }

    function getGroupIndexer(uint256 groupId)
        external
        view
        returns (bool exist, uint256 index)
    {
        RecordIndex memory recordIndex = GroupIndexer[groupId];
        return (recordIndex.exists, recordIndex.index);
    }

    function getRecordIndexLengthForCreator(address groupCreator)
        external
        view
        returns (uint256)
    {
        return GroupForCreatorIndexer[groupCreator].length;
    }

    function getGroupForCreatorIndexer(
        address groupCreator,
        int256 indexerLocation
    ) external view returns (bool exist, uint256 index) {

            RecordIndex memory recordIndex
         = GroupForCreatorIndexer[groupCreator][index];
        return (recordIndex.exists, recordIndex.index);
    }

    function getGroupIndexerByName(string calldata groupName)
        external
        view
        returns (bool exist, uint256 index)
    {
        RecordIndex memory recordIndex = GroupIndexerByName[groupName];
        return (recordIndex.exists, recordIndex.index);
    }

    function getGroupById(uint256 groupId)
        public
        view
        onlyStorageOracle
        returns (
            uint256,
            string memory,
            string memory,
            address payable
        )
    {
        uint256 index = getGroupIndex(groupId);

        Group storage group = Groups[index];
        return (group.id, group.name, group.symbol, group.creatorAddress);
    }

    function getGroupByIndex(uint256 index)
        public
        view
        onlyStorageOracle
        returns (
            uint256,
            string memory,
            string memory,
            address payable
        )
    {
        uint256 length = Groups.length;
        require(length > index, "Out of range");
        Group storage group = Groups[index];
        return (group.id, group.name, group.symbol, group.creatorAddress);
    }

    function getGroupIndex(uint256 groupId)
        public
        view
        onlyStorageOracle
        returns (uint256)
    {
        bool doesGroupExist = GroupIndexer[groupId].exists;
        require(doesGroupExist == true, "Group not found");
        uint256 index = GroupIndexer[groupId].index;
        return index;
    }
}
