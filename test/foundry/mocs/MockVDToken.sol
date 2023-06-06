//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockVDToken is ERC20Burnable {
    uint256 public lastClaimedTime;
    uint256 public lastClaimedRewardTime;
    uint8 public dec = 18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address who, uint256 amount) public {
        _mint(who, amount);
        if (lastClaimedTime == 0) {
            lastClaimedTime = block.number;
            lastClaimedRewardTime = block.number;
        }
    }

    function burn(address who, uint256 amount) public {
        _burn(who, amount);
    }

    function setLastClaimedRewardTime() public {
        lastClaimedRewardTime = block.number;
    }

    function decimals() public view override returns (uint8) {
        return dec;
    }

    function setDecimals(uint8 _dec) public {
        dec = _dec;
    }
}