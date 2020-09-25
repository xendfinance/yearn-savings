pragma solidity ^0.6.6;

interface ISavingsConfig {
    enum RuleDefinition {RANGE, VALUE}

    function changeRuleCreator(string calldata ruleKey, address newRuleManager)
        external;

    function createRule(
        string calldata ruleKey,
        uint256 minimum,
        uint256 maximum,
        uint256 exact,
        RuleDefinition ruleDefinition
    ) external;

    function modifyRule(
        string calldata ruleKey,
        uint256 minimum,
        uint256 maximum,
        uint256 exact,
        RuleDefinition ruleDefinition
    ) external;

    function disableRule(string calldata ruleKey) external;

    function enableRule(string calldata ruleKey) external;
}
