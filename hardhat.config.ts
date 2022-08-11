import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "./tasks/index";

import * as fs from "fs";
import { ethers } from "hardhat";


const defaultNetwork = "astarLocal";

//astar
export const LiquidStakingAddr = "0x70d264472327B67898c919809A9dc4759B6c0f27";
const deployerPK = "";

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    if (defaultNetwork !== "astarLocal") {
      console.log(
        "☢️ WARNING: No mnemonic file created for a deploy account. Try `yarn run generate` and then `yarn run account`."
      );
    }
  }
  return "";
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
      //gas: 2100000,
      //gasPrice: 20000000000,
      url: "http://localhost:9933",
      chainId: 4369,
      accounts: {
        count: 20,
        path: "m/44'/60'/0'/0/0",
        mnemonic: "gown village inner smoke child coach mutual ancient wide warrior document antique",
      },
    },
    shibuya: {
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      url: "https://evm.shibuya.astar.network",
      chainId: 81,
      accounts: [deployerPK],
    },
    astar: {
      live: true,
      saveDeployments: true,
      tags: ["production"],
      url: "https://evm.astar.network",
      chainId: 592,
      accounts: [deployerPK],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
}

export default config;
