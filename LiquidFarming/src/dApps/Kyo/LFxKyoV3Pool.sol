//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "src/Pool.sol";
import "src/interfaces/LF/ILFVault.sol";
/// @title Pool contract which purpose is to provide required pair info
///        and participates in ALGM distribution
/// @custom:oz-upgrades-from LFxKyoV3Pool

contract LFxKyoV3Pool is Pool {
    using SafeERC20 for IERC20;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initialize
    /// @param _pairToken address (for ETH/USDT it is USDT)
    /// @param _master LFMaster contract
    /// @param _algm token
    function initialize(address _pairToken, address _master, address _algm) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        pairToken = _pairToken;
        master = ILFMaster(_master);
        ALGM = _algm;
    }

    /// @notice get total LPs staked
    /// @return total_ balance of this pool
    function totalBalance() external view returns (uint256 total_) {
        for (uint256 i = 0; i < vaultsCount; i++) {
            total_ += ILFVault(vaults[i]).totalBalance();
        }
    }

    /// @notice get total user lp balance
    /// @param _user to get balance
    /// @return total_ balance
    function balances(address _user) external view returns (uint256 total_) {
        for (uint256 i = 0; i < vaultsCount; i++) {
            (uint256 lp,,,,,) = ILFVault(vaults[i]).positions(_user);
            total_ += lp;
        }
    }
}
