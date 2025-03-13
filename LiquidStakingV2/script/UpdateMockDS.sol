// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { MockDappsStaking } from "../src/Mocks/MockDappsStaking.sol";

/// @notice Updates DappsStaking implementation on Sepolia
contract UpdateMockDS is Script {
    ProxyAdmin admin;
    MockDappsStaking ds;
    ITransparentUpgradeableProxy proxy;

    function setUp() public {
        admin = ProxyAdmin(0xd65690Ae0622B6f3e867Ab621cc2ba9B81F59fBD);
        proxy = ITransparentUpgradeableProxy(payable(0x97Ca75B521FC2Fc1B68b019F4e3e2c9bd3cb43A0));
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPK);

        ds = new MockDappsStaking();
        admin.upgradeAndCall(proxy, address(ds), "");

        vm.stopBroadcast();
    }
}