const CONTRACT_SIRIUS = "SiriusAdapter";
const CONTRACT_AS = "ArthswapAdapter";

const { ethers, upgrades } = require("hardhat");

const localCHainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    const sirius = await ethers.getContractFactory(CONTRACT_SIRIUS);
    const as = await ethers.getContractFactory(CONTRACT_AS);

    const instanceSirius = await sirius.deploy()
    await instanceSirius.deployed();

    const instanceAs = await as.deploy()
    await instanceAs.deployed();

    console.log(CONTRACT_SIRIUS + " deployed to: " + instanceSirius.address, "=> Done");
    console.log(CONTRACT_AS + " deployed to: " + instanceAs.address, "=> Done");
};
module.exports.tags = [CONTRACT_SIRIUS];