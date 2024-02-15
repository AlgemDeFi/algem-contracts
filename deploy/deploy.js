const CONTRACT_NAME = "LiquidStakingMain";

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

// misc with correct 0xAA25e9cf48B6A4Ce5836Cb77938128c8d327CCff ["0x0ceff204", "0xa0231e29", "0xa9c8733c"]
// misc without correct 0xc17ADE820dF5327f26E3242B7450Eb4f56BDbA7A ["0x0ceff204", "0xa0231e29"]

// 11646
// 11514