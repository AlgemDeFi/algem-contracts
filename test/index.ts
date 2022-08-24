import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { run } from "hardhat";
import { Contract } from "ethers";

const zero = ethers.constants.AddressZero;
const parse = ethers.utils.parseEther;
const wait = async(ms: number) => {
    console.log("Waiting", ms, "ms")
    await new Promise(f => setTimeout(f, ms));
}

describe("Algem App", function () {
    let owner: SignerWithAddress,
        someGuy1: SignerWithAddress,
        someGuy2: SignerWithAddress,
        someGuy3: SignerWithAddress;

    let distr: Contract,
        dnt: Contract,
        ls: Contract;

    before(async function() {
        [owner, someGuy1, someGuy2, someGuy3] = await ethers.getSigners();
        await run("giveMoney", {to: owner.address, amount: "10000"});
        await wait(4000);
        await run("giveMoney", {to: someGuy1.address, amount: "10000"});
        await wait(4000);
        await run("giveMoney", {to: someGuy2.address, amount: "10000"});
        await wait(4000);
        await run("giveMoney", {to: someGuy3.address, amount: "10000"});
        await wait(4000);
    });

    describe("Deploy contracts", function () {
        it("Should deploy nDistributor", async () => {
            const distrFactory = await ethers.getContractFactory("NDistributor");
            distr = await upgrades.deployProxy(distrFactory);
            await distr.deployed();
            await distr.deployTransaction.wait();
            (distr.address).should.not.equal(zero);
        });

        it("Should deploy dnt", async () => {
            const dntFactory = await ethers.getContractFactory("NASTR");
            dnt = await upgrades.deployProxy(dntFactory, [distr.address]);
            await dnt.deployed();
            await dnt.deployTransaction.wait();
            dnt.address.should.not.equal(zero);
        });

        it("Should deploy LiquidStaking", async () => {
            const lsFactory = await ethers.getContractFactory("LiquidStaking");
            ls = await upgrades.deployProxy(lsFactory, [
                "nASTR", "LiquidStaking",
                distr.address, dnt.address
            ]);
            await ls.deployed();
            await ls.deployTransaction.wait();
            ls.address.should.not.equal(zero);
        });
    });

    describe("Initial contract setup", function () {
        describe("NDistributor", function () {
            it("Should addUtility", async () => {
                const tx = await distr.addUtility("LiquidStaking");
                await tx.wait();
                const utilID = await distr.utilityId("LiquidStaking");
                const util = await distr.utilityDB(utilID);
                util.isActive.should.be.equal(true);
            });
        });

        it("Should register dapp in DAPPS_STAKING");
    });

    describe("Admin functions", function () {
        describe("nDistributor", function () {

        });

        describe("DNT", function () {

        });

        describe("LiquidStaking", function () {

        });
    });

    describe("Core functions", function () {

    });
});