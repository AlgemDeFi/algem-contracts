// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "../contracts/LiquidStaking/LiquidStakingMain.sol";
import "../contracts/LiquidStaking/LiquidStakingMisc.sol";

contract Deployer is Script { 
    LiquidStakingMisc public deployedContract;

    function setUp() public {}

    function run() public {
        uint256 signerPk = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(signerPk);
        
        vm.startBroadcast(signerPk);

        console.log("Signer address is:", signer);
        deployedContract = new LiquidStakingMisc();
        
        console.log("Deployed contract address:", address(deployedContract));

        vm.stopBroadcast();
    }
}