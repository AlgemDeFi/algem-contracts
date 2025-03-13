// SPDX-License-Identifier: UNLICENSED
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

/// @notice LiquidStakingLayer2 deploying on Sepolia
contract DeploySepolia is Script {
    using Strings for uint256;

    uint256 public DAPPS_AMOUNT = 3;

    address linkToken;
    address router;
    address payable wastr;

    MockAlgemNFT nftContract;
    MockDapp dapp;
    ALGM algm;

    XNASTR xnastr;

    LiquidStaking liquidImpl;
    LiquidStaking liquidWrappedProxy;
    TransparentUpgradeableProxy liquidProxy;

    LiquidStakingLayer2 liquidL2Impl;
    LiquidStakingLayer2 liquidL2;
    TransparentUpgradeableProxy liquidL2Proxy;

    LiquidStakingManager lmanagerImpl;
    LiquidStakingManager lmanagerWrappedProxy;
    TransparentUpgradeableProxy lmanagerProxy;

    LiquidStakingMain liquidMain;
    LiquidStakingAdmin liquidAdmin;
    LiquidStakingVoting liquidVoting;

    LiquidStakingMain liquidMainImpl;
    LiquidStakingAdmin liquidAdminImpl;
    LiquidStakingVoting liquidVotingImpl;

    ALGMStaking algmStakingImpl;
    ALGMStaking algmStakingWrappedProxy;
    TransparentUpgradeableProxy algmStakingProxy;

    MockDappsStaking dsImpl;
    MockDappsStaking ds;
    TransparentUpgradeableProxy dsProxy;

    ProxyAdmin admin;

    bytes4[] liquidMainSelectors = [bytes4(0x3b2736ed), bytes4(0xb3fc1a6e), bytes4(0x59b40f41), bytes4(0xa217fddf), bytes4(0x1b2df850), bytes4(0x86b3cd26), bytes4(0x0b627b4e), bytes4(0xd45221b8), bytes4(0xebf69039), bytes4(0x33e382b1), bytes4(0x867ef36e), bytes4(0x254701a6), bytes4(0xa8feb462), bytes4(0x13f22214), bytes4(0x973628f6), bytes4(0x06040618), bytes4(0xe3287414), bytes4(0xd0928e88), bytes4(0xdcf425df), bytes4(0xda3bc958), bytes4(0xdd5418fb), bytes4(0x78b2d4de), bytes4(0x77b8ac64), bytes4(0xf5646e33), bytes4(0xe53034f9), bytes4(0x73c9cebe), bytes4(0xf16ca2e4), bytes4(0x721b2f62), bytes4(0xe12c398c), bytes4(0xe88539e3), bytes4(0x248a9ca3), bytes4(0x331d437b), bytes4(0xc6ecccb8), bytes4(0x4f84a0bf), bytes4(0x2f2ff15d), bytes4(0x91d14854), bytes4(0xc8902a21), bytes4(0x09b65e66), bytes4(0xa735b85f), bytes4(0x5495ec81), bytes4(0xd0b06f5d), bytes4(0x0a7285be), bytes4(0x5ca5914e), bytes4(0x6cbcfa49), bytes4(0xf1887684), bytes4(0x39ec4df9), bytes4(0x75bea166), bytes4(0x599db0f8), bytes4(0x5c975abb), bytes4(0x45cb9f58), bytes4(0x36568abe), bytes4(0x7f753de6), bytes4(0xd547741f), bytes4(0x66666aa9), bytes4(0x3a4b66f1), bytes4(0x26476204), bytes4(0x01ffc9a7), bytes4(0xb1357bf9), bytes4(0x449696d7), bytes4(0x817b1cd2), bytes4(0xb3a2273f), bytes4(0x7d3c0c65), bytes4(0x20637d8e), bytes4(0x21d0af34), bytes4(0x9ebea88c), bytes4(0x62190150), bytes4(0xe909f0a4), bytes4(0xfae514f8), bytes4(0x0ab2a9a2), bytes4(0xf3fef3a3), bytes4(0x2e1a7d4d), bytes4(0x422b1077), bytes4(0xbdd7ab83)];
    bytes4[] liquidAdminSelectors = [bytes4(0x447a91fd), bytes4(0x27917d60), bytes4(0x36568abe), bytes4(0x036d78bc), bytes4(0xd547741f), bytes4(0x1f35d63c), bytes4(0x9300a052), bytes4(0xeb4af045), bytes4(0x6ea3a228), bytes4(0x56a9e4e4), bytes4(0xd3686954), bytes4(0x0ceff204), bytes4(0x6b4ae2a8), bytes4(0x3238162f)];
    bytes4[] liquidVotingSelectors = [bytes4(0xa58bdf2c), bytes4(0xabfe87bf), bytes4(0x92a12996), bytes4(0xd8787ddb), bytes4(0x81160b02), bytes4(0x2a4a1b73)];

    function setUp() public {
        linkToken = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // sepolia's ccip link token
        router = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // sepolia's ccip router
        wastr = payable(0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42);
        xnastr = XNASTR(0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e);
    }

    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);
        vm.startBroadcast(deployerPK);

        algm = new ALGM();
        nftContract = new MockAlgemNFT("AlgemNFT", "ALGMNFT");

        // deploy ALGMStaking
        // algmStakingImpl = new ALGMStaking();
        // algmStakingProxy = new TransparentUpgradeableProxy(address(algmStakingImpl), deployer, "");
        // algmStakingWrappedProxy = ALGMStaking(address(algmStakingProxy));
        // algmStakingWrappedProxy.initialize(
        //     IERC20(address(algm)),
        //     IVeALGM(address(veProxy))
        // );

        // deploy DappsStaking
        ds = new MockDappsStaking();
        dsImpl = new MockDappsStaking();
        dsProxy = new TransparentUpgradeableProxy(address(dsImpl), deployer, "");
        ds = MockDappsStaking(payable(address(dsProxy)));
        ds.initialize(address(wastr));

        // deploy LiquidStaking
        liquidImpl = new LiquidStaking();
        liquidProxy = new TransparentUpgradeableProxy(address(liquidImpl), deployer, "");
        liquidWrappedProxy = LiquidStaking(payable(address(liquidProxy)));

        // address[] memory authorizedList = new address[](1);
        // authorizedList[0] = address(liquidWrappedProxy);
        // algmStakingWrappedProxy.updateAuthorizedList(authorizedList);

        // initialize LS
        liquidWrappedProxy.initialize(
            xnastr,
            linkToken,
            router,
            WETH9(wastr),
            makeAddr("algemDsAddr")
        );

        lmanagerImpl = new LiquidStakingManager();
        lmanagerProxy = new TransparentUpgradeableProxy(address(lmanagerImpl), deployer, "");
        lmanagerWrappedProxy = LiquidStakingManager(address(lmanagerProxy));
        lmanagerWrappedProxy.initialize();

        // set LS Manager in LS
        liquidWrappedProxy.setLiquidStakingManager(address(lmanagerProxy));

        // deploy facets
        liquidMainImpl = new LiquidStakingMain();
        liquidAdminImpl = new LiquidStakingAdmin();
        liquidVotingImpl = new LiquidStakingVoting();

        // add selectors to manager
        lmanagerWrappedProxy.addSelectorsBatch(liquidMainSelectors, address(liquidMainImpl));
        lmanagerWrappedProxy.addSelectorsBatch(liquidAdminSelectors, address(liquidAdminImpl));
        lmanagerWrappedProxy.addSelectorsBatch(liquidVotingSelectors, address(liquidVotingImpl));


        liquidMain = LiquidStakingMain(payable(address(liquidProxy)));
        liquidAdmin = LiquidStakingAdmin(address(liquidProxy));
        liquidVoting = LiquidStakingVoting(address(liquidProxy));

        liquidAdmin.addNft(address(nftContract));

        addUtilities();
        liquidAdmin.toggleWeights();

        vm.stopBroadcast();

        console.log("DappsStaking:", address(ds));
        console.log("LiquidStaking:", address(liquidWrappedProxy));
        console.log("LiquidStakingManager:", address(lmanagerWrappedProxy));
        console.log("LiquidStakingMain:", address(liquidMainImpl));
        console.log("LiquidStakingAdmin:", address(liquidAdminImpl));
        console.log("LiquidStakingVoting:", address(liquidVotingImpl));
        console.log("XNASTR:", address(xnastr));
        console.log("ALGM:", address(algm));
        // console.log("veALGM:", address(veWrappedProxy));
        // console.log("ALGMStaking:", address(algmStakingWrappedProxy));
        console.log("NFT:", address(nftContract));
    }

    function addUtilities() public {
        for (uint256 i = 2; i <= DAPPS_AMOUNT; i++) {
            uint256[] memory weights = new uint256[](i);
            uint256 oneWeight = 10000 / i;
            for (uint256 j; j < i; j++) {
                weights[j] = oneWeight;
            }
            weights[0] += 10000 - oneWeight * i;
            liquidVoting.addDapp(
                string(abi.encodePacked("Dapp", i.toString())),
                vm.addr(1000 - i), // for different addrss
                weights
            );
        }
    }
}

