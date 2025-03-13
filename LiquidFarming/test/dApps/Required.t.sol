pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/LFMaster.sol";
import "src/LWRAPPED.sol";
import "src/interfaces/IWETH9.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

abstract contract Required is Test {
    ProxyAdmin admin;
    IWETH9 wrapped;

    LFMaster master;

    LWRAPPED algm;
    LWRAPPED lwrapped;
    LWRAPPED pair;

    function deposit(uint256 wrapped, address sender) public virtual;

    function generateRewards(uint256 runs) public virtual;

    function warpRounds(uint256 rounds) public virtual;

    function fund(address to, uint256 wrapped, uint256 pair) public virtual;

    //function priceImpact(uint256 percentage) public virtual;
}
