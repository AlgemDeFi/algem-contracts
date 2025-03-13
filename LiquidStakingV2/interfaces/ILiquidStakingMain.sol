// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library LiquidStakingStorage {
    struct Withdrawal {
        uint256 val;
        uint256 blockReq;
        uint256 lag;
    }
}

interface Interface {
    error AlreadyClaimed();
    error AlreadyPartiallyPaused();
    error AlreadyPaused();
    error ArraysLengthMismatch();
    error DappAlreadyAdded();
    error DappInactive();
    error DappIsNotActive();
    error DappLimitReached();
    error EraUpdated();
    error EraYetToCome();
    error FunctionIsUnderPause();
    error IncorrectDappAddr();
    error IncorrectWeightsSumm();
    error InsufficientAmount();
    error InsufficientValue();
    error LockNotFounded();
    error ManagerShouldBeContract();
    error NftAlreadyLockedByUser();
    error NoCashbackLocks();
    error NoUtilitySpecified();
    error NotAllowedForDefaultAdmin();
    error NotAllowedSender();
    error NotAllowedToRenounce();
    error NotEnoughBlocksPassed();
    error NotEnoughLockedALGM();
    error NotEnoughNFTForLock();
    error NotEnoughRewardPool();
    error NotEnoughRewards();
    error NotEnoughTokenBalance();
    error NotEnoughVotesToUnvote();
    error NotEnoughVotingPower();
    error NotEnoughXNASTRForLock();
    error NotPartiallyPaused();
    error NotPaused();
    error NothingToClaim();
    error OnlyForThis();
    error OnlyNDistributorAllowed();
    error PartnerPoolsCanNotClaim();
    error RestakeFromRewardPoolFailed();
    error RevenuePoolInsufficientFunds();
    error RewardsPoolInsufficientFunds();
    error TooLargeAlgmStakingShare();
    error TooLargeAmount();
    error TooLowUnstake();
    error UnknownDapp();
    error UnlockedPoolInsufficientFunds();
    error WrongAddress();
    error WrongNFTAdding();
    error WrongNFTClaim();
    error WrongNFTRelease();
    error WrongNftAddress();
    error WrongWeightsLength();
    error ZeroAddress();
    error ZeroAmountSetMinStake();
    error ZeroAmountStake();
    error ZeroAmountUnstake();
    error ZeroAmountWithdrawDappRewards();
    error ZeroCashback();

    event AlgmStakingShareSetted(address indexed who, uint256 indexed share);
    event BonusRewardsClaimError(uint256 indexed period, string dappName, bytes reason);
    event BonusRewardsClaimSuccess(uint256 indexed period, string dappName, uint256 gain);
    event CashbackClaimed(address indexed user, uint256 indexed amount);
    event CashbackLockAdded(address indexed user, address indexed nftAddr, uint256 amount, uint256 tokenId);
    event CashbackLockReleased(address indexed user, address indexed nftAddr, uint256 amount, uint256 tokenId);
    event ClaimStakerRewardsError(uint256 indexed era, bytes indexed reason);
    event ClaimStakerRewardsSuccess(uint256 indexed era, uint256 receivedRewards);
    event Claimed(address indexed user, uint256 amount);
    event ClaimedFromUtility(address indexed user, string indexed utility, uint256 amount);
    event CleanUpExpiredEntriesError(uint256 indexed period, bytes reason);
    event CleanUpExpiredEntriesSuccess(uint256 indexed period);
    event FillRewardPool(address indexed sender, uint256 value);
    event FillUnbonded(address indexed sender, uint256 value);
    event FillUnstaking(address indexed sender, uint256 value);
    event HarvestRewards(address indexed user, string indexed utility, uint256 amount);
    event ImmediateUnstaked(address indexed user, uint256 amount, bool immediate);
    event Initialized(uint8 version);
    event NftAdded(address indexed nftAddr);
    event PeriodUpdateStakeSuccess(uint256 indexed period, string dappName);
    event RestakedFromRewardPool(address indexed who, uint256 amount);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event SetMinStakeAmount(address indexed sender, uint256 amount);
    event SetMinUnstakeAmount(address indexed sender, uint256 amount);
    event StakeError(address indexed staker, string indexed utilityName, uint256 amount, bytes reason);
    event StakeSuccess(address indexed staker, string indexed utilityName, uint256 amount);
    event Staked(address indexed user, uint256 val);
    event StakedInDapp(address indexed user, string indexed utility, uint256 val);
    event Synchronization(address indexed sender, uint256 indexed era);
    event TokensBurned(address indexed user, uint256 xnastrAmount, uint256 astrAmount, uint256 timestamp);
    event TokensMinted(address indexed user, uint256 xnastrAmount, uint256 astrAmount, uint256 timestamp);
    event UnlockError(string indexed utility, uint256 sum2unstake, uint256 indexed era, bytes indexed reason);
    event UnlockInitiated();
    event UnstakeError(string indexed utility, uint256 sum2unstake, uint256 indexed era, bytes indexed reason);
    event UnstakeSuccess(uint256 indexed era, uint256 sum2unstake);
    event Unstaked(address indexed user, uint256 amount, bool immediate);
    event UnstakedFromUtility(address indexed user, string indexed utility, uint256 amount, bool immediate);
    event UnvoteSuccess(address indexed user, uint256 indexed amount, uint256 indexed dappId);
    event VoteSuccess(address indexed user, uint256 indexed amount, uint256 indexed dappId);
    event WeightsToggled(bool isVoteWeights, uint256 time);
    event WithdrawRevenue(uint256 amount);
    event WithdrawUnbondedError(uint256 indexed _era, bytes indexed reason);
    event WithdrawUnbondedSuccess(uint256 indexed _era);
    event Withdrawn(address indexed user, uint256 val);

