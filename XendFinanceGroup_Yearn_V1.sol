// SPDX-License-Identifier: MIT
//pragma experimental ABIEncoderV2;

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IGroups.sol";
import "./ICycles.sol";
import "./IGroupSchema.sol";
import "./IDaiLendingService.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract XendFinanceGroup_Yearn_V1 is IGroupSchema, Ownable {
    using SafeMath for uint256;

    using Address for address payable;

    struct CycleDepositResult {
        Group group;
        Member member;
        GroupMember groupMember;
        CycleMember cycleMember;
        uint256 underlyingAmountDeposited;
    }

    event UnderlyingAssetDeposited(
        uint256 indexed cycleId,
        address payable indexed memberAddress,
        uint256 groupId,
        uint256 underlyingAmount,
        address indexed tokenAddress
    );

    event DerivativeAssetWithdrawn(
        uint256 indexed cycleId,
        address payable indexed memberAddress,
        uint256 underlyingAmount,
        address tokenAddress
    );

    event GroupCreated(
        uint256 indexed groupId,
        address payable indexed groupCreator
    );

    event CycleCreated(
        uint256 indexed cycleId,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 stakeAmount,
        uint256 expectedCycleStartTimeStamp,
        uint256 cycleDuration
    );

    event MemberJoinedCycle(
        uint256 indexed cycleId,
        address payable indexed memberAddress,
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
    IGroups groupStorage;
    ICycles cycleStorage;

    address LendingAdapterAddress;
    address TokenAddress;

    constructor(
        address lendingAdapterAddress,
        address lendingServiceAddress,
        address tokenAddress,
        address groupStorageAddress,
        address cycleStorageAddress
    ) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        LendingAdapterAddress = lendingAdapterAddress;
        TokenAddress = tokenAddress;
        groupStorage = IGroups(groupStorageAddress);
        cycleStorage = ICycles(cycleStorageAddress);
    }

    function getRecordIndexLengthForCycleMembers(uint256 cycleId)
        external
        view
        returns (uint256)
    {
        return cycleStorage.getRecordIndexLengthForCycleMembers(cycleId);
    }

    function getRecordIndexLengthForCycleMembersByDepositor(
        address depositorAddress
    ) external view returns (uint256) {
        return
            cycleStorage.getRecordIndexLengthForCycleMembersByDepositor(
                depositorAddress
            );
    }

    function getRecordIndexLengthForGroupMembers(uint256 groupId)
        external
        view
        returns (uint256)
    {
        return groupStorage.getRecordIndexLengthForGroupMembersIndexer(groupId);
    }

    function getRecordIndexLengthForGroupMembersByDepositor(
        address depositorAddress
    ) external view returns (uint256) {
        return
            groupStorage.getRecordIndexLengthForGroupMembersIndexerByDepositor(
                depositorAddress
            );
    }

    function getRecordIndexLengthForGroupCycles(uint256 groupId)
        external
        view
        returns (uint256)
    {
        return cycleStorage.getRecordIndexLengthForGroupCycleIndexer(groupId);
    }

    function getRecordIndexLengthForCreator(address groupCreator)
        external
        view
        returns (uint256)
    {
        return groupStorage.getRecordIndexLengthForCreator(groupCreator);
    }

    function getSecondsLeftForCycleToEnd(uint256 cycleId)
        external
        view
        returns (uint256)
    {
        Cycle memory cycle = _getCycleById(cycleId);
        require(cycle.cycleStatus == CycleStatus.ONGOING);
        uint256 cycleEndTimeStamp = cycle.cycleStartTimeStamp +
            cycle.cycleDuration;

        if (cycleEndTimeStamp >= now) return cycleEndTimeStamp - now;
        else return 0;
    }

    function getSecondsLeftForCycleToStart(uint256 cycleId)
        external
        view
        returns (uint256)
    {
        Cycle memory cycle = _getCycleById(cycleId);
        require(cycle.cycleStatus == CycleStatus.NOT_STARTED);

        if (cycle.cycleStartTimeStamp >= now)
            return cycle.cycleStartTimeStamp - now;
        else return 0;
    }

    function getCycleFinancials(uint256 index)
        external
        view
        returns (
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance
        )
    {
        CycleFinancial memory cycleFinancial = _getCycleFinancialByIndex(index);

        return (
            cycleFinancial.underlyingTotalDeposits,
            cycleFinancial.underlyingTotalWithdrawn,
            cycleFinancial.underlyingBalance,
            cycleFinancial.derivativeBalance
        );
    }

    function getCycleByIndex(uint256 index)
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
        Cycle memory cycle = _getCycleByIndex(index);

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

    function getGroupByIndex(uint256 index)
        external
        view
        returns (
            bool exists,
            uint256 id,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        )
    {
        Group memory group = _getGroupByIndex(index);
        return (
            group.exists,
            group.id,
            group.name,
            group.symbol,
            group.creatorAddress
        );
    }

    function getGroupById(uint256 _id)
        external
        view
        returns (
            bool exists,
            uint256 id,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        )
    {
        Group memory group = _getGroupById(_id);
        return (
            group.exists,
            group.id,
            group.name,
            group.symbol,
            group.creatorAddress
        );
    }

    function getCycleMember(uint256 index)
        external
        view
        returns (
            bool exist,
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
            cycleMember.exist,
            cycleMember.cycleId,
            cycleMember.groupId,
            cycleMember._address,
            cycleMember.totalLiquidityAsPenalty,
            cycleMember.numberOfCycleStakes,
            cycleMember.stakesClaimed,
            cycleMember.hasWithdrawn
        );
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

        Cycle memory cycle = _getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = _getCycleFinancialByCycleId(
            cycleId
        );

        bool memberExistInCycle = cycleStorage.doesCycleMemberExist(
            cycleId,
            memberAddress
        );

        require(
            memberExistInCycle == true,
            "You are not a member of this cycle"
        );

        CycleMember memory cycleMember = _getCycleMember(
            memberAddress,
            cycle.id,
            cycle.groupId,
            true
        );

        require(
            cycleMember.hasWithdrawn == false,
            "Funds have already been withdrawn"
        );

        //how many stakes a cycle member has
        uint256 stakesHoldings = cycleMember.numberOfCycleStakes;

        //getting the underlying asset amount that backs 1 stake amount
        uint256 underlyingAssetForStake = cycleFinancial.underlyingBalance.div(
            cycle.totalStakes
        );

        //cycle members stake amount worth
        uint256 totalCycleMemberAssetAmount = underlyingAssetForStake.mul(
            stakesHoldings
        );

        cycle.stakesClaimed += stakesHoldings;
        cycleFinancial.underlyingTotalWithdrawn -= totalCycleMemberAssetAmount;

        cycleMember.hasWithdrawn = true;
        cycleMember.stakesClaimed += stakesHoldings;

        _updateCycle(cycle);
        _updateCycleFinancials(cycleFinancial);
        _updateCycleMember(cycleMember);

        emit DerivativeAssetWithdrawn(
            cycleId,
            memberAddress,
            totalCycleMemberAssetAmount,
            TokenAddress
        );
    }

    function activateCycle(uint256 cycleId) external onlyCycleCreator(cycleId) {
        Cycle memory cycle = _getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = _getCycleFinancialByCycleId(
            cycleId
        );

        uint256 currentTimeStamp = now;
        require(
            cycle.cycleStatus == CycleStatus.NOT_STARTED,
            "Cannot activate a cycle not in the 'NOT_STARTED' state"
        );
        require(
            cycle.numberOfDepositors > 0,
            "Cannot activate cycle that has no depositors"
        );

        require(
            cycle.cycleStartTimeStamp <= currentTimeStamp,
            "Cycle start time has not been reached"
        );

        uint256 derivativeAmount = lendCycleDeposit(cycleFinancial);
        cycleFinancial.derivativeBalance = derivativeAmount;
        cycle.cycleStartTimeStamp = currentTimeStamp;
        _startCycle(cycle);
        _updateCycleFinancials(cycleFinancial);

        uint256 blockNumber = block.number;
        uint256 blockTimestamp = currentTimeStamp;

        emit CycleStartedEvent(
            cycleId,
            blockTimestamp,
            blockNumber,
            derivativeAmount,
            cycleFinancial.underlyingTotalDeposits
        );
    }

    function endCycle(uint256 cycleId) external {
        _endCycle(cycleId);
    }

    function _endCycle(uint256 cycleId) internal {
        bool isCycleReadyToBeEnded = _isCycleReadyToBeEnded(cycleId);
        require(isCycleReadyToBeEnded == true, "Cycle is still ongoing");

        Cycle memory cycle = _getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = _getCycleFinancialByCycleId(
            cycleId
        );

        uint256 underlyingAmount = redeemLending(cycleFinancial);

        cycleFinancial.underlyingBalance = underlyingAmount;
        cycle.cycleStatus = CycleStatus.ENDED;

        _updateCycle(cycle);
    }

    function _isCycleReadyToBeEnded(uint256 cycleId)
        internal
        view
        returns (bool)
    {
        Cycle memory cycle = _getCycleById(cycleId);

        if (cycle.cycleStatus != CycleStatus.ONGOING) return false;

        uint256 currentTimeStamp = now;
        uint256 cycleEndTimeStamp = cycle.cycleStartTimeStamp +
            cycle.cycleDuration;

        if (currentTimeStamp >= cycleEndTimeStamp) return true;
        else return false;
    }

    function lendCycleDeposit(CycleFinancial memory cycleFinancial)
        internal
        returns (uint256)
    {
        daiToken.approve(
            LendingAdapterAddress,
            cycleFinancial.underlyingTotalDeposits
        );

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(cycleFinancial.underlyingTotalDeposits);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        return amountOfyDai;
    }

    function redeemLending(CycleFinancial memory cycleFinancial)
        internal
        returns (uint256)
    {
        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.WithdrawBySharesOnly(cycleFinancial.derivativeBalance);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn = balanceBeforeWithdraw.sub(
            balanceAfterWithdraw
        );

        return amountOfUnderlyingAssetWithdrawn;
    }

    function createGroup(string calldata name, string calldata symbol)
        external
    {
        _validateGroupNameAndSymbolIsAvailable(name, symbol);

        uint256 groupId = groupStorage.createGroup(name, symbol, msg.sender);

        emit GroupCreated(groupId, msg.sender);
    }

    function _validateGroupNameAndSymbolIsAvailable(
        string memory name,
        string memory symbol
    ) internal {
        bytes memory nameInBytes = bytes(name); // Uses memory
        bytes memory symbolInBytes = bytes(symbol); // Uses memory

        require(nameInBytes.length > 0, "Group name cannot be empty");
        require(symbolInBytes.length > 0, "Group sysmbol cannot be empty");

        bool nameExist = groupStorage.doesGroupExist(name);

        require(nameExist == false, "Group name has already been used");
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

        uint256 cycleId = cycleStorage.createCycle(
            groupId,
            0,
            startTimeStamp,
            duration,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            0,
            0,
            CycleStatus.NOT_STARTED
        );

        emit CycleCreated(
            cycleId,
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
        require(numberOfStakes > 0, "Minimum stakes that can be acquired is 1");

        Group memory group = _getCycleGroup(cycleId);
        Cycle memory cycle = _getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = _getCycleFinancialByCycleId(
            cycleId
        );

        bool didCycleMemberExistBeforeNow = cycleStorage.doesCycleMemberExist(
            cycleId,
            depositorAddress
        );
        bool didGroupMemberExistBeforeNow = groupStorage.doesGroupMemberExist(
            group.id,
            depositorAddress
        );

        _validateCycleDepositCriteriaAreMet(
            cycle,
            didCycleMemberExistBeforeNow
        );

        CycleDepositResult memory result = _addDepositorToCycle(
            cycleId,
            cycle.cycleStakeAmount,
            numberOfStakes,
            depositorAddress
        );

        _updateCycleStakeDeposit(cycle, cycleFinancial, numberOfStakes);
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

    function _validateCycleDepositCriteriaAreMet(
        Cycle memory cycle,
        bool didCycleMemberExistBeforeNow
    ) internal view {
        bool hasMaximumSlots = cycle.hasMaximumSlots;
        if (hasMaximumSlots == true && didCycleMemberExistBeforeNow == false) {
            require(
                cycle.numberOfDepositors < cycle.maximumSlots,
                "Maximum slot for depositors has been reached"
            );
        }

        require(
            cycle.cycleStatus == CycleStatus.NOT_STARTED,
            "This cycle is not accepting deposits anymore"
        );
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

        cycleMember = _saveMemberDeposit(cycleMember, numberOfStakes);

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
        CycleFinancial memory cycleFinancial,
        uint256 numberOfCycleStakes
    ) internal {
        cycle.totalStakes += numberOfCycleStakes;
        uint256 depositAmount = cycle.cycleStakeAmount.mul(numberOfCycleStakes);
        cycleFinancial.underlyingTotalDeposits += depositAmount;
        _updateCycleFinancials(cycleFinancial);
        _updateTotalTokenDepositAmount(depositAmount);
    }

    function _updateTotalTokenDepositAmount(uint256 amount) internal {
        groupStorage.incrementTokenDeposit(TokenAddress, amount);
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
        cycleMember.numberOfCycleStakes += numberOfCycleStakes;
        _updateCycleMember(cycleMember);
        return cycleMember;
    }

    function _getMember(address payable depositor, bool throwOnNotFound)
        internal
        returns (Member memory)
    {
        bool memberExists = groupStorage.doesMemberExist(depositor);
        if (throwOnNotFound) require(memberExists == true, "Member not found");

        if (!memberExists) {
            groupStorage.createMember(depositor);
        }

        address depositorAddress = groupStorage.getMember(depositor);
        return Member(true, depositor);
    }

    function _getCycleMember(
        address payable depositor,
        uint256 _cycleId,
        uint256 _groupId,
        bool throwOnNotFound
    ) internal returns (CycleMember memory) {
        bool cycleMemberExists = cycleStorage.doesCycleMemberExist(
            _cycleId,
            depositor
        );

        if (throwOnNotFound)
            require(cycleMemberExists == true, "Member not found");

        if (!cycleMemberExists) {
            cycleStorage.createCycleMember(
                _cycleId,
                _groupId,
                depositor,
                0,
                0,
                0,
                false
            );
        }

        uint256 index = cycleStorage.getCycleMemberIndex(_cycleId, depositor);

        return _getCycleMember(index);
    }

    function _getCycleMember(uint256 index)
        internal
        view
        returns (CycleMember memory)
    {
        (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        ) = cycleStorage.getCycleMember(index);

        return
            CycleMember(
                true,
                cycleId,
                groupId,
                _address,
                totalLiquidityAsPenalty,
                numberOfCycleStakes,
                stakesClaimed,
                hasWithdrawn
            );
    }

    function _getGroupMember(
        address payable depositor,
        uint256 groupId,
        bool throwOnNotFound
    ) internal returns (GroupMember memory) {
        bool groupMemberExists = groupStorage.doesGroupMemberExist(
            groupId,
            depositor
        );

        if (throwOnNotFound)
            require(groupMemberExists == true, "Member not found");

        if (!groupMemberExists) {
            groupStorage.createGroupMember(groupId, depositor);
        }

        uint256 index = groupStorage.getGroupMembersDeepIndexer(
            groupId,
            depositor
        );
        (address payable _address, uint256 groupId) = groupStorage
            .getGroupMember(index);

        return GroupMember(true, _address, groupId);
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
        cycleStorage.updateCycle(
            cycle.id,
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

    function _updateCycleFinancials(CycleFinancial memory cycleFinancial)
        internal
    {
        cycleStorage.updateCycleFinancials(
            cycleFinancial.cycleId,
            cycleFinancial.underlyingTotalDeposits,
            cycleFinancial.underlyingTotalWithdrawn,
            cycleFinancial.underlyingBalance,
            cycleFinancial.derivativeBalance
        );
    }

    function _updateGroup(Group memory group) internal {
        uint256 index = _getGroupIndex(group.id);

        (
            uint256 id,
            string memory name,
            string memory symbol,
            address payable groupCreator
        ) = (group.id, group.name, group.symbol, group.creatorAddress);

        groupStorage.updateGroup(id, name, symbol, groupCreator);
    }

    function _updateCycleMember(CycleMember memory cycleMember) internal {
        uint256 index = _getCycleMemberIndex(
            cycleMember.cycleId,
            cycleMember._address
        );
        (
            uint256 cycleId,
            address payable depositor,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        ) = (
            cycleMember.cycleId,
            cycleMember._address,
            cycleMember.totalLiquidityAsPenalty,
            cycleMember.numberOfCycleStakes,
            cycleMember.stakesClaimed,
            cycleMember.hasWithdrawn
        );
        cycleStorage.updateCycleMember(
            cycleId,
            depositor,
            totalLiquidityAsPenalty,
            numberOfCycleStakes,
            stakesClaimed,
            hasWithdrawn
        );
    }

    function _validateCycleCreationActionValid(
        uint256 groupId,
        uint256 maximumsSlots,
        bool hasMaximumSlots
    ) internal {
        bool doesGroupExist = doesGroupExist(groupId);

        require(doesGroupExist == true, "Group not found");

        if (hasMaximumSlots == true) {
            require(maximumsSlots > 0, "Maximum slot settings cannot be empty");
        }
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
        bool groupExist = groupStorage.doesGroupExist(groupId);

        return groupExist;
    }

    function _doesGroupExist(string memory groupName)
        internal
        view
        returns (bool)
    {
        bool groupExist = groupStorage.doesGroupExist(groupName);

        return groupExist;
    }

    function _getGroup(uint256 groupId) internal view returns (Group memory) {
        return _getGroupById(groupId);
    }

    function _getCycleGroup(uint256 cycleId)
        internal
        view
        returns (Group memory)
    {
        Cycle memory cycle = _getCycleById(cycleId);

        return _getGroupById(cycle.groupId);
    }

    function _getCycleById(uint256 cycleId)
        internal
        view
        returns (Cycle memory)
    {
        (
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
        ) = cycleStorage.getCycleInfoById(cycleId);

        Cycle memory cycleInfo = Cycle(
            true,
            id,
            groupId,
            numberOfDepositors,
            cycleStartTimeStamp,
            cycleDuration,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            totalStakes,
            stakesClaimed,
            cycleStatus
        );

        return cycleInfo;
    }

    function _getCycleByIndex(uint256 index)
        internal
        view
        returns (Cycle memory)
    {
        (
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
        ) = cycleStorage.getCycleInfoByIndex(index);

        Cycle memory cycleInfo = Cycle(
            true,
            id,
            groupId,
            numberOfDepositors,
            cycleStartTimeStamp,
            cycleDuration,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            totalStakes,
            stakesClaimed,
            cycleStatus
        );

        return cycleInfo;
    }

    function _getCycleFinancialByCycleId(uint256 cycleId)
        internal
        view
        returns (CycleFinancial memory)
    {
        (
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance
        ) = cycleStorage.getCycleFinancialsByCycleId(cycleId);

        return
            CycleFinancial(
                true,
                cycleId,
                underlyingTotalDeposits,
                underlyingTotalWithdrawn,
                underlyingBalance,
                derivativeBalance
            );
    }

    function _getCycleFinancialByIndex(uint256 index)
        internal
        view
        returns (CycleFinancial memory)
    {
        (
            uint256 cycleId,
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance
        ) = cycleStorage.getCycleFinancialsByIndex(index);

        return
            CycleFinancial(
                true,
                cycleId,
                underlyingTotalDeposits,
                underlyingTotalWithdrawn,
                underlyingBalance,
                derivativeBalance
            );
    }

    /*
    function _getTrackedGroup(uint256 _groupId)
        internal
        view
        returns (Group memory)
    {
        (
            uint256 groupId,
            string memory name ,
            string memory symbol,
            address payable creatorAddress
        ) = groupStorage.getGroupById(_groupId);
        
        Group memory group = Group(true,groupId,name,symbol,creatorAddress);
        return group;
    }
    */

    function _getGroupById(uint256 _groupId)
        internal
        view
        returns (Group memory)
    {
        (
            uint256 groupId,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        ) = groupStorage.getGroupById(_groupId);

        Group memory group = Group(true, groupId, name, symbol, creatorAddress);
        return group;
    }

    function _getGroupByIndex(uint256 index)
        internal
        view
        returns (Group memory)
    {
        (
            uint256 groupId,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        ) = groupStorage.getGroupByIndex(index);

        Group memory group = Group(true, groupId, name, symbol, creatorAddress);
        return group;
    }

    function _getGroupIndex(uint256 groupId) internal view returns (uint256) {
        return groupStorage.getGroupIndex(groupId);
    }

    function _getCycleIndex(uint256 cycleId) internal view returns (uint256) {
        return cycleStorage.getCycleIndex(cycleId);
    }

    function _getCycleMemberIndex(
        uint256 cycleId,
        address payable memberAddress
    ) internal view returns (uint256) {
        return cycleStorage.getCycleMemberIndex(cycleId, memberAddress);
    }

    modifier onlyGroupCreator(uint256 groupId) {
        Group memory group = _getGroup(groupId);

        require(
            msg.sender == group.creatorAddress,
            "unauthorized access to contract"
        );
        _;
    }

    modifier onlyCycleCreator(uint256 cycleId) {
        Group memory group = _getCycleGroup(cycleId);

        require(
            msg.sender == group.creatorAddress,
            "unauthorized access to contract"
        );
        _;
    }
}
