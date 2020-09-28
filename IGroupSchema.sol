pragma solidity ^0.6.6;

interface IGroupSchema {
    struct Group {
        bool exists;
        uint256 id;
        string name;
        string symbol;
        address payable creatorAddress;
    }

    struct RecordIndex {
        bool exists;
        uint256 index;
    }
}
