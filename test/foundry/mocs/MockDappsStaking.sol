//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MockDappsStaking {
    uint256 public totalStake;
    uint256 public lastStakeBlock;
    uint256 public unbondingStartBlock;
    uint256 public withdrawal;
    uint256 public startTime;
    uint256 public sumToUnstake;
    uint256 public unstakeTime;
    uint256 public stakeTime;

    mapping(uint256 => uint256) public unstakesInEra;

    constructor() {
        startTime = block.timestamp;
    }

    function read_unbonding_period() public view returns (uint256) {
        return 10; // 10 eras unbonding period;
    }

    function read_current_era()  public view returns (uint256) {
        return 1 + (block.timestamp - startTime) / 1 days; // + 1 era per day
    }

    function bond_and_stake(address liquid, uint128 amount) public payable {
        totalStake += amount;
        stakeTime = block.timestamp;
    }

    function unbond_and_unstake(address cl, uint128 amount) public {
        uint256 era = read_current_era();
        require(totalStake >= amount, "MockDappsStaking: amount > totalStake");
        totalStake -= amount;
        sumToUnstake += amount;
        unstakesInEra[era] += 1;
        unstakeTime = block.timestamp;

        require(unstakesInEra[era] < 5, "To much unstakes for current era");
    }

    function claim_staker(address liquid) public {
        require(block.number - unbondingStartBlock > read_unbonding_period(), "unbonding period not end");
        uint256 time = unstakeTime;
        if (unstakeTime == 0) time = block.timestamp;
        (bool ok, ) = msg.sender.call{value: time - stakeTime}("");
        require(ok);
    }

    function withdraw_unbonded() public {
        require(unstakeTime != 0, "UnstakeTime == 0");
        require(block.timestamp - unstakeTime >= 10 days, "Unbonding period has not passed yet");
        (bool ok, ) = msg.sender.call{value: sumToUnstake}("");
        require(ok);
        sumToUnstake = 0;
        unstakeTime = 0;
    }
}

// function read_unbonding_period() external view returns (uint256);
// function read_current_era() external view returns (uint256);
// function bond_and_stake(address, uint128) external;
// function unbond_and_unstake(address, uint128) external;
// function claim_staker(address) external;
// function withdraw_unbonded() external;