//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILLMaster {
    function getUserPools(
        address
    ) external view returns (address[] memory, uint256[] memory);
}
