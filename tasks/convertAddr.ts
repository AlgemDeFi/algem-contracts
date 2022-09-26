import { task } from "hardhat/config";
import * as polkadotCryptoUtils from "@polkadot/util-crypto";

task("convertAddr", "Converts evm addr to plm")
    .addParam("addr", "Address to convert")
    .setAction(async (taskArgs) => {
        if (
            taskArgs.addr && polkadotCryptoUtils.isEthereumAddress(taskArgs.addr)
        ) {
            const converted = polkadotCryptoUtils.evmToAddress(taskArgs.addr);
            console.log(converted);
            return converted;
        } else {
            console.log("Invalid address");
            return "";
        }
    });