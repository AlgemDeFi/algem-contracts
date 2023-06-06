// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFlashLoanReceiver} from './interfaces/IFlashLoanReceiver.sol';
import {ISio2LendingPoolAddressesProvider} from './interfaces/ISio2LendingPoolAddressesProvider.sol';
import {ISio2LendingPool} from './interfaces/ISio2LendingPool.sol';

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;

  ISio2LendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ISio2LendingPool public immutable override LENDING_POOL;

  constructor(ISio2LendingPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ISio2LendingPool(provider.getLendingPool());
  }
}