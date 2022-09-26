//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockArthswapRouter.sol";

contract MockArthswapPair {
    MockArthswapRouter public pool;

    constructor(MockArthswapRouter _pool) {
        pool = _pool;
    }
    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        reserve0 = uint112(pool.reservesT());
        reserve1 = uint112(pool.reservesN());
        blockTimestampLast = uint32(block.timestamp);
    }
}