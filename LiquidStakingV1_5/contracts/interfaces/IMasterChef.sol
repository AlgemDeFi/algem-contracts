//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

struct PoolInfo {
    uint128 accARSWPerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
}

struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
}

interface IMasterChef {
    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

    function pendingARSW(
        uint256 pid,
        address user
    ) external view returns (uint256);

    function harvest(uint256 pid, address to) external;

    function getPeriod(
        uint256 blockNumber
    ) external view returns (uint256 period);

    function poolInfos(uint) external view returns (PoolInfo memory);

    function ARSWPerBlock(
        uint256 period
    ) external pure returns (uint256 amount);

    function totalAllocPoint() external view returns (uint256);

    function lpTokens(uint256 idx) external view returns (address);

    function userInfos(
        uint256,
        address
    ) external view returns (UserInfo memory);
}
