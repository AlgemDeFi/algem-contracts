import { ApiPromise, Keyring, WsProvider } from "@polkadot/api";
import { task } from "hardhat/config";
import * as polkadotCryptoUtils from "@polkadot/util-crypto";

task("giveMoney", "Give money from Alice dev account")
    .addParam("to", "Whom to give")
    .addParam("amount", "Amount of tokens")
    .setAction(async (taskArgs, { ethers }) => {
        const amount = ethers.utils.parseEther(taskArgs.amount);

        let recepient = "";
        if (taskArgs.to) {
            if (polkadotCryptoUtils.isEthereumAddress(taskArgs.to)) {
                recepient = polkadotCryptoUtils.evmToAddress(taskArgs.to);
            } else {
                recepient = taskArgs.to;
            }
        } else {
            console.log("provide address")
        }

        const wsProvider = new WsProvider('ws://localhost:9944')
        const keyring = new Keyring({ type: 'sr25519' });

        const polkalice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        const polkapi = await ApiPromise.create({ provider: wsProvider });

        const tx = polkapi.tx.balances.transfer(recepient, amount);
        await tx.signAndSend(polkalice);
        console.log("Given", amount.toString(), "to", taskArgs.to);
    });