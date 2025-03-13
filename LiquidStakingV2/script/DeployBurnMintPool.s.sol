// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";

import { BurnMintTokenPool } from "@ccip/ccip/pools/BurnMintTokenPool.sol";

import { IBurnMintERC20 } from "@ccip/shared/token/ERC20/IBurnMintERC20.sol";

/// @notice XNASTR mint/burn pools deploying
contract DeployBurnMintPool is Script {
    BurnMintTokenPool pool;

    function setUp() public {
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        // on sepolia
        // pool = new BurnMintTokenPool(
        //     IBurnMintERC20(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e),
        //     new address[](0),
        //     0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
        //     0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
        // );

        // on minato
        pool = new BurnMintTokenPool(
            IBurnMintERC20(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e),
            new address[](0),
            0x6172F4f60eEE3876cF83318DEe4477BfAf15Ffd3,
            0x443a1bce545d56E2c3f20ED32eA588395FFce0f4
        );

        console.log("Pool deployed at:", address(pool));

        vm.stopBroadcast();
    }
}

// minato deployed pool at:  0x1d4D3BF457A47eB98118B3CF138c9C32b1b4E47C
// sepolia deployed pool at: 0xf34755260d8465478cA019f4104d0B664FC253FB 