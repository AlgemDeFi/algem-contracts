import { task } from "hardhat/config";
import { LiquidStakingAddr } from "../hardhat.config";
import * as fs from "fs";
import stakersJSON from "../stakers.json";

task("shooter", "calls erashot for each staker in stakers.json")
//.addParam("stakers", "path to stakers.json")
.setAction(async (taskArgs, { ethers }) => {
	const LSContract = await ethers.getContractAt("LiquidStaking", LiquidStakingAddr);
   	for(let i = 0; i < stakersJSON.length; i++) {
   	    const staker = stakersJSON[i];
   	    console.log("Shooting ", staker);
   	    await LSContract.eraShot(staker, "LiquidStaking", "NSBY");
   	}
});
