// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILiquidStakingManager {
    function getAddress(bytes4 selector) external view returns (address);
}