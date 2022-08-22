//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


interface ISiriusPool {
    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256[] memory minAmounts,uint256 deadline) external;
    function removeLiquidityImbalance(uint256[] memory amounts, uint256 maxBurnAmount, uint256 deadline) external;
    function removeLiquidityOneCoin(uint256 tokenAmount, uint256 tokenIndex, uint256 minAmount, address receiver) external;
}
