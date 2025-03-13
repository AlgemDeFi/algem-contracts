// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockAlgemNFT is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(address _to, uint256 _id) external {
        _mint(_to, _id);
    }

    function discount() external pure returns (uint256) {
        return 1000;
    }
}  
