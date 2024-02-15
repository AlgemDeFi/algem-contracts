// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";

contract LiquidStakingMisc is AccessControlUpgradeable, LiquidStakingStorage {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    /// @notice Withdraw revenue
    function withdrawRevenue(uint256 _amount) external onlyRole(MANAGER) {
        require(totalRevenue >= _amount, "Not enough funds in revenue pool");
        totalRevenue -= _amount;
        payable(msg.sender).sendValue(_amount);

        emit WithdrawRevenue(_amount);
    }

    /// @notice Withdraw rewards overage. Calculates offchain.
    ///         Formed when users use their nASTR tokens in defi protocols bypassing algem-adapters.
    function withdrawOverage(uint256 amount) external onlyRole(MANAGER) {
        rewardPool -= amount;
        payable(msg.sender).sendValue(amount);
    }

    /// @notice Changing the application address in the event of delisting
    function changeDappAddress(
        string memory _dappName,
        address _newAddress
    ) external onlyRole(MANAGER) {
        Dapp storage dapp = dapps[_dappName];
        uint256 toRestake = dapp.stakedBalance + dapp.sum2unstake;

        // unstake from deprecated address
        DAPPS_STAKING.withdraw_from_unregistered(dapp.dappAddress);

        // change address
        dapp.dappAddress = _newAddress;

        // stake unstaked ASTR to new address
        DAPPS_STAKING.bond_and_stake(_newAddress, uint128(toRestake));
    }
}

// selectors ["0x0ceff204","0xa0231e29","0x27917d60"]