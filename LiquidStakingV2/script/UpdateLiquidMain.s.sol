// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/LiquidStaking/LiquidStaking.sol";
import "../src/LiquidStaking/LiquidStakingMain.sol";
import "../src/LiquidStaking/LiquidStakingManager.sol";
import "../src/LiquidStaking/LiquidStakingVoting.sol";
import "../src/LiquidStaking/LiquidStakingAdmin.sol";
import "../src/XNASTR.sol";
import "../src/Mocks/MockDappsStaking.sol";
import "../src/Mocks/MockAlgemNFT.sol";
import "../src/Mocks/MockDapp.sol";
import "../test/ALGMStaking/ALGMStaking.sol";
import "../test/ALGMStaking/VeALGM.sol";
import "../test/ALGMStaking/tokens/ALGM.sol";
import { LiquidStakingLayer2, ILiquidStakingLayer2 } from "../src/LiquidStakingLayer2.sol";

/// @notice Update LiquidStakingMain implementation
contract UpdateLiquidMain is Script {
    LiquidStakingMain liquidMain;
    LiquidStakingManager manager;
    XNASTR xnastr;

    bytes4[] liquidMainSelectors = [bytes4(0x3b2736ed), bytes4(0xb3fc1a6e), bytes4(0x59b40f41), bytes4(0xa217fddf), bytes4(0x1b2df850), bytes4(0x86b3cd26), bytes4(0x0b627b4e), bytes4(0xd45221b8), bytes4(0xebf69039), bytes4(0x33e382b1), bytes4(0x867ef36e), bytes4(0x254701a6), bytes4(0xa8feb462), bytes4(0x13f22214), bytes4(0x973628f6), bytes4(0x06040618), bytes4(0xe3287414), bytes4(0xd0928e88), bytes4(0xdcf425df), bytes4(0xda3bc958), bytes4(0xdd5418fb), bytes4(0x78b2d4de), bytes4(0x77b8ac64), bytes4(0xf5646e33), bytes4(0xe53034f9), bytes4(0x73c9cebe), bytes4(0xf16ca2e4), bytes4(0x721b2f62), bytes4(0xe12c398c), bytes4(0xe88539e3), bytes4(0x248a9ca3), bytes4(0x331d437b), bytes4(0xc6ecccb8), bytes4(0x4f84a0bf), bytes4(0x2f2ff15d), bytes4(0x91d14854), bytes4(0xc8902a21), bytes4(0x09b65e66), bytes4(0xa735b85f), bytes4(0x5495ec81), bytes4(0xd0b06f5d), bytes4(0x0a7285be), bytes4(0x5ca5914e), bytes4(0x6cbcfa49), bytes4(0xf1887684), bytes4(0x39ec4df9), bytes4(0x75bea166), bytes4(0x599db0f8), bytes4(0x5c975abb), bytes4(0x45cb9f58), bytes4(0x36568abe), bytes4(0x7f753de6), bytes4(0xd547741f), bytes4(0x66666aa9), bytes4(0x3a4b66f1), bytes4(0x26476204), bytes4(0x01ffc9a7), bytes4(0xb1357bf9), bytes4(0x449696d7), bytes4(0x817b1cd2), bytes4(0xb3a2273f), bytes4(0x7d3c0c65), bytes4(0x20637d8e), bytes4(0x21d0af34), bytes4(0x9ebea88c), bytes4(0x62190150), bytes4(0xe909f0a4), bytes4(0xfae514f8), bytes4(0x0ab2a9a2), bytes4(0xf3fef3a3), bytes4(0x2e1a7d4d), bytes4(0x422b1077), bytes4(0xbdd7ab83)];

    function setUp() public {
        manager = LiquidStakingManager(0x4bDEd6e30DfF18c38C978565D3F6342F43437A03);
        // liquidAdmin = LiquidStakingAdmin(address(0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91));

        // xnastr on both chains sepolia and minato
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        // do 
        manager.deleteAllAddressSelectors(0xe8B74E05a7bf415a920321a82D6DA0677d6EFF04); // remove old liquidMain

        liquidMain = new LiquidStakingMain();
        manager.addSelectorsBatch(liquidMainSelectors, address(liquidMain));

        console.log("LiquidStakingMains new implementation:", address(liquidMain));

        vm.stopBroadcast();
    }
}

// "addNft(address)": "447a91fd",
// "changeDappAddress(string,address)": "27917d60",
// "renounceRole(bytes32,address)": "36568abe",
// "restakeFromRewardPool(uint256)": "036d78bc",
// "revokeRole(bytes32,address)": "d547741f",
// "setAlgmStakingShare(uint256)": "1f35d63c",
// "setMaxDappNumber(uint256)": "9300a052",
// "setMinStakeAmount(uint256)": "eb4af045",
// "setMinUnstakeAmount(uint256)": "6ea3a228",
// "switchNftAvailability(address)": "56a9e4e4",
// "toggleWeights()": "d3686954",
// "updateXnastrAddr(address)": "2b1bad1d",
// "withdrawRevenue(uint256)": "0ceff204",
