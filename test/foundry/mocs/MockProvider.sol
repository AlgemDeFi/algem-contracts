//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MockProvider {
    address public lendingPool;

    constructor(address _lendingPool) {
        lendingPool = _lendingPool;
    }

    function getLendingPool() public view returns (address) {
        return lendingPool;
    }
}