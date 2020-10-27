pragma solidity ^0.6.6;

import "./IDaiToken.sol";
import "./IYDaiToken.sol";

import "../IDaiLendingService.sol";
import "./OwnableService.sol";
import "../ITreasury.sol";
import "../ISavingsConfig.sol";
import "../ISavingsConfigSchema.sol";
import "../IGroups.sol";
import "../IRewardConfig.sol";
import "../IXendToken.sol";
import "../SafeMath.sol";



contract EsusuAdapter is OwnableService, ISavingsConfigSchema {

    /*
        Events to emit 
        1. Creation of Esusu Cycle 
        2. Joining of Esusu Cycle 
        3. Starting of Esusu Cycle 
        4. Withdrawal of ROI
        5. Withdrawal of Capital
    */
    event CreateEsusuCycleEvent
    (
        uint date,
        uint indexed cycleId,
        uint depositAmount,
        address  Owner,
        uint payoutIntervalSeconds,
        CurrencyEnum currency,
        string currencySymbol,
        CycleStateEnum cycleState
    );
    
    event JoinEsusuCycleEvent
    (
        uint date,
        address indexed member,   
        uint memberPosition,
        uint totalAmountDeposited,
        uint cycleId
    );
    
    event StartEsusuCycleEvent
    (
        uint date,
        address owner,  
        uint totalAmountDeposited,
        uint totalCycleDuration,
        uint totalShares,
        uint totalMembers,
        uint indexed cycleId
    );
    
    event ROIWithdrawalEvent
    (
        uint date,
        address indexed member,  
        uint cycleId,
        uint amount
        
    );
    
    event CapitalWithdrawalEvent
    (
        uint date,
        address indexed member,  
        uint cycleId,
        uint amount
        
    );
    
    /*  Enum definitions */
    enum CurrencyEnum{
        Dai
    }
    
    enum CycleStateEnum{
        Idle,               // Cycle has just been created and members can join in this state
        Active,             // Cycle has started and members can take their ROI
        Expired,            // Cycle Duration has elapsed and members can withdraw their capital as well as ROI
        Inactive            // Total beneficiaries is equal to Total members, so all members have withdrawn their Capital and ROI 
    }

    /*  Struct Definitions */
    struct EsusuCycle{
        uint CycleId;
        uint GroupId;                   //  Group this Esusu Cycle belongs to
        uint DepositAmount;
        uint TotalMembers;
        uint TotalBeneficiaries;        //  This is the total number of members that have withdrawn their ROI 
        address Owner;                  //  This is the creator of the cycle who is also the creator of the group
        uint PayoutIntervalSeconds;     //  Time each member receives overall ROI within one Esusu Cycle in seconds
        uint TotalCycleDuration;        //  The total time it will take for all users to be paid which is (number of members * payout interval)
        CurrencyEnum Currency;          //  Currency supported in this Esusu Cycle 
        CycleStateEnum CycleState;      //  The current state of the Esusu Cycle
        uint256 TotalAmountDeposited;   // Total  Dai Deposited
        uint TotalCapitalWithdrawn;     // Total Capital In Dai Withdrawn
        uint CycleStartTime;            //  Time which the cycle will start when it has elapsed. Anyone can start cycle after this time has elapsed
        uint TotalShares;               //  Total yDai Shares 
        uint MaxMembers;                //  Maximum number of members that can join this esusu cycle
    }
    
    struct Member{
        address MemberId;
        uint TotalDeposited;
        uint TotalPayoutReceived;
    }
    
    struct MemberCycle{
        uint CycleId;
        address MemberId;
        uint TotalAmountDepositedInCycle;
        uint TotalPayoutReceivedInCycle;
    }
    
        /*  Model definition starts */
    string Dai = "Dai Stablecoin";


    /* Model definition ends */
    
    //  Member variables
    address _owner;
    ITreasury _treasuryContract;
    ISavingsConfig _savingsConfigContract;
    IGroups _groupsContract;
    IRewardConfig _rewardConfigContract;
    IXendToken  _xendTokenContract;
    
    IDaiLendingService _iDaiLendingService;
    IDaiToken _dai = IDaiToken(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IYDaiToken _yDai = IYDaiToken(0xC2cB1040220768554cf699b0d863A3cd4324ce32);
    string _feeRuleKey;

    uint EsusuCycleId = 0;
    

    mapping(uint => EsusuCycle) EsusuCycleMapping;
    

    mapping(address=>mapping(uint=>MemberCycle)) MemberAddressToMemberCycleMapping;

    mapping(uint=>mapping(address=>uint)) CycleToMemberPositionMapping;   //  This tracks position of the  member in an Esusu Cycle

    mapping(uint=>mapping(address=> uint)) CycleToBeneficiaryMapping;  // This tracks members that have received overall ROI and amount received within an Esusu Cycle
    
    mapping(uint=>mapping(address=> uint)) CycleToMemberWithdrawnCapitalMapping;    // This tracks members that have withdrawn their capital and the amount withdrawn 
    
    uint TotalDeposits; //  This holds all the dai amounts users have deposited in this contract
    
    using SafeMath for uint256;

    constructor (address payable serviceContract, address payable treasuryContract, address savingsConfigContract, 
                    string memory feeRuleKey, address groupsContract, address rewardConfigContract,
                    address xendTokenContract) public OwnableService(serviceContract){
        _owner = msg.sender;
        _treasuryContract = ITreasury(treasuryContract);
        _savingsConfigContract = ISavingsConfig(savingsConfigContract);
        _feeRuleKey = feeRuleKey;
        _groupsContract = IGroups(groupsContract);
        _rewardConfigContract = IRewardConfig(rewardConfigContract);
        _xendTokenContract = IXendToken(xendTokenContract);
    }
    
    //  TODO: Uncommenting this makes the code too large, find alternative 
    // function UpdateDependencies (address payable treasuryContract, address savingsConfigContract, 
    //                 string calldata feeRuleKey, address groupsContract, address rewardConfigContract,
    //                 address xendTokenContract) external onlyOwner{
    //     _treasuryContract = ITreasury(treasuryContract);
    //     _savingsConfigContract = ISavingsConfig(savingsConfigContract);
    //     _feeRuleKey = feeRuleKey;
    //     _groupsContract = IGroups(groupsContract);
    //     _rewardConfigContract = IRewardConfig(rewardConfigContract);
    //     _xendTokenContract = IXendToken(xendTokenContract);
    // }
    
    function UpdateDaiLendingService(address daiLendingServiceContractAddress) onlyOwner external {
        _iDaiLendingService = IDaiLendingService(daiLendingServiceContractAddress);
    }
    

    /*
        NOTE: startTimeInSeconds is the time at which when elapsed, any one can start the cycle 
        -   Creates a new EsusuCycle
        -   Esusu Cycle can only be created by the owner of the group
    */
    
    function CreateEsusu(uint groupId, uint depositAmount, uint payoutIntervalSeconds,uint startTimeInSeconds, address owner, uint maxMembers) public onlyOwnerAndServiceContract {

        // Get Group information by Id
        (uint id, string memory name, string memory symbol, address creatorAddress) = GetGroupInformationById(groupId);
        
        require(owner == creatorAddress, "EsusuCycle can only be created by group owner");
        
        //  Increment EsusuCycleId by 1
        EsusuCycleId += 1;
        EsusuCycleMapping[EsusuCycleId].CycleId = EsusuCycleId;
        EsusuCycleMapping[EsusuCycleId].DepositAmount = depositAmount;
        EsusuCycleMapping[EsusuCycleId].PayoutIntervalSeconds = payoutIntervalSeconds;
        EsusuCycleMapping[EsusuCycleId].Currency = CurrencyEnum.Dai;
        EsusuCycleMapping[EsusuCycleId].CycleState = CycleStateEnum.Idle; 
        EsusuCycleMapping[EsusuCycleId].Owner = owner;
        EsusuCycleMapping[EsusuCycleId].MaxMembers = maxMembers;
        
        
        //  Set the Cycle start time 
        EsusuCycleMapping[EsusuCycleId].CycleStartTime = startTimeInSeconds;

         //  Assign groupId
        EsusuCycleMapping[EsusuCycleId].GroupId = groupId;
        
        //  emit event
        emit CreateEsusuCycleEvent(now, EsusuCycleId, depositAmount, owner, payoutIntervalSeconds,CurrencyEnum.Dai,Dai,EsusuCycleMapping[EsusuCycleId].CycleState);
        
    }
    
    //  Join a particular Esusu Cycle 
    /*
        - Check if the cycle ID is valid
        - Check if the cycle is in Idle state, that is the only state a member can join
        - Check if member is already in Cycle
        - Ensure member has approved this contract to transfer the token on his/her behalf
        - If member has enough balance, transfer the tokens to this contract else bounce
        - Increment the total deposited amount in this cycle and total deposited amount for the member cycle struct 
        - Increment the total number of Members that have joined this cycle 
    */
    
    function JoinEsusu(uint esusuCycleId, address member) public onlyOwnerAndServiceContract {
        //  Check if the cycle ID is valid
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");

        //  If cycle is not in Idle State, bounce 
        require( EsusuCycleMapping[esusuCycleId].CycleState == CycleStateEnum.Idle, "Esusu Cycle must be in Idle State before you can join");
        
        //  If cycle is filled up, bounce 
        require(EsusuCycleMapping[esusuCycleId].TotalMembers < EsusuCycleMapping[esusuCycleId].MaxMembers, "Esusu Cycle is filled up, you can't join");
        
        //  check if member is already in this cycle 
        require(_isMemberInCycle(member,esusuCycleId) == false, "Member can't join same Esusu Cycle more than once");
        
        //  If user does not have enough Balance, bounce. For now we use Dai as default
        uint memberBalance = _dai.balanceOf(member);
        
        require(memberBalance >=  EsusuCycleMapping[esusuCycleId].DepositAmount, "Balance must be greater than or equal to Deposit Amount");
        
        //  If user balance is greater than or equal to deposit amount then transfer from member to this contract
        //  NOTE: approve this contract to withdraw before transferFrom can work
        _dai.transferFrom(member, address(this), EsusuCycleMapping[esusuCycleId].DepositAmount);
        
        //  Increment the total deposited amount in this cycle
        EsusuCycleMapping[esusuCycleId].TotalAmountDeposited =  EsusuCycleMapping[esusuCycleId].TotalAmountDeposited.add(EsusuCycleMapping[esusuCycleId].DepositAmount);
        
        //  Increment the total deposited amount for the member cycle struct
        mapping(uint=>MemberCycle) storage memberCycleMapping =  MemberAddressToMemberCycleMapping[member];
        

        memberCycleMapping[esusuCycleId].CycleId = esusuCycleId;
        memberCycleMapping[esusuCycleId].MemberId = member;
        memberCycleMapping[esusuCycleId].TotalAmountDepositedInCycle = memberCycleMapping[esusuCycleId].TotalAmountDepositedInCycle.add( EsusuCycleMapping[esusuCycleId].DepositAmount);
        memberCycleMapping[esusuCycleId].TotalPayoutReceivedInCycle = memberCycleMapping[esusuCycleId].TotalPayoutReceivedInCycle.add(0);
        
        //  Increase TotalMembers count by 1
        EsusuCycleMapping[esusuCycleId].TotalMembers +=1;
        
        mapping(address=>uint) storage memberPositionMapping =  CycleToMemberPositionMapping[esusuCycleId];
        
        //  Assign Position to Member In this Cycle
        memberPositionMapping[member] = EsusuCycleMapping[esusuCycleId].TotalMembers;
        
        
        //  emit event 
        emit JoinEsusuCycleEvent(now, member,memberPositionMapping[member], EsusuCycleMapping[esusuCycleId].TotalAmountDeposited,esusuCycleId);
    }

    
    /*
        - Check if the Id is a valid ID
        - Check if the cycle is in Idle State
        - Anyone  can start that cycle -
        - Get the total number of members and then mulitply by the time interval in seconds to get the total time this Cycle will last for
        - Set the Cycle start time to now 
        - Take everyones deposited DAI from this Esusu Cycle and then invest through Yearn 
        - Track the yDai shares that belong to this cycle using the derived equation below for save/investment operation
            - yDaiSharesPerCycle = Change in yDaiSharesForContract + Current yDai Shares in the cycle 
            - Change in yDaiSharesForContract = yDai.balanceOf(address(this) after save operation - yDai.balanceOf(address(this) after before operation
    */
    
    function StartEsusuCycle(uint esusuCycleId) public onlyOwnerAndServiceContract{

        //  If cycle ID is valid, else bonunce
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        EsusuCycle storage cycle = EsusuCycleMapping[esusuCycleId];
        
        require(cycle.CycleState == CycleStateEnum.Idle, "Cycle can only be started when in Idle state");
        
        require(now > cycle.CycleStartTime, "Cycle can only be started when start time has elapsed");
        
        EsusuCycleMapping[esusuCycleId].CycleState = CycleStateEnum.Active;
        
        //  Calculate Cycle LifeTime in seconds
        EsusuCycleMapping[esusuCycleId].TotalCycleDuration = cycle.PayoutIntervalSeconds * cycle.TotalMembers;
        

        
        //  Get all the dai deposited for this cycle
        uint esusuCycleBalance = cycle.TotalAmountDeposited;
        
        //  Get the balance of yDaiSharesForContract before save opration
        uint yDaiSharesForContractBeforeSave = _yDai.balanceOf(address(this));
        
        //  Invest the dai in Yearn Finance using Dai Lending Service.
        
        //  NOTE: yDai will be sent to this contract
        //  Transfer dai from this contract to dai lending adapter and then call a new save function that will not use transferFrom internally
        //  Approve the daiLendingAdapter so it can spend our Dai on our behalf 
        address daiLendingAdapterContractAddress = _iDaiLendingService.GetDaiLendingAdapterAddress();
        _dai.approve(daiLendingAdapterContractAddress,esusuCycleBalance);
        
        _iDaiLendingService.save(esusuCycleBalance);
        
        //  Get the balance of yDaiSharesForContract after save operation
        uint yDaiSharesForContractAfterSave = _yDai.balanceOf(address(this));
        
        
        //  Save yDai Total balanceShares
        EsusuCycleMapping[esusuCycleId].TotalShares = yDaiSharesForContractAfterSave.sub(yDaiSharesForContractBeforeSave).add(EsusuCycleMapping[esusuCycleId].TotalShares);
        
        //  Update the Cycle start time to now
        EsusuCycleMapping[esusuCycleId].CycleStartTime = now;
        
        //  Increase TotalDeposits made to this contract 
        TotalDeposits = TotalDeposits.add(esusuCycleBalance);
        
        //  emit event 
        emit StartEsusuCycleEvent(now,cycle.Owner,esusuCycleBalance, EsusuCycleMapping[esusuCycleId].TotalCycleDuration,
                                    EsusuCycleMapping[esusuCycleId].TotalShares,cycle.TotalMembers,esusuCycleId);
    }
    
    
  
      function GetMemberCycleInfo(address memberAddress, uint esusuCycleId) public view returns(uint CycleId, address MemberId, uint TotalAmountDepositedInCycle, uint TotalPayoutReceivedInCycle, uint memberPosition){
        
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        mapping(uint=>MemberCycle) storage memberCycleMapping =  MemberAddressToMemberCycleMapping[memberAddress];
        
        mapping(address=>uint) storage memberPositionMapping =  CycleToMemberPositionMapping[esusuCycleId];
        
        //  Get Number(Position) of Member In this Cycle
        uint memberPos = memberPositionMapping[memberAddress];
        
        return  (memberCycleMapping[esusuCycleId].CycleId,memberCycleMapping[esusuCycleId].MemberId,
        memberCycleMapping[esusuCycleId].TotalAmountDepositedInCycle,
        memberCycleMapping[esusuCycleId].TotalPayoutReceivedInCycle,memberPos);
    }

    function GetEsusuCycle(uint esusuCycleId) public view returns(uint CycleId, uint DepositAmount, 
                                                            uint PayoutIntervalSeconds, uint CycleState, 
                                                            uint TotalMembers, uint TotalAmountDeposited, uint TotalShares, 
                                                            uint TotalCycleDurationInSeconds, uint TotalCapitalWithdrawn, uint CycleStartTimeInSeconds,
                                                            uint TotalBeneficiaries, uint MaxMembers){
        
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        EsusuCycle memory cycle = EsusuCycleMapping[esusuCycleId];
        
        return (cycle.CycleId, cycle.DepositAmount,  cycle.PayoutIntervalSeconds, 
                uint256(cycle.CycleState),
                cycle.TotalMembers, cycle.TotalAmountDeposited, cycle.TotalShares,
                cycle.TotalCycleDuration, cycle.TotalCapitalWithdrawn, cycle.CycleStartTime,
                cycle.TotalBeneficiaries, cycle.MaxMembers);
        
    }
    
    /*
        This function checks whether the user can withdraw at the time at which the user is making this call
        
        - Check if cycle is valid 
        - Check if cycle is in active state
        - Check if member is in cycle
        - Check if member is a beneficiary
        - Calculate member withdrawal time
        - Check if member can withdraw at this time
    */
    function IsMemberEligibleToWithdrawROI(uint esusuCycleId, address member) public view returns(bool){
        
        return _isMemberEligibleToWithdrawROI(esusuCycleId,member);
        
    }
    
    /*
        This function checks whether the user can withdraw capital after the Esusu Cycle is complete. 
        
        The cycle must be in an inactive state before capital can be withdrawn
    */
    function IsMemberEligibleToWithdrawCapital(uint esusuCycleId, address member) public view returns(bool){
        
        return _isMemberEligibleToWithdrawCapital(esusuCycleId,member);
        
    }
    
    function _isMemberEligibleToWithdrawROI(uint esusuCycleId, address member) internal view returns(bool){
        
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        EsusuCycle memory cycle = EsusuCycleMapping[esusuCycleId];
        
        require(cycle.CycleState == CycleStateEnum.Active || cycle.CycleState == CycleStateEnum.Expired, "Cycle must be in active or expired state");
        
        require(_isMemberInCycle(member,esusuCycleId), "Member is not in this cycle");
        
        require(_isMemberABeneficiaryInCycle(member,esusuCycleId) == false, "Member is already a beneficiary");
        
        uint memberWithdrawalTime = _calculateMemberWithdrawalTime(cycle,member);
        
        if(now > memberWithdrawalTime){
            return true;

        }else{
            return false;
        }
        
    }
    
    function _isMemberEligibleToWithdrawCapital(uint esusuCycleId, address member) internal view returns(bool){
        
        require(esusuCycleId > 0 && esusuCycleId <= EsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        EsusuCycle memory cycle = EsusuCycleMapping[esusuCycleId];
        
        require(cycle.CycleState == CycleStateEnum.Expired, "Cycle must be in Expired state for you to withdraw capital");
        
        require(_isMemberInCycle(member,esusuCycleId), "Member is not in this cycle");
        
        require(_isMemberABeneficiaryInCycle(member,esusuCycleId) == true, "Member must be a beneficiary before you can withdraw capital");

        require(_isMemberInWithdrawnCapitalMapping(member,esusuCycleId) == false, "Member can't withdraw capital twice");

        return true;
        
    }
    
    // /* Test helper functions starts  TODO: remove later */
    function GetDaiBalance(address member) external view returns(uint){
        return _dai.balanceOf(member);
    }
    
    function GetYDaiBalance(address member) external view returns(uint){
        return _yDai.balanceOf(member);
    }
    
    
    // function CalculateMemberWithdrawalTime(uint esusuCycleId, address member) internal view returns(uint){
        
    //     EsusuCycle memory cycle = EsusuCycleMapping[esusuCycleId];

    //     mapping(address=>uint) storage memberPositionMapping =  CycleToMemberPositionMapping[cycle.CycleId];
        
    //     uint memberPosition = memberPositionMapping[member];
        
    //     uint withdrawalTime = (cycle.CycleStartTime.add(memberPosition.mul(cycle.PayoutIntervalSeconds)));
        
    //     return withdrawalTime;
    // }
    
    function GetTotalDeposits() public view returns(uint)  {
        return TotalDeposits;
    } 
    
    // /*  Test helper functions ends TODO: remove later */

    /*
        This function returns the Withdrawal time for a member in seconds
        
        Parameters
        - Wt    -> Withdrawal Time for a member 
        - To    -> Cycle Start Time
        - Mpos  -> Member Position in the Cycle 
        - Ct     -> Cycle Time Interval in seconds
        
        Equation
        Wt = (To + (Mpos * Ct))
    */
    
    function _calculateMemberWithdrawalTime(EsusuCycle memory cycle, address member) internal view returns(uint){
        
        mapping(address=>uint) storage memberPositionMapping =  CycleToMemberPositionMapping[cycle.CycleId];
        
        uint memberPosition = memberPositionMapping[member];
        
        uint withdrawalTime = (cycle.CycleStartTime.add(memberPosition.mul(cycle.PayoutIntervalSeconds)));
        
        return withdrawalTime;
    }
    
    function GetCurrentEsusuCycleId() public view returns(uint){
        
        EsusuCycle memory cycle = EsusuCycleMapping[EsusuCycleId];
        
        return cycle.CycleId;
    }
    
    function _isMemberInCycle(address memberAddress,uint esusuCycleId ) internal view returns(bool){
        
        mapping(uint=>MemberCycle) storage memberCycleMapping =  MemberAddressToMemberCycleMapping[memberAddress];
        
        //  If member is in cycle, the cycle ID should be greater than 0
        if(memberCycleMapping[esusuCycleId].CycleId > 0){
            
            return true;
        }else{
            return false;
        }
    }
    
    function _isMemberABeneficiaryInCycle(address memberAddress,uint esusuCycleId ) internal view returns(bool){
        
        mapping(address=>uint) storage beneficiaryMapping =  CycleToBeneficiaryMapping[esusuCycleId];
        
        uint amount = beneficiaryMapping[memberAddress];
        
        //  If member has received money from this cycle, the amount recieved should be greater than 0

        if(amount > 0){
            
            return true;
        }else{
            return false;
        }
    }
    
    function _isMemberInWithdrawnCapitalMapping(address memberAddress,uint esusuCycleId ) internal view returns(bool){
        
        mapping(address=>uint) storage memberWithdrawnCapitalMapping =  CycleToMemberWithdrawnCapitalMapping[esusuCycleId];
        
        uint amount = memberWithdrawnCapitalMapping[memberAddress];
        
        //  If member has withdrawn capital from this cycle, the amount recieved should be greater than 0

        if(amount > 0){
            
            return true;
        }else{
            return false;
        }
    }
    
    /*
        - Get the group index by name
        - Get the group information by index
    */
    function GetGroupInformationByName(string memory name) public view returns (uint groupId, string memory groupName, string memory groupSymbol, address groupCreatorAddress){
        
        //  Get the group index by name
        (bool exists, uint index ) = _groupsContract.getGroupIndexerByName(name);
        
        //  Get the group id by index and return 

        return _groupsContract.getGroupByIndex(index);
    }
    
        /*
        - Get the group information by Id
    */
    function GetGroupInformationById(uint id) public view returns (uint groupId, string memory groupName, string memory groupSymbol, address groupCreatorAddress){
        
        //  Get the group id by index and return 

        return _groupsContract.getGroupById(id);
    }
    
    /*
        - Creates the group 
        - returns the ID and other information
    */
    function CreateGroup(string memory name, string memory symbol, address groupCreator) public {
        
           _groupsContract.createGroup(name,symbol,groupCreator);
           
    }
    
    
    function _rewardMember(uint totalCycleTime, address member, uint amount) internal {
        
        uint reward = _rewardConfigContract.CalculateEsusuReward(totalCycleTime, amount);
        
        // get Xend Token contract and mint token for member
        _xendTokenContract.mint(payable(member), reward);
    }
    
        /*
        This function allows members to withdraw their capital from the esusu cycle
        
        - Check if member can withdraw capital 
        - Withdraw capital and increase TotalCapitalWithdrawn
            - Get the total balanceShares from the calling contract
            - Withdraw all the money from dai lending service
            - Send the member's deposited amount to his/her address 
            - re-invest the remaining dai until all members have taken their capital, then we set the cycle inactive
        - Reward member with Xend Tokens 
        - Add this member to the EsusuCycleCapitalMapping
        - Check if TotalCapitalWithdrawn == TotalAmountDeposited && if TotalMembers == TotalBeneficiaries, if yes, set the Cycle to Inactive

    */
    
    function WithdrawCapitalFromEsusuCycle(uint esusuCycleId, address member) public {
        
        require(_isMemberEligibleToWithdrawCapital(esusuCycleId,member));
        
        //  Add member to capital withdrawn mapping
        
        mapping(address=>uint) storage memberCapitalMapping =  CycleToMemberWithdrawnCapitalMapping[esusuCycleId];
        
        EsusuCycle storage cycle = EsusuCycleMapping[esusuCycleId];

        uint memberDeposit = cycle.DepositAmount;
        
        //  Get the current yDaiSharesPerCycle and call the WithdrawByShares function on the daiLending Service
        uint yDaiSharesPerCycle = cycle.TotalShares;
        
        //  Get the yDaiSharesForContractBeforeWithdrawal 
        uint yDaiSharesForContractBeforeWithdrawal = _yDai.balanceOf(address(this));
        
        //  Withdraw the Dai. At this point, we have withdrawn  Dai Capital deposited by this member for this cycle and we will now transfer the dai capital to the member
        address daiLendingAdapterContractAddress = _iDaiLendingService.GetDaiLendingAdapterAddress();
        _yDai.approve(daiLendingAdapterContractAddress,yDaiSharesPerCycle);
        _iDaiLendingService.WithdrawByShares(memberDeposit,yDaiSharesPerCycle);
        
        //  Now the Dai is in this contract, transfer it to the member 
        _dai.transfer(member, memberDeposit);
        
        //  Reward member with Xend Tokens
        _rewardMember(cycle.TotalCycleDuration,member,memberDeposit);
        
        //  Get the yDaiSharesForContractAfterWithdrawal 
        uint yDaiSharesForContractAfterWithdrawal = _yDai.balanceOf(address(this));
        
        require(yDaiSharesForContractBeforeWithdrawal > yDaiSharesForContractAfterWithdrawal, "yDai shares before withdrawal must be greater !!!");
        
        //  Update the total balanceShares for this cycle 
        cycle.TotalShares = yDaiSharesPerCycle.sub(yDaiSharesForContractBeforeWithdrawal.sub(yDaiSharesForContractAfterWithdrawal));
        
        //  Add this member to the CycleToMemberWithdrawnCapitalMapping
        memberCapitalMapping[member] = memberDeposit;
        
        //  Increase total capital withdrawn 
        cycle.TotalCapitalWithdrawn = cycle.TotalCapitalWithdrawn.add(memberDeposit);
        
        //   Check if TotalCapitalWithdrawn == TotalAmountDeposited && if TotalMembers == TotalBeneficiaries, if yes, set the Cycle to Inactive
        
        if(cycle.TotalCapitalWithdrawn == cycle.TotalAmountDeposited && cycle.TotalMembers == cycle.TotalBeneficiaries){
            
            EsusuCycleMapping[esusuCycleId].CycleState = CycleStateEnum.Inactive;
            
            //  Since this cycle is inactive, send whatever Total shares Dai equivalent that is left to our treasury contract

            //  Withdraw DAI equivalent fof TotalShares
            _yDai.approve(daiLendingAdapterContractAddress,cycle.TotalShares);
            _iDaiLendingService.WithdrawBySharesOnly(cycle.TotalShares);
            
            //  Now the Dai is in this contract, transfer it to the treasury contract 
            uint balance = _dai.balanceOf(address(this));
            _dai.approve(address(_treasuryContract),balance);
            _treasuryContract.depositToken(address(_dai));
            
        }
        
        //  emit event
        emit CapitalWithdrawalEvent(now, member, esusuCycleId,memberDeposit);
        
    }
    
      /*
        Assumption:
        - We assume even distribution of Overall accumulated ROI among members of the group when a member places a withdrawal request at a time inverval 
          greater than members in the previous position who have not placed a withdrawal request.
        
        This function sends all ROI generated within an Esusu Cycle Payout Interval to a particular member
        
        - Check if member is eligible to withdraw
        - Get the price per full share from Dai Lending Service\
        - Get overall DAI => yDai balanceShares * pricePerFullShare (NOTE: value is in 1e36)
        - Get ROI => overall Dai - Total Deposited Dai in this esusu cycle 
        - Implement our derived equation to determine what ROI will be allocated to this member who is withdrawing 
        - Deduct fees from Member's ROI
        - Equation Parameters
            - Ta => Total available time in seconds
            - Bt => Total Time Interval for beneficiaries in this cycle in seconds
            - Tnow => Current Time in seconds
            - T => Cycle PayoutIntervalSeconds
            - Troi => Total accumulated ROI
            - Mroi => Member ROI 
            
            Equations 
            - Bt = T * number of beneficiaries
            - Ta = Tnow - Bt
            - Troi = ((balanceShares * pricePerFullShare ) - TotalDeposited - TotalCapitalWithdrawn)
            - Mroi = (Total accumulated ROI at Tnow) / (Ta)   
        
        NOTE: As members withdraw their funds, the yDai balanceShares will change and we will be updating the TotalShares with this new value
        at all times till TotalShares becomes approximately zero when all amounts have been withdrawn including capital invested
        
        - Track the yDai shares that belong to this cycle using the derived equation below for withdraw operation
            - yDaiSharesPerCycle = Current yDai Shares in the cycle - Change in yDaiSharesForContract   
            - Change in yDaiSharesForContract = yDai.balanceOf(address(this)) before withdraw operation - yDai.balanceOf(address(this)) after withdraw operation
        
    */
    
    function WithdrawROIFromEsusuCycle(uint esusuCycleId, address member) public  {
        
        bool isMemberEligibleToWithdraw = _isMemberEligibleToWithdrawROI(esusuCycleId,member);
        
        require(isMemberEligibleToWithdraw, "Member cannot withdraw at this time");
        
        EsusuCycle storage cycle = EsusuCycleMapping[esusuCycleId];

        uint currentBalanceShares = cycle.TotalShares;
        
        uint pricePerFullShare = _iDaiLendingService.getPricePerFullShare();
        
        uint overallGrossDaiBalance = currentBalanceShares.mul(pricePerFullShare).div(1e18);
        
        
        //  Implement our derived equation to get the amount of Dai to transfer to the member as ROI
        uint Bt = cycle.PayoutIntervalSeconds.mul(cycle.TotalBeneficiaries);
        uint Ta = now.sub(Bt);
        uint Troi = overallGrossDaiBalance.sub(cycle.TotalAmountDeposited.sub(cycle.TotalCapitalWithdrawn));
        uint Mroi = Troi.div(Ta);
        
        //  Get the current yDaiSharesPerCycle and call the WithdrawByShares function on the daiLending Service
        uint yDaiSharesPerCycle = cycle.TotalShares;
        
        //  Get the yDaiSharesForContractBeforeWithdrawal 
        uint yDaiSharesForContractBeforeWithdrawal = _yDai.balanceOf(address(this));
        
        //  Withdraw the Dai. At this point, we have withdrawn the Dai ROI for this member and the dai ROI is in this contract, we will now transfer it to the member
        address daiLendingAdapterContractAddress = _iDaiLendingService.GetDaiLendingAdapterAddress();
        _yDai.approve(daiLendingAdapterContractAddress,yDaiSharesPerCycle);
        _iDaiLendingService.WithdrawByShares(Mroi,yDaiSharesPerCycle);
        
        
        //  Now the Dai is in this contract, transfer the net ROI to the member and fee to treasury contract 
        sendROI(Mroi,member,cycle);
        
        //  Get the yDaiSharesForContractAfterWithdrawal 
        uint yDaiSharesForContractAfterWithdrawal = _yDai.balanceOf(address(this));
        
        require(yDaiSharesForContractBeforeWithdrawal > yDaiSharesForContractAfterWithdrawal, "yDai shares before withdrawal must be greater !!!");
        
        //  Update the total balanceShares for this cycle 
        cycle.TotalShares = yDaiSharesPerCycle.sub(yDaiSharesForContractBeforeWithdrawal.sub(yDaiSharesForContractAfterWithdrawal));
        
        //  Increase total number of beneficiaries by 1
        cycle.TotalBeneficiaries = cycle.TotalBeneficiaries.add(1);
        
        /*
                
            - Check whether the TotalCycleDuration has elapsed, if that is the case then this cycle has expired
            - If cycle has expired then we move the left over yDai to treasury
        */
        
        if(now > cycle.TotalCycleDuration){
            
            cycle.CycleState = CycleStateEnum.Expired;
        }
        

        //  emit event 
        _emitROIWithdrawalEvent(member,Mroi,cycle);
    }
    
    function _emitROIWithdrawalEvent(address member,uint Mroi, EsusuCycle memory cycle) internal{

        emit ROIWithdrawalEvent(now, member,cycle.CycleId,Mroi);
    }
    
            /*
        This gets the fee percentage from the fee contract, deducts the fee and sends to treasury contract 
        
        For now let us assume fee percentage is 0.1% 
        - Get the fee
        - Send the net ROI in dai to member 
        - Send the fee to the treasury
        - Add member to beneficiary mapping
    */
    function sendROI(uint Mroi, address memberAddress, EsusuCycle storage cycle) internal{
        
        //  get feeRate from fee contract

        (uint minimum, uint maximum, uint exact, bool applies, RuleDefinition e)  = _savingsConfigContract.getRuleSet(_feeRuleKey);
        
        uint feeRate = exact;  
        uint fee = Mroi.div(feeRate);
        
        //  Deduct the fee
        uint memberROINet = Mroi.sub(fee); 
        
         //  Add member to beneficiary mapping
        mapping(address=>uint) storage beneficiaryMapping =  CycleToBeneficiaryMapping[cycle.CycleId];
        
        beneficiaryMapping[memberAddress] = memberROINet;
        
        //  Send ROI to member 
        _dai.transfer(memberAddress, memberROINet);
        
        //  Send deducted fee to treasury
        //  Approve the treasury contract
        _dai.approve(address(_treasuryContract),fee);
        _treasuryContract.depositToken(address(_dai));
        
    }


}