    function ALGMStaking() external view returns (address);
    function ALGMStakingASTR() external view returns (address);
    function DAPPS_STAKING() external view returns (address);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function MANAGER() external view returns (bytes32);
    function REWARDS_PRECISION() external view returns (uint256);
    function WEIGHTS_PRECISION() external view returns (uint256);
    function addCashbackLock(address _nftAddr, uint256 _amount, uint256 _tokenId) external;
    function algmStakingShare() external view returns (uint256);
    function bonusRewardsPerPeriod(uint256, uint256) external view returns (uint256);
    function cashbackLocks(address, address) external view returns (uint256 amount, uint256 tokenId, uint256 debt);
    function chunkLen() external view returns (uint256);
    function claimCashback(address[] memory _nftsAddr) external;
    function collectedCashback(address) external view returns (uint256);
    function currentEra() external view returns (uint256);
    function currentPeriod() external view returns (uint256);
    function dappLimit() external view returns (uint256);
    function dappVotes(uint256) external view returns (uint256);
    function dapps(string memory)
        external
        view
        returns (uint256 id, address dappAddress, uint256 stakedBalance, uint256 sum2unstake);
    function dappsList(uint256) external view returns (string memory);
    function defaultWeights(string memory) external view returns (uint256);
    function distributionByWeights(bool _isStake, uint256 _amount)
        external
        view
        returns (string[] memory dappsNames, uint256[] memory dappsAmounts, uint256 surplus);
    function getASTRValue(uint256 _xnastrAmount) external view returns (uint256);
    function getAccumulatedCashback(address _user, address _nftAddr) external view returns (uint256);
    function getDappsInfo(address _user)
        external
        returns (
            uint256[] memory totalVotesInDapps,
            uint256[] memory dappsWeights,
            uint256[] memory totalStakedInDapps,
            uint256[] memory userVePosInDapps
        );
    function getDappsInfoInRange(uint256 _fromId, uint256 _toId, address _user)
        external
        view
        returns (
            uint256[] memory totalVotesInDapps,
            uint256[] memory dappsWeights,
            uint256[] memory totalStakedInDapps,
            uint256[] memory userVePosInDapps
        );
    function getDappsList() external view returns (string[] memory);
    function getDappsWeights() external view returns (uint256[] memory weights);
    function getDappsWeightsInRange(uint256 _fromId, uint256 _toId) external view returns (uint256[] memory weights);
    function getNftList() external view returns (address[] memory);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function getUserWithdrawals() external view returns (LiquidStakingStorage.Withdrawal[] memory);
    function getUserWithdrawalsArray(address _user) external view returns (LiquidStakingStorage.Withdrawal[] memory);
    function getXNASTRValue(uint256 _astrAmount) external view returns (uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function isActive(string memory) external view returns (bool);
    function isPaused(bytes4) external view returns (bool);
    function isPeriodInited(uint256) external view returns (bool);
    function lastUnstaked() external view returns (uint256);
    function lastUpdated() external view returns (uint256);
    function linkAddr() external view returns (address);
    function liquidStakingManager() external view returns (address);
    function maxUnlockingChunks() external view returns (uint256);
    function minStakeAmount() external view returns (uint256);
    function minUnstakeAmount() external view returns (uint256);
    function nftList(uint256) external view returns (address);
    function nfts(address) external view returns (uint256 arps, uint256 totalLocked, uint256 discount, bool isActive);
    function paused() external view returns (bool);
    function releaseCashbackLock(address _nftAddr, uint256 _amount) external;
    function renounceRole(bytes32 role, address account) external;
    function revenuePool() external view returns (uint256);
    function revokeRole(bytes32 role, address account) external;
    function rewardPool() external view returns (uint256);
    function stake(address _staker) external payable returns (uint256, uint256);
    function stake() external payable returns (uint256 mintedXnastr);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function sync(uint256 _era) external;
    function totalCashbackLock() external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function totalVoted() external view returns (uint256);
    function unlockedPool() external view returns (uint256);
    function unlockingPeriod() external view returns (uint256);
    function unstake(address _staker, uint256 _xnastrAmount, bool _immediate) external returns (uint256, uint256);
    function unstake(uint256 _xnastrAmount, bool _immediate) external returns (uint256, uint256);
    function userVotes(address) external view returns (uint256 totalUsed);
    function usingVoteWeights() external view returns (bool);
    function voteSubperiod() external view returns (bool);
    function wastr() external view returns (address);
    function withdraw(uint256 _id) external;
    function withdraw(address _staker, uint256 _id) external;
    function withdrawals(address, uint256) external view returns (uint256 val, uint256 blockReq, uint256 lag);
    function xnASTR() external view returns (address);
}
