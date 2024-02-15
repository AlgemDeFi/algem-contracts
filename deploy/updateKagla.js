const CONTRACT_NAME = "KaglaAdapter";

const { ethers, upgrades } = require("hardhat");

const localCHainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    const contract = await ethers.getContractFactory(CONTRACT_NAME);
    // const instance = await upgrades.deployProxy(contract, { deployer });
    //const instance = await upgrades.upgradeProxy("0xD9E81aDADAd5f0a0B59b1a70e0b0118B85E2E2d3", contract)
    // await instance.deployed();

    // prepare upgrade
    // const implAddress = await upgrades.prepareUpgrade("0x8d4F87A8f688Af04e9E3023C8846c3f6c64f410e", contract);
    
    // in case of errors
    // const instance = await upgrades.forceImport("0x8d4F87A8f688Af04e9E3023C8846c3f6c64f410e", contract)

    // regular deploy
    const instance = await contract.deploy()
    await instance.deployed();

    console.log(CONTRACT_NAME + " deployed to: " + instance.address, "=> Finish");
};
module.exports.tags = [CONTRACT_NAME];