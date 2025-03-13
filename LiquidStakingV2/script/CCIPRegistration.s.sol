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

/// @notice Pool registration on Sepolia and Minato for CCIP iteraction for XNASTR token
contract CCIPRegistration is Script {
    XNASTR xnastr;

    BurnMintTokenPool poolSepolia;
    BurnMintTokenPool poolMinato;

    IRegistryModuleOwnerCustom registryModuleOwnerCustomSepolia;
    IRegistryModuleOwnerCustom registryModuleOwnerCustomMinato;

    ITokenAdminRegistry tokenAdminRegistrySepolia;
    ITokenAdminRegistry tokenAdminRegistryMinato;    

    function setUp() public {
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);

        // sepolia
        poolSepolia = BurnMintTokenPool(0xf34755260d8465478cA019f4104d0B664FC253FB);
        registryModuleOwnerCustomSepolia = IRegistryModuleOwnerCustom(0x62e731218d0D47305aba2BE3751E7EE9E5520790);
        tokenAdminRegistrySepolia = ITokenAdminRegistry(0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82);

        // minato
        poolMinato = BurnMintTokenPool(0x1d4D3BF457A47eB98118B3CF138c9C32b1b4E47C);
        registryModuleOwnerCustomMinato = IRegistryModuleOwnerCustom(0xe06fE3AEfef3a27b8BF0edd5ae834B006EdE3aa1);
        tokenAdminRegistryMinato = ITokenAdminRegistry(0xD2334a6f4f79CE462193EAcB89eB2c29Ae552750);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        // address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        // registration on sepolia
        // TokenPool.ChainUpdate[] memory chainUpdatesSepolia = new TokenPool.ChainUpdate[](1);
        // chainUpdatesSepolia[0] = TokenPool.ChainUpdate({
        //     remoteChainSelector: 686603546605904534, // minato's selector
        //     allowed: true,
        //     remotePoolAddress: abi.encode(0x1d4D3BF457A47eB98118B3CF138c9C32b1b4E47C),
        //     remoteTokenAddress: abi.encode(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e),
        //     outboundRateLimiterConfig: RateLimiter.Config(false, 0, 0),
        //     inboundRateLimiterConfig: RateLimiter.Config(false, 0, 0)
        // });

        // registryModuleOwnerCustomSepolia.registerAdminViaOwner(address(xnastr));
        // tokenAdminRegistrySepolia.acceptAdminRole(address(xnastr));
        // tokenAdminRegistrySepolia.setPool(address(xnastr), address(poolSepolia));
        // poolSepolia.applyChainUpdates(chainUpdatesSepolia);
        // poolSepolia.setRemotePool(686603546605904534, abi.encode(0x1d4D3BF457A47eB98118B3CF138c9C32b1b4E47C));

        // registration on minato
        TokenPool.ChainUpdate[] memory chainUpdatesMinato = new TokenPool.ChainUpdate[](1);
        chainUpdatesMinato[0] = TokenPool.ChainUpdate({
            remoteChainSelector: 16015286601757825753, // sepolia's selector
            allowed: true,
            remotePoolAddress: abi.encode(0xf34755260d8465478cA019f4104d0B664FC253FB),
            remoteTokenAddress: abi.encode(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e),
            outboundRateLimiterConfig: RateLimiter.Config(false, 0, 0),
            inboundRateLimiterConfig: RateLimiter.Config(false, 0, 0)
        });

        registryModuleOwnerCustomMinato.registerAdminViaOwner(address(xnastr));
        tokenAdminRegistryMinato.acceptAdminRole(address(xnastr));
        tokenAdminRegistryMinato.setPool(address(xnastr), address(poolMinato));
        poolMinato.applyChainUpdates(chainUpdatesMinato);
        poolMinato.setRemotePool(16015286601757825753, abi.encode(0xf34755260d8465478cA019f4104d0B664FC253FB));

        vm.stopBroadcast();
    }
}
