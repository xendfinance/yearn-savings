// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IDaiLendingService.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract XendFinanceGroup_Yearn_V1 is Ownable {
    using SafeMath for uint256;

    using Address for address payable;

    // list of group records
    Group[] Groups;
    //Mapping that enables ease of traversal of the group records
    mapping(uint256 => RecordIndex) public GroupIndexer;

    // Mapping that enables ease of traversal of groups created by an addressor
    mapping(address => RecordIndex[]) public GroupForCreatorIndexer;

    // indexes a group location using the group name
    mapping(string => RecordIndex) public GroupIndexerByName;

    // list of Group Cycles
    Cycle[] Cycles;

    //Mapping that enables ease of traversal of the cycle records. Key is cycle id
    mapping(uint256 => RecordIndex) public CycleIndexer;

    //Mapping that enables ease of traversal of cycle records by the group. key is group id
    mapping(uint256 => RecordIndex[]) public GroupCycleIndexer;

    // list of group records
    Member[] Members;

    //Mapping that enables ease of traversal of the member records. key is the member address
    mapping(address => RecordIndex) public MemberIndexer;

    GroupMember[] GroupMembers;

    //Mapping of a groups members. Key is the group id,
    mapping(uint256 => RecordIndex[]) public GroupMembersIndexer;

    mapping(address => RecordIndex[]) public GroupMembersIndexerByDepositor;

    //Mapping that enables easy traversal of cycle members in a group. outer key is the group id, inner key is the member address
    mapping(uint256 => mapping(address => RecordIndex)) GroupMembersDeepIndexer;

    CycleMember[] CycleMembers;

    //Mapping of a cycle members. key is the cycle id
    mapping(uint256 => RecordIndex[]) public CycleMembersIndexer;

    mapping(address => RecordIndex[]) public CycleMembersIndexerByDepositor;

    //Mapping that enables easy traversal of cycle members in a group. outer key is the cycle id, inner key is the member address
    mapping(uint256 => mapping(address => RecordIndex))
        public CycleMembersDeepIndexer;

    uint256 lastGroupId;
    uint256 lastCycleId;
    //uint lastGroupMemberId;
    //uint lastCycleMemberId;

    address LendingServiceAddress;

    struct Group {
        bool exists;
        uint256 id;
        string name;
        string symbol;
        address payable creatorAddress;
    }

    struct Cycle {
        bool exists;
        uint256 id;
        uint256 groupId;
        uint256 numberOfDepositors;
        uint256 cycleStartTimeStamp;
        uint256 cycleDuration;
        uint256 maximumSlots;
        bool hasMaximumSlots;
        uint256 cycleStakeAmount;
        //total underlying asset deposited into contract
        uint256 underlyingTotalDeposits;
        //total underlying asset that have been withdrawn by cycle members
        uint256 underlyingTotalWithdrawn;
        // underlying amount gotten after lending period has ended and shares have been reedemed for underlying asset;
        uint256 underlyingBalance;
        // lending shares representation of amount deposited in lending protocol
        uint256 derivativeBalance;
        // represents the total stakes of every cycle member deposits
        uint256 totalStakes;
        //represents the total stakes of every cycle member withdrawal
        uint256 stakesClaimed;
        CycleStatus cycleStatus;
    }

    struct Member {
        bool exists;
        address payable _address;
    }

    struct GroupMember {
        bool exists;
        address payable _address;
        uint256 groupId;
    }

    struct CycleMember {
        bool exist;
        uint256 cycleId;
        uint256 groupId;
        address payable _address;
        uint256 totalLiquidityAsPenalty;
        uint256 numberOfCycleStakes;
        uint256 stakesClaimed;
        bool hasWithdrawn;
    }

    struct RecordIndex {
        bool exists;
        uint256 index;
    }

    struct CycleDepositResult {
        Group group;
        Member member;
        GroupMember groupMember;
        CycleMember cycleMember;
        uint256 underlyingAmountDeposited;
    }

    enum CycleStatus {NOT_STARTED, ONGOING, ENDED}

    event UnderlyingAssetDeposited(
        uint256 cycleId,
        address payable memberAddress,
        uint256 groupId,
        uint256 underlyingAmount,
        address tokenAddress
    );

    event DerivativeAssetWithdrawn(
        uint256 cycleId,
        address payable memberAddress,
        uint256 underlyingAmount,
        address tokenAddress
    );

    event GroupCreated(uint256 groupId, address payable groupCreator);

    event CycleCreated(
        uint256 cycleId,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 stakeAmount,
        uint256 expectedCycleStartTimeStamp,
        uint256 cycleDuration
    );

    event MemberJoinedCycle(
        uint256 cycleId,
        address payable memberAddress,
        uint256 groupId
    );

    event MemberJoinedGroup(address payable memberAddress, uint256 groupId);

    event CycleStartedEvent(
        uint256 indexed cycleId,
        uint256 indexed blockTimeStamp,
        uint256 blockNumber,
        uint256 totalDerivativeAmount,
        uint256 totalUnderlyingAmount
    );

    IDaiLendingService lendingService;
    IERC20 daiToken;
    address LendingAdapterAddress;
    address TokenAddress;

    constructor(
        address lendingAdapterAddress,
        address lendingServiceAddress,
        address tokenAddress
    ) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        LendingAdapterAddress = lendingAdapterAddress;
        TokenAddress = tokenAddress;
    }

    function withdrawFromCycle(uint256 cycleId) external {
        address payable memberAddress = msg.sender;
        _withdrawFromCycle(cycleId, memberAddress);
    }

    function withdrawFromCycle(uint256 cycleId, address payable memberAddress)
        external
    {
        _withdrawFromCycle(cycleId, memberAddress);
    }

    function _withdrawFromCycle(uint256 cycleId, address payable memberAddress)
        internal
    {
        bool isCycleReadyToBeEnded = _isCycleReadyToBeEnded(cycleId);

        if (isCycleReadyToBeEnded) {
            _endCycle(cycleId);
        }

        Cycle memory cycle = _getCycle(cycleId);


            bool memberExistInCycle
         = CycleMembersDeepIndexer[cycleId][memberAddress].exists;

        require(
            memberExistInCycle == true,
            "You are not a member of this cycle"
        );

        uint256 index = CycleMembersDeepIndexer[cycleId][memberAddress].index;

        CycleMember memory cycleMember = CycleMembers[index];

        require(
            cycleMember.hasWithdrawn == false,
            "Funds have already been withdrawn"
        );

        //how many stakes a cycle member has
        uint256 stakesHoldings = cycleMember.numberOfCycleStakes;

        //getting the underlying asset amount that backs 1 stake amount
        uint256 underlyingAssetForStake = cycle.underlyingBalance.div(
            cycle.totalStakes
        );

        //cycle members stake amount worth
        uint256 totalCycleMemberAssetAmount = underlyingAssetForStake.mul(
            stakesHoldings
        );

        cycle.stakesClaimed += stakesHoldings;
        cycle.underlyingTotalWithdrawn -= totalCycleMemberAssetAmount;

        cycleMember.hasWithdrawn = true;
        cycleMember.stakesClaimed += stakesHoldings;

        _updateCycle(cycle);
        _updateCycleMember(cycleMember);

        emit DerivativeAssetWithdrawn(
            cycleId,
            memberAddress,
            totalCycleMemberAssetAmount,
            TokenAddress
        );
    }

    function activateCycle(uint256 cycleId) external onlyCycleCreator(cycleId) {
        Cycle memory cycle = _getCycle(cycleId);
        require(
            cycle.cycleStatus == CycleStatus.NOT_STARTED,
            "Cannot activate a cycle not in the 'NOT_STARTED' state"
        );

        uint256 derivativeAmount = lendCycleDeposit(cycle);

        _startCycle(cycle);
        uint256 blockNumber = block.number;
        uint256 blockTimestamp = now;

        emit CycleStartedEvent(
            cycleId,
            blockTimestamp,
            blockNumber,
            derivativeAmount,
            cycle.underlyingTotalDeposits
        );
    }

    function endCycle(uint256 cycleId) external {
        _endCycle(cycleId);
    }

    function _endCycle(uint256 cycleId) internal {
        bool isCycleReadyToBeEnded = _isCycleReadyToBeEnded(cycleId);
        require(isCycleReadyToBeEnded == true, "Cycle is still ongoing");

        Cycle memory cycle = _getCycle(cycleId);

        uint256 underlyingAmount = redeemLending(cycle);

        cycle.underlyingBalance = underlyingAmount;
        cycle.cycleStatus = CycleStatus.ENDED;

        _updateCycle(cycle);
    }

    function _isCycleReadyToBeEnded(uint256 cycleId)
        internal
        view
        returns (bool)
    {
        Cycle memory cycle = _getCycle(cycleId);

        if (cycle.cycleStatus != CycleStatus.ONGOING) return false;

        uint256 currentTimeStamp = now;
        uint256 cycleEndTimeStamp = cycle.cycleStartTimeStamp +
            cycle.cycleDuration;

        if (cycleEndTimeStamp >= currentTimeStamp) return true;
        else return false;
    }

    function lendCycleDeposit(Cycle memory cycle) internal returns (uint256) {
        daiToken.approve(LendingAdapterAddress, cycle.underlyingTotalDeposits);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(cycle.underlyingTotalDeposits);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        return amountOfyDai;
    }

    function redeemLending(Cycle memory cycle) internal returns (uint256) {
        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.Withdraw(cycle.derivativeBalance);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn = balanceBeforeWithdraw.sub(
            balanceAfterWithdraw
        );

        return amountOfUnderlyingAssetWithdrawn;
    }

    function createGroup(string calldata name, string calldata symbol)
        external
    {
        lastGroupId += 1;
        Group memory group = Group(true, lastGroupId, name, symbol, msg.sender);

        uint256 index = Groups.length;
        RecordIndex memory recordIndex = RecordIndex(true, index);

        Groups.push(group);
        GroupIndexer[lastGroupId] = recordIndex;
        GroupIndexerByName[name] = recordIndex;

        emit GroupCreated(group.id, msg.sender);
    }

    function createCycle(
        uint256 groupId,
        uint256 startTimeStamp,
        uint256 duration,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 cycleStakeAmount
    ) external onlyGroupCreator(groupId) {
        _validateCycleCreationActionValid(
            groupId,
            maximumSlots,
            hasMaximumSlots
        );

        lastCycleId += 1;
        Cycle memory cycle = Cycle(
            true,
            lastCycleId,
            groupId,
            0,
            startTimeStamp,
            duration,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            0,
            0,
            0,
            0,
            0,
            0,
            CycleStatus.NOT_STARTED
        );

        uint256 index = Cycles.length;

        RecordIndex memory recordIndex = RecordIndex(true, index);

        Cycles.push(cycle);
        CycleIndexer[lastCycleId] = recordIndex;

        emit CycleCreated(
            cycle.id,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            startTimeStamp,
            duration
        );
    }

    function joinCycle(uint256 cycleId, uint256 numberOfStakes) external {
        address payable depositorAddress = msg.sender;
        _joinCycle(cycleId, numberOfStakes, depositorAddress);
    }

    function joinCycleDelegate(
        uint256 cycleId,
        uint256 numberOfStakes,
        address payable depositorAddress
    ) external {
        _joinCycle(cycleId, numberOfStakes, depositorAddress);
    }

    function _joinCycle(
        uint256 cycleId,
        uint256 numberOfStakes,
        address payable depositorAddress
    ) internal {
        Group memory group = _getCycleGroup(cycleId);


            bool didCycleMemberExistBeforeNow
         = CycleMembersDeepIndexer[cycleId][depositorAddress].exists;
        bool didGroupMemberExistBeforeNow = GroupMembersDeepIndexer[group
            .id][depositorAddress]
            .exists;

        Cycle memory cycle = _getCycle(cycleId);

        CycleDepositResult memory result = _addDepositorToCycle(
            cycleId,
            cycle.cycleStakeAmount,
            numberOfStakes,
            depositorAddress
        );

        _updateCycleStakeDeposit(cycle, numberOfStakes);

        emit UnderlyingAssetDeposited(
            cycle.id,
            depositorAddress,
            result.group.id,
            result.underlyingAmountDeposited,
            TokenAddress
        );

        if (!didCycleMemberExistBeforeNow) {
            cycle.numberOfDepositors += 1;
            _updateCycle(cycle);

            emit MemberJoinedCycle(cycleId, depositorAddress, result.group.id);
        }

        if (!didGroupMemberExistBeforeNow) {
            emit MemberJoinedGroup(depositorAddress, result.group.id);
        }
    }

    function _addDepositorToCycle(
        uint256 cycleId,
        uint256 cycleAmountForStake,
        uint256 numberOfStakes,
        address payable depositorAddress
    ) internal returns (CycleDepositResult memory) {
        Group memory group = _getCycleGroup(cycleId);
        Member memory member = _createMemberIfNotExist(depositorAddress);
        GroupMember memory groupMember = _createGroupMemberIfNotExist(
            depositorAddress,
            group.id
        );
        CycleMember memory cycleMember = _createCycleMemberIfNotExist(
            depositorAddress,
            cycleId,
            group.id
        );

        uint256 underlyingAmount = _processMemberDeposit(
            numberOfStakes,
            cycleAmountForStake,
            depositorAddress
        );

        cycleMember = _saveMemberDeposit(cycleMember, underlyingAmount);

        CycleDepositResult memory result = CycleDepositResult(
            group,
            member,
            groupMember,
            cycleMember,
            underlyingAmount
        );

        return result;
    }

    function _updateCycleStakeDeposit(
        Cycle memory cycle,
        uint256 numberOfCycleStakes
    ) internal {
        cycle.totalStakes += numberOfCycleStakes;
        cycle.underlyingTotalDeposits += cycle.cycleStakeAmount.mul(
            numberOfCycleStakes
        );
        _updateCycle(cycle);
    }

    function _processMemberDeposit(
        uint256 numberOfStakes,
        uint256 amountForStake,
        address payable depositorAddress
    ) internal returns (uint256 underlyingAmount) {
        uint256 expectedAmount = numberOfStakes.mul(amountForStake);

        address recipient = address(this);
        uint256 amountTransferrable = daiToken.allowance(
            depositorAddress,
            recipient
        );

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        require(
            amountTransferrable >= expectedAmount,
            "Token allowance does not cover stake claim"
        );

        bool isSuccessful = daiToken.transferFrom(
            depositorAddress,
            recipient,
            expectedAmount
        );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        return expectedAmount;
    }

    function _createMemberIfNotExist(address payable depositor)
        internal
        returns (Member memory)
    {
        Member memory member = _getMember(depositor, false);
        return member;
    }

    function _createGroupMemberIfNotExist(
        address payable depositor,
        uint256 groupId
    ) internal returns (GroupMember memory) {
        GroupMember memory groupMember = _getGroupMember(
            depositor,
            groupId,
            false
        );
        return groupMember;
    }

    function _createCycleMemberIfNotExist(
        address payable depositor,
        uint256 cycleId,
        uint256 groupId
    ) internal returns (CycleMember memory) {
        CycleMember memory cycleMember = _getCycleMember(
            depositor,
            cycleId,
            groupId,
            false
        );
        return cycleMember;
    }

    function _saveMemberDeposit(
        CycleMember memory cycleMember,
        uint256 numberOfCycleStakes
    ) internal returns (CycleMember memory) {
        uint256 index = CycleMembersDeepIndexer[cycleMember.cycleId][cycleMember
            ._address]
            .index;
        cycleMember.numberOfCycleStakes += numberOfCycleStakes;
        _updateCycleMember(cycleMember);
        return cycleMember;
    }

    function _getMember(address payable depositor, bool throwOnNotFound)
        internal
        returns (Member memory)
    {
        bool memberExists = MemberIndexer[depositor].exists;
        if (throwOnNotFound) require(memberExists == true, "Member not found");

        if (!memberExists) {
            Member memory member = Member(true, depositor);
            uint256 index = Members.length;

            RecordIndex memory recordIndex = RecordIndex(true, index);

            MemberIndexer[depositor] = recordIndex;
            Members.push(member);
            return member;
        } else {
            uint256 index = MemberIndexer[depositor].index;
            return Members[index];
        }
    }

    function _getCycleMember(
        address payable depositor,
        uint256 cycleId,
        uint256 groupId,
        bool throwOnNotFound
    ) internal returns (CycleMember memory) {
        bool cycleMemberExists = CycleMembersDeepIndexer[cycleId][depositor]
            .exists;

        if (throwOnNotFound)
            require(cycleMemberExists == true, "Member not found");

        if (!cycleMemberExists) {
            CycleMember memory cycleMember = CycleMember(
                true,
                cycleId,
                groupId,
                depositor,
                0,
                0,
                0,
                false
            );
            uint256 index = CycleMembers.length;

            RecordIndex memory recordIndex = RecordIndex(true, index);

            CycleMembersDeepIndexer[cycleId][depositor] = recordIndex;
            CycleMembersIndexer[cycleId].push(recordIndex);
            CycleMembersIndexerByDepositor[depositor].push(recordIndex);

            CycleMembers.push(cycleMember);
            return cycleMember;
        } else {
            uint256 index = CycleMembersDeepIndexer[cycleId][depositor].index;
            CycleMember memory cycleMember = CycleMembers[index];
            return cycleMember;
        }
    }

    function _getGroupMember(
        address payable depositor,
        uint256 groupId,
        bool throwOnNotFound
    ) internal returns (GroupMember memory) {
        bool groupMemberExists = GroupMembersDeepIndexer[groupId][depositor]
            .exists;

        if (throwOnNotFound)
            require(groupMemberExists == true, "Member not found");

        if (!groupMemberExists) {
            GroupMember memory groupMember = GroupMember(
                true,
                depositor,
                groupId
            );
            uint256 index = GroupMembers.length;

            RecordIndex memory recordIndex = RecordIndex(true, index);

            GroupMembersDeepIndexer[groupId][depositor] = recordIndex;
            GroupMembersIndexer[groupId].push(recordIndex);
            GroupMembersIndexerByDepositor[depositor].push(recordIndex);

            GroupMembers.push(groupMember);
            return groupMember;
        } else {
            uint256 index = GroupMembersDeepIndexer[groupId][depositor].index;
            GroupMember memory groupMember = GroupMembers[index];
            return groupMember;
        }
    }

    function _startCycle(Cycle memory cycle) internal {
        cycle.cycleStatus = CycleStatus.ONGOING;
        _updateCycle(cycle);
    }

    function _endCycle(Cycle memory cycle) internal {
        cycle.cycleStatus = CycleStatus.ENDED;
        _updateCycle(cycle);
    }

    function _updateCycle(Cycle memory cycle) internal {
        uint256 index = _getCycleIndex(cycle.id);
        Cycles[index] = cycle;
    }

    function _updateGroup(Group memory group) internal {
        uint256 index = _getGroupIndex(group.id);
        Groups[index] = group;
    }

    function _updateCycleMember(CycleMember memory cycleMember) internal {
        uint256 index = _getCycleMemberIndex(
            cycleMember.cycleId,
            cycleMember._address
        );
        CycleMembers[index] = cycleMember;
    }

    function _validateCycleCreationActionValid(
        uint256 groupId,
        uint256 maximumsSlots,
        bool hasMaximumSlots
    ) internal {
        bool doesGroupExist = doesGroupExist(groupId);

        require(doesGroupExist == true, "Group not found");

        require(
            hasMaximumSlots == true && maximumsSlots == 0,
            "Maximum slot settings cannot be empty"
        );
    }

    function doesGroupExist(uint256 groupId) internal view returns (bool) {
        return _doesGroupExist(groupId);
    }

    function doesGroupNameExist(uint256 groupName)
        internal
        view
        returns (bool)
    {
        return _doesGroupExist(groupName);
    }

    function _doesGroupExist(uint256 groupId) internal view returns (bool) {
        bool groupExist = GroupIndexer[groupId].exists;

        if (groupExist) return true;
        else return false;
    }

    function _doesGroupExist(string memory groupName)
        internal
        view
        returns (bool)
    {
        bool groupExist = GroupIndexerByName[groupName].exists;

        if (groupExist) return true;
        else return false;
    }

    function _getGroup(uint256 groupId) internal view returns (Group memory) {
        uint256 index = _getGroupIndex(groupId);

        Group memory group = Groups[index];
        return group;
    }

    function _getCycleGroup(uint256 cycleId)
        internal
        view
        returns (Group memory)
    {
        uint256 index = _getCycleIndex(cycleId);

        Cycle memory cycle = Cycles[index];

        return _getGroup(cycle.groupId);
    }

    function _getCycle(uint256 cycleId) internal view returns (Cycle memory) {
        uint256 index = _getCycleIndex(cycleId);

        Cycle memory cycle = Cycles[index];
        return cycle;
    }

    function _getTrackedGroup(uint256 groupId)
        internal
        view
        returns (Group memory)
    {
        uint256 index = _getGroupIndex(groupId);

        Group storage group = Groups[index];
        return group;
    }

    function _getGroupIndex(uint256 groupId) internal view returns (uint256) {
        bool doesGroupExist = GroupIndexer[groupId].exists;
        require(doesGroupExist == true, "Group not found");

        uint256 index = GroupIndexer[groupId].index;
        return index;
    }

    function _getCycleIndex(uint256 cycleId) internal view returns (uint256) {
        bool doesCycleExist = CycleIndexer[cycleId].exists;
        require(doesCycleExist == true, "Cycle not found");

        uint256 index = CycleIndexer[cycleId].index;
        return index;
    }

    function _getCycleMemberIndex(
        uint256 cycleId,
        address payable memberAddress
    ) internal view returns (uint256) {

            bool doesCycleMemberExist
         = CycleMembersDeepIndexer[cycleId][memberAddress].exists;
        require(doesCycleMemberExist == true, "Cycle not found");

        uint256 index = CycleMembersDeepIndexer[cycleId][memberAddress].index;
        return index;
    }

    modifier onlyGroupCreator(uint256 groupId) {
        Group memory group = _getGroup(groupId);

        require(
            msg.sender == group.creatorAddress,
            "nauthorized access to contract"
        );
        _;
    }

    modifier onlyCycleCreator(uint256 cycleId) {
        Group memory group = _getCycleGroup(cycleId);

        require(
            msg.sender == group.creatorAddress,
            "nauthorized access to contract"
        );
        _;
    }
}
