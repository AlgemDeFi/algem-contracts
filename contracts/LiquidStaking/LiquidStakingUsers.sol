// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./LiquidStakingMain.sol";

contract LiquidStakingUsers is LiquidStakingMain {
    function removeStakers() public onlyRole(MANAGER) {
        delete stakers;
    }

    function addStakers(address[] memory _stakers) public onlyRole(MANAGER) {
        string[6] memory utils = [
            "LiquidStaking",
            "Astar Degens",
            "ArthSwap",
            "Astar Core Contributors",
            "Algem",
            "AstridDAO"
        ];

        for (uint256 i; i < _stakers.length; ) {
            address _addr = _stakers[i];

            isStaker[_addr] = true;
            stakers.push(_addr);

            for (uint256 ii; ii < utils.length; ) {
                if (dapps[utils[ii]].stakers[_addr].lastClaimedEra == 0)
                    dapps[utils[ii]].stakers[_addr].lastClaimedEra =
                        currentEra() +
                        1;
                unchecked {
                    ++ii;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function getSelectors() public pure returns (bytes4[2] memory) {
        return [this.addStakers.selector, this.removeStakers.selector];
    }
}
