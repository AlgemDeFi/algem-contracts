//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "src/interfaces/LF/ILFVault.sol";
import "src/interfaces/LF/ILWRAPPED.sol";
import "src/interfaces/LF/ILFPool.sol";

interface IALGMStaking {
    function topUpRewardsPool(address token, uint256 qty) external payable;
}

/// @title Base liquid farming vault contract which should be extended based on particular dApp
abstract contract Vault is ILFVault, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public expired;
    uint8 public LIQUIDATION_THRESHOLD;

    uint8 public revenueSplit;
    /// @dev magic address used in ALGMStaking contract
    address constant ASTR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public rewardFee;
    uint256 public constant REWARDS_PRECISION = 1_000_000_000_000;

    uint256 public roundDuration;
    uint256 public START;
    uint256 public FINISH;

    uint256 public totalALGMStaked;
    uint256 public algmRewardPool;

    uint256 public totalWRAPPEDBalance;
    uint256 public totalTokenBalance;

    IERC20 public ALGM;
    ILWRAPPED public lWRAPPED;
    IALGMStaking public algmStaking;
    ILFPool public pool;

    mapping(address => uint256) public userALGMBalance;
    mapping(uint256 => uint256) public roundALGMStaked;
    mapping(uint256 => uint256) public algmRewards;

    event HarvestALGM(uint256 round, uint256 amount);
    event ALGMStaked(address indexed sender, uint256 amount);
    event ALGMUnstaked(address indexed receiver, uint256 amount);
    event LiquidationThresholdSet(uint256 newValue);

    error InvalidAmount();
    error Expiration();
    error Liquidation();

    /// @notice restake ALGM on claim to gain more farming rewards in future rounds
    /// @param _user restaker
    /// @param _amount to restake
    function _restakeALGM(address _user, uint256 _amount) internal {
        userALGMBalance[_user] += _amount;
        totalALGMStaked += _amount;

        emit ALGMStaked(_user, _amount);
    }

    /// @notice unstake ALGM which were prevoiusly staked
    /// @param _user unstaker
    /// @param _amount to unstake
    function _unstakeALGM(address _user, uint256 _amount) internal {
        if (userALGMBalance[_user] < _amount) {
            revert InvalidAmount();
        }

        totalALGMStaked -= _amount;
        userALGMBalance[_user] -= _amount;

        ALGM.safeTransfer(_user, _amount);

        emit ALGMUnstaked(_user, _amount);
    }

    /// @notice find out which round we are currently in
    /// @return uint256 round number
    function getCurrentRound() public view returns (uint256) {
        if (START == 0) {
            revert Expiration();
        }

        if (block.timestamp > FINISH) {
            return totalRounds() + 1;
        }
        return (block.timestamp - START) / roundDuration + 1;
    }

    /// @notice fill ALGM rewards pool since round till current
    /// @param _amount approved
    /// @param _round number to start from
    function addALGMRewards(uint256 _amount, uint256 _round) external returns (uint256) {
        require(msg.sender == address(pool));
        if (_round > totalRounds()) return _round;

        ALGM.safeTransferFrom(msg.sender, address(this), _amount);
        algmRewardPool += _amount;
        uint256 cr = getCurrentRound();

        uint256 rounds = cr - _round;
        if (rounds == 0) return _round;
        ++_round;
        uint256 amount = _amount / rounds;
        for (uint256 i = _round; i <= cr; i++) {
            algmRewards[_round] += amount;
            unchecked {
                ++_round;
            }
        }

        emit HarvestALGM(_round, _amount);
        return cr;
    }

    /// @notice calculate total rounds
    /// @return uint256 total amount of rounds
    function totalRounds() public view returns (uint256) {
        return (FINISH - START) / roundDuration;
    }

    /// @notice pauses deposits
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice unpauses deposits
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /// @notice set liquidation threshold
    /// @param _t new value
    function setLiquidation(uint8 _t) external onlyOwner {
        require(_t < 200);
        require(LIQUIDATION_THRESHOLD == 0);
        LIQUIDATION_THRESHOLD = _t;

        emit LiquidationThresholdSet(_t);
    }

    /// @notice override this in particular vault
    function withdrawRevenue() external virtual;

    /// @notice set % amount sent to ALGM staking
    /// @param _split percentage
    function setRevenueSplit(uint8 _split) external onlyOwner {
        require(_split <= 100);
        require(_split >= 50);
        revenueSplit = _split;
    }

    /// @notice set algm staking contract address
    /// @param _staking address
    function setALGMStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        require(address(algmStaking) == address(0));

        algmStaking = IALGMStaking(_staking);
    }
}
