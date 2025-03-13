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

/// @notice Pool registration on Sepolia and Minato for CCIP iteraction for WASTR token
contract CCIPRegistrationETH is Script {
    WASTRCCT wastrMinato;
    WASTRCCT wastrSepolia;

    BurnMintTokenPool poolSepolia;
    BurnMintTokenPool poolMinato;

    IRegistryModuleOwnerCustom registryModuleOwnerCustomSepolia;
    IRegistryModuleOwnerCustom registryModuleOwnerCustomMinato;

    ITokenAdminRegistry tokenAdminRegistrySepolia;
    ITokenAdminRegistry tokenAdminRegistryMinato;    

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");

    function setUp() public {
        wastrMinato = WASTRCCT(payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42));
        wastrSepolia = WASTRCCT(payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42));

        // sepolia
        poolSepolia = BurnMintTokenPool(0x6549b2fa1cad333E6E593b8504b948175711f7Df);
        registryModuleOwnerCustomSepolia = IRegistryModuleOwnerCustom(0x62e731218d0D47305aba2BE3751E7EE9E5520790);
        tokenAdminRegistrySepolia = ITokenAdminRegistry(0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82);

        // minato
        poolMinato = BurnMintTokenPool(0xf59Bc633286d66DC01C96e2a92F62582C7e3ebeD);
        registryModuleOwnerCustomMinato = IRegistryModuleOwnerCustom(0xe06fE3AEfef3a27b8BF0edd5ae834B006EdE3aa1);
        tokenAdminRegistryMinato = ITokenAdminRegistry(0xD2334a6f4f79CE462193EAcB89eB2c29Ae552750);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPK);

        vm.createSelectFork(SEPOLIA_RPC_URL);
        vm.startBroadcast(deployerPK);

        // do on sepolia
        TokenPool.ChainUpdate[] memory chainUpdatesSepolia = new TokenPool.ChainUpdate[](1);
        chainUpdatesSepolia[0] = TokenPool.ChainUpdate({
            remoteChainSelector: 686603546605904534, // minato's selector
            allowed: true,
            remotePoolAddress: abi.encode(0xf59Bc633286d66DC01C96e2a92F62582C7e3ebeD),
            remoteTokenAddress: abi.encode(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42),
            outboundRateLimiterConfig: RateLimiter.Config(false, 0, 0),
            inboundRateLimiterConfig: RateLimiter.Config(false, 0, 0)
        });

        registryModuleOwnerCustomSepolia.registerAdminViaOwner(address(wastrSepolia));
        tokenAdminRegistrySepolia.acceptAdminRole(address(wastrSepolia));
        tokenAdminRegistrySepolia.setPool(address(wastrSepolia), address(poolSepolia));
        poolSepolia.applyChainUpdates(chainUpdatesSepolia);
        poolSepolia.setRemotePool(686603546605904534, abi.encode(0xf59Bc633286d66DC01C96e2a92F62582C7e3ebeD));

        vm.stopBroadcast();

        vm.createSelectFork(MINATO_RPC_URL);
        vm.startBroadcast(deployerPK);

        // do on minato
        TokenPool.ChainUpdate[] memory chainUpdatesMinato = new TokenPool.ChainUpdate[](1);
        chainUpdatesMinato[0] = TokenPool.ChainUpdate({
            remoteChainSelector: 16015286601757825753, // sepolia's selector
            allowed: true,
            remotePoolAddress: abi.encode(0x6549b2fa1cad333E6E593b8504b948175711f7Df),
            remoteTokenAddress: abi.encode(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42),
            outboundRateLimiterConfig: RateLimiter.Config(false, 0, 0),
            inboundRateLimiterConfig: RateLimiter.Config(false, 0, 0)
        });

        registryModuleOwnerCustomMinato.registerAdminViaOwner(address(wastrMinato));
        tokenAdminRegistryMinato.acceptAdminRole(address(wastrMinato));
        tokenAdminRegistryMinato.setPool(address(wastrMinato), address(poolMinato));
        poolMinato.applyChainUpdates(chainUpdatesMinato);
        poolMinato.setRemotePool(16015286601757825753, abi.encode(0x6549b2fa1cad333E6E593b8504b948175711f7Df));

        vm.stopBroadcast();
    }
}
