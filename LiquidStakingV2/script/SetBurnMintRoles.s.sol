// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import { BurnMintTokenPool, TokenPool } from "@ccip/ccip/pools/BurnMintTokenPool.sol";
import { RateLimiter } from "@ccip/ccip/libraries/RateLimiter.sol";

import { XNASTR } from "../src/XNASTR.sol";


interface IRegistryModuleOwnerCustom {
    function registerAdminViaGetCCIPAdmin(address token) external;
    function registerAdminViaOwner(address token) external;
}

interface ITokenAdminRegistry {
    function acceptAdminRole(address localToken) external;
    function setPool(address localToken, address pool) external;
}

/// @notice Set burn and mint roles for XNASTR
contract SetBurnMintRoles is Script {
    XNASTR xnastr;

    BurnMintTokenPool poolSepolia;
    BurnMintTokenPool poolMinato;

    function setUp() public {
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);

        // sepolia
        poolSepolia = BurnMintTokenPool(0xf34755260d8465478cA019f4104d0B664FC253FB);

        // minato
        poolMinato = BurnMintTokenPool(0x1d4D3BF457A47eB98118B3CF138c9C32b1b4E47C);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        // do on sepolia
        // xnastr.grantMintAndBurnRoles(address(poolSepolia));

        // do on minato
        xnastr.grantMintAndBurnRoles(address(poolMinato));

        vm.stopBroadcast();
    }
}
