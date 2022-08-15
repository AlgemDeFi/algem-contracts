import { ethers, upgrades } from "hardhat";
import { evmToPlm } from "../scripts/utils";
import { ApiPromise, Keyring, WsProvider } from "@polkadot/api";
import { BigNumber } from "ethers";

import distr from "./contracts/NDistributor";
import dnt from "./contracts/DNT";
import ls from "./contracts/LiquidStaking";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Algem app", function () {
    before(async function() {
        //this.accounts = await ethers.getSigners();
        //console.log(accs);
        //this.accounts = accs;

        const wsProvider = new WsProvider('ws://localhost:9944')
        const keyring = new Keyring({ type: 'sr25519' });

        this.polkalice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        this.polkapi = await ApiPromise.create({ provider: wsProvider });

        this.giveMoney = async (to: string, amount: BigNumber) => {
            const recepient = evmToPlm(to);
            const tx = this.polkapi.tx.balances.transfer(recepient, amount);
            const txHash = await tx.signAndSend(this.polkalice);
        }

        this.registerDapp = async (app: string) => {
            const tx = this.polkapi.tx.dappsStaking.register({ evm: app });
            const txHash = await tx.signAndSend(this.polkalice);
        }
});

    describe("NDistributor", distr.bind(this));
    describe("DNT", dnt.bind(this));
    describe("LiquidStaking", ls.bind(this));

    describe("Environment", function () {
        it("Should register LS proxy to dappsStaking", async function () {
            (await this.registerDapp(this.ls.address)).should.satisfy;
        });
    });

    describe("Stake", function () {

    });

    describe("Unstake", function () {

    });

    describe("Withdraw", function () {

    });

    describe("Liquidity", function () {

    });
});