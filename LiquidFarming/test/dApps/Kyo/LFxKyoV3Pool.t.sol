pragma solidity ^0.8.0;

import "test/dApps/Required.t.sol";
import "script/Workbench.s.sol";

contract LFxKyoV3PoolTest is Required, Workbench {
    //handy
    function deposit(uint256 wrapped, address sender) public override {}

    function generateRewards(uint256 runs) public override {}

    function warpRounds(uint256 rounds) public override {}

    function fund(address to, uint256 wrapped, uint256 pair) public override {}

    function priceImpact(uint256 percentage) public {}
    //^handy

    function setUp() public {
        _chooseConfig("script/cfg/Minato/dApps/Kyo/", 0);
    }
}
