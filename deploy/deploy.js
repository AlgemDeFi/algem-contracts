const CONTRACT_NAME = "ArthswapAdapter";

const { ethers, upgrades } = require("hardhat");

const localCHainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId}) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    const contract = await ethers.getContractFactory(CONTRACT_NAME);
    const instance = await contract.deploy()
    await instance.deployed();
    console.log(CONTRACT_NAME + " deployed to: " + instance.address);
};
module.exports.tags = [CONTRACT_NAME];