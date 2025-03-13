// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ILiquidStaking {
    function isStaker(address) external view returns (bool);
    function currentEra() external view returns (uint);
    function REVENUE_FEE() external view returns (uint8);
    function sync(uint256 _era) external;
    function transferOfAssets(address from, address to) external;
}
