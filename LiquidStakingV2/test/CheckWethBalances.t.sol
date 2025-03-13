// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract CheckWethBalancesTest is Test {
    IERC20 wethMinato;
    IERC20 wethSepolia;

    address user;

    uint256 minatoFork;
    uint256 sepoliaFork;

    IERC20 linkMinato;
    IERC20 linkSepolia;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");

    function setUp() public {
        wethMinato = IERC20(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42);
        wethSepolia = IERC20(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42);

        linkMinato = IERC20(0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2);
        linkSepolia = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

        user = 0x7ECD92b9835E0096880bF6bA778d9eA40d1338B5;
    }

    function test_do() public {
        minatoFork = vm.createFork(MINATO_RPC_URL);
        vm.selectFork(minatoFork);        

        console2.log("Minato WETH balance:", wethMinato.balanceOf(user));
        console2.log("Minato LINK balance:", linkMinato.balanceOf(user) / 1e18);

        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
        vm.selectFork(sepoliaFork);        

        console2.log("Sepolia WETH balance:", wethSepolia.balanceOf(user));
        console2.log("Sepolia LINK balance:", linkSepolia.balanceOf(user) / 1e18);
    }
}
