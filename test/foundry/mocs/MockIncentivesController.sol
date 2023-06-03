//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockSCollateralToken.sol";
import "./MockVDToken.sol";
import "./MockERC20.sol";

contract MockIncentivesController {
    MockSCollateralToken public snastr;
    MockVDToken public vdbusd;
    MockERC20 public rewardToken;

    uint256 public constant REWARDS_PER_BLOCK = 1e10;

    constructor(
        MockSCollateralToken _snastr,
        MockVDToken _vdbusd,
        MockERC20 _rewardToken
    ) {
        snastr = _snastr;
        vdbusd = _vdbusd;
        rewardToken = _rewardToken;
    }

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(amount == getUserUnclaimedRewards(msg.sender), "MockIncentive: Not enough rewards");
        snastr.setLastClaimedRewardTime();
        vdbusd.setLastClaimedRewardTime();
        rewardToken.mint(msg.sender, amount);
        return amount;
    }

    function getUserUnclaimedRewards(
        address user
    ) public view returns (uint256) {
        uint256 lastTimeDebt = vdbusd.lastClaimedRewardTime();
        uint256 lastTimeColl = snastr.lastClaimedRewardTime();
        uint256 incomeDebtRewards;
        uint256 incomeCollRewards;
        lastTimeDebt > 0 && lastTimeDebt < block.number ? 
        incomeDebtRewards = (block.number - lastTimeDebt) * REWARDS_PER_BLOCK : 0;
        lastTimeColl > 0 && lastTimeColl < block.number ?
        incomeCollRewards = (block.number - lastTimeColl) * REWARDS_PER_BLOCK : 0;
        return incomeDebtRewards + incomeCollRewards;
    }
}
