// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import { BurnMintTokenPool, TokenPool } from "@ccip/ccip/pools/BurnMintTokenPool.sol";
import { RateLimiter } from "@ccip/ccip/libraries/RateLimiter.sol";

import { WASTRCCT } from "../src/WASTRCCT.sol";


interface IRegistryModuleOwnerCustom {
    function registerAdminViaGetCCIPAdmin(address token) external;
    function registerAdminViaOwner(address token) external;
}

interface ITokenAdminRegistry {
    function acceptAdminRole(address localToken) external;
    function setPool(address localToken, address pool) external;
}

/// @notice Set burn and mint roles for WASTR
contract SetBurnMintRolesETH is Script {
    WASTRCCT wastrMinato;
    WASTRCCT wastrSepolia;

    BurnMintTokenPool poolSepolia;
    BurnMintTokenPool poolMinato;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");

    function setUp() public {
        wastrMinato = WASTRCCT(payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42));
        wastrSepolia = WASTRCCT(payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42));

        // sepolia
        poolSepolia = BurnMintTokenPool(0x6549b2fa1cad333E6E593b8504b948175711f7Df);

        // minato
        poolMinato = BurnMintTokenPool(0xf59Bc633286d66DC01C96e2a92F62582C7e3ebeD);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        vm.createSelectFork(SEPOLIA_RPC_URL);
        vm.startBroadcast(deployerPK);
        // do on sepolia
        // wastrSepolia.grantMintAndBurnRoles(address(deployer));
        wastrSepolia.mint(deployer, 1e18);
        vm.stopBroadcast();

        vm.createSelectFork(MINATO_RPC_URL);
        vm.startBroadcast(deployerPK);
        // do on minato
        // wastrMinato.grantMintAndBurnRoles(address(deployer));
        wastrMinato.mint(deployer, 1e18);
        vm.stopBroadcast();
    }
}
