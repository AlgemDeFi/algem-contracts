//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockVeALGM is Initializable, ERC20Upgradeable {
    function initialize() public initializer {
        __ERC20_init("Vote escrow ALGM", "veALGM");
    }

    function mint(address _who, uint256 _amount) public {
        _mint(_who, _amount);
    }

    function burn(address _who, uint256 _amount) public {
        _burn(_who, _amount);
    }
}