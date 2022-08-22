//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


interface ISiriusFarm {
    function deposit(uint256 value, address account, bool claimRewards) external;
    function withdraw(uint256 value,bool claimRewards) external;
}