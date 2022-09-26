import { task } from "hardhat/config";
import { ApiPromise, Keyring, WsProvider } from "@polkadot/api";

task("registerDapp", "Registers contract in DAPPS_STAKING module")
.addParam("contract", "Dapp address")
.setAction(async (taskArgs) => {
        const wsProvider = new WsProvider('ws://localhost:9944')
        const keyring = new Keyring({ type: 'sr25519' });
        const alice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        const api = await ApiPromise.create({ provider: wsProvider });

        const tx = api.tx.dappsStaking.register("Xrb2mPkS8RvT584xtJUaBm2mts79xc2Wm8bWoVCErvjmSRb",{evm: taskArgs.contract });
        const txHash = await tx.signAndSend(alice);
        console.log("Registered [", taskArgs.contract, "]");

});