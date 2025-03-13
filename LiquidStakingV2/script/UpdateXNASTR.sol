// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { XNASTR } from "../src/XNASTR.sol";

/// @notice Update XNASTR implementation
contract UpdateXNASTR is Script {
    ProxyAdmin admin;
    XNASTR xnastr;
    ITransparentUpgradeableProxy proxy;

    function setUp() public {
        admin = ProxyAdmin(0x53052248DDED441226d33273cA1Ec413b3653B95);
        proxy = ITransparentUpgradeableProxy(payable(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e));
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        xnastr = new XNASTR();
        admin.upgradeAndCall(proxy, address(xnastr), "");

        vm.stopBroadcast();
    }
}