//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


interface IKaglaPool {
    function add_liquidity(uint256[2] calldata amounts, uint256 minToMint) external payable returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] memory minAmounts) external returns (uint256[2] memory);
    function remove_liquidity_imbalance(uint256[] memory amounts, uint256 maxBurnAmount, uint256 deadline) external returns (uint256);
    function remove_liquidity_one_coin(uint256 tokenAmount, uint256 tokenIndex, uint256 minAmount, address receiver) external;
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function balances(uint256 arg0) external view returns (uint256);
}
