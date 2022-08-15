import { ethers, upgrades } from "hardhat";

//contract names
const CONTRACTS = {
    distr: "NDistributor",
    dnt: "nASTR",
    ls: "LiquidStaking"
}

before("#deployment", async function () {
    this.accounts = await ethers.getSigners();
    await this.giveMoney(this.accounts[0].address, ethers.utils.parseEther("1000"));
    let f = await ethers.getContractFactory(CONTRACTS.distr);
    let c = await upgrades.deployProxy(f);
    await c.deployed();
    this.distr = c;
    console.log("Got distr");

    f = await ethers.getContractFactory(CONTRACTS.dnt);
    c = await upgrades.deployProxy(this.distr.address);
    await c.deployed();
    this.dnt = c;
    console.log("Got dnt");

    f = await ethers.getContractFactory(CONTRACTS.ls);
    c = await upgrades.deployProxy(f,
        [CONTRACTS.dnt, "LiquidStaking",
        this.distr.address, this.dnt.address]
    );
    await c.deployed();
    this.ls = c;
    console.log("Got ls");
});
