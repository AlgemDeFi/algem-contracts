// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILiquidStakingErrors {
    error AlreadyClaimed();
    error ArraysLengthMismatch();
    error DappAlreadyAdded();
    error DappInactive();
    error EraUpdated();
    error EraYetToCome();
    error InsufficientAmount();
    error InsufficientValue();
    error NotEnoughRewards();
    error NoUtilitySpecified();
    error NothingToClaim();
    error OnlyNDistributorAllowed();
    error PartnerPoolsCanNotClaim();
    error RevenuePoolInsufficientFunds();
    error RewardsPoolInsufficientFunds();
    error UnlockedPoolInsufficientFunds();
    error ZeroAddress();
    error ZeroAmountStake();
    error ZeroAmountUnstake();
    error ZeroAmountSetMinStake();
    error NotEnoughTokenBalance();
    error WrongNftAddress();
    error NotEnoughNFTForLock();
    error WrongLockAmount();
    error NoCashbackLocks();
    error NotEnoughLockedALGM();
    error LockNotFounded();
    error NftAlreadyLockedByUser();
    error WrongNFTRelease();
    error WrongNFTClaim();
    error WrongNFTAdding();
    error ZeroCashback();
    error RestakeFromRewardPoolFailed();
    /// @dev Not enough reward pool for immediate unstake
    error NotEnoughRewardPool();
    error NotEnoughBlocksPassed();
    /// @dev Sum of weights should be equal to 1
    error IncorrectWeightsSumm();
    error UnknownDapp();
    /// @dev Length of weights array should be equal to dappsList length
    error WrongWeightsLength();
    /// @dev Can only renounce roles for self
    error NotAllowedToRenounce();
    /// @dev Default admin cannot revoke or renounce role
    error NotAllowedForDefaultAdmin();
    error ZeroAmountWithdrawDappRewards();
    error TooLargeAmount();
    error IncorrectDappAddr();
    error DappLimitReached();
    error NotEnoughVotingPower();
    error NotEnoughVotesToUnvote();
    error NotPartiallyPaused();
    error AlreadyPartiallyPaused();
    error DappIsNotActive();
    error FunctionIsUnderPause();
    error AlreadyPaused();
    error NotPaused();
    error WrongAddress();
    error ManagerShouldBeContract();
    /// @dev algmStakingShare cannot be larger that 100%
    error TooLargeAlgmStakingShare();
    /// @dev Allowed only for LiquidStaking 
    error OnlyForThis();
    error NotAllowedSender();
    error TooLowUnstake();
    error SourceChainNotAllowed();
    error SenderNotAllowed();
    error NftAlreadyAdded();
    error NftNotFound();
}