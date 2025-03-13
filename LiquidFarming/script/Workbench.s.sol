pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
//handy functions for easy project interaction

contract Workbench is Script {
    struct Config {
        address pair;
        address pairwhale;
        address pool;
        address wrapped;
    }

    Config cfg;

    struct LFConfig {
        address algm;
        address master;
        address pool;
        address vault;
        address lwrapped;
        address lwrappedcentre;
    }

    LFConfig lfcfg;

    function writeConfig() public {
        // Prompt the user for config details
        string memory chain = vm.prompt("chain name");
        string memory dappname = vm.prompt("dapp name");
        string memory cfgname = vm.prompt("cfg name");
        cfg.wrapped = vm.parseAddress(vm.prompt("Enter wrapped addr"));
        cfg.pair = vm.parseAddress(vm.prompt("Enter pair addr"));
        cfg.pairwhale = vm.parseAddress(vm.prompt("Enter pair whale addr"));
        cfg.pool = vm.parseAddress(vm.prompt("Enter pool addr"));

        string memory json = vm.serializeAddress(cfgname, "wrapped", cfg.wrapped);
        json = vm.serializeAddress(cfgname, "pair", cfg.pair);
        json = vm.serializeAddress(cfgname, "pairwhale", cfg.pairwhale);
        json = vm.serializeAddress(cfgname, "pool", cfg.pool);

        // Write the JSON to a file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/cfg/", chain, "/dApps/", dappname, "/", cfgname, ".json");
        console.log(path);
        vm.writeJson(json, path);

        console.log("Config written to %s", path);
    }

    function chooseConfig() public {
        string memory chain = vm.prompt("chain");
        string memory dApp = vm.prompt("dApp");
        uint256 pair = vm.parseUint(vm.prompt(">> pair number"));
        string memory path = string.concat(vm.projectRoot(), "/script/cfg/", chain, "/dApps/", dApp);

        _chooseConfig(path, pair);
    }

    function _chooseConfig(string memory path, uint256 pair) internal {
        Vm.DirEntry[] memory configs = vm.readDir(path);

        cfg = abi.decode(vm.parseJson(vm.readFile(configs[pair].path)), (Config));
    }

    function readConfigs() public {
        // Get the project root directory
        string memory root = vm.projectRoot();

        // Read the cfg directory
        string memory cfgPath = string.concat(root, "/script/cfg");
        Vm.DirEntry[] memory entries = vm.readDir(cfgPath);

        // Iterate through the entries and read JSON configs
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].isDir) {
                Vm.DirEntry[] memory dAppEntries = vm.readDir(string.concat(entries[i].path, "/dApps/"));

                for (uint256 j = 0; j < dAppEntries.length; j++) {
                    if (dAppEntries[j].isDir) {
                        Vm.DirEntry[] memory configEntries = vm.readDir(dAppEntries[j].path);

                        for (uint256 k = 0; k < configEntries.length; k++) {
                            if (!configEntries[k].isDir) {
                                Config memory config =
                                    abi.decode(vm.parseJson(vm.readFile(configEntries[k].path)), (Config));

                                // Parse and print the config
                                console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                                console.log(">>", k);
                                console.log(configEntries[k].path);
                                console.log("wrapped: ", config.wrapped);
                                console.log("pair: ", config.pair);
                                console.log("pool: ", config.pool);
                                console.log(">>", k);
                                console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
                            }
                        }
                    }
                }
            }
        }
    }
}
