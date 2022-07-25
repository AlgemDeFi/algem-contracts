//import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
//import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { NDistributor, NDistributor__factory } from "../typechain-types";

import { ApiPromise, WsProvider } from '@polkadot/api';
import { Keyring } from "@polkadot/api";

const CONTRACT_NAME = "NDistributor";

describe("NDistributor", function () {
    let distrF: NDistributor__factory;
    let distrContract;
    let alice;
    
    before(async () => {
        // Construct API provider
        console.log("Connecting to localhost");
        const wsProvider = new WsProvider('ws://localhost:9944');
        const api = await ApiPromise.create({ provider: wsProvider });
        const keyring = new Keyring({ type: 'sr25519' });
        console.log("Connected. Getting substrate alice dev account");
        alice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        console.log("Preparing to send native tokens to evm addr");
        const tx = await api.tx.balances.transfer("XCzUdy6YNQyS4Dyz67k5X5ZrEnS4zuoFJ3Pg6VAbfuyocoF", ethers.utils.parseEther("1000000"));
        const encodedCalldata = tx.method.toHex();
        const txHash = await tx.signAndSend(alice);
        console.log("All done");
    });

    describe("Deployment", function () {
        it("Deploy proxy", async () => {
            let me = await ethers.getSigner("0x94C2C73f1Ea93DD3F2477c8B1A0c136D973dEee3");
            distrF = await ethers.getContractFactory(CONTRACT_NAME);
            await ethers.provider.
            //distrContract = await upgrades.deployProxy(distrF, { me });
            let distr = await upgrades.deployProxy(distrF, { me });
            await distrContract.deployed();
            expect(distrContract.address).not.equal(ethers.constants.AddressZero);
        });
    });
});
