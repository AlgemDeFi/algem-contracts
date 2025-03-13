// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IALGMStaking {
    struct TimeDistributedReward {
        bytes4 id;
        address token;
        uint256 qty;
        uint256 startAt;
        uint256 timeframe;
        uint256 slicesDistributed;
        uint256 sliceValue;
        uint256[3] poolsWeights;
    }

    struct WithdrawalRequest {
        uint256 id;
        uint256 qty;
        uint256 withdrawAfter;
        uint256 poolID;
    }

    function acceptOwnership() external;
    function addPartnerToken(address token) external;
    function algm() external view returns (address);
    function appendAuthrizedList(address addr) external;
    function authorizedList(uint256) external view returns (address);
    function calculateRewards(address staker, uint256 poolID)
        external
        view
        returns (uint256, address, uint256[] memory, bool);
    function checkIfAllowedToStakeInPool(address staker, uint256 poolID) external view returns (bool);
    function checkIfStaker(address user) external view returns (bool);
    function claimRewards(uint256 poolID) external;
    function delPartnerToken(address token) external;
    function getActualStakeQty(address staker, uint256 poolID) external view returns (uint256);
    function getAuthorizedList() external view returns (address[] memory);
    function getPartnerTokensList() external view returns (address);
    function getPendingWithdrawalRequests(address addr) external view returns (WithdrawalRequest[] memory);
    function getPoolsWeights() external view returns (uint256[3] memory);
    function getStakers() external view returns (uint256, address[] memory);
    function getTimeDistRewards() external view returns (TimeDistributedReward[] memory);
    function initialize(address _algm, address _veAlgm) external;
    function isPartnerToken(address) external view returns (bool);
    function liqlend() external view returns (address);
    function owner() external view returns (address);
    function partnerTokenAddrToIndex(address) external view returns (uint256);
    function partnerTokens(uint256) external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function pendingOwner() external view returns (address);
    function pools(uint256)
        external
        view
        returns (uint256 shareOfRewardsPool, uint256 veAlgmPerStake, uint256 unbondPeriod, uint256 totalStaked);
    function renounceOwnership() external;
    function rewardDebts(address, uint256, address) external view returns (uint256);
    function rewards(address, uint256, address) external view returns (uint256);
    function rpSurplus(address) external view returns (uint256);
    function rpTimeDistRewards(uint256)
        external
        view
        returns (
            bytes4 id,
            address token,
            uint256 qty,
            uint256 startAt,
            uint256 timeframe,
            uint256 slicesDistributed,
            uint256 sliceValue
        );
    function rpTokensARPS(uint256, address) external view returns (uint256);
    function rpTokensQty(address) external view returns (uint256);
    function setLiquidLendingAddr(address _liqlend) external;
    function setPoolWeights(uint256[] memory weights) external;
    function stake(uint256 poolID, uint256 stakeQty) external;
    function stakes(uint256, address) external view returns (uint256 algmQty, uint256 veAlgmQty);
    function topUpRewardsPool(address token, uint256 qty) external payable;
    function topUpRewardsPoolFor(address token, uint256 qty, uint256 timeframe) external payable;
    function totalAlgmStaked() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function unstake(uint256 poolID, uint256 unstakeQty) external;
    function updateAuthorizedList(address[] memory authorized) external;
    function veAlgm() external view returns (address);
    function withdraw(uint256 id) external;
    function withdrawStuck(address token, address to, uint256 qty) external;
    function withdrawSurplus(address token, address to, uint256 qty) external;
    function withdrawalRequests(address, uint256)
        external
        view
        returns (uint256 id, uint256 qty, uint256 withdrawAfter, uint256 poolID);
}
