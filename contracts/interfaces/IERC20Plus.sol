//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface IERC20Plus is IERC20Upgradeable {
    function mint(address beneficiary, uint256 amount) external returns (bool);

    function burn(address who, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}
