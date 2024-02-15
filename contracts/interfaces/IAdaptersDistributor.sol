// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAdaptersDistributor {
    struct Adapter {
        address contractAddress;
        //uint256 totalAmount;
        // mapping(address => uint256) userAmount;
    }
    function getUserBalanceInAdapters(
        address user
    ) external view returns (uint256);

    function updateBalanceInAdapter(
        string memory _adapter,
        address user,
        uint256 amountAfter
    ) external;
    function adapters(string memory adapterName) external view returns (Adapter memory);
    function adaptersList(uint256 idx) external view returns (string memory);
}