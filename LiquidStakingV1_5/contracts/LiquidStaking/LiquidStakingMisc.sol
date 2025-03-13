// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";

contract LiquidStakingMisc is AccessControlUpgradeable, LiquidStakingStorage {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    function withdrawRevenue(uint256 _amount) external onlyRole(MANAGER) {
        require(totalRevenue >= _amount, "Not enough funds in revenue pool");
        totalRevenue -= _amount;
        payable(msg.sender).sendValue(_amount);

        emit WithdrawRevenue(_amount);
    }

    function withdrawOverage(uint256 amount) external onlyRole(MANAGER) {
        require(address(this).balance - amount >= rewardPool, "Not allowed");
        payable(msg.sender).sendValue(amount);
    }
}