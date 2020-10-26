pragma solidity ^0.6.6;
import "./Ownable.sol";
import "./IEsusuService.sol";
import "./IGroups.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/*
    @Brief: This contract should calculate the Xend Token reward for users. This contract implements the reward system as described in Litepaper but this is
    much more detailed 
    
    1. We must get the Current Threshold level which is determined by the total amount deposited on the different smart contracts 
    2. They perform one or more of the following operations (Individual savings, cooperative savings, esusu)
    3. The users must meet the timelock conditions per operation to receive reward for that condition
    4. Create timelock to Category to CategoryRewardFactor Mapping 
    5. Once a new threshold level is reached, we will add it to the threshold level mapping with maximum Xend Tokens to be distributed in that level
    6. We should be able to stop reward distribution by the owner
    7. This contract can be replaced at anytime and updated in calling contracts 

*/
contract RewardConfig is Ownable {
    
    using SafeMath for uint256;

    
    constructor(address esusuServiceContract, address groupServiceContract) public Ownable(serviceContract){
        
        iEsusuService = IEsusuService(esusuServiceContract);
        
        //  NOTE: The groups contracts holds overall deposits for all savings , i.e Individual savings and groups savings
        savingsStorage = IGroups(groupServiceContract);
    }
    
    IEsusuService iEsusuService;
    IGroups savingsStorage;
    address daiTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;   

    
    uint CurrentThresholdLevel;                 // 
    
    mapping(uint => uint)   DurationToRewardFactorMapping;
    
    uint InitialThresholdValueInUSD;
    uint XendTokenRewardAtInitialThreshold;
    uint DepreciationFactor;
    uint TimeLevelUnitInSeconds;        //  This unit is used to calculate the time levels.
    uint SavingsCategoryRewardFactor;   //  Cir -> 0.7 (but we have to make it 7 to handle decimal)
    uint GroupCategoryRewardFactor;     //  Cgr -> 1.0 (but we have to make it 10 to handle decimal)
    uint EsusuCategoryRewardFactor;     //  Cer -> 1.5 (but we have to make it 10 to handle decimal)
    
    
    //  The member variables below determine the reward factor based on time. 
    //  NOTE: Ensure that the PercentageRewardFactorPerTimeLevel at 100% corresponds with MaximumTimeLevel. It means MaximumTimeLevel/PercentageRewardFactorPerTimeLevel = 1
    
    uint PercentageRewardFactorPerTimeLevel;    //  This determines the percentage of the reward factor paid for each time level eg 4 means 25%, 5 means 20%
    uint MinimumNumberOfSeconds = 2592000;      //  This determines whether we are checking time level by days, weeks, months or years. It is 30 days(1 month) in seconds by default
    uint MaximumTimeLevel;                      //  This determines how many levels can be derived based on the MinimumNumberOfSeconds that has been set
    bool RewardActive;
    
    
    
    /*  
        -   Sets the inital threshold value in USD (value in 1e18)
        -   Sets XendToken reward at the initial threshold (value in 1e18)
        -   Sets DepreciationFactor
        
    */
    function SetRewardParams(uint thresholdValue, uint xendTokenReward, uint depreciationFactor, 
                                uint savingsCategoryRewardFactor, uint groupCategoryRewardFactor, 
                                uint esusuCategoryRewardFactor, uint percentageRewardFactorPerTimeLevel,
                                uint minimumNumberOfSeconds, uint maximumTimeLevel) onlyOwner external{
        require(PercentageRewardFactorPerTimeLevel == MaximumTimeLevel, "Values must be the same to achieve unity at maximum level");
        InitialThresholdValueInUSD = thresholdValue;
        XendTokenRewardAtInitialThreshold = xendTokenReward;
        DepreciationFactor = depreciationFactor;
        SavingsCategoryRewardFactor = savingsCategoryRewardFactor;
        GroupCategoryRewardFactor = groupCategoryRewardFactor;
        EsusuCategoryRewardFactor = esusuCategoryRewardFactor;
        PercentageRewardFactorPerTimeLevel = percentageRewardFactorPerTimeLevel;
        MinimumNumberOfSeconds = minimumNumberOfSeconds;
        MaximumTimeLevel = maximumTimeLevel;
       
    }
    
    /*
        This function calculates XTr for individual savings based on the total cycle time and amountDeposited
    */
    function CalculateIndividualSavingsReward(uint totalCycleTimeInSeconds, uint amountDeposited) external view returns(uint){
        
        //  If we are not currently rewarding users, return 0
        if(RewardActive == false){
            return 0;
        }
        
        uint Cir = CalculateCategoryFactor(totalCycleTimeInSeconds,SavingsCategoryRewardFactor);
        uint XTf = CalculateRewardFactorForCurrentThresholdLevel();
        uint XTr = XTf.mul(Cir);    // NOTE: this value is in 1e18 
        
        // return XTr * amountdeposited and divided by 1e18 since the amount is already in the wei unit 

        uint individualSavingsReward = XTr.mul(amountDeposited).div(1e36);
        
        return individualSavingsReward;
    }
    
    /*
        This function calculates XTr for group or cooperative or Group savings based on the total cycle time and amountDeposited
    */
    function CalculateCooperativeSavingsReward(uint totalCycleTimeInSeconds, uint amountDeposited) external view returns(uint){
        
        //  If we are not currently rewarding users, return 0
        if(RewardActive == false){
            return 0;
        }
        
        uint Cgr = CalculateCategoryFactor(totalCycleTimeInSeconds,GroupCategoryRewardFactor);
        uint XTf = CalculateRewardFactorForCurrentThresholdLevel();
        uint XTr = XTf.mul(Cgr);    // NOTE: this value is in 1e18 which is correct
        
        // return XTr * amountdeposited and divided by 1e18 since the amount is already in the wei unit 

        uint groupSavingsReward = XTr.mul(amountDeposited).div(1e36);
        return groupSavingsReward;
    }
    
    /*
        This function calculates XTr for Esusu based on the total cycle time and amountDeposited
    */
    function CalculateEsusuReward(uint totalCycleTimeInSeconds, uint amountDeposited) external view returns(uint){
        
        //  If we are not currently rewarding users, return 0
        if(RewardActive == false){
            return 0;
        }
        
        uint Cer = CalculateCategoryFactor(totalCycleTimeInSeconds,EsusuCategoryRewardFactor);
        uint XTf = CalculateRewardFactorForCurrentThresholdLevel();
        uint XTr = XTf.mul(Cer);    // NOTE: this value is in 1e18 which is correct
        
        // return XTr * amountdeposited and divided by 1e18 since the amount is already in the wei unit 

        uint groupSavingsReward = XTr.mul(amountDeposited).div(1e36);
        return groupSavingsReward;
    }
    
    /*
        -   Get the RewardTimeLevel based on the totalCycleTimeInSeconds
        -   Get the PercentageRewardFactor based on the RewardTimeLevel : NOTE value is in 1e18
        -   Reward value is multipied by 10 because it is usually a decimal based on the category 
    */
    
    function CalculateCategoryFactor(uint totalCycleTimeInSeconds, uint reward) public view returns(uint){
        
        uint timeLevel = GetRewardTimeLevel(totalCycleTimeInSeconds);
        
        uint percentageRewardFactor = CalculatePercentageRewardFactor(timeLevel);
        
        uint result = percentageRewardFactor.mul(reward).div(10);
        
        return result;
    }
    
    /*
        1. Get the CurrentThresholdLevel
        2. Get reward factor for current threshold level (XTf) => Xend Token Threshold Per Level / Deposit Threshold for that level in USD
        
    */
    function CalculateRewardFactorForCurrentThresholdLevel() public view returns(uint){
        
        uint level = GetCurrentThresholdLevel();
        uint currentDepositThreshold = level.mul(InitialThresholdValueInUSD);
        uint currentXendTokenRewardThreshold = GetCurrentXendTokenRewardThresholdAtCurrentLevel();
        uint XTf = currentXendTokenRewardThreshold.mul(1e18).div(currentDepositThreshold);
        
        return XTf;
    }
    

    
    /*
        - This function gets the total deposits from all XendFinance smart contracts 
        - tokenAddress is required to get total deposits for the savings storage contract . Esusu service works only with DAI
    */
    function GetTotalDeposits() public view returns(uint){
        
        uint esusuDesposit = iEsusuService.GetTotalDeposits();
        
        uint savingsDeposit = savingsStorage.getTokenDeposit(daiTokenAddress);
        
        uint result = esusuDesposit.add(savingsDeposit);
        
        return result;
    }
    
    function GetCurrentThresholdLevel() public view returns(uint){
        
        uint totalDeposits = GetTotalDeposits();
        uint initialThresholdValue = InitialThresholdValueInUSD;
        
        uint level = totalDeposits.div(initialThresholdValue);
         
         if (level == 0){
             return 1;
         }
         
         return level;
    }
    
    function GetCurrentXendTokenRewardThresholdAtCurrentLevel() public view returns(uint){
        
        uint level = GetCurrentThresholdLevel();
        uint result = XendTokenRewardAtInitialThreshold.div(DepreciationFactor ** level.sub(1));
        
        return result;
    }
    
    
    /*
        - Reward time levels determine the amount of reward you will receive based on the total time of the savings cycle
        - Minimum reward time is 30 days which is 2592000 seconds 
        - If the Timelevel is 0, user does not get any Xend Token reward
        - User gets maximum Xend Token reward from Timelevel 4 since the PercentageRewardFactor will return 100% 
    */
    
    function GetRewardTimeLevel(uint totalCycleTimeInSeconds) public view returns(uint){
        
        
        uint level = totalCycleTimeInSeconds.div(MinimumNumberOfSeconds);
        
        if(level >= MaximumTimeLevel){
            level = MaximumTimeLevel;
        }
        return level;
    }
    
    /*
        -   This function calculates the percentage of the reward factor per time level.
        -   PercentageRewardFactor = TimeLevel / PercentageRewardFactorPerTimeLevel
        -   Value is returned in 1e18 to handle decimals
    */
    function CalculatePercentageRewardFactor(uint rewardTimeLevel) public view returns(uint){
        
        uint result = rewardTimeLevel.mul(1e18).div(PercentageRewardFactorPerTimeLevel);
        
        return result;
    }
    
    function SetRewardActive(bool isActive) onlyOwner external {
        RewardActive = isActive;
    }
    
}
