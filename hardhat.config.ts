import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "./tasks/index";
import '@typechain/hardhat'
import "@nomicfoundation/hardhat-toolbox";

import * as dotenv from "dotenv";
import * as fs from "fs";


dotenv.config();

//astar
export const LiquidStakingAddr = "0x70d264472327B67898c919809A9dc4759B6c0f27";

function deployerPK(network: string) {
  const pk = process.env.DEPLOYER !== undefined ? process.env.DEPLOYER : "";
  if (pk !== "") {
    console.log("Using deployer defined in .env for", network);
  } else {
    console.log("Deployer private key not found in .env!");
  }
    return pk;
}

const config: HardhatUserConfig = {
  mocha: { 
    timeout: 100000000,
  },
  solidity: {
    compilers: [{
      version: "0.8.4",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    }],
  },
  networks: {
    astarLocal: {
      live: false,
      saveDeployments: false,
      tags: ["local", "test"],
      url: "http://localhost:9933",
      chainId: 4369,
      accounts: {
        count: 20,
        path: "m/44'/60'/0'/0/0",
        // DO NOT USE THIS MNEMONIC IN PRODUCTION
        mnemonic: "gown village inner smoke child coach mutual ancient wide warrior document antique",
      },
    },
    shibuya: {
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      url: "https://evm.shibuya.astar.network",
      chainId: 81,
      accounts: [deployerPK("shibuya")],
    },
    astar: {
      live: true,
      saveDeployments: true,
      tags: ["production"],
      url: "https://evm.astar.network",
      chainId: 592,
      accounts: [deployerPK("astar")],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
}

export default config;
