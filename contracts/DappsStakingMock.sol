//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/DappsStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DappsStakingMock is Ownable {
    uint256 public era = 100;
    uint256 public start;
    uint256 public eraDuration = 60;
    uint256 public unstakesSum;
    uint256 public stakerRewards;

    struct Unstake {
        uint128 amount;
        uint128 startEra;
    }

    Unstake[] public unstakes;

    constructor() {
        start = block.timestamp;
    }

    /// @notice Stake provided amount on the contract.
    function bond_and_stake(address, uint128) external payable {}

    /// @notice Start unbonding process and unstake balance from the contract.
    function unbond_and_unstake(address, uint128 amount) external {
        unstakesSum += amount;
        if (unstakesSum <= address(this).balance) {
            unstakes.push(Unstake(amount, uint128(read_current_era())));
            stakerRewards += 1;
        }
    }

    /// @notice Withdraw all funds that have completed the unbonding process.
    function withdraw_unbonded() external {
        for (uint256 i; i < unstakes.length; i++) {
            if (block.timestamp - unstakes[i].startEra >= 10 && unstakes[i].amount > 0) {
                payable(msg.sender).transfer(unstakes[i].amount);
                unstakesSum -= unstakes[i].amount;
                unstakes[i].amount = 0;
            }
        }
    }

    /// @notice Claim one era of unclaimed staker rewards for the specifeid contract.
    ///         Staker account is derived from the caller address.
    function claim_staker(address) external onlyOwner {
        payable(msg.sender).transfer(stakerRewards);
        stakerRewards = 0;
    }

    /// @notice Read current era.
    /// @return era, The current era
    function read_current_era() public view returns (uint256) {
        return era + (block.timestamp - start) / eraDuration; // era changed every minute
    }

    /// @notice Read unbonding period constant.
    /// @return period, The unbonding period in eras
    function read_unbonding_period() external view returns (uint256) {
        return 10;
    }

    function setEraDuration(uint256 _duration) public {
        eraDuration = _duration;
    }

    receive() external payable {}
}