// == Logs ==
//   DappsStaking: 0x97Ca75B521FC2Fc1B68b019F4e3e2c9bd3cb43A0
//   LiquidStaking: 0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91
//   LiquidStakingManager: 0x4bDEd6e30DfF18c38C978565D3F6342F43437A03
//   LiquidStakingMain: 0x27d385187cD42802F8C575551f4Dfa32E38555df
//   LiquidStakingAdmin: 0x614ea36a59D4eC264E14193A1CD2c91741ccdc10
//   LiquidStakingVoting: 0xE0a018B382173854324F75B7D04db8558B886959
//   XNASTR: 0x8c4b8f923C99C1b1e00c4956D5d623e95390d47e
//   WASTR: 0xe857591eEa4030bda6260c4cAbEB5B3Baf935B42
//   ALGM: 0xFd688dadDF7c5Ac274AbEd78A526985f0283e997
//   veALGM: 0xDF4d5878Cb636D55132A587331fED20065D9d5D5
//   ALGMStaking: 0x67AC8d5a8020a6F7e4FdADbD878fc750526D78E2
//   NFT: 0xf138702204CDcd5C2552D447e9698897f9dE33A5

// superbridge sepolia 0x5f5a404A5edabcDD80DB05E8e54A78c9EBF000C2
// superbridge minato  0x4200000000000000000000000000000000000010