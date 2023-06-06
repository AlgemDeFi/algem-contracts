import { ethers, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
const CONTRACT_NAME = "NDistributor";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
	const { deployer } = await getNamedAccounts();

	console.log("Deployer: ", deployer);

	const contract = await ethers.getContractFactory(CONTRACT_NAME);
	const instance  = await upgrades.deployProxy(contract);
	await instance.deployed();
	console.log(CONTRACT_NAME + " deployed to " + instance.address);
}
export default func;
