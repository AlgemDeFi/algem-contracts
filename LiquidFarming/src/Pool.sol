//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "src/interfaces/LF/ILFMaster.sol";
import "src/interfaces/LF/ILFVault.sol";

/// @title Base liquid farming pool contract which should be extended based on particular dApp
abstract contract Pool is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct vaultData {
        address addr;
        uint256 duration;
        uint256 startTS;
        uint256 finTS;
        uint256 cr;
        uint256 tr;
        uint256 dailyALGM;
    }

    address public pairToken;
    address public ALGM;

    ILFMaster public master;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    uint256 public totalALGMBalance;
    uint256 public vaultsCount;

    address[] public vaults;
    uint256[3] public lastDistributed;
    uint256[3] public shares;

    error InvalidAmount();
    error InvalidAddress();

    event DistributedALGM(uint256 id, address indexed vault, uint256 _amount);
    event AddVault(address vault, uint256 share);
    event SetVaultShare(uint256 id, address indexed vault, uint256 share);
    event RemoveVault(address vault);

    ////VAULT MANAGEMENT FUNCTIONS///
    /// @notice register new vault
    /// @param _vault address
    function addVault(address _vault, uint256 _share) external onlyRole(MANAGER_ROLE) {
        require(vaultsCount < 3);
        require(_share > 0);
        if (_vault == address(0)) {
            revert InvalidAddress();
        }

        //duplicate check
        for (uint256 i = vaultsCount; i > 0;) {
            require(_vault != vaults[i - 1]);
            unchecked {
                --i;
            }
        }
        shares[vaultsCount] = _share;
        ++vaultsCount;
        require(shares[0] + shares[1] + shares[2] <= 100);
        _grantRole(VAULT_ROLE, _vault);
        if (vaults.length < vaultsCount) {
            vaults.push(_vault);
        } else {
            vaults[vaultsCount - 1] = _vault;
        }
        emit AddVault(_vault, _share);
    }

    /// @notice set vault share in ALGM distribution
    /// @param _id vault id
    /// @param _share new share
    function setVaultShare(uint256 _id, uint256 _share) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_id < 3);
        shares[_id] = _share;
        require(shares[0] + shares[1] + shares[2] <= 100);

        emit SetVaultShare(_id, vaults[_id], _share);
    }

    /// @notice unregister vault
    /// @param _id of the vault
    function removeVault(uint256 _id) external onlyRole(MANAGER_ROLE) {
        address vault = vaults[_id];
        _revokeRole(VAULT_ROLE, vault);
        --vaultsCount;
        vaults[_id] = vaults[vaultsCount];
        shares[_id] = shares[vaultsCount];
        lastDistributed[_id] = lastDistributed[vaultsCount];
        delete vaults[vaultsCount];

        emit RemoveVault(vault);
    }

    ////ALGM DISTRIBUTION FUNCTIONS////
    /// @notice add some algm and distribute it accordingly
    /// @param _amount algm amount to add
    function addALGM(uint256 _amount) external {
        require(msg.sender == address(master)); //@dev actually [H01] related
        
        if (_amount > 0) IERC20(ALGM).safeTransferFrom(msg.sender, address(this), _amount);
        else return;
        for (uint8 i = 0; i < vaultsCount; i++) {
            uint256 amount = _amount * shares[i] / 100;
            if (amount == 0) {
                lastDistributed[i]++;
                continue;
            }
            IERC20(ALGM).safeIncreaseAllowance(vaults[i], amount);
            lastDistributed[i] = ILFVault(vaults[i]).addALGMRewards(amount, lastDistributed[i]);

            emit DistributedALGM(i, vaults[i], amount);
        }
    }

    /// @notice called by vault to obtain ALGM
    function harvest() external onlyRole(VAULT_ROLE) {
        master.harvest();
    }

    ////VIEW FUNCTIONS////
    /// @notice get all registered vaults
    /// @return vaults_ addresses
    function getVaults() external view returns (vaultData[] memory vaults_) {
        vaults_ = new vaultData[](vaultsCount);

        for (uint256 i; i < vaultsCount;) {
            uint256 start = ILFVault(vaults[i]).START();
            uint256 fin = ILFVault(vaults[i]).FINISH();
            uint256 cr = ILFVault(vaults[i]).getCurrentRound();
            vaults_[i].addr = vaults[i];
            vaults_[i].duration = fin - start;
            vaults_[i].startTS = start;
            vaults_[i].finTS = fin;
            vaults_[i].cr = cr;
            vaults_[i].tr = (fin - start) / ILFVault(vaults[i]).roundDuration();
            ///@dev assuming default 1 week round duration, otherwise value considered invalid
            vaults_[i].dailyALGM = ILFVault(vaults[i]).algmRewards(cr > 1 ? cr - 1 : cr) * 2;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice get user nft + LiquidStaking bonus
    /// @param _user to calculate
    function getUserBonus(address _user) external view returns (uint256) {
        return master.getUserBonus(_user);
    }
}
