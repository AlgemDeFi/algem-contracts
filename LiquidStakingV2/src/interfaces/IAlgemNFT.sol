// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAlgemNFT is IERC721 {
    function discount() external view returns (uint256);
}