// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAdaptersDistributor {
    function getUserBalanceInAdapters(
        address user
    ) external view returns (uint256);

    function updateBalanceInAdapter(
        string memory _adapter,
        address user,
        uint256 amountAfter
    ) external;
}
