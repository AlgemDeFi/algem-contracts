//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockSiriusFarm.sol";
import "./MockERC20.sol";

contract MockSiriusMinter {
    MockSiriusFarm farm;
    MockERC20 srs;

    constructor(
        MockSiriusFarm _farm,
        MockERC20 _srs
    ) {
        farm = _farm;
        srs = _srs;
    }

    function mint(address gaugeToken) external {
        uint256 pendingRewards;
        uint256 time = farm.startTime(msg.sender);
        if (block.timestamp > time) {
            pendingRewards = block.timestamp - time;
        }
        farm.setStartTime(msg.sender, block.timestamp);
        srs.mint(msg.sender, pendingRewards * 1e6);
    }
}