// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/LiquidStaking/LiquidStaking.sol";
import "../src/LiquidStaking/LiquidStakingMain.sol";
import "../src/LiquidStaking/LiquidStakingManager.sol";
import "../src/LiquidStaking/LiquidStakingVoting.sol";
import "../src/LiquidStaking/LiquidStakingAdmin.sol";
import "../src/XNASTR.sol";
import "../src/Mocks/MockDappsStaking.sol";
import "../src/Mocks/MockAlgemNFT.sol";
import "../src/Mocks/MockDapp.sol";
import "../test/ALGMStaking/ALGMStaking.sol";
import "../test/ALGMStaking/VeALGM.sol";
import "../test/ALGMStaking/tokens/ALGM.sol";
import { LiquidStakingLayer2, ILiquidStakingLayer2 } from "../src/LiquidStakingLayer2.sol";

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import { IAny2EVMMessageReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

/// @notice WASTR crosschain transferring
contract CrosschainTransferETH is Script {
    XNASTR xnastr;

    address linkAddrMinato;
    address linkAddrSepolia;

    address i_ccipRouterMinato;
    address i_ccipRouterSepolia;

    address deployer;
    address wethAddr;

    uint64 sepoliaChainSelector;
    uint64 minatoChainSelector;

    function setUp() public {
        // xnastr on both chains sepolia and minato
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);

        // minato
        linkAddrMinato = 0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2;
        i_ccipRouterMinato = 0x443a1bce545d56E2c3f20ED32eA588395FFce0f4;
        sepoliaChainSelector = 16015286601757825753;

        // sepolia
        linkAddrSepolia = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        i_ccipRouterSepolia = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
        minatoChainSelector = 686603546605904534;

        wethAddr = 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42;
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        // do 
        bytes memory data = abi.encode("Hi from Minato");
        
        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
        tokens[0] = Client.EVMTokenAmount(wethAddr, 0.5 ether);

        uint256 destination = 1; // 0 - sepolia, 1 - minato
        _ccipSend(destination, tokens, data);

        vm.stopBroadcast();
    }

    function _ccipSend(
        uint256 destination,
        Client.EVMTokenAmount[] memory tokens,
        bytes memory _data
    ) internal {
        address linkAddr;
        address i_ccipRouter;
        uint64 receiverChainSelector;

        if (destination == 1) {
            // sending from sepolia to minato
            linkAddr = linkAddrSepolia;
            i_ccipRouter = i_ccipRouterSepolia;
            receiverChainSelector = minatoChainSelector;
        } else {
            // sending from minato to sepolia
            linkAddr = linkAddrMinato;
            i_ccipRouter = i_ccipRouterMinato;
            receiverChainSelector = sepoliaChainSelector;
        }

        // set message data
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(deployer),
            data: _data,
            tokenAmounts: tokens,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 2_000_000})),
            feeToken: linkAddr
        });

        // approve tokens for router if there is a need to send it
        if (tokens.length > 0) {
            for (uint256 i; i < tokens.length; i++) {
                IERC20(tokens[i].token).approve(i_ccipRouter, tokens[i].amount);
            }            
        }

        uint256 fee = IRouterClient(i_ccipRouter).getFee(receiverChainSelector, message);

        IERC20(linkAddr).approve(address(i_ccipRouter), fee);

        IRouterClient(i_ccipRouter).ccipSend(
            receiverChainSelector,
            message
        );
    }
}

// weth minato 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42
// weth sepolia 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42

// before
// Logs:
//   Minato WETH balance: 1000000000000000000
//   Minato LINK balance: 304
//   Sepolia WETH balance: 1000000000000000000
//   Sepolia LINK balance: 43

// after
// Logs:
//   Minato WETH balance: 500000000000000000
//   Minato LINK balance: 298
//   Sepolia WETH balance: 1500000000000000000
//   Sepolia LINK balance: 43