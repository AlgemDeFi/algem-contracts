// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";

import { BurnMintTokenPool } from "@ccip/ccip/pools/BurnMintTokenPool.sol";

import { IBurnMintERC20 } from "@ccip/shared/token/ERC20/IBurnMintERC20.sol";

/// @notice WASTR mint/burn pools deploying
contract DeployBurnMintPoolETH is Script {
    BurnMintTokenPool poolMinato;
    BurnMintTokenPool poolSepolia;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");

    function setUp() public {
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");

        // on minato
        vm.createSelectFork(MINATO_RPC_URL);
        vm.startBroadcast(deployerPK);
        poolMinato = new BurnMintTokenPool(
            IBurnMintERC20(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42),
            new address[](0),
            0x6172F4f60eEE3876cF83318DEe4477BfAf15Ffd3,
            0x443a1bce545d56E2c3f20ED32eA588395FFce0f4
        );
        console.log("Minato pool at:", address(poolMinato));
        vm.stopBroadcast();

        // on sepolia
        vm.createSelectFork(SEPOLIA_RPC_URL);
        vm.startBroadcast(deployerPK);
        poolSepolia = new BurnMintTokenPool(
            IBurnMintERC20(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42),
            new address[](0),
            0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
            0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
        );
        console.log("Sepolia pool at:", address(poolSepolia));
        vm.stopBroadcast();
    }
}

// == Logs ==
//   Minato pool at: 0xf59Bc633286d66DC01C96e2a92F62582C7e3ebeD
//   Sepolia pool at: 0x6549b2fa1cad333E6E593b8504b948175711f7Df