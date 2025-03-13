//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PartnerToken1 is ERC20 {
    constructor() ERC20("PartnerToken1", "PT1") {
        _mint(msg.sender, ~uint128(0));
    }

    function mint(uint256 qty) external {
        require(qty > 0, "Zero Qty");

        _mint(msg.sender, qty);
    }
}
