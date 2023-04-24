//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

struct PoolInfo {
    address farmingToken; // Address of farming token contract.
    address[] rewardTokens; // Reward tokens.
    uint256[] rewardPerBlock; // Reward tokens created per block.
    uint256[] accRewardPerShare; // Accumulated rewards per share, times 1e12.
    uint256[] remainingRewards; // remaining rewards in the pool.
    uint256 amount; // amount of farming token.
    uint256 lastRewardBlock; // Last block number that pools updated.
    uint256 startBlock; // Start block of pools.
    uint256 claimableInterval; // How many blocks of rewards can be claimed.
}

interface IZenlinkFarm {
    // Stake farming tokens to the given pool.
    function stake(uint256 pid, address farmingToken, uint256 amount) external;
    // Redeem farming tokens from the given pool.
    function redeem(uint256 pid, address farmingToken, uint256 amount) external;
    // Claim rewards when block number larger than user's nextClaimableBlock.
    function claim(uint256 _pid) external;
    function pendingRewards(uint256 _pid, address _user) external view returns(uint256[] memory rewards, uint256 nextClaimableBlock);
    function getPoolInfo(uint256 pid) external view returns (
        address farmingToken,
        uint256 amount,
        address[] memory rewardTokens,
        uint256[] memory rewardPerBlock,
        uint256[] memory accRewardPerShare,
        uint256 lastRewardBlock,
        uint256 startBlock,
        uint256 claimableInterval
    );
}
