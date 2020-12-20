pragma solidity >=0.6.6;

// import "../interfaces/IDaiToken.sol";
// import "../interfaces/IYDaiToken.sol";

// import "../interfaces/IDaiLendingService.sol";

import "../IBEP20.sol";
import "../IFToken.sol";
import "../IForTubeBankService.sol";

import "./OwnableService.sol";

import "../ISavingsConfig.sol";
import "../ISavingsConfigSchema.sol";
import "../IGroups.sol";
import "../SafeMath.sol";
import "../IEsusuStorage.sol";


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
        uint cycleState
    );
    
    event DepricateContractEvent(
        
        uint date,
        address owner, 
        string reason,
        uint yDaiSharesTransfered
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
        uint totalAmountDeposited,
        uint totalCycleDuration,
        uint totalShares,
        uint indexed cycleId
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

    
    /*  Model definition starts */
    string Dai = "BUSD Stablecoin";


    /* Model definition ends */
    
    //  Member variables
    address _owner;
    ISavingsConfig _savingsConfigContract;
    IGroups _groupsContract;

    IForTubeBankService _forTubeBankService;
    IBEP20 _BUSD = IBEP20(0x3b1F033dD955f3BE8649Cc9825A2e3E194765a3F);      //  BEP20 - ForTube BUSD Testnet TODO: change to live when moving to mainnet 
    IFToken _fBUSD = IFToken(0x6112a45160b2058C6402a5bfBE3A446c8fD4fb45);   //  BEP20 - fBUSD Testnet TODO: change to mainnet
    IEsusuStorage _esusuStorage;
    address  _delegateContract;
    bool _isActive = true;
    
    using SafeMath for uint256;

    constructor (address payable serviceContract, address savingsConfigContract, 
                     address groupsContract,
                    address esusuStorageContract) public OwnableService(serviceContract){
        _owner = msg.sender;
        _savingsConfigContract = ISavingsConfig(savingsConfigContract);
        _groupsContract = IGroups(groupsContract);
        _esusuStorage = IEsusuStorage(esusuStorageContract);
    }

    
    function UpdateForTubeBankService(address forTubeBankServiceContractAddress) active onlyOwner external {
        _forTubeBankService = IForTubeBankService(forTubeBankServiceContractAddress);
    }
    
    function UpdateEsusuAdapterWithdrawalDelegate(address delegateContract) onlyOwner active external {
        _delegateContract = delegateContract;
    }
    
    /*
        NOTE: startTimeInSeconds is the time at which when elapsed, any one can start the cycle 
        -   Creates a new EsusuCycle
        -   Esusu Cycle can only be created by the owner of the group
    */
    
    function CreateEsusu(uint groupId, uint depositAmount, uint payoutIntervalSeconds,uint startTimeInSeconds, address owner, uint maxMembers) public active onlyOwnerAndServiceContract {
        //  Get Current EsusuCycleId
        uint currentEsusuCycleId = _esusuStorage.GetEsusuCycleId();

        // Get Group information by Id
        (uint id, string memory name, string memory symbol, address creatorAddress) = GetGroupInformationById(groupId);
        
        require(owner == creatorAddress, "EsusuCycle can only be created by group owner");
        
        _esusuStorage.CreateEsusuCycleMapping(groupId,depositAmount,payoutIntervalSeconds,startTimeInSeconds,owner,maxMembers);
        
        //  emit event
        emit CreateEsusuCycleEvent(now, currentEsusuCycleId, depositAmount, owner, payoutIntervalSeconds,CurrencyEnum.Dai,Dai,_esusuStorage.GetEsusuCycleState(currentEsusuCycleId));
        
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
    
       function JoinEsusu(uint esusuCycleId, address member) public onlyOwnerAndServiceContract active {
        //  Get Current EsusuCycleId
        uint currentEsusuCycleId = _esusuStorage.GetEsusuCycleId();
        
        //  Check if the cycle ID is valid
        require(esusuCycleId > 0 && esusuCycleId <= currentEsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        
        //  Get the Esusu Cycle struct
        
        (uint CycleId, uint DepositAmount, uint CycleState,uint TotalMembers,uint MaxMembers) = _esusuStorage.GetEsusuCycleBasicInformationForEsusuAdapter(esusuCycleId);
        //  If cycle is not in Idle State, bounce 
        require( CycleState == uint(CycleStateEnum.Idle), "Esusu Cycle must be in Idle State before you can join");

        
        //  If cycle is filled up, bounce 

        require(TotalMembers < MaxMembers, "Esusu Cycle is filled up, you can't join");
        
        //  check if member is already in this cycle 
        require(_isMemberInCycle(member,esusuCycleId) == false, "Member can't join same Esusu Cycle more than once");
        
        //  If user does not have enough Balance, bounce. For now we use Dai as default
        uint memberBalance = _BUSD.balanceOf(member);
        
        require(memberBalance >= DepositAmount, "Balance must be greater than or equal to Deposit Amount");
        
        
        //  If user balance is greater than or equal to deposit amount then transfer from member to this contract
        //  NOTE: approve this contract to withdraw before transferFrom can work
        _BUSD.transferFrom(member, address(this), DepositAmount);
        
        //  Increment the total deposited amount in this cycle
        uint totalAmountDeposited = _esusuStorage.IncreaseTotalAmountDepositedInCycle(CycleId,DepositAmount);
        
        
       _esusuStorage.CreateMemberAddressToMemberCycleMapping(
            member,
            esusuCycleId
        );

        //  Increase TotalMembers count by 1
        _esusuStorage.IncreaseTotalMembersInCycle(esusuCycleId);
        //  Create the position of the member in the cycle
        _esusuStorage.CreateMemberPositionMapping(CycleId, member);
        //  Create mapping to track the Cycles a member belongs to by index and by ID
        _esusuStorage.CreateMemberToCycleIndexToCycleIDMapping(member, CycleId);

        //  Get  the BUSD deposited for this cycle by this user: DepositAmount
        
        //  Get the balance of fBUSDSharesForContract before save operation for this user
        uint fBUSDSharesForContractBeforeSave = _fBUSD.balanceOf(address(this));
        
        //  Invest the dai in Yearn Finance using Dai Lending Service.
        
        //  NOTE: yDai will be sent to this contract
        //  Transfer dai from this contract to dai lending adapter and then call a new save function that will not use transferFrom internally
        //  Approve the daiLendingAdapter so it can spend our Dai on our behalf 
        address daiLendingAdapterContractAddress = _forTubeBankService.GetForTubeAdapterAddress();
        _BUSD.approve(daiLendingAdapterContractAddress,DepositAmount);
        
        _forTubeBankService.Save(DepositAmount);
        
        //  Get the balance of fBUSDSharesForContract after save operation
        uint fBUSDSharesForContractAfterSave = _fBUSD.balanceOf(address(this));
        
        
        //  Save fBUSD Total balanceShares for this member
        uint sharesForMember = fBUSDSharesForContractAfterSave.sub(fBUSDSharesForContractBeforeSave);
        
        //  Increase TotalDeposits made to this contract 

        _esusuStorage.IncreaseTotalDeposits(DepositAmount);

        //  Update Esusu Cycle State, total cycle duration, total shares  and  cycle start time, 
        _esusuStorage.UpdateEsusuCycleSharesDuringJoin(CycleId, sharesForMember);

        //  emit event 
        emit JoinEsusuCycleEvent(now, member,TotalMembers, totalAmountDeposited,CycleId);
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
    
    function StartEsusuCycle(uint esusuCycleId) public onlyOwnerAndServiceContract active{
        
        //  Get Current EsusuCycleId
        uint currentEsusuCycleId = _esusuStorage.GetEsusuCycleId();
        
        //  Get Esusu Cycle Basic information
        (uint CycleId, uint DepositAmount, uint CycleState,uint TotalMembers,uint MaxMembers, uint PayoutIntervalSeconds, uint GroupId) = _esusuStorage.GetEsusuCycleBasicInformation(esusuCycleId);

        //  Get Esusu Cycle Total Shares
        (uint EsusuCycleTotalShares) = _esusuStorage.GetEsusuCycleTotalShares(esusuCycleId);
        
        
        //  Get Esusu Cycle Payout Interval 
        (uint EsusuCyclePayoutInterval) = _esusuStorage.GetEsusuCyclePayoutInterval(esusuCycleId);
        
        
        //  If cycle ID is valid, else bonunce
        require(esusuCycleId > 0 && esusuCycleId <= currentEsusuCycleId, "Cycle ID must be within valid EsusuCycleId range");
        

        require(CycleState == uint(CycleStateEnum.Idle), "Cycle can only be started when in Idle state");
        
        require(now > _esusuStorage.GetEsusuCycleStartTime(esusuCycleId), "Cycle can only be started when start time has elapsed");
        
    require(TotalMembers >= 2, "Cycle can only be started with 2 or more members" );
    
        //  Calculate Cycle LifeTime in seconds
        uint toalCycleDuration = EsusuCyclePayoutInterval * TotalMembers;

        
        //  Get all the BUSD deposited for this cycle
        uint esusuCycleBalance = _esusuStorage.GetEsusuCycleTotalAmountDeposited(esusuCycleId);
        
        //  Get the balance of fBUSDSharesForContract before save opration
        // uint fBUSDSharesForContractBeforeSave = _fBUSD.balanceOf(address(this));
        
        // //  Invest the dai in Yearn Finance using Dai Lending Service.
        
        // //  NOTE: yDai will be sent to this contract
        // //  Transfer dai from this contract to dai lending adapter and then call a new save function that will not use transferFrom internally
        // //  Approve the daiLendingAdapter so it can spend our Dai on our behalf 
        // address daiLendingAdapterContractAddress = _forTubeBankService.GetForTubeAdapterAddress();
        // _BUSD.approve(daiLendingAdapterContractAddress,esusuCycleBalance);
        
        // _forTubeBankService.Save(esusuCycleBalance);
        
        // //  Get the balance of fBUSDSharesForContract after save operation
        // uint fBUSDSharesForContractAfterSave = _fBUSD.balanceOf(address(this));
        
        
        // //  Save fBUSD Total balanceShares
        // uint totalShares = fBUSDSharesForContractAfterSave.sub(fBUSDSharesForContractBeforeSave).add(EsusuCycleTotalShares);
        
        // //  Increase TotalDeposits made to this contract 

        // _esusuStorage.IncreaseTotalDeposits(esusuCycleBalance);
        
        //  Update Esusu Cycle State, total cycle duration, total shares  and  cycle start time, 
        _esusuStorage.UpdateEsusuCycleDuringStart(CycleId,uint(CycleStateEnum.Active),toalCycleDuration,EsusuCycleTotalShares,now);
        
        //  emit event 
        emit StartEsusuCycleEvent(now,esusuCycleBalance, toalCycleDuration,
                                    EsusuCycleTotalShares,esusuCycleId);
    }
    
    
  
    function GetMemberCycleInfo(address memberAddress, uint esusuCycleId) active public view returns(uint CycleId, address MemberId, uint TotalAmountDepositedInCycle, uint TotalPayoutReceivedInCycle, uint memberPosition) {
        
        return _esusuStorage.GetMemberCycleInfo(memberAddress, esusuCycleId);
    }

    function GetEsusuCycle(uint esusuCycleId) public view returns(uint CycleId, uint DepositAmount, 
                                                            uint PayoutIntervalSeconds, uint CycleState, 
                                                            uint TotalMembers, uint TotalAmountDeposited, uint TotalShares, 
                                                            uint TotalCycleDurationInSeconds, uint TotalCapitalWithdrawn, uint CycleStartTimeInSeconds,
                                                            uint TotalBeneficiaries, uint MaxMembers){
        
        return _esusuStorage.GetEsusuCycle(esusuCycleId);
        
    }
    
    

    
    function GetBUSDBalance(address member) active external view returns(uint){
        return _BUSD.balanceOf(member);
    }
    
    function GetfBUSDBalance(address member) active external view returns(uint){
        return _fBUSD.balanceOf(member);
    }
    
    
    
    function GetTotalDeposits() active public view returns(uint)  {
        return _esusuStorage.GetTotalDeposits();
    } 
    
    

    
    function GetCurrentEsusuCycleId() active public view returns(uint){
        
        return _esusuStorage.GetEsusuCycleId();
    }
    
    function _isMemberInCycle(address memberAddress,uint esusuCycleId ) internal view returns(bool){
        
        return _esusuStorage.IsMemberInCycle(memberAddress,esusuCycleId);
    }
    
    function _isMemberABeneficiaryInCycle(address memberAddress,uint esusuCycleId ) internal view returns(bool){

        uint amount = _esusuStorage.GetMemberCycleToBeneficiaryMapping(esusuCycleId, memberAddress);

        //  If member has received money from this cycle, the amount recieved should be greater than 0

        if(amount > 0){
            
            return true;
        }else{
            return false;
        }
    }
    
    function _isMemberInWithdrawnCapitalMapping(address memberAddress,uint esusuCycleId ) internal view returns(bool){
        
        uint amount = _esusuStorage.GetMemberWithdrawnCapitalInEsusuCycle(esusuCycleId, memberAddress);
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
    function GetGroupInformationByName(string memory name) active public view returns (uint groupId, string memory groupName, string memory groupSymbol, address groupCreatorAddress){
        
        //  Get the group index by name
        (bool exists, uint index ) = _groupsContract.getGroupIndexerByName(name);
        
        //  Get the group id by index and return 

        return _groupsContract.getGroupByIndex(index);
    }
    
        /*
        - Get the group information by Id
    */
    function GetGroupInformationById(uint id) active public view returns (uint groupId, string memory groupName, string memory groupSymbol, address groupCreatorAddress){
        
        //  Get the group id by index and return 

        return _groupsContract.getGroupById(id);
    }
    
    /*
        - Creates the group 
        - returns the ID and other information
    */
    function CreateGroup(string memory name, string memory symbol, address groupCreator) active public {
        
           _groupsContract.createGroup(name,symbol,groupCreator);
           
    }
    
    function TransferfBUSDSharesToWithdrawalDelegate(uint amount) external active onlyOwnerAndDelegateContract {
        
        _fBUSD.transfer(_delegateContract, amount);

    }


    function DepricateContract(address newEsusuAdapterContract, string calldata reason) external onlyOwner{
        //  set _isActive to false
        _isActive = false;
        
        uint yDaiSharesBalance = _fBUSD.balanceOf(address(this));

        //  Send fBUSD shares to the new contract and halt operations of this contract
        _fBUSD.transfer(newEsusuAdapterContract, yDaiSharesBalance);
        
        DepricateContractEvent(now, _owner, reason, yDaiSharesBalance);

    }
    
    modifier onlyOwnerAndDelegateContract() {
        require(
            msg.sender == owner || msg.sender == _delegateContract,
            "Unauthorized access to contract"
        );
        _;
    }
    
    modifier active(){
        require(_isActive == true, "This contract is depricated, use new version of contract");
        _;
    }
    

}
