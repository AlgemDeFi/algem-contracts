import { task } from "hardhat/config";
import { LiquidStakingAddr } from "../hardhat.config";
import * as fs from "fs";

task("stakers", "Retrieve stakers array from LS contract")
.setAction(async (_, { ethers }) => {
    const LSContract = await ethers.getContractAt("LiquidStaking", LiquidStakingAddr);
    const res = await LSContract.getStakers();
    const jsonData = JSON.stringify(res);
    console.log(jsonData);
    fs.writeFileSync("stakers.json", jsonData);
    console.log(res);
});

