// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { LiquidStakingLayer2 } from "../src/LiquidStakingLayer2.sol";
import { WASTRCCT } from "../src/WASTRCCT.sol";
import { XNASTR } from "../src/XNASTR.sol";
import { MockVeALGM } from "../src/Mocks/MockVeALGM.sol";

/// @notice LiquidStakingLayer2 deploying on Minato
contract DeployMinato is Script {
    ProxyAdmin admin;

    LiquidStakingLayer2 lsImpl;
    LiquidStakingLayer2 ls;
    TransparentUpgradeableProxy lsProxy;

    MockVeALGM ve;
    MockVeALGM veImpl;
    TransparentUpgradeableProxy veProxy;

    address wastrAddr;
    address xnastrAddr;
    address liquidStakingAstarAddr;
    address linkAddr;
    address ccipRouter;
    address deployer;

    uint64 sepoliaChainSelector;

    function setUp() public {
        wastrAddr = 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42;
        xnastrAddr = 0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e;
        liquidStakingAstarAddr = 0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91;
        linkAddr = 0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2; // LINK token Minato
        ccipRouter = 0x443a1bce545d56E2c3f20ED32eA588395FFce0f4; // CCIP Router Minato
        sepoliaChainSelector = 16015286601757825753;
        deployer = 0x7ECD92b9835E0096880bF6bA778d9eA40d1338B5;
    }

    function run() public {
        vm.createSelectFork(vm.envString("MINATO_RPC_URL"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        veImpl = new MockVeALGM();
        veProxy = new TransparentUpgradeableProxy(address(veImpl), deployer, "");
        ve = MockVeALGM(address(veProxy));
        ve.initialize();

        lsImpl = new LiquidStakingLayer2();
        lsProxy = new TransparentUpgradeableProxy(address(lsImpl), deployer, "");
        ls = LiquidStakingLayer2(address(lsProxy));
        ls.initialize(
            wastrAddr,
            xnastrAddr,
            address(ve),
            liquidStakingAstarAddr,
            linkAddr,
            ccipRouter,
            sepoliaChainSelector
        );

        console.log("Deployed veALGM:", address(ve));
        console.log("Deployed LiquidStakingLayer2:", address(ls));
    }
}

// == Logs ==
//   Deployed veALGM: 0x1b23253C35E0B738aA97013B8625608E182D7d07
//   Deployed LiquidStakingLayer2: 0xef20528472545Bf72dB9832Be38DB4cB441FF751