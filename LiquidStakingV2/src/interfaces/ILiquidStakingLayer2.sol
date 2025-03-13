//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface ILiquidStakingLayer2 {
    struct Unstake {
        uint128 amount;
        uint64 startTime;
        // duration in number of Astars blocks
        // can be expressed in seconds depends on Astar's block creation time (6 or 12 secs)
        uint32 duration;
        uint16 remoteId;
        bool inWithdrawProcess;
    }

    struct VotesInfo {
        uint256 totalUsed;
        mapping(uint256 => uint256) dapp;
    }
    
    error ZeroAddress();
    error WrongStakeAmount();
    error WrongUnstakeAmount();
    error WrongTime();
    error UnstakeStillLocked();
    error SourceChainNotAllowed();
    error SenderNotAllowed();
    error AlreadyClaimed();
    error AlreadyBeingWithdrawn();
    error NotEnoughVotePower();
    error NotEnoughVotes();
    error WrongVotesNumber();
    error AlreadyPaused();
    error NotPaused();
    error NotAllowedWhenPaused();

    event StakeInited(address indexed who, uint256 indexed amount);
    event Staked(address indexed who, uint256 indexed mintedXnastr);
    event UnstakeInited(address indexed who, uint256 indexed amount, bool immediate);
    event Unstaked(address indexed who, uint256 indexed astrAmount, uint256 indexed duration, bool immediate);
    event UnstakeFailed(address indexed staker, uint256 indexed xnastrAmount);
    event StakeFailed(address indexed staker, uint256 indexed wastrAmount);
    event WithdrawInited(address indexed staker, uint256 indexed unstakeId);
    event Withdrawn(address indexed staker, uint256 indexed amount);
    event WithdrawFailed(address indexed staker, uint256 indexed unstakeId);
    event VoteInited(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event VoteFailed(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event Voted(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event UnvoteInited(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event UnvoteFailed(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event Unvoted(address indexed staker, uint256 indexed votes, uint256 indexed dappId);
    event InvalidCCIPMethod(bytes messageData);
    event Paused(address caller);
    event Unpaused(address caller);
}