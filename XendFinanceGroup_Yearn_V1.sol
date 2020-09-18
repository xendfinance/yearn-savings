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
    mapping(uint => RecordIndex) public GroupIndexer;
    
    // Mapping that enables ease of traversal of groups created by an addressor
    mapping(address => RecordIndex[]) public GroupForCreatorIndexer;


    // indexes a group location using the group name
    mapping(string => RecordIndex) public GroupIndexerByName;


    // list of Group Cycles
    Cycle[] Cycles;
    
    //Mapping that enables ease of traversal of the cycle records. Key is cycle id
    mapping(uint => RecordIndex) public CycleIndexer;
    
    //Mapping that enables ease of traversal of cycle records by the group. key is group id
    mapping(uint => RecordIndex[]) public GroupCycleIndexer;
    
    
    
     // list of group records
    Member[] Members;
    
    //Mapping that enables ease of traversal of the member records. key is the member address
    mapping(address => RecordIndex) public MemberIndexer;
    
    
    //Mapping of a groups members. Key is the group id, 
    mapping(uint => GroupMember[])public GroupMembers;
    
    //Mapping of a cycle members. key is the cycle id
    mapping(uint => CycleMember[])public CycleMembers;
    
    
    uint lastGroupId;
    uint lastCycleId;

    address LendingServiceAddress;
    
   
    struct Group {
        bool exists;
        uint id;
        string name;
        string symbol;
        address payable creatorAddress;
        uint256 totalLiquidityAsPenalty;
        uint256 availableBalance;
        uint256 totalDeposited;
        uint256 underlyingTotalDeposits;
        uint256 underlyingTotalWithdrawn;
        uint256 derivativeBalance;
        uint256 derivativeTotalDeposits;
        uint256 derivativeTotalWithdrawn;
    }
    
    struct Cycle{
        bool exists;
        uint id;
        uint groupId;
        uint numberOfDepositors;
       
        uint cycleStartTimeStamp;
        uint cycleDuration;
        
        uint maximumSlots;
        bool hasMaximumSlots;
        uint256 minimumCycleDeposit;
        
        uint256 underlyingTotalDeposits;
        uint256 underlyingTotalWithdrawn;
        uint256 derivativeBalance;
        uint256 derivativeTotalDeposits;
        uint256 derivativeTotalWithdrawn;
        
        
        CycleStatus cycleStatus; 
        
        
    }
    
    struct Member{
        bool exists;
        address payable _address;
    }
    
    struct GroupMember{
        uint id;
        bool exists;
        address payable memberAddress;
        uint groupId;
    }
    
    struct CycleMember{
        bool exist;
        uint id;
        uint cycleId;
        uint groupMemerId;
    }
    
    
    struct MemberCycleTransaction{
        bool exists;
        uint id;
        uint cycleMemberId;
        address payable _address;
        uint256 TotalLiquidityAsPenalty;
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


    enum CycleStatus {NOT_STARTED, ONGOING, ENDED}

    event UnderlyingAssetDeposited(
        uint cycleId,
        address payable memberAddress,
        uint cycleMemberId,
        uint256 underlyingAmount,
        uint256 derivativeAmount,
        uint256 balance
    );

    event DerivativeAssetWithdrawn(
        uint cycleId,
        address payable memberAddress,
        uint cycleMemberId,
        uint256 underlyingAmount,
        uint256 derivativeAmount,
        uint256 balance
    );
    
    event GroupCreated(
        uint groupId,
        address payable groupCreator

    );
    
     event CycleCreated(
        uint cycleId,
        uint numberOfDepositors,
        uint maximumSlots,
        bool hasMaximumSlots,
        uint256 minimumCycleDeposit,
        uint expectedCycleStartTimeStamp,
        uint cycleDuration
    );
    
    event MemberJoinedCycle(
        uint cycleId,
        address payable memberAddress,
        uint groupId
       
    );
    
     event MemberJoinedGroup(
        address payable memberAddress,
        uint groupId
       
    );







    IDaiLendingService lendingService;
    IERC20 daiToken;

    constructor(address lendingServiceAddress, address tokenAddress) public {
        lendingService = IDaiLendingService(lendingServiceAddress);
        daiToken = IERC20(tokenAddress);
        LendingServiceAddress = lendingServiceAddress;
    }
    
    
    function joinCycle(uint cycleId) external{
        
    }
    
    function joinCycleDelegate(uint cycleId, address payable depositorAddress) external{
        
    }
    
    
    function _joinCycle(uint cycleId, address payable depositorAddress){
        address recipient = address(this);
        uint256 amountTransferrable = daiToken.allowance(
            depositorAddress,
            recipient
        );

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful = daiToken.transferFrom(
            depositorAddress,
            recipient,
            amountTransferrable
        );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );
    }
    
    function _addDepositorToCycle(uint cycleId, address payable depositorAddress){
        
    }
    
    
    
    function _createCycleMemberIfNotExist(){
        
    }
    
    function _getMember(address payable depositor, bool throwOnNotFound) returns (Member){
        bool memberExists = MemberIndexer[depositor].exists;
        if(throwOnNotFound)
          require(memberExists==true,"Member not found");
          
        if(!memberExists){
            
        }
        
         
          
    }
    
    
    function activateCycle(uint cycleId) onlyCycleCreator(cycleId) external{
       Cycle memory cycle = _getCycle(cycleId);
       require(cycle.cycleStatus==CycleStatus.NOT_STARTED, "Cannot activate a cycle not in the 'NOT_STARTED' state");
       
       //todo: call lending contract
       
       _startCycle(cycle);
       
    }
    
    function _startCycle(Cycle memory cycle) internal {
        cycle.cycleStatus = CycleStatus.ONGOING;
       _updateCycle(cycle);
    }
    
    function createGroup(string calldata name, string calldata symbol) external{
        lastGroupId +=1;
        Group memory group = Group(true,lastGroupId,name,symbol, msg.sender,0,0,0,0,0,0,0,0);
       
        uint index = Groups.length;
        RecordIndex memory recordIndex = RecordIndex(true,index);


        Groups.push(group);
        GroupIndexer[lastGroupId] =  recordIndex;
        GroupIndexerByName[name] = recordIndex;
    }
    
    function createCycle(uint groupId,  uint startTimeStamp, uint duration, uint maximumSlots, bool hasMaximumSlots, uint minimumCycleDeposit) onlyGroupCreator(groupId) external {
        
      _validateCycleCreationActionValid(groupId,maximumSlots,hasMaximumSlots);
        
      lastCycleId +=1;
      Cycle memory cycle  = Cycle(true,lastCycleId,groupId,0,startTimeStamp,duration,maximumSlots,hasMaximumSlots,minimumCycleDeposit,0,0,0,0,0, CycleStatus.NOT_STARTED);
      
      uint index = Cycles.length;
      
      RecordIndex memory recordIndex = RecordIndex(true,index);
      
      Cycles.push(cycle); 
      CycleIndexer[lastCycleId] =  recordIndex;
    }
    
    
    
    function _updateCycle(Cycle memory cycle) internal {
        
       uint index = _getCycleIndex(cycle.id);
       Cycles[index] = cycle;
        
    }
    
     function _updateGroup(Group memory group) internal {
        uint index = _getGroupIndex(group.id);
        Groups[index] = group;
    }
    
    
    
    
    
    function _validateCycleCreationActionValid(uint groupId, uint maximumsSlots, bool hasMaximumSlots) internal{
       bool doesGroupExist = doesGroupExist(groupId);
       
       require(doesGroupExist==true,"Group not found");
       
       require(hasMaximumSlots==true && maximumsSlots==0, "Maximum slot settings cannot be empty" );
       
       
    }
    
    
    function doesGroupExist(uint groupId) internal view  returns (bool){
        return _doesGroupExist(groupId);
    }
    
     function doesGroupNameExist(uint groupName) internal view  returns (bool){
        return _doesGroupExist(groupName);
    }
    
    function _doesGroupExist(uint groupId) internal view returns (bool){
        
       bool groupExist =  GroupIndexer[groupId].exists;
       
       if(groupExist)
           return true;
       else
            return false;
        
    }
    
    function _doesGroupExist(string memory groupName) internal view returns (bool){
        
       bool groupExist =  GroupIndexerByName[groupName].exists;
       
       if(groupExist)
           return true;
       else
            return false;
        
    }
    
    function _getGroup(uint groupId) internal view returns (Group memory) {
        
        uint index = _getGroupIndex(groupId);
        
         Group memory group  = Groups[index];
         return group;
    }
    
    
    function _getCycleGroup(uint cycleId) internal view returns (Group memory) {
        
         uint index = _getCycleIndex(cycleId);
        
         Cycle memory cycle  = Cycles[index];
         
         return _getGroup(cycle.groupId);
    }
    
     function _getCycle(uint cycleId) internal view returns (Cycle memory) {
        
         uint index = _getCycleIndex(cycleId);
        
         Cycle memory cycle  = Cycles[index];
         return cycle;
    }
    
    function _getTrackedGroup(uint groupId) internal view returns (Group memory) {
       
         uint index = _getGroupIndex(groupId);

         Group storage group  = Groups[index];
         return group;
    }
    
    function _getGroupIndex(uint groupId) internal   view returns (uint){
        
         bool doesGroupExist =  GroupIndexer[groupId].exists;
         require(doesGroupExist==true,"Group not found");
        
         uint index = GroupIndexer[groupId].index;
         return index;
        
    }
    
     function _getCycleIndex(uint cycleId) internal   view returns (uint){
        
         bool doesCycleExist =  CycleIndexer[cycleId].exists;
         require(doesCycleExist==true,"Cycle not found");
        
         uint index = CycleIndexer[cycleId].index;
         return index;
        
    }
    
    
    modifier onlyGroupCreator(uint groupId) {
    
     Group memory group  = _getGroup(groupId);
    
     require(msg.sender == group.creatorAddress , "nauthorized access to contract");
      _;
  }
  
  modifier onlyCycleCreator(uint cycleId) {
    
     Group memory group = _getCycleGroup(cycleId);
     
     
    
     require(msg.sender == group.creatorAddress , "nauthorized access to contract");
      _;
  }
    
   
    
    
    
    
    /*
    
    
    function withdraw(uint256 derivativeAmount) external {
        address payable recipient = msg.sender;
        _withdraw(recipient, derivativeAmount);
    }

    function withdrawDelegate(
        address payable recipient,
        uint256 derivativeAmount
    ) external onlyOwner {
        _withdraw(recipient, derivativeAmount);
    }

    function _withdraw(address payable recipient, uint256 derivativeAmount)
        internal
    {
        _validateUserBalanceIsSufficient(recipient, derivativeAmount);

        uint256 balanceBeforeWithdraw = lendingService.userDaiBalance();

        lendingService.Withdraw(derivativeAmount);

        uint256 balanceAfterWithdraw = lendingService.userDaiBalance();

        uint256 amountOfUnderlyingAssetWithdrawn = balanceBeforeWithdraw.sub(
            balanceAfterWithdraw
        );

        ClientRecord memory clientRecord = _updateClientRecordAfterWithdrawal(
            recipient,
            amountOfUnderlyingAssetWithdrawn,
            derivativeAmount
        );
        emit DerivativeAssetWithdrawn(
            recipient,
            amountOfUnderlyingAssetWithdrawn,
            derivativeAmount,
            clientRecord.derivativeBalance
        );
    }

    function _validateUserBalanceIsSufficient(
        address payable recipient,
        uint256 derivativeAmount
    ) internal view returns (uint256) {
        RecordIndex memory recordIndex = ClientRecordIndexer[recipient];
        ClientRecord storage record = ClientRecords[recordIndex.index];

        uint256 derivativeBalance = record.derivativeBalance;

        require(
            derivativeBalance >= derivativeAmount,
            "Withdrawal cannot be processes, reason: Insufficient Balance"
        );
    }

    function deposit(string calldata email) external {
        address payable depositor = msg.sender;
        _deposit(depositor, email);
    }

    function depositDelegate(
        address payable depositorAddress,
        string calldata email
    ) external onlyOwner {
        _deposit(depositorAddress, email);
    }

    function _deposit(address payable depositorAddress, string memory email)
        internal
    {
        address recipient = address(this);
        uint256 amountTransferrable = daiToken.allowance(
            depositorAddress,
            recipient
        );

        require(
            amountTransferrable > 0,
            "Approve an amount > 0 for token before proceeding"
        );
        bool isSuccessful = daiToken.transferFrom(
            depositorAddress,
            recipient,
            amountTransferrable
        );
        require(
            isSuccessful == true,
            "Could not complete deposit process from token contract"
        );

        daiToken.approve(LendingServiceAddress, amountTransferrable);

        uint256 balanceBeforeDeposit = lendingService.userShares();

        lendingService.save(amountTransferrable);

        uint256 balanceAfterDeposit = lendingService.userShares();

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);
        ClientRecord memory clientRecord = _updateClientRecordAfterDeposit(
            depositorAddress,
            email,
            amountTransferrable,
            amountOfyDai
        );

        emit DerivativeAssetWithdrawn(
            recipient,
            amountTransferrable,
            amountOfyDai,
            clientRecord.derivativeBalance
        );
    }

    function _updateClientRecordAfterDeposit(
        address payable client,
        string memory email,
        uint256 underlyingAmountDeposited,
        uint256 derivativeAmountDeposited
    ) internal returns (ClientRecord storage) {
        bool exists = ClientRecordIndexer[client].exists;
        if (!exists) {
            uint256 arrayLength = ClientRecords.length;

            ClientRecord memory record = ClientRecord(
                true,
                client,
                email,
                underlyingAmountDeposited,
                underlyingAmountDeposited,
                derivativeAmountDeposited,
                derivativeAmountDeposited,
                0
            );

            record.underlyingTotalDeposits.add(underlyingAmountDeposited);

            record.derivativeTotalDeposits.add(derivativeAmountDeposited);
            record.derivativeBalance.add(derivativeAmountDeposited);

            RecordIndex memory recordIndex = RecordIndex(true, arrayLength);

            ClientRecords.push(record);
            ClientRecordIndexer[client] = recordIndex;
            return record;
        } else {
            RecordIndex memory recordIndex = ClientRecordIndexer[client];

            ClientRecord storage record = ClientRecords[recordIndex.index];

            record.underlyingTotalDeposits.add(underlyingAmountDeposited);

            record.derivativeTotalDeposits.add(derivativeAmountDeposited);
            record.derivativeBalance.add(derivativeAmountDeposited);
            return record;
        }
    }

    function _updateClientRecordAfterWithdrawal(
        address payable client,
        uint256 underlyingAmountWithdrawn,
        uint256 derivativeAmountWithdrawn
    ) internal returns (ClientRecord storage) {
        bool exists = ClientRecordIndexer[client].exists;

        require(exists == true, "User record not found in contract");

        RecordIndex memory recordIndex = ClientRecordIndexer[client];

        ClientRecord storage record = ClientRecords[recordIndex.index];

        record.underlyingTotalWithdrawn.add(underlyingAmountWithdrawn);

        record.derivativeTotalDeposits.add(derivativeAmountWithdrawn);
        record.derivativeBalance.add(derivativeAmountWithdrawn);

        return record;
    }
    */
    
}
