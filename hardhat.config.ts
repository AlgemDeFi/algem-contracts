import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "./tasks/index";

import * as fs from "fs";


const defaultNetwork = "shidenLocal";

export const LiquidStakingAddr = "0x70d264472327B67898c919809A9dc4759B6c0f27";

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    if (defaultNetwork !== "shidenLocal") {
      console.log(
        "☢️ WARNING: No mnemonic file created for a deploy account. Try `yarn run generate` and then `yarn run account`."
      );
    }
  }
  return "";
}
const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    astarKEK: {
	    url: "",
	    chainId: 4369,
	    accounts: {
		    mnemonic: mnemonic(),
      }
    },
    astarLocal: {
      url: "http://localhost:9933",
      chainId: 4369,
      accounts: {
        mnemonic: mnemonic();
      }
    },
    shibuyaTestnet: {
      url: "",
      chainId: 81,
      accounts: {
        mnemonic: mnemonic()
      },
    },
    astar: {
      url: "https://evm.astar.network",
      chainId: 592,
      accounts: {
        mnemonic: mnemonic();
      },
    },
  }
}

export default config;
