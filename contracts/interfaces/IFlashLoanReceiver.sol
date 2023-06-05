// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISio2LendingPoolAddressesProvider} from "./ISio2LendingPoolAddressesProvider.sol";
import {ISio2LendingPool} from "./ISio2LendingPool.sol";

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the SiO2 fee IFlashLoanReceiver.
 * @author SiO2
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER()
        external
        view
        returns (ISio2LendingPoolAddressesProvider);

    function LENDING_POOL() external view returns (ISio2LendingPool);
}
