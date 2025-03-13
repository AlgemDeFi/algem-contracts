//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/LF/ILWRAPPED.sol";
import "src/interfaces/LF/ILFVault.sol";

/// @title Liquid Wrapped Centre contract
/// @notice This contract is needed to help any LWRAPPED token owner
///         to quickly burn those tokens in exchange for base liquidity
contract LWRAPPEDCentre is OwnableUpgradeable {
    using SafeERC20 for ILWRAPPED;
    using Address for address payable;

    /// @notice all data on signle vault
    struct getterData {
        address vault;
        address lwrapped;
        string name;
        uint256 deadline;
        uint256 balance;
    }

    uint256 public vaultsCount;
    address[] public vaults;
    mapping(address => uint256) public vaultIndex;
    mapping(address => address) public vault2LWRAPPED;

    error InvalidAmount();
    error InvalidAddress();

    event VaultAdded(address vault, address lwrapped);
    event VaultRemoved(address vault, address lwrapped);
    event Withdrawn(address indexed user, address indexed vault, uint256 _amount);

    receive() external payable {
        require(msg.sender == vaults[vaultIndex[msg.sender]]);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

    /// @notice register the vault in centre contract
    /// @param _vault to add
    /// @param _lwrapped owned by vault
    function addVault(address _vault, address _lwrapped) external onlyOwner {
        if (_vault == address(0) || _lwrapped == address(0)) revert InvalidAddress();
        require(vault2LWRAPPED[_vault] == address(0) && vaultIndex[_vault] == 0, "Already set");
        vaultIndex[_vault] = vaultsCount;
        vault2LWRAPPED[_vault] = _lwrapped;
        ++vaultsCount;
        vaults.push(_vault);

        emit VaultAdded(_vault, _lwrapped);
    }

    /// @notice remove vault from the centre contract
    /// @param _vault to remove
    function removeVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert InvalidAddress();
        require(vault2LWRAPPED[_vault] != address(0), "Not set");
        // set index of last added vault to the vault we are about to delete
        vaultIndex[vaults[vaultsCount - 1]] = vaultIndex[_vault];
        // set last added vault to deleted vault
        vaults[vaultIndex[_vault]] = vaults[vaultsCount - 1];

        emit VaultRemoved(_vault, vault2LWRAPPED[_vault]);
        // deleted vault lwrapped nullify
        vault2LWRAPPED[_vault] = address(0);
        // nullify deleted vault index
        vaultIndex[_vault] = 0;
        --vaultsCount;
        vaults.pop();
    }

    /// @notice "route" the lwrapped tokens back to its vault to burn them
    /// @param _amount to burn
    /// @param _vault to withdraw from
    function withdraw(uint256 _amount, address _vault) external {
        ILWRAPPED lwrapped = ILWRAPPED(vault2LWRAPPED[_vault]);
        lwrapped.safeTransferFrom(msg.sender, address(this), _amount);
        lwrapped.approve(_vault, _amount);

        ILFVault(_vault).withdraw(_amount);
        payable(msg.sender).sendValue(_amount);

        emit Withdrawn(msg.sender, _vault, _amount);
    }

    /// @notice getter function to find out which token user holds
    /// @param _user to check
    /// @return data_ info on vaults & user balance
    function getVaults(address _user) external view returns (getterData[] memory data_) {
        data_ = new getterData[](vaultsCount);

        for (uint256 i = 0; i < vaultsCount;) {
            data_[i].vault = vaults[i];
            data_[i].lwrapped = vault2LWRAPPED[vaults[i]];
            data_[i].name = ILWRAPPED(vault2LWRAPPED[vaults[i]]).name();
            data_[i].deadline = ILFVault(vaults[i]).FINISH();
            data_[i].balance = ILWRAPPED(vault2LWRAPPED[vaults[i]]).balanceOf(_user);
            unchecked {
                ++i;
            }
        }
    }
}
