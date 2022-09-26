import hre from "hardhat";
import { ethers, upgrades } from "hardhat";

//nDistributor
//DNT
//LiquidStaking
async function main() {
    const [me] = await ethers.getSigners();
    console.log("Deploying with", me.address);
    const distrF = await ethers.getContractFactory("NDistributor");
    const dntF = await ethers.getContractFactory("NASTR");
    const lsF = await ethers.getContractFactory("LiquidStaking");

    //deploy distr

    const distr = await upgrades.deployProxy(distrF);
    await distr.deployed();
    await distr.deployTransaction.wait();
    console.log("Distr deployed to:", distr.address);

    const dnt = await upgrades.deployProxy(dntF, [distr.address]);
    await dnt.deployed();
    await dnt.deployTransaction.wait();
    console.log("DNT deployed to:", dnt.address);

    const ls = await upgrades.deployProxy(lsF, [
        "nASTR", "LiquidStaking",
        distr.address, dnt.address
    ]);
    await ls.deployed();
    await ls.deployTransaction.wait();
    console.log("Liquid staking deployed to:", ls.address);

    let tx = await distr.addUtility("LiquidStaking");
    await tx.wait();
    console.log("Utility added");

    tx = await distr.addDnt("nASTR", dnt.address);
    await tx.wait();
    console.log("DNT added");

    tx = await distr.addManager(dnt.address);
    await tx.wait();
    console.log("Added dnt as manager");

    tx = await distr.addManager(ls.address);
    await tx.wait();
    console.log("Added liquidstaking as manager");
    // It's sad buy Astar doesn't support easy verification methods :(
    
    tx = await distr.setLiquidStaking(ls.address);
    await tx.wait();
    console.log("Added liquidstaking via setLiquidStaking");
}

main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
})