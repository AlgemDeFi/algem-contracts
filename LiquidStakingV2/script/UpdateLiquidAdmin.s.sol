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

/// @notice Update LiquidStakingAdmin implementation
contract UpdateLiquidAdmin is Script {
    LiquidStakingAdmin liquidAdmin;
    LiquidStakingManager manager;
    XNASTR xnastr;

    bytes4[] liquidAdminSelectors = [bytes4(0x447a91fd), bytes4(0x27917d60), bytes4(0x36568abe), bytes4(0x036d78bc), bytes4(0xd547741f), bytes4(0x1f35d63c), bytes4(0x9300a052), bytes4(0xeb4af045), bytes4(0x6ea3a228), bytes4(0x56a9e4e4), bytes4(0xd3686954), bytes4(0x0ceff204), bytes4(0x6b4ae2a8)];

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
        manager.deleteAllAddressSelectors(0x75283a7521a8eD91E7d8F8EdAc934Fe88095A4a5); // remove liquidAdmin

        liquidAdmin = new LiquidStakingAdmin();
        manager.addSelectorsBatch(liquidAdminSelectors, address(liquidAdmin));

        console.log("LiquidStakingAdmin new implementation:", address(liquidAdmin));

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
