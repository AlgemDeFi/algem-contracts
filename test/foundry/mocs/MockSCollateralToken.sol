//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockSCollateralToken is ERC20Burnable {
    uint256 public lastClaimedTime;
    uint256 public lastClaimedRewardTime;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address who, uint256 amount) public {
        _mint(who, amount);
        if (lastClaimedTime == 0) {
            lastClaimedTime = block.timestamp;
            lastClaimedRewardTime = block.timestamp;
        }
    }

    function burn(address who, uint256 amount) public {
        _burn(who, amount);
    }

    function setLastClaimedRewardTime() public {
        lastClaimedRewardTime = block.timestamp;
    }
}