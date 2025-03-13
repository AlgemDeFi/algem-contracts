// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { XNASTR } from "../src/XNASTR.sol";

/// @notice Deploy XNASTR on both chains by the same address
contract DeployXNASTRCreate2 is Script {
    ProxyAdmin admin;
    TransparentUpgradeableProxy proxy;

    XNASTR token;
    XNASTR implementation;

    bytes32 salt;

    function setUp() public {
        salt = keccak256(abi.encodePacked("Algem xnASTR"));
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        // ...
        implementation = new XNASTR{salt: salt}();
        proxy = new TransparentUpgradeableProxy{salt: salt}(address(implementation), deployer, "");
        token = XNASTR(address(proxy));
        token.initialize();

        console.log("Deployed contract at:", address(token));

        vm.stopBroadcast();
    }
}

// sepolia deployed token at: 0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e
// minato deployed token at: 0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e