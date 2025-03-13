//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ALGM is ERC20 {
    constructor() ERC20("ALGM", "ALGM") {
        _mint(msg.sender, ~uint128(0));
    }

    function mint(uint256 qty) external {
        require(qty > 0, "Zero Qty");

        _mint(msg.sender, qty);
    }
}
