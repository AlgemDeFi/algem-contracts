// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { WASTRCCT } from "../src/WASTRCCT.sol";

/// @notice Deploy WASTR on both chains by the same address
contract DeployWASTRCreate2 is Script {
    ProxyAdmin adminMinato;
    ProxyAdmin adminSepolia;
    
    TransparentUpgradeableProxy proxyMinato;
    TransparentUpgradeableProxy proxySepolia;

    WASTRCCT implMinato;
    WASTRCCT implSepolia;

    WASTRCCT wastrMinato;
    WASTRCCT wastrSepolia;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string MINATO_RPC_URL = vm.envString("MINATO_RPC_URL");    

    bytes32 salt;

    address user;

    function setUp() public {
        salt = keccak256(abi.encodePacked("Algem2"));
        user = 0x7ECD92b9835E0096880bF6bA778d9eA40d1338B5;
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);
        vm.createSelectFork(MINATO_RPC_URL);
        vm.startBroadcast(deployerPK);

        // minato

        implMinato = new WASTRCCT{salt: salt}();
        proxyMinato = new TransparentUpgradeableProxy{salt: salt}(address(implMinato), deployer, "");
        wastrMinato = WASTRCCT(payable(address(proxyMinato)));
        wastrMinato.initialize();
        
        console.log("weth on minato:", address(wastrMinato));

        vm.stopBroadcast();

        vm.createSelectFork(SEPOLIA_RPC_URL);
        vm.startBroadcast(deployerPK);

        // sepolia
        
        implSepolia = new WASTRCCT{salt: salt}();
        proxySepolia = new TransparentUpgradeableProxy{salt: salt}(address(implSepolia), deployer, "");
        wastrSepolia = WASTRCCT(payable(address(proxySepolia)));
        wastrSepolia.initialize();
        
        console.log("weth on Sepolia:", address(wastrSepolia));

        vm.stopBroadcast();
    }
}

// == Logs ==
//   wastr on minato: 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42
//   wastr on Sepolia: 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42