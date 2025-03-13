// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILiquidStakingEvents {
    event Staked(address indexed user, uint256 val);
    event StakedInDapp(
        address indexed user,
        string indexed utility,
        uint256 val
    );
    event Unstaked(address indexed user, uint256 amount, bool immediate);
    event UnstakedFromUtility(
        address indexed user,
        string indexed utility,
        uint256 amount,
        bool immediate
    );
    event Withdrawn(address indexed user, uint256 val);
    event Claimed(address indexed user, uint256 amount);
    event ClaimedFromUtility(
        address indexed user,
        string indexed utility,
        uint256 amount
    );
    event HarvestRewards(
        address indexed user,
        string indexed utility,
        uint256 amount
    );
    event UnstakeError(
        string indexed utility,
        uint256 sum2unstake,
        uint256 indexed era,
        bytes indexed reason
    );
    event WithdrawUnbondedError(uint256 indexed _era, bytes indexed reason);
    event SetMinStakeAmount(address indexed sender, uint256 amount);
    event SetMinUnstakeAmount(address indexed sender, uint256 amount);
    event WithdrawRevenue(uint256 amount);
    event Synchronization(address indexed sender, uint256 indexed era);
    event FillUnstaking(address indexed sender, uint256 value);
    event FillRewardPool(address indexed sender, uint256 value);
    event FillUnbonded(address indexed sender, uint256 value);
    event WithdrawUnbondedSuccess(uint256 indexed _era);
    event UnstakeSuccess(uint256 indexed era, uint256 sum2unstake);
    event ClaimStakerRewardsSuccess(uint256 indexed era, uint256 receivedRewards);
    event ClaimStakerRewardsError(uint256 indexed era, bytes indexed reason);
    event StakeSuccess(
        address indexed staker,
        string indexed utilityName,
        uint256 amount
    );
    event StakeError(
        address indexed staker,
        string indexed utilityName,
        uint256 amount,
        bytes reason
    );
    event UnlockInitiated();
    event UnlockError(
        string indexed utility,
        uint256 sum2unstake,
        uint256 indexed era,
        bytes indexed reason
    );
    event PeriodUpdateStakeSuccess(uint256 indexed period, string dappName);
    event BonusRewardsClaimSuccess(
        uint256 indexed period,
        string dappName,
        uint256 gain
    );
    event BonusRewardsClaimError(
        uint256 indexed period,
        string dappName,
        bytes reason
    );
    event CleanUpExpiredEntriesSuccess(uint256 indexed period);
    event CleanUpExpiredEntriesError(uint256 indexed period, bytes reason);
    event VoteSuccess(address indexed user, uint256 indexed amount, uint256 indexed dappId);
    event UnvoteSuccess(address indexed user, uint256 indexed amount, uint256 indexed dappId);
    event CashbackLockAdded(address indexed user, address indexed nftAddr, uint256 amount, uint256 tokenId);
    event CashbackLockReleased(address indexed user, address indexed nftAddr, uint256 amount, uint256 tokenId);
    event CashbackClaimed(address indexed user, uint256 indexed amount);
    event TokensMinted(address indexed user, uint256 xnastrAmount, uint256 astrAmount, uint256 timestamp);
    event TokensBurned(address indexed user, uint256 xnastrAmount, uint256 astrAmount, uint256 timestamp);
    event NftAdded(address indexed nftAddr);
    event NftRemoved(address indexed nftAddr);
    event RestakedFromRewardPool(address indexed who, uint256 amount);
    event ImmediateUnstaked(address indexed user, uint256 amount, bool immediate);
    event WeightsToggled(bool isVoteWeights, uint256 time);
    event AlgmStakingShareSetted(address indexed who, uint256 indexed share);
    event ALGMStakingAddressSet(address indexed _newAddr);
    event InvalidCCIPMethod(bytes messageData);
    event Paused(address caller);
    event Unpaused(address caller);
    event LiquidStakingManagerSet(address liquidStakingManagerAddress);
    event FunctionPaused(bytes4 selector, bool isPaused);
}