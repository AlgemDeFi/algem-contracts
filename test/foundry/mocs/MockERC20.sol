pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockERC20 is ERC20Burnable {
    uint8 public dec = 18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }

    function mint(address user, uint256 amount) public returns (bool) {
        _mint(user, amount);
        return true;
    }

    function burn(address user, uint256 amount) public returns (bool) {
        _burn(user, amount);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return dec;
    }

    function setDecimals(uint8 _dec) public {
        dec = _dec;
    }
}