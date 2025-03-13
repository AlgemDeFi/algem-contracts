// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILiquidStakingAdmin {
    function restakeFromRewardPool(uint256 _amount) external;
    function addNft(address _nftAddr) external;
    function switchNftAvailability(address _nftAddr) external;
    function withdrawBonusRewards() external payable;
    function toggleWeights() external;
    function setMinStakeAmount(uint256 _amount) external payable;
    function withdrawRevenue(uint256 _amount) external payable;
    function changeDappAddress(string memory _dappName, address _newAddress) external;
    function partiallyPause() external;
    function partiallyUnpause() external;
    function revokeRole(bytes32 _role, address _account) external;
    function renounceRole(bytes32 _role, address _account) external;
    function getUserWithdrawals() external view returns (Withdrawal[] memory);
    function getUserWithdrawalsArray(address _user) external view returns (Withdrawal[] memory);
    function getDappsList() external view returns (string[] memory);
}

// ["restakeFromRewardPool(uint256)",
// "addNft(address)",
// "switchNftAvailability(address)",
// "withdrawBonusRewards()",
// "toggleWeights()",
// "setMinStakeAmount(uint256)",
// "withdrawRevenue(uint256)",
// "changeDappAddress(string,address)",
// "partiallyPause()",
// "partiallyUnpause()",
// "revokeRole(bytes32,address)",
// "renounceRole(bytes32,address)",
// "getUserWithdrawals()",
// "getUserWithdrawalsArray(address)",
// "getDappsList()"]