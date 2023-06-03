pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

contract MockERC20Upgradeable is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
    }

    function mint(address user, uint256 amount) public returns (bool) {
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) public returns (bool) {
        _burn(user, amount);
    }
}