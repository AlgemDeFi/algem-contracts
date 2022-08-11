import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ApiPromise, Keyring, WsProvider } from "@polkadot/api";
import { ethers, network, upgrades } from "hardhat";
import { evmToPlm } from "../scripts/utils";
import { BigNumber, Contract, Wallet } from "ethers";
import { expect } from "chai";
import { LiquidStaking, NASTR, NDistributor } from "../typechain-types";

let CONTRACTS = {
    distr: { name: "NDistributor", addr: "0x0" },
    dnt: { name: "NASTR", addr: "0x0" },
    ls: { name: "LiquidStaking", addr: "0x0" }
};

const parse = ethers.utils.parseEther;

describe("Algem App", function () {
    let owner: SignerWithAddress;
    let someGuy1: SignerWithAddress;
    let someGuy2: SignerWithAddress;
    let someGuy3: SignerWithAddress;

    let distrContract: Contract;
    let dntContract: Contract;
    let lsContract: Contract;

    const waitBlocks = async(blocks: number) => {
        await new Promise(f => setTimeout(f, blocks * 2000));
    }
    const giveMoney = async (to: string, amount: BigNumber) => {
        const wsProvider = new WsProvider('ws://localhost:9944')
        const keyring = new Keyring({ type: 'sr25519' });
        const alice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        const api = await ApiPromise.create({ provider: wsProvider });

        const recepient = evmToPlm(to);
        const tx = api.tx.balances.transfer(recepient, amount);
        const txHash = await tx.signAndSend(alice);
        await new Promise(f => setTimeout(f, 2100));
    }
    const registerDapp = async (app: string) => {
        const wsProvider = new WsProvider('ws://localhost:9944')
        const keyring = new Keyring({ type: 'sr25519' });
        const alice = keyring.addFromUri('//Alice', { name: 'Alice default' });
        const api = await ApiPromise.create({ provider: wsProvider });

        const tx = api.tx.dappsStaking.register({ evm: app });
        const txHash = await tx.signAndSend(alice);
        console.log("Registered [", app, "]");
    }

    before(async () => {
        [owner, someGuy1, someGuy2, someGuy3] = await ethers.getSigners();
        await giveMoney(owner.address, parse("10000"));
    });

    describe("Deploy contracts", function () {
        it("Should deploy NDistributor", async () => {
            const f = await ethers.getContractFactory(CONTRACTS.distr.name);
            distrContract = await upgrades.deployProxy(f);
            await distrContract.deployed();
            expect(distrContract.address).not.equal(ethers.constants.AddressZero);
        });
        it("Should deploy DNT", async () => {
            const f = await ethers.getContractFactory(CONTRACTS.dnt.name);
            dntContract = await upgrades.deployProxy(f, [distrContract.address]);
            await dntContract.deployed();
            expect(dntContract.address).not.equal(ethers.constants.AddressZero);
        })
        it("Should deploy LiquidStaking", async () => {
            const f = await ethers.getContractFactory(CONTRACTS.ls.name);
            lsContract = await upgrades.deployProxy(f, [
                CONTRACTS.dnt.name, "LiquidStaking",
                distrContract.address, dntContract.address
            ]);
            await lsContract.deployed();
            expect(lsContract.address).not.equal(ethers.constants.AddressZero);
        });
    });
    describe("Initial setup", function () {
        it("Should add dnt in distributor", async () => {
            expect(await distrContract.addDnt(CONTRACTS.dnt.name, dntContract.address)).to.satisfy;
        });
        it("Should set util in distributor", async () => {
            expect(await distrContract.addUtility("LiquidStaking")).to.satisfy;
        });
        it("Should set liquid staking addr in distributor", async () => {
            expect(await distrContract.setLiquidStaking(lsContract.address)).to.satisfy;
        });
        it("Should set dnt as manager in distributor", async () => {
            expect(await distrContract.addManager(dntContract.address)).to.satisfy;
        });
        it("Should add liquid staking as manager in distributor", async () => {
            expect(await distrContract.addManager(lsContract.address)).to.satisfy;
        });

        it("Should register app at dapp staking module", async () => {
            expect(await registerDapp(lsContract.address)).to.satisfy;
        });
    });
    describe("Admin funcs", function () {
        it("Should fill unstaking pool", async () => {
            expect(await lsContract.connect(owner).fillUnstaking({ value: parse("1000") })).to.satisfy;
        });
    });
    describe("Core funcs", function () {
        describe("Staking", function () {
            it("Should stake 1 token", async () => {
                await giveMoney(someGuy1.address, parse("200"));
                expect(await lsContract.connect(someGuy1).stake({ value: parse("1") })).to.emit(
                    lsContract, "Staked").withArgs(someGuy1.address, parse("1"));
            });
            it("Should stake 100 tokens", async () => {
                await giveMoney(someGuy2.address, parse("200"));
                expect(await lsContract.connect(someGuy2).stake({ value: parse("100") })).to.emit(
                    lsContract, "Staked").withArgs(someGuy2.address, parse("100"));
            });
            it("Should stake 1000 token", async () => {
                await giveMoney(someGuy3.address, parse("3000"));
                expect(await lsContract.connect(someGuy3).stake({ value: parse("1000") })).to.emit(
                    lsContract, "Staked").withArgs(someGuy3.address, parse("1000"));
            });
            it("Should not stake 0 tokens", async () => {
                expect(lsContract.connect(someGuy1).stake()).to.be.reverted;
            });
        });

        describe("Unstaking", function () {
            it("Should unstake 100 tokens immediately", async () => {
                expect(await lsContract.connect(someGuy2).unstake(parse("100"), true)).to.emit(
                    lsContract, "Unstaked").withArgs(someGuy2.address, parse("100"), true);
            });
            it("Should unstake 1 tokens", async () => {
                expect(await lsContract.connect(someGuy1).unstake(parse("1"), false)).to.emit(
                    lsContract, "Unstaked").withArgs(someGuy1.address, parse("1"), false);
            });
        });

        describe("Rewards", function () {
            it("Should wait 2 eras", async () => {
				console.log("Waiting 2 eras");
                expect(await waitBlocks(120)).to.satisfy;
            })
            it("Should call eraShots on each staker", async () => {
                const stakers = await lsContract.getStakers();
                for(const s in stakers){
                    try {
                        console.log(s);
                    expect(await lsContract.eraShot(s, "LiquidStaking", "NASTR")).to.satisfy;
                    } catch(err) {
                        console.log(err);
                    }
                }
            });
            it("Should claim rewards", async () => {
                const reward = await lsContract.totalUserRewards(someGuy3.address);
                console.log(reward.toString());
                expect(await lsContract.connect(someGuy3).claim(reward)).to.emit(
                    lsContract, "Claimed").withArgs(someGuy3.address, reward);
            });
        });

        describe("Withdraw", function () {
            it("Should withdraw unbonded tokens", async () => {
                expect(await lsContract.connect(someGuy1).withdraw(0)).to.emit(
                    lsContract, "Withdrawn").withArgs(someGuy1.address, parse("1"));
            });
        });

        describe("Transfer", function () {
            it("Should transfer dnt", async() => {
                expect(await dntContract.connect(someGuy3).transfer(someGuy1.address, parse("100"))).to.satisfy;
            });
            it("Should unstake transferred tokens", async() => {
                expect(await lsContract.connect(someGuy1).unstake(parse("50"), true));
            })
        });
    });
});
