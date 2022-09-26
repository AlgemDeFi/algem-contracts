//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockERC20.sol";

contract MockSiriusFarm {
    MockERC20 public gauge;
    MockERC20 public lp;
    
    mapping(address => uint256) public startTime;

    constructor(
        MockERC20 _gauge,
        MockERC20 _lp
    ) {
        gauge = _gauge;
        lp = _lp;
    }

    function deposit(uint256 value, address account, bool _claimRewards) external {
        lp.transferFrom(msg.sender, address(this), value);
        gauge.mint(msg.sender, value);
        startTime[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 value,bool _claimRewards) external {
        gauge.transferFrom(msg.sender, address(this), value);
        lp.transfer(msg.sender, value);
    }

    function claimableTokens(address _addr) external returns (uint256) {
        uint256 pendingRewards = block.timestamp - startTime[msg.sender];
        return (pendingRewards * 1e6);
    }

    function setStartTime(address user, uint256 time) public {
        startTime[user] = time;
    }
}