// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console, console2, StdStyle } from "forge-std/Script.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { LiquidStaking } from "../src/LiquidStaking/LiquidStaking.sol";
import { LiquidStakingMain } from "../src/LiquidStaking/LiquidStakingMain.sol";
import { LiquidStakingManager } from "../src/LiquidStaking/LiquidStakingManager.sol";
import { LiquidStakingVoting } from "../src/LiquidStaking/LiquidStakingVoting.sol";
import { LiquidStakingAdmin } from "../src/LiquidStaking/LiquidStakingAdmin.sol";
import { XNASTR } from "../src/XNASTR.sol";
import { MockDappsStaking } from "../src/Mocks/MockDappsStaking.sol";
import { MockAlgemNFT } from "../src/Mocks/MockAlgemNFT.sol";
import { MockDapp } from "../src/Mocks/MockDapp.sol";
import { ALGMStaking } from "../test/ALGMStaking/ALGMStaking.sol";
import { VeALGM } from "../test/ALGMStaking/VeALGM.sol";
import { ALGM } from "../test/ALGMStaking/tokens/ALGM.sol";
import { WASTRCCT } from "../src/WASTRCCT.sol";
import { LiquidStakingLayer2, ILiquidStakingLayer2 } from "../src/LiquidStakingLayer2.sol";

/// @notice Setup for LiquidStakingV2 testing on the Sepolia/Minato line
contract Do is Script {
    LiquidStakingMain liquidMain;
    LiquidStakingAdmin liquidAdmin;
    LiquidStakingVoting liquidVoting;
    LiquidStakingManager manager;
    MockDappsStaking ds;

    LiquidStakingLayer2 liquidMinato;

    XNASTR xnastr;
    WASTRCCT wastr;

    IERC20 linkSepolia;
    IERC20 linkMinato;

    VeALGM vealgm;

    uint256 sepolia;
    uint256 minato;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");

    address deployer;

    function setUp() public {
        sepolia = vm.createFork(SEPOLIA_RPC_URL);
        minato = vm.createFork(MINATO_RPC_URL);

        deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        manager = LiquidStakingManager(0x4bDEd6e30DfF18c38C978565D3F6342F43437A03);
        liquidMain = LiquidStakingMain(payable(address(0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91)));
        liquidAdmin = LiquidStakingAdmin(address(0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91));
        liquidVoting = LiquidStakingVoting(address(0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91));
        ds = MockDappsStaking(payable(0x97Ca75B521FC2Fc1B68b019F4e3e2c9bd3cb43A0));

        linkSepolia = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        linkMinato = IERC20(0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2);

        liquidMinato = LiquidStakingLayer2(0xef20528472545Bf72dB9832Be38DB4cB441FF751);
        
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);
        wastr = WASTRCCT(payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42));
        vealgm = VeALGM(0x1b23253C35E0B738aA97013B8625608E182D7d07);
    }

    function run() public {
        fork(sepolia);

        // ...

        fork(minato);

        // ...
    }

    function fork(uint256 _forkId) internal {
        try vm.stopBroadcast() {} catch {}
        vm.selectFork(_forkId);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    }
}