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

contract Cycles is IGroupSchema, GroupStorageOwners {
    // list of Group Cycles
    Cycle[] private Cycles;
    CycleFinancial[] private CycleFinancials;

    //Mapping that enables ease of traversal of the cycle records. Key is cycle id
    mapping(uint256 => RecordIndex) private CycleIndexer;

    //Mapping that enables ease of traversal of cycle records by the group. key is group id
    mapping(uint256 => RecordIndex[]) private GroupCycleIndexer;

    //Mapping that enables ease of traversal of the cycle financials records. Key is cycle id
    mapping(uint256 => RecordIndex) private CycleFinancialsIndexer;

    //Mapping that enables ease of traversal of cycle financials records by the group. key is group id
    mapping(uint256 => RecordIndex[]) private GroupCycleFinancialsIndexer;

    CycleMember[] private CycleMembers;

    //Mapping of a cycle members. key is the cycle id
    mapping(uint256 => RecordIndex[]) private CycleMembersIndexer;
    //Mapping of a cycle members, key is depositor address
    mapping(address => RecordIndex[]) private CycleMembersIndexerByDepositor;
    //Mapping that enables easy traversal of cycle members in a group. outer key is the cycle id, inner key is the member address
    mapping(uint256 => mapping(address => RecordIndex))
        private CycleMembersDeepIndexer;

    uint256 lastCycleId;

    function getCycleInfoByIndex(uint256 cycleId)
        external
        view
        returns (
            uint256 id,
            uint256 groupId,
            uint256 numberOfDepositors,
            uint256 cycleStartTimeStamp,
            uint256 cycleDuration,
            uint256 maximumSlots,
            bool hasMaximumSlots,
            uint256 cycleStakeAmount,
            uint256 totalStakes,
            uint256 stakesClaimed,
            CycleStatus cycleStatus
        )
    {
        Cycle memory cycle = Cycles[index];

        return (
            cycle.id,
            cycle.groupId,
            cycle.numberOfDepositors,
            cycle.cycleStartTimeStamp,
            cycle.cycleDuration,
            cycle.maximumSlots,
            cycle.hasMaximumSlots,
            cycle.cycleStakeAmount,
            cycle.totalStakes,
            cycle.stakesClaimed,
            cycle.cycleStatus
        );
    }

    function getCycleInfoById(uint256 cycleId)
        external
        view
        returns (
            uint256 id,
            uint256 groupId,
            uint256 numberOfDepositors,
            uint256 cycleStartTimeStamp,
            uint256 cycleDuration,
            uint256 maximumSlots,
            bool hasMaximumSlots,
            uint256 cycleStakeAmount,
            uint256 totalStakes,
            uint256 stakesClaimed,
            CycleStatus cycleStatus
        )
    {
        uint256 index = _getCycleIndex(cycleId);

        Cycle memory cycle = Cycles[index];

        return (
            cycle.id,
            cycle.groupId,
            cycle.numberOfDepositors,
            cycle.cycleStartTimeStamp,
            cycle.cycleDuration,
            cycle.maximumSlots,
            cycle.hasMaximumSlots,
            cycle.cycleStakeAmount,
            cycle.totalStakes,
            cycle.stakesClaimed,
            cycle.cycleStatus
        );
    }

    function getCycleFinancialsByIndex(uint256 index)
        external
        view
        returns (
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance
        )
    {
        CycleFinancial memory cycleFinancial = CycleFinancials[index];

        return (
            cycleFinancial.underlyingTotalDeposits,
            cycleFinancial.underlyingTotalWithdrawn,
            cycleFinancial.underlyingBalance,
            cycleFinancial.derivativeBalance
        );
    }

    function getCycleFinancialsByCycleId(uint256 cycleId)
        external
        view
        returns (
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance
        )
    {
        uint256 index = _getCycleFinancialIndex(cycleId);
        CycleFinancial memory cycleFinancial = CycleFinancials[index];

        return (
            cycleFinancial.underlyingTotalDeposits,
            cycleFinancial.underlyingTotalWithdrawn,
            cycleFinancial.underlyingBalance,
            cycleFinancial.derivativeBalance
        );
    }

    function getCycleMember(uint256 index)
        external
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        )
    {
        CycleMember memory cycleMember = _getCycleMember(index);

        return (
            cycleMember.cycleId,
            cycleMember.groupId,
            cycleMember._address,
            cycleMember.totalLiquidityAsPenalty,
            cycleMember.numberOfCycleStakes,
            cycleMember.stakesClaimed,
            cycleMember.hasWithdrawn
        );
    }

    function createCycleMember(
        uint256 cycleId,
        uint256 groupId,
        address payable depositor,
        uint256 totalLiquidityAsPenalty,
        uint256 numberOfCycleStakes,
        uint256 stakesClaimed,
        bool hasWithdrawn
    ) external {
        bool exist = _doesCycleMemberExist(cycleId, depositor);
        require(exist == false, "Cycle member already exist");

        CycleMember memory cycleMember = CycleMember(
            true,
            cycleId,
            groupId,
            depositor,
            totalLiquidityAsPenalty,
            numberOfCycleStakes,
            stakesClaimed,
            hasWithdrawn
        );
        RecordIndex memory recordIndex = RecordIndex(true, CycleMembers.length);

        CycleMembers.push(cycleMember);
        CycleIndexer[lastCycleId] = recordIndex;
        CycleMembersIndexerByDepositor[depositor].push(recordIndex);

        CycleMembersDeepIndexer[groupId][depositor] = recordIndex;
    }

    function updateCycleMember(
        uint256 cycleId,
        address payable depositor,
        uint256 totalLiquidityAsPenalty,
        uint256 numberOfCycleStakes,
        uint256 stakesClaimed,
        bool hasWithdrawn
    ) external {
        CycleMember memory cycleMember = _getCycleMember(cycleId, depositor);
        cycleMember._address = depositor;
        cycleMember.totalLiquidityAsPenalty = totalLiquidityAsPenalty;
        cycleMember.numberOfCycleStakes = numberOfCycleStakes;
        cycleMember.stakesClaimed = stakesClaimed;
        cycleMember.hasWithdrawn = hasWithdrawn;

        _updateCycleMember(cycleMember);
    }

    function createCycle(
        uint256 groupId,
        uint256 numberOfDepositors,
        uint256 startTimeStamp,
        uint256 duration,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 cycleStakeAmount,
        uint256 totalStakes,
        uint256 stakesClaimed,
        CycleStatus cycleStatus
    ) external {
        lastCycleId += 1;
        Cycle memory cycle = Cycle(
            true,
            lastCycleId,
            groupId,
            numberOfDepositors,
            startTimeStamp,
            duration,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            totalStakes,
            stakesClaimed,
            cycleStatus
        );

        RecordIndex memory recordIndex = RecordIndex(true, Cycles.length);

        Cycles.push(cycle);
        CycleIndexer[lastCycleId] = recordIndex;
        GroupCycleIndexer[cycle.groupId].push(recordIndex);
    }

    function createCycleFinancials(
        uint256 cycleId,
        uint256 groupId,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 underlyingBalance,
        uint256 derivativeBalance
    ) external {
        RecordIndex memory recordIndex = CycleIndexer[cycleId];
        CycleFinancial memory cycleFinancial = CycleFinancial(
            true,
            cycleId,
            underlyingTotalDeposits,
            underlyingTotalWithdrawn,
            underlyingBalance,
            derivativeBalance
        );
        CycleFinancials.push(cycleFinancial);
        CycleFinancialsIndexer[cycleId] = recordIndex;
        GroupCycleFinancialsIndexer[groupId].push(recordIndex);
    }

    function updateCycle(
        uint256 cycleId,
        uint256 numberOfDepositors,
        uint256 startTimeStamp,
        uint256 duration,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 cycleStakeAmount,
        uint256 totalStakes,
        uint256 stakesClaimed,
        CycleStatus cycleStatus
    ) external {
        Cycle memory cycle = _getCycle(cycleId);
        cycle.numberOfDepositors = numberOfDepositors;
        cycle.cycleStartTimeStamp = startTimeStamp;
        cycle.cycleDuration = duration;
        cycle.maximumSlots = maximumSlots;
        cycle.hasMaximumSlots = hasMaximumSlots;
        cycle.cycleStakeAmount = cycleStakeAmount;

        cycle.totalStakes = totalStakes;
        cycle.stakesClaimed = stakesClaimed;
        cycle.cycleStatus = cycleStatus;
        _updateCycle(cycle);
    }

    function updateCycleFinancials(
        uint256 cycleId,
        uint256 underlyingTotalDeposits,
        uint256 underlyingTotalWithdrawn,
        uint256 underlyingBalance,
        uint256 derivativeBalance
    ) external {
        uint256 index = _getCycleFinancialIndex(cycleId);

        CycleFinancial memory cycleFinancial = CycleFinancials[index];
        cycleFinancial.underlyingTotalDeposits = underlyingTotalDeposits;
        cycleFinancial.underlyingTotalWithdrawn = underlyingTotalWithdrawn;
        cycleFinancial.underlyingBalance = underlyingBalance;
        cycleFinancial.derivativeBalance = derivativeBalance;

        _updateCycleFinancial(cycleFinancial);
    }

    function getCycleIndex(uint256 cycleId) external view returns (uint256) {
        uint256 index = _getCycleIndex(cycleId);
        return index;
    }

    function getCycleFinancialIndex(uint256 cycleId)
        external
        view
        returns (uint256)
    {
        uint256 index = _getCycleFinancialIndex(cycleId);
        return index;
    }

    function _getCycleIndex(uint256 cycleId) internal view returns (uint256) {
        bool doesCycleExist = CycleIndexer[cycleId].exists;
        require(doesCycleExist == true, "Cycle not found");

        uint256 index = CycleIndexer[cycleId].index;
        return index;
    }

    function getRecordIndexForCycleMembersIndexerByDepositor(
        uint256 cycleId,
        uint256 recordIndexLocation
    ) external returns (bool, uint256) {

            RecordIndex memory recordIndex
         = CycleMembersIndexer[cycleId][recordIndexLocation];
        return (recordIndex.exists, recordIndex.index);
    }

    function getRecordIndexForCycleMembersIndexer(
        address depositorAddress,
        uint256 recordIndexLocation
    ) external returns (bool, uint256) {

            RecordIndex memory recordIndex
         = CycleMembersIndexerByDepositor[depositorAddress][recordIndexLocation];
        return (recordIndex.exists, recordIndex.index);
    }

    function getRecordIndexLengthForCycleMembers(uint256 cycleId)
        external
        view
        returns (uint256)
    {
        return CycleMembersIndexer[cycleId].length;
    }

    function getRecordIndexLengthForCycleMembersByDepositor(
        address depositorAddress
    ) external view returns (uint256) {
        return CycleMembersIndexerByDepositor[depositorAddress].length;
    }

    function getCycleMemberIndex(uint256 cycleId, address payable memberAddress)
        external
        view
        returns (uint256)
    {
        return _getCycleMemberIndex(cycleId, memberAddress);
    }

    function _getCycleMember(uint256 cycleId, address payable depositor)
        internal
        view
        returns (CycleMember memory)
    {
        uint256 index = _getCycleMemberIndex(cycleId, depositor);
        CycleMember memory cycleMember = _getCycleMember(index);
        return cycleMember;
    }

    function _getCycleMember(uint256 index)
        internal
        view
        returns (CycleMember memory)
    {
        return CycleMembers[index];
    }

    function _getCycleMemberIndex(uint256 cycleId, address payable depositor)
        internal
        view
        returns (uint256)
    {
        bool doesCycleMemberExist = CycleMembersDeepIndexer[cycleId][depositor]
            .exists;
        require(doesCycleMemberExist == true, "Cycle member not found");

        uint256 index = CycleMembersDeepIndexer[cycleId][depositor].index;
        return index;
    }

    function _getCycleFinancialIndex(uint256 cycleId)
        internal
        view
        returns (uint256)
    {
        bool doesCycleFinancialExist = CycleFinancialsIndexer[cycleId].exists;
        require(doesCycleFinancialExist == true, "Cycle financials not found");

        uint256 index = CycleFinancialsIndexer[cycleId].index;
        return index;
    }

    function _updateCycleMember(CycleMember memory cycleMember) internal {
        uint256 index = _getCycleMemberIndex(
            cycleMember.cycleId,
            cycleMember._address
        );
        CycleMembers[index] = cycleMember;
    }

    function _updateCycle(Cycle memory cycle) internal {
        uint256 index = _getCycleIndex(cycle.id);
        Cycles[index] = cycle;
    }

    function _updateCycleFinancial(CycleFinancial memory cycleFinancial)
        internal
    {
        uint256 index = _getCycleIndex(cycleFinancial.cycleId);
        CycleFinancials[index] = cycleFinancial;
    }

    function _getCycle(uint256 cycleId) internal view returns (Cycle memory) {
        uint256 index = _getCycleIndex(cycleId);

        Cycle memory cycle = Cycles[index];
        return cycle;
    }

    function _getCycleFinancial(uint256 cycleId)
        internal
        view
        returns (CycleFinancial memory)
    {
        uint256 index = _getCycleFinancialIndex(cycleId);

        CycleFinancial memory cycleFinancial = CycleFinancials[index];
        return cycleFinancial;
    }

    function doesCycleMemberExist(uint256 cycleId, address depositor)
        external
        view
        returns (bool)
    {
        return _doesCycleMemberExist(cycleId, depositor);
    }

    function _doesCycleMemberExist(uint256 cycleId, address depositor)
        internal
        view
        returns (bool)
    {
        bool exist = CycleMembersDeepIndexer[cycleId][depositor].exists;

        if (exist) return true;
        else return false;
    }
}
