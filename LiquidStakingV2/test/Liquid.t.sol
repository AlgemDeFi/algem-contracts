// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
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

contract LiquidTest is Test {
    using Strings for uint256;
    address user;
    address user2;
    address user3;
    address user10;
    address user11;
    address user12;
    address user13;
    address deployer;

    uint256 public constant DAPPS_AMOUNT = 5;

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

    LiquidStaking ls;

    ProxyAdmin admin;

    address linkAddr;
    address ccipRouterAddr;
    WETH9 wastr;

    bytes4[] liquidMainSelectors = [bytes4(0x3b2736ed), bytes4(0xb3fc1a6e), bytes4(0x59b40f41), bytes4(0xa217fddf), bytes4(0x1b2df850), bytes4(0x86b3cd26), bytes4(0x0b627b4e), bytes4(0xd45221b8), bytes4(0x5cad6177), bytes4(0x867ef36e), bytes4(0x254701a6), bytes4(0xa8feb462), bytes4(0x13f22214), bytes4(0x973628f6), bytes4(0x06040618), bytes4(0xd0928e88), bytes4(0x1ac05b29), bytes4(0xda3bc958), bytes4(0x78bdadd7), bytes4(0x77b8ac64), bytes4(0xf5646e33), bytes4(0xaa11c44f), bytes4(0x763671a5), bytes4(0x721b2f62), bytes4(0xe12c398c), bytes4(0x248a9ca3), bytes4(0x4f84a0bf), bytes4(0x2f2ff15d), bytes4(0x91d14854), bytes4(0xc8902a21), bytes4(0x09b65e66), bytes4(0xa735b85f), bytes4(0x5495ec81), bytes4(0xd0b06f5d), bytes4(0x5ca5914e), bytes4(0x6cbcfa49), bytes4(0xf1887684), bytes4(0x75bea166), bytes4(0x599db0f8), bytes4(0xf692c21d), bytes4(0x5c975abb), bytes4(0x45cb9f58), bytes4(0x36568abe), bytes4(0x7f753de6), bytes4(0xd547741f), bytes4(0x66666aa9), bytes4(0x3a4b66f1), bytes4(0x01ffc9a7), bytes4(0xb1357bf9), bytes4(0x449696d7), bytes4(0x817b1cd2), bytes4(0xb3a2273f), bytes4(0x7d3c0c65), bytes4(0x20637d8e), bytes4(0x9ebea88c), bytes4(0x62190150), bytes4(0xe909f0a4), bytes4(0x879b29ef), bytes4(0xfae514f8), bytes4(0x2e1a7d4d), bytes4(0x422b1077), bytes4(0xbdd7ab83), bytes4(0xe88539e3), bytes4(0xcb1f3ae7)];
    bytes4[] liquidAdminSelectors = [bytes4(0x447a91fd), bytes4(0x27917d60), bytes4(0x36568abe), bytes4(0x036d78bc), bytes4(0xd547741f), bytes4(0x1f35d63c), bytes4(0x9300a052), bytes4(0xeb4af045), bytes4(0x6ea3a228), bytes4(0x56a9e4e4), bytes4(0xd3686954), bytes4(0x0ceff204), bytes4(0x6b4ae2a8), bytes4(0xd97f6741)];
    bytes4[] liquidVotingSelectors = [bytes4(0xb384abef),bytes4(0x5292b2f9),bytes4(0xa58bdf2c),bytes4(0xd8787ddb),bytes4(0x92a12996),bytes4(0xb0c8f9dc)];

    modifier prank(address _who) {
        vm.startPrank(_who);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        user = makeAddr("user");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user10 = makeAddr("user10");
        user11 = makeAddr("user11");
        user12 = makeAddr("user12");
        user13 = makeAddr("user13");
        deployer = makeAddr("deployer");

        // plugs for unused addresses
        linkAddr = makeAddr("linkAddr");
        ccipRouterAddr = makeAddr("ccipRouterAddr");
        wastr = WETH9(payable(makeAddr("wastr")));
        
        vm.deal(user, ~uint128(0));
        vm.deal(user2, ~uint128(0));
        vm.deal(user3, ~uint128(0));

        vm.startPrank(deployer);
        deploy();

        addUtilities();
        // liquidAdmin.toggleWeights();

        liquidAdmin.setCCIPParams(
            uint64(uint256(keccak256(abi.encodePacked("soneiumChainSelector")))),
            makeAddr("liquidStakingLayer2Addr"),
            makeAddr("feeToken")
        );

        vm.stopPrank();

        deal(address(veWrappedProxy), user, 1000 ether);
    }

    function test_audit_H1() public {
        vm.deal(deployer, 100 ether);
        vm.prank(deployer);
        liquidMain.stake{value:1 ether}();
        vm.prank(user);
        liquidMain.stake{value:10 ether}();
        vm.prank(user3);
        liquidMain.stake{value: 8 ether}();
        vm.prank(user2);
        liquidMain.stake{value: 4 ether}();
        vm.roll(2 * 100000);
        uint xNastrBalanceUser = xnastr.balanceOf(user);
        uint xNastrBalanceUser2 = xnastr.balanceOf(user2);
        uint xNastrBalanceUser3 = xnastr.balanceOf(user3);
        vm.prank(user);
        liquidMain.unstake(xNastrBalanceUser, false);
        vm.prank(user3);
        liquidMain.unstake(xNastrBalanceUser3, false);
        vm.prank(user2);
        liquidMain.unstake(xNastrBalanceUser2, false);
        vm.roll(2 * 200000);
        uint currentERA = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(currentERA);
        vm.roll(2 * 300000);
        vm.prank(user);
        liquidMain.withdraw(0);
        vm.prank(user2);
        liquidMain.withdraw(0);
        vm.prank(user3);
        liquidMain.withdraw(0);
    }

    function test_audit_H2() public {
        vm.deal(deployer, 100 ether);
        nftContract.mint(deployer, 0);
        
        vm.prank(deployer);
        liquidMain.stake{value:1 ether}();

        vm.startPrank(user);
        liquidMain.stake{value:10 ether}();
        uint xnastrUserBalance = xnastr.balanceOf(user);
        nftContract.mint(user, 1);
        xnastr.approve(address(liquidMain), xnastrUserBalance);
        nftContract.approve((address(liquidMain)), 1);
        liquidMain.addCashbackLock(address(nftContract), xnastr.balanceOf(user) / 2, 1);
        uint xnastrUserBalance2 = xnastr.balanceOf(user);
        vm.stopPrank();

        vm.roll(2 * 200000);
        uint currentERA2 = liquidMain.currentEra();

        vm.prank(deployer);
        liquidMain.sync(currentERA2);
        vm.roll(2 * 300000);
        (uint amountCashBack, ,) = liquidMain.cashbackLocks(user,
        address(nftContract));
        vm.prank(user);
        liquidMain.releaseCashbackLock(address(nftContract), amountCashBack);
    }

    function test_audit_M1() public {
        vm.deal(deployer, 100 ether);
        vm.prank(deployer);
        liquidMain.stake{value:1 ether}();
        vm.startPrank(user);
        liquidMain.stake{value:10 ether}();
        uint xnastrUserBalance = xnastr.balanceOf(user);
        nftContract.mint(user, 1);
        xnastr.approve(address(liquidMain), xnastrUserBalance);
        nftContract.approve((address(liquidMain)), 1);
        // First addCashBack
        liquidMain.addCashbackLock(address(nftContract), xnastrUserBalance/3, 1);
        // console.log("cashBack Amount", liquidMain.collectedCashback(user));
        // Second addCashBack
        liquidMain.addCashbackLock(address(nftContract), xnastrUserBalance/3, 1);
        // console.log("cashBack Amount", liquidMain.collectedCashback(user));
        vm.stopPrank();
        vm.roll(2 * 200000);
        vm.startPrank(deployer);
        liquidMain.sync(liquidMain.currentEra());
        vm.stopPrank();
        vm.roll(2 * 300000);
        // Third addCashBack
        vm.startPrank(user);
        liquidMain.addCashbackLock(address(nftContract), xnastrUserBalance/3, 1);
        // console.log("cashBack Amount", liquidMain.collectedCashback(user));
        vm.stopPrank();
        vm.roll(2 * 400000);
        
        vm.startPrank(deployer);
        liquidMain.sync(liquidMain.currentEra());
        vm.stopPrank();
        
        vm.roll(2 * 500000);
        (uint lockAmountFromUser, , ) = liquidMain.cashbackLocks(user, address(nftContract));
        // console.log(lockAmountFromUser);

        vm.startPrank(user);
        liquidMain.releaseCashbackLock(address(nftContract), lockAmountFromUser);
        // console.log("cashBack Amount", liquidMain.collectedCashback(user));
        address[] memory path = new address[](1);
        path[0] = address(nftContract);
        // console.log("UserBalance Before claim CashBack", address(user).balance);
        liquidMain.claimCashback(path);
        // console.log("UserBalance After claim CashBack", address(user).balance);
    }

    function test_audit() public {
        vm.deal(user10, 100 ether);
        vm.deal(user11, 100 ether);
        vm.deal(user12, 100 ether);
        vm.deal(user13, 100 ether);
        vm.deal(deployer, 100 ether);

        switchPrank(deployer);
        liquidAdmin.setMinStakeAmount(1 ether);
        liquidMain.stake{value: 1 ether}();

        // console.log(address(user10).balance, "Init");
        // console.log(address(user11).balance, "Init");
        // console.log(address(user12).balance, "Init");
        // console.log("");

        switchPrank(user10);
        liquidMain.stake{value: 10 ether}();

        switchPrank(user11);
        liquidMain.stake{value: 8 ether}();

        switchPrank(user12);
        liquidMain.stake{value: 4 ether}();

        // console.log(address(user10).balance, "AfterStake");
        // console.log(address(user11).balance, "AfterStake");
        // console.log(address(user12).balance, "AfterStake");
        // console.log("");

        vm.roll(2 * 50000);

        uint256 xnastrBalUser10 = xnastr.balanceOf(user10);
        uint256 xnastrBalUser11 = xnastr.balanceOf(user11);
        uint256 xnastrBalUser12 = xnastr.balanceOf(user12);

        switchPrank(user10);
        liquidMain.unstake(xnastrBalUser10, false);

        switchPrank(user11);
        liquidMain.unstake(xnastrBalUser11, false);

        switchPrank(user12);
        liquidMain.unstake(xnastrBalUser12, false);

        // console.log(address(user10).balance, "AfterUnstake");
        // console.log(address(user11).balance, "AfterUnstake");
        // console.log(address(user12).balance, "AfterUnstake");
        // console.log("");

        switchPrank(user13);
        liquidMain.stake{value: 1 ether}();

        vm.roll(2 * 100000);

        switchPrank(deployer);
        liquidMain.sync(liquidMain.currentEra());

        vm.roll(2 * 200000);

        switchPrank(user10);
        liquidMain.withdraw(0);

        switchPrank(user11);
        liquidMain.withdraw(0);

        switchPrank(user12);
        liquidMain.withdraw(0);

        // console.log(address(user10).balance, "AfterWIthdraw");
        // console.log(address(user11).balance, "AfterWIthdraw");
        // console.log(address(user12).balance, "AfterWIthdraw");
        // console.log(address(liquidMain).balance, "LiquidMainAfterWIthdraw");
    }

    /// @dev Check gas consumption
    function test_eco_stake() public prank(user) {
        liquidMain.stake{value: 1000 ether}();
    }

    function test_stake() public prank(user) {
        uint256 amount = 1000 ether; // Example stake amount
        uint256 balanceBefore = user.balance;
        // Call the stake function on the liquidMain
        liquidMain.stake{value: amount}();

        uint256 xnastrValue = liquidMain.getXNASTRValue(balanceBefore - user.balance); // correction for surplus
        // Check that the staker's balance in the xnastr has increased
        assertEq(xnastr.balanceOf(user), xnastrValue, "Stake amount not recorded correctly");
    }

    function test_unstake_not_immediate() public prank(user) {
        uint256 amount = 1000 ether;

        // Call the stake function on the liquidMain
        liquidMain.stake{value: amount}();

        vm.roll(2 * 60000);
        uint256 xnastrAmount = xnastr.balanceOf(user);
        // Call the unstake function from the liquidMain
        liquidMain.unstake(xnastrAmount, false);    
    }

    function test_unstake_immediate() public {
        uint256 amount = 1000 ether;

        vm.prank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 120000 * 1000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        uint256 collectedRewards = liquidMain.rewardPool();
        uint256 xnastrValue = liquidMain.getXNASTRValue(collectedRewards);
        uint256 astrValue = liquidMain.getASTRValue(xnastrValue);

        uint256 balanceBefore = user.balance;

        // do immediate unstake
        vm.prank(user);
        liquidMain.unstake(xnastrValue, true);

        assertEq(liquidMain.rewardPool(), collectedRewards - astrValue);
        assertGt(user.balance, balanceBefore, "Wrong received ASTR amount");
    }

    function test_withdraw_audit() public {
        uint256 amount = 1000 ether;

        // Call the stake function on the liquidMain
        vm.startPrank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 60000);
        uint256 xnastrAmount = xnastr.balanceOf(user);
        // Call the unstake function from the liquidMain
        liquidMain.unstake(xnastrAmount, false);

        vm.roll(2 * 120000);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 200000);
        liquidMain.withdraw(0);   
        vm.stopPrank();   
    }

    function test_withdraw() public {
        uint256 amount = 1000 ether;

        // Call the stake function on the liquidMain
        vm.startPrank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 60000);
        uint256 xnastrAmount = xnastr.balanceOf(user);
        // Call the unstake function from the liquidMain
        liquidMain.unstake(xnastrAmount, false);

        vm.roll(2 * 120000);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 200000);
        liquidMain.withdraw(0);   
        vm.stopPrank();   
    }

    function test_bonusRewards() public {
        uint256 amountToStake = 1000 ether;
        string[] memory dappsList = liquidAdmin.getDappsList();

        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        vm.roll(2 * 10000);
        uint256 currentPeriod = liquidMain.currentPeriod();
        switchPrank(deployer);
        liquidMain.sync(liquidMain.currentEra());

        assertEq(currentPeriod, 1);
        for (uint256 i; i < dappsList.length; i++) {
            assertEq(liquidMain.bonusRewardsPerPeriod(currentPeriod, i), 0);
        }

        vm.roll(2 * 7200 * 3);
        currentPeriod = liquidMain.currentPeriod();
        assertEq(liquidMain.currentPeriod(), 2);

        liquidMain.sync(liquidMain.currentEra());

        for (uint256 i; i < dappsList.length; i++) {
            assertGt(liquidMain.bonusRewardsPerPeriod(currentPeriod - 1, i), 0);
        }
    }

    function test_cashback_lock() public {
        uint256 amountToStake = 1000 ether;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        uint256 receivedXnastr = xnastr.balanceOf(user);

        uint256 xnastrAmount = 10 ether;
        uint256 tokenId = 0;

        nftContract.mint(user, tokenId);
        assertEq(nftContract.balanceOf(user), 1, "User has not any nft");

        // Call the addCashbackLock function on the contract
        vm.startPrank(user);
        nftContract.approve(address(liquidMain), 0);
        xnastr.approve(address(liquidMain), xnastrAmount);
        liquidMain.addCashbackLock(address(nftContract), xnastrAmount, tokenId);
        vm.stopPrank();

        assertEq(xnastr.balanceOf(user), receivedXnastr - xnastrAmount);
        assertEq(nftContract.balanceOf(user), 0, "User NFT balance not updated");

        (uint256 lockAmount, uint256 lockTokenId, ) = liquidMain.cashbackLocks(user, address(nftContract));

        // Verify that the user's cashbackLocks mapping is updated correctly
        assertEq(lockAmount, xnastrAmount, "Amount not locked correctly");
        assertEq(lockTokenId, tokenId, "Token ID not set correctly");

        // Call the addCashbackLock function on the contract
        vm.startPrank(user);
        xnastr.approve(address(liquidMain), xnastrAmount);
        liquidMain.addCashbackLock(address(nftContract), xnastrAmount, tokenId);
        vm.stopPrank();

        (lockAmount, lockTokenId, ) = liquidMain.cashbackLocks(user, address(nftContract));
        assertEq(lockAmount, xnastrAmount * 2, "Amount not locked correctly");
    }

    function test_cashback_unlock() public {
        uint256 amountToStake = 1000 ether;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        uint256 receivedXnastr = xnastr.balanceOf(user);

        uint256 xnastrAmount = 10 ether;
        uint256 tokenId = 0;

        nftContract.mint(user, tokenId);
        assertEq(nftContract.balanceOf(user), 1, "User has not any nft");

        vm.startPrank(user);
        nftContract.approve(address(liquidMain), 0);
        xnastr.approve(address(liquidMain), xnastrAmount);
        liquidMain.addCashbackLock(address(nftContract), xnastrAmount, tokenId);

        vm.roll(2 * 60000);

        liquidMain.releaseCashbackLock(address(nftContract), xnastrAmount / 2);
        assertEq(nftContract.balanceOf(user), 0);
        assertEq(xnastr.balanceOf(user), receivedXnastr - xnastrAmount / 2);

        liquidMain.releaseCashbackLock(address(nftContract), xnastrAmount / 2);
        assertEq(nftContract.balanceOf(user), 1);
        assertEq(xnastr.balanceOf(user), receivedXnastr);
        vm.stopPrank();
    }

    function test_claim_cashback() public {
        uint256 amountToStake = 1000 ether;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        uint256 xnastrAmount = 10 ether;
        uint256 tokenId = 0;

        nftContract.mint(user, tokenId);
        assertEq(nftContract.balanceOf(user), 1, "User has not any nft");

        vm.startPrank(user);
        nftContract.approve(address(liquidMain), 0);
        xnastr.approve(address(liquidMain), xnastrAmount);
        liquidMain.addCashbackLock(address(nftContract), xnastrAmount, tokenId);
        vm.stopPrank();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        uint256 predictedCashback = liquidMain.getAccumulatedCashback(user, address(nftContract));

        address[] memory arr = new address[](1);
        arr[0] = address(nftContract);
        uint256 balanceBefore = user.balance;
        vm.prank(user);
        liquidMain.claimCashback(arr);

        // check if user not available to claim cashback more
        assertEq(liquidMain.getAccumulatedCashback(user, address(nftContract)), 0);
        // check if user claimed the right amount of astr
        assertEq(balanceBefore + predictedCashback, user.balance);
    }

    function test_withdrawRevenue() public {
        uint256 amountToStake = 1000 ether;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        uint256 revenue = liquidMain.revenuePool();
        assertGt(revenue, 0);
        
        vm.expectRevert();
        vm.prank(user);
        liquidAdmin.withdrawRevenue(revenue);

        uint256 balance = deployer.balance;

        vm.prank(deployer);
        liquidAdmin.withdrawRevenue(revenue);
        assertEq(deployer.balance, balance + revenue);
    }

    function test_sync() public {
        uint256 amountToStake = 1000 ether;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        uint256 xnastrAmount = 10 ether;
        uint256 tokenId = 0;

        nftContract.mint(user, tokenId);
        assertEq(nftContract.balanceOf(user), 1, "User has not any nft");

        vm.startPrank(user);
        nftContract.approve(address(liquidMain), 0);
        xnastr.approve(address(liquidMain), xnastrAmount);
        liquidMain.addCashbackLock(address(nftContract), xnastrAmount, tokenId);
        vm.stopPrank();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        assertGt(liquidMain.rewardPool(), 0);
        assertEq(liquidMain.lastUpdated(), era);
    }

    function test_get_xnastr_value() public {
        uint256 amount = 1000 ether;
        vm.prank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        // Mock values for totalAstrBalance and xnastrSupply
        uint256 totalAstrBalance = liquidMain.rewardPool() + liquidMain.totalStaked(); // Total ASTR balance
        uint256 xnastrSupply = xnastr.totalSupply(); // Total supply of XNASTR tokens

        // Call getXNASTRValue with a mock ASTR amount
        uint256 astrAmount = 5000e18;
        uint256 expectedXNASTRValue = (astrAmount * xnastrSupply) / totalAstrBalance;
        uint256 actualXNASTRValue = liquidMain.getXNASTRValue(astrAmount);

        // Assert that the calculated XNASTR value matches the expected value
        assertEq(actualXNASTRValue, expectedXNASTRValue, "Incorrect XNASTR value calculated");
    }

    function test_get_astr_value() public {
        uint256 amount = 1000 ether;
        vm.prank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        // Mock values for totalAstrBalance and xnastrSupply
        uint256 totalAstrBalance = liquidMain.rewardPool() + liquidMain.totalStaked(); // Total ASTR balance
        uint256 xnastrSupply = xnastr.totalSupply(); // Total supply of XNASTR tokens

        // Call getXNASTRValue with a mock ASTR amount
        uint256 xnastrAmount = 5000e18;
        uint256 expectedASTRValue = (xnastrAmount * totalAstrBalance) / xnastrSupply;
        uint256 actualASTRValue = liquidMain.getASTRValue(xnastrAmount);

        // Assert that the calculated XNASTR value matches the expected value
        assertEq(actualASTRValue, expectedASTRValue, "Incorrect ASTR value calculated");
    }

    function test_add_nft() public {
        MockAlgemNFT newNFT = new MockAlgemNFT("newNFT", "newNFT");

        // Call addNft function on liquidAdmin
        vm.prank(deployer);
        liquidAdmin.addNft(address(newNFT));

        ( , , , bool isActive) = liquidMain.nfts(address(newNFT));
        // Perform assertions to check if NFT was added successfully
        assertTrue(isActive, "NFT should be active");
    }

    function test_switch_nft_availability() public {
        MockAlgemNFT newNFT = new MockAlgemNFT("newNFT", "newNFT");

        // Add the NFT to the contract
        vm.prank(deployer);
        liquidAdmin.addNft(address(newNFT));

        // Call switchNftAvailability function to toggle availability
        vm.prank(deployer);
        liquidAdmin.switchNftAvailability(address(newNFT));

        ( , , , bool isActive) = liquidMain.nfts(address(newNFT));
        // Perform assertions to check if NFT availability was toggled
        assertFalse(isActive, "NFT should be inactive after toggling");

        vm.prank(deployer);
        liquidAdmin.switchNftAvailability(address(newNFT));

        ( , , , isActive) = liquidMain.nfts(address(newNFT));
        assertTrue(isActive, "NFT should be active after toggling");
    }

    function test_toggle_dapp_availability() public {
        assertTrue(liquidMain.isActive("Algem"), "Dapp should be active");

        uint256 len = liquidAdmin.getDappsList().length;
        uint256[] memory wts = new uint256[](len);
        (wts[0], wts[1], wts[2], wts[3], wts[4]) = (0, 2500, 2500, 2500, 2500);
        vm.prank(deployer);
        liquidVoting.toggleDappAvailability("Algem", wts);

        // Ensure the Dapp is inactive after toggling
        assertFalse(liquidMain.isActive("Algem"), "Dapp should be inactive after toggle");
    }

    function test_toggle_weights() public {
        // Call toggleWeights function as the manager role
        vm.prank(deployer);
        liquidAdmin.toggleWeights();
        
        // Ensure usingVoteWeights is now false
        assertTrue(liquidMain.usingVoteWeights(), "Using vote weights should be false after toggling again");

        vm.prank(deployer);
        liquidAdmin.toggleWeights();

        // Ensure usingVoteWeights is now true
        assertFalse(liquidMain.usingVoteWeights(), "Using vote weights should be true after toggling");        
    }

    function test_set_min_stake_amount() public {
        // Set the new minimum stake amount
        uint256 newAmount = 1000 ether;
        vm.prank(deployer);
        liquidAdmin.setMinStakeAmount(newAmount);

        assertEq(liquidMain.minStakeAmount(), newAmount, "Minimum stake amount should be set to 1000 ether");
    }

    function test_withdraw_revenue() public {
        uint256 amount = 1000 ether;
        vm.prank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 120000);
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        uint256 revenue = liquidMain.revenuePool();
        vm.prank(deployer);     
        liquidAdmin.withdrawRevenue(revenue);

        // Ensure that the total revenue pool is updated correctly
        assertEq(liquidMain.revenuePool(), 0, "Total revenue should be eq to zero");
    }

    function test_change_dapp_address() public {
        address newAddr = vm.addr(101);
        // Call the changeDappAddress function
        vm.prank(deployer);
        liquidAdmin.changeDappAddress("LiquidStaking", newAddr);

        ( , address addr, , ) = liquidMain.dapps("LiquidStaking");
        // Verify that the Dapp address has been updated correctly
        assertEq(addr, newAddr, "Dapp address should be updated");
    }

    function test_partially_pause() public {
        bytes4 selector = 0x3a4b66f1; // stake() func for partially pause

        vm.prank(deployer);
        liquidWrappedProxy.setPauseOnFunc(selector, true);
        assertTrue(liquidMain.isPaused(selector));

        vm.prank(user);
        vm.expectRevert(ILiquidStakingErrors.FunctionIsUnderPause.selector);
        liquidMain.stake{value: 100 ether}();
    }

    function test_partially_unpause() public {
        bytes4 selector = 0x3a4b66f1; // stake() func for partially pause

        vm.prank(deployer);
        liquidWrappedProxy.setPauseOnFunc(selector, true);
        assertTrue(liquidMain.isPaused(selector));

        vm.prank(user);
        vm.expectRevert(ILiquidStakingErrors.FunctionIsUnderPause.selector);
        liquidMain.stake{value: 100 ether}();

        vm.prank(deployer);
        liquidWrappedProxy.setPauseOnFunc(selector, false);
        assertFalse(liquidMain.isPaused(selector));
    }

    function test_get_user_withdrawals() public {
        uint256 amount = 1000 ether;

        // Call the stake function on the liquidMain
        vm.startPrank(user);
        liquidMain.stake{value: amount}();

        vm.roll(2 * 60000);
        uint256 xnastrAmount = xnastr.balanceOf(user);
        // Call the unstake function from the liquidMain
        liquidMain.unstake(xnastrAmount, false);

        vm.roll(2 * 120000);
        liquidMain.stake{value: amount}();

        LiquidStakingMain.Withdrawal[] memory arr = liquidAdmin.getUserWithdrawalsArray(user);
        uint256 value = arr[0].val;
        uint256 blockReq = arr[0].blockReq;

        assertEq(arr.length, 1, "Wrong withdrawals amount");
        assertEq(value, xnastrAmount, "Wrong withdrawal amount");
        assertEq(blockReq, 120000, "Wrong block number");
    }

    function test_get_dapps_list() public {
        // Retrieve the list of DApp names
        string[] memory dappsList = liquidAdmin.getDappsList();

        // Check that the correct number of DApps is returned
        assertEq(dappsList.length, DAPPS_AMOUNT, "Incorrect number of DApps in the list");

        // // Check the names of the returned DApps
        assertEq(dappsList[0], "Algem", "Incorrect name for the first DApp");
        assertEq(dappsList[1], "Dapp2", "Incorrect name for the second DApp");
        assertEq(dappsList[2], "Dapp3", "Incorrect name for the third DApp");
        assertEq(dappsList[3], "Dapp4", "Incorrect name for the third DApp");
        assertEq(dappsList[4], "Dapp5", "Incorrect name for the third DApp");
    }

    function test_add_dapp() public {
        string memory newDapp = "NewDapp";
        address dappAddress = vm.addr(102);

        uint256[] memory w = new uint256[](6);
        (w[0], w[1], w[2], w[3], w[4], w[5]) = (2000, 1500, 1500, 2000, 2000, 1000);

        uint256 lenBefore = liquidAdmin.getDappsList().length;

        vm.prank(deployer);
        liquidVoting.addDapp(
            newDapp, 
            dappAddress, 
            w
        );

        // Validate that the DApp was added
        assertEq(lenBefore + 1, liquidAdmin.getDappsList().length, "Wrong dappsList array length");
        assertEq(
            newDapp,
            liquidMain.dappsList(5),
            "Added DApp name does not match the expected DApp name"
        );        
    }

    function test_set_weights() public {
        uint256[] memory w = new uint256[](5);
        (w[0], w[1], w[2], w[3], w[4]) = (1000, 2000, 3000, 3500, 500);

        vm.prank(deployer);
        liquidVoting.setDefaultWeights(w);

        // Validate that the weights have been updated correctly
        assertEq(
            liquidMain.defaultWeights("Algem"),
            1000,
            "Weight for Dapp1 was not updated correctly"
        );
        assertEq(
            liquidMain.defaultWeights("Dapp5"),
            500,
            "Weight for Dapp5 was not updated correctly"
        );
    }

    function test_restakeFromRewardPool() public {
        uint256 amountToStake = 1000 ether;
        uint256 balanceBeforeStake = user.balance;
        // make stake to get xnastr
        vm.prank(user);
        liquidMain.stake{value: amountToStake}();

        uint256 staked = balanceBeforeStake - user.balance;
        assertEq(staked, liquidMain.totalStaked(), "Wrong staked amount");

        vm.roll(2 * 120000 * 1000); // block should be increased significantly to collect enough ASTR for restaking
        uint256 era = liquidMain.currentEra();
        vm.prank(deployer);
        liquidMain.sync(era);

        uint256 rewards = liquidMain.rewardPool();

        vm.prank(deployer);
        liquidAdmin.restakeFromRewardPool(rewards);
        assertEq(liquidMain.totalStaked(), staked + rewards  - liquidMain.rewardPool(), "Wrong staked amount");
    }

    function deploy() public {
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

        // initialize LS
        liquidWrappedProxy.initialize(
            xnastr,
            linkAddr,
            ccipRouterAddr,
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
        ls = LiquidStaking(payable(address(liquidProxy)));

        liquidAdmin.addNft(address(nftContract));
        liquidAdmin.setMinStakeAmount(1e18);
        liquidAdmin.setMinUnstakeAmount(1e16);

        xnastr.grantMintAndBurnRoles(address(liquidMain));
    }

    function addUtilities() public {
        for (uint256 i = 2; i <= DAPPS_AMOUNT; i++) {
            uint256[] memory weights = new uint256[](i);
            uint256 oneWeight = 10000 / i;
            for (uint256 j; j < i; j++) {
                weights[j] = oneWeight;
            }
            weights[0] += 10000 - oneWeight * i;
            string memory dappName = string(abi.encodePacked("Dapp", i.toString()));
            liquidVoting.addDapp(
                dappName,
                makeAddr(dappName), 
                weights
            );
        }
    }

    function test_getDefaultWeights() public view {
        string[] memory dapps = liquidAdmin.getDappsList();
        for (uint256 i; i < dapps.length; i++) {
            // uint256 w = liquidMain.defaultWeights(dapps[i]);
            // console.log(dapps[i], w);
        }
    }

    function test_getDappsWeights() public view {
        uint256[] memory weights = liquidMain.getDappsWeights();

        for (uint256 i; i < weights.length; i++) {
            // console.log(weights[i]);
        }
    }

    function switchPrank(address _user) internal {
        vm.stopPrank();
        vm.startPrank(_user);
    }
}