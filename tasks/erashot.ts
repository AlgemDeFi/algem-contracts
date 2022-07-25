import { task } from "hardhat/config";
import { LiquidStakingAddr } from "../hardhat.config";

task("eraShot", "Save info about user balance")
.addParam("user", "Address which balance should be saved")
.addParam("util", "Utility name")
.addParam("dnt", "DNT name")
.setAction(async (taskArgs, { ethers }) => {
    const LSContract = await ethers.getContractAt("LiquidStaking", LiquidStakingAddr);
    await LSContract.eraShot(taskArgs.user, taskArgs.util, taskArgs.dnt);
});