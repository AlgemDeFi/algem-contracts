//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockERC20.sol";

contract MockArthswapMasterChef {
    MockERC20 public arsw;
    MockERC20 public lp;
    
    mapping(address => uint256) public startTime;

    constructor(
        MockERC20 _arsw,
        MockERC20 _lp
    ) {
        arsw = _arsw;
        lp = _lp;
    }

    function deposit(uint256 pid, uint256 amount, address to) external {
        lp.transferFrom(msg.sender, address(this), amount);
        startTime[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 pid, uint256 amount, address to) external {
        require(lp.balanceOf(address(this)) >= amount, "Not enough LP on farm contract");
        lp.transfer(msg.sender, amount);
    }

    function pendingARSW(uint256 pid, address user) external view returns (uint256) {
        uint256 pendingRewards = block.timestamp - startTime[msg.sender];
        return (pendingRewards * 1_000_000);
    }

    function harvest(uint256 pid, address to) external {
        require(startTime[msg.sender] > 0 && startTime[msg.sender] < block.timestamp, "LP were not deposited by the adapter");
        uint256 amountToSend = block.timestamp - startTime[msg.sender];
        arsw.transfer(msg.sender, amountToSend * 1_000_000);
    }
}