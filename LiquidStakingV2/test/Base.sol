// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
import "./ALGMStaking/ALGMStaking.sol";
import "./ALGMStaking/VeALGM.sol";
import "./ALGMStaking/tokens/ALGM.sol";
import { LiquidStakingLayer2, ILiquidStakingLayer2 } from "../src/LiquidStakingLayer2.sol";

contract Base is Test {
    using Strings for uint256;

    uint256 public constant DAPPS_AMOUNT = 5;

    address user;
    address receiver;
    address deployer;

    address userA;
    address userB;
    address userC;

    uint64 chainSelector;

    MockAlgemNFT nftContract;
    MockDappsStaking ds;
    MockDapp dapp;
    ALGM algm;

    XNASTR xnastr;
    XNASTR xnastrImpl;
    TransparentUpgradeableProxy xnastrProxy;

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

    VeALGM veImpl;
    VeALGM veWrappedProxy;
    TransparentUpgradeableProxy veProxy;

    ALGMStaking algmStakingImpl;
    ALGMStaking algmStakingWrappedProxy;
    TransparentUpgradeableProxy algmStakingProxy;

    ProxyAdmin admin;

    bytes4[] liquidMainSelectors = [bytes4(0xf3fef3a3), bytes4(0x21d0af34), bytes4(0x26476204), bytes4(0x3b2736ed), bytes4(0xb3fc1a6e), bytes4(0x59b40f41), bytes4(0xa217fddf), bytes4(0x1b2df850), bytes4(0x86b3cd26), bytes4(0x0b627b4e), bytes4(0xd45221b8), bytes4(0x5cad6177), bytes4(0x867ef36e), bytes4(0x254701a6), bytes4(0xa8feb462), bytes4(0x13f22214), bytes4(0x973628f6), bytes4(0x06040618), bytes4(0xd0928e88), bytes4(0x1ac05b29), bytes4(0xda3bc958), bytes4(0x78bdadd7), bytes4(0x77b8ac64), bytes4(0xf5646e33), bytes4(0xaa11c44f), bytes4(0x763671a5), bytes4(0x721b2f62), bytes4(0xe12c398c), bytes4(0x248a9ca3), bytes4(0x4f84a0bf), bytes4(0x2f2ff15d), bytes4(0x91d14854), bytes4(0xc8902a21), bytes4(0x09b65e66), bytes4(0xa735b85f), bytes4(0x5495ec81), bytes4(0xd0b06f5d), bytes4(0x5ca5914e), bytes4(0x6cbcfa49), bytes4(0xf1887684), bytes4(0x75bea166), bytes4(0x599db0f8), bytes4(0xf692c21d), bytes4(0x5c975abb), bytes4(0x45cb9f58), bytes4(0x36568abe), bytes4(0x7f753de6), bytes4(0xd547741f), bytes4(0x66666aa9), bytes4(0x3a4b66f1), bytes4(0x01ffc9a7), bytes4(0xb1357bf9), bytes4(0x449696d7), bytes4(0x817b1cd2), bytes4(0xb3a2273f), bytes4(0x7d3c0c65), bytes4(0x20637d8e), bytes4(0x9ebea88c), bytes4(0x62190150), bytes4(0xe909f0a4), bytes4(0x879b29ef), bytes4(0xfae514f8), bytes4(0x2e1a7d4d), bytes4(0x422b1077), bytes4(0xbdd7ab83), bytes4(0xe88539e3)];
    bytes4[] liquidAdminSelectors = [bytes4(0x447a91fd), bytes4(0x27917d60), bytes4(0x36568abe), bytes4(0x036d78bc), bytes4(0xd547741f), bytes4(0x1f35d63c), bytes4(0x9300a052), bytes4(0xeb4af045), bytes4(0x6ea3a228), bytes4(0x56a9e4e4), bytes4(0xd3686954), bytes4(0x0ceff204), bytes4(0x6b4ae2a8), bytes4(0xd97f6741)];
    bytes4[] liquidVotingSelectors = [bytes4(0x81160b02), bytes4(0xabfe87bf), bytes4(0x2a4a1b73),bytes4(0xa58bdf2c),bytes4(0xd8787ddb),bytes4(0x92a12996)];

    function _deployLiquidStakingAstar(
        address linkToken,
        address router,
        WETH9 wastr
    ) internal {
        algm = new ALGM();

        nftContract = new MockAlgemNFT("AlgemNFT", "ALGMNFT");

        // deploy VeALGM
        veImpl = new VeALGM();
        veProxy = new TransparentUpgradeableProxy(address(veImpl), deployer, "");
        veWrappedProxy = VeALGM(address(veProxy));
        veWrappedProxy.initialize();

        // deploy ALGMStaking
        algmStakingImpl = new ALGMStaking();
        algmStakingProxy = new TransparentUpgradeableProxy(address(algmStakingImpl), deployer, "");
        algmStakingWrappedProxy = ALGMStaking(address(algmStakingProxy));
        algmStakingWrappedProxy.initialize(
            IERC20(address(algm)),
            IVeALGM(address(veProxy))
        );

        // deploy mock dappsStaking to certain address
        ds = new MockDappsStaking();
        bytes memory dsCode = address(ds).code;
        vm.etch(0x0000000000000000000000000000000000005001, dsCode);
        ds = MockDappsStaking(payable(0x0000000000000000000000000000000000005001));
        vm.deal(address(ds), ~uint256(0));

        // deploy LiquidStaking
        liquidImpl = new LiquidStaking();
        liquidProxy = new TransparentUpgradeableProxy(address(liquidImpl), deployer, "");
        liquidWrappedProxy = LiquidStaking(payable(address(liquidProxy)));

        address[] memory authorizedList = new address[](1);
        authorizedList[0] = address(liquidWrappedProxy);
        algmStakingWrappedProxy.updateAuthorizedList(authorizedList);

        // deploy xnastr
        xnastrImpl = new XNASTR();
        xnastrProxy = new TransparentUpgradeableProxy(address(xnastrImpl), deployer, "");
        xnastr = XNASTR(address(xnastrProxy));
        xnastr.initialize();
        xnastr.grantMintAndBurnRoles(router);
        xnastr.grantMintAndBurnRoles(address(liquidWrappedProxy));

        // initialize LS
        liquidWrappedProxy.initialize(
            xnastr,
            linkToken,
            router,
            wastr,
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

    function doVoting() public {
        deal(address(veWrappedProxy), user, 1000 ether);
        string[] memory dapps = liquidAdmin.getDappsList();
        uint256 votes;
        for (uint256 i; i < dapps.length; i++) {
            votes++;
            liquidL2.vote(votes * 1 ether, i);
        }
    }

    function _deployLiquidStakingLayer2(
        uint64 _chainSelector,
        address linkToken,
        address router,
        address payable wastrAddr,
        address xnastrAddr,
        address vealgmAddr
    ) internal {
        liquidL2Impl = new LiquidStakingLayer2();
        liquidL2Proxy = new TransparentUpgradeableProxy(address(liquidL2Impl), deployer, "");
        liquidL2 = LiquidStakingLayer2(payable(address(liquidL2Proxy)));
        liquidL2.initialize(
            wastrAddr,
            xnastrAddr,
            vealgmAddr,
            address(liquidMain),
            linkToken,
            router,
            _chainSelector
        );
        xnastr.grantMintAndBurnRoles(router);
    }

    function sprank(address addr) internal {
        vm.stopPrank();
        vm.startPrank(addr);
    }

    /// @dev Add blocks and increase time accordinly
    /// @dev Supposed that 1 block creation is 12 sec
    function mine(uint256 _blocks) internal {
        (uint256 timeNow, uint256 blockNow) = (block.timestamp, block.number);
        vm.roll(blockNow + _blocks);
        vm.warp(timeNow + _blocks * 6);
    }

    // function print(string memory label, uint256 number) internal { console2.log(StdStyle.cyan(label), StdStyle.cyan(number)); }
    // function print(string memory label, address addr) internal { console2.log(StdStyle.cyan(label), StdStyle.cyan(addr)); }
    // function print(address addr) internal { console2.log(StdStyle.cyan(addr)); }
    // function print(uint256 number) internal { console2.log(StdStyle.cyan(number)); }
    // function print(string memory label) internal { console2.log(StdStyle.cyan(label)); }
    // function print(string memory label, string memory message) internal { console2.log(StdStyle.cyan(label), StdStyle.cyan(message)); }
    // function print(string memory label, bytes32 data) internal { console2.log(StdStyle.cyan(label), StdStyle.cyanBytes32(data)); }
}