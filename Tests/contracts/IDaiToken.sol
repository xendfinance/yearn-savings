// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './IERC20.sol';

/*
    This contract returns the address of the Dai Stable Coin Smart Contract
*/
interface IDaiToken is IERC20{
     
    function getDaiContractAddress() external view returns(address);
       
}