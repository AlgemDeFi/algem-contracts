//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IKaglaFarm {
    function deposit(uint256 value, address account, bool _claimRewards) external;
    function withdraw(uint256 value, bool _claimRewards) external;
    function claimable_tokens(address adr) external returns (uint256);
}