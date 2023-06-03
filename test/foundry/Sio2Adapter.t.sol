// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/Sio2Adapter.sol";
import "../src/Sio2AdapterAssetManager.sol";
import "../src/Liquidator.sol";
import "./mocs/MockSio2LendingPool.sol";
import "./mocs/MockERC20.sol";
import "./mocs/MockSCollateralToken.sol";
import "./mocs/MockPriceOracle.sol";
import "./mocs/MockVDToken.sol";
import "./mocs/MockProvider.sol";
import "./mocs/MockIncentivesController.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "../src/interfaces/ISio2LendingPoolAddressesProvider.sol";
import "../src/interfaces/ISio2LendingPool.sol";

contract Sio2AdapterTest is Test {
    Sio2Adapter adapter;
    Sio2AdapterAssetManager assetManager;

    MockSio2LendingPool pool;
    MockERC20 nastr;
    MockERC20 rewardToken;
    MockERC20 busd;
    MockERC20 dot;
    MockVDToken vddot;
    MockERC20 dai;
    MockVDToken vddai;
    MockERC20 usdc;
    MockVDToken vdusdc;
    MockERC20 usdt;
    MockVDToken vdusdt;
    MockSCollateralToken snastr;
    MockVDToken vdbusd;
    MockPriceOracle priceOracle;
    MockIncentivesController incentivesController;
    Liquidator liquidatorContract;

    address provider;
    address user;
    address liquidator;

    uint256 dot_precision = 1e8;

    function setUp() public {
        nastr = new MockERC20("nASTR", "nASTR");
        snastr = new MockSCollateralToken("snASTR", "snASTR");
        busd = new MockERC20("BUSD", "BUSD");
        vdbusd = new MockVDToken("vdBUSD", "vdBUSD");
        rewardToken = new MockERC20("SIO2", "SIO2");
        dot = new MockERC20("DOT", "DOT");
        dot.setDecimals(10);
        vddot = new MockVDToken("vdDOT", "vdDOT");
        vddot.setDecimals(10);
        dai = new MockERC20("DAI", "DAI");
        vddai = new MockVDToken("vdDAI", "vdDAI");
        usdc = new MockERC20("USDC", "USDC");
        vdusdc = new MockVDToken("vdUSDC", "vdUSDC");
        usdc.setDecimals(6);
        vdusdc.setDecimals(6);
        usdt = new MockERC20("USDT", "USDT");
        vdusdt = new MockVDToken("vdUSDT", "vdUSDT");
        usdt.setDecimals(6);
        vdusdt.setDecimals(6);

        incentivesController = new MockIncentivesController(
            snastr,
            vdbusd,
            rewardToken
        );

        pool = new MockSio2LendingPool(
            snastr,
            nastr,
            busd,
            dot,
            vdbusd,
            vddot,
            dai,
            vddai,
            usdc,
            vdusdc,
            usdt,
            vdusdt
        );

        provider = address(new MockProvider(address(pool)));

        assetManager = new Sio2AdapterAssetManager();
        assetManager.initialize(
            ISio2LendingPool(address(pool)),
            address(snastr)
        );

        assetManager.addAsset(address(busd), address(vdbusd), 8);

        assetManager.addAsset(address(dot), address(vddot), 12);

        priceOracle = new MockPriceOracle(
            address(nastr),
            address(busd),
            address(dot),
            address(dai),
            address(usdc),
            address(usdt)
        );

        adapter = new Sio2Adapter();
        adapter.initialize(
            ISio2LendingPool(address(pool)),
            IERC20Upgradeable(address(nastr)),
            IERC20Upgradeable(address(snastr)),
            ISio2IncentivesController(address(incentivesController)),
            IERC20Upgradeable(address(rewardToken)),
            assetManager,
            ISio2PriceOracle(address(priceOracle))
        );

        assetManager.setAdapter(adapter);

        user = vm.addr(1); // convert private key to address
        liquidator = vm.addr(2);

        liquidatorContract = new Liquidator(
            ISio2LendingPool(address(pool)),
            adapter,
            assetManager,
            ISio2LendingPoolAddressesProvider(provider),
            address(nastr)
        );
        liquidatorContract.grantRole(liquidatorContract.LIQUIDATOR(), user);

        vm.deal(user, 5 ether); // add ether to user
        nastr.mint(user, 1e72);
        busd.mint(liquidator, 1e36);
        dot.mint(liquidator, 1e36);

        vm.prank(user);
        nastr.approve(address(adapter), 1e36);
    }

    function testSupply() public {
        uint256 bal = nastr.balanceOf(user);
        uint256 amount = 1 ether;

        vm.startPrank(user);

        vm.expectRevert("Should be greater than zero");
        adapter.supply(0);

        vm.expectRevert("Not enough nASTR tokens on the user balance");
        adapter.supply(UINT256_MAX);

        adapter.supply(amount);

        assertEq(snastr.balanceOf(address(adapter)), amount);
        assertEq(nastr.balanceOf(user), bal - amount);

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user);

        adapter.supply(1 ether);
        (, , uint256 colBefore, , , ) = adapter.userInfo(user);
        assertEq(colBefore, 1 ether);

        adapter.withdraw(1 ether);
        (, , uint256 colAfter, , , ) = adapter.userInfo(user);
        assertEq(colAfter, 0);

        vm.stopPrank();
    }

    function testBorrow() public {
        vm.startPrank(user);
        adapter.supply(10000 ether); // supply 10000 nASTR
        adapter.borrow("BUSD", 1 ether); // borrow 1 BUSD
        adapter.borrow("DOT", 1 ether);
        vm.warp(1 days);
        adapter.borrow("BUSD", 1 ether);
        adapter.borrow("DOT", 1 ether);
        uint256 debt = adapter.calcEstimateUserDebtUSD(user);
        assertEq(busd.balanceOf(user), 2 ether);
        assertGt(dot.balanceOf(user), 0);
        assertGt(debt, 0);
        vm.stopPrank();
    }

    function testRepay() public {
        vm.startPrank(user);
        adapter.supply(1000 ether);
        adapter.borrow("BUSD", 10 ether);

        vm.expectRevert();
        adapter.repayPart("DOT", 5 ether);

        adapter.borrow("DOT", 1 ether);
        assertEq(busd.balanceOf(user), 10 ether);
        // assertEq(dot.balanceOf(user), 1 ether / dot_precision);
        busd.approve(address(adapter), 10 ether);
        dot.approve(address(adapter), 10 ether);

        //test repay part
        vm.expectRevert("Not enough wallet balance to repay");
        adapter.repayPart("BUSD", 15 ether);

        vm.expectRevert("Amount should be greater than zero");
        adapter.repayPart("BUSD", 0);

        adapter.repayPart("BUSD", 5 ether);
        assertEq(busd.balanceOf(user), 5 ether);
        uint256 debtPart = adapter.debts(user, "BUSD");
        assertEq(debtPart, 5 ether);

        //test repay full
        adapter.repayFull("BUSD");
        assertEq(busd.balanceOf(user), 0);
        uint256 debtFull = adapter.debts(user, "BUSD");
        assertEq(debtFull, 0);

        //test repay full dot
        adapter.repayFull("DOT");
        assertEq(dot.balanceOf(user), 0);

        vm.stopPrank();
    }

    function testGetHF() public {
        vm.startPrank(user);
        adapter.supply(1000 ether);
        adapter.borrow("BUSD", 10 ether);
        (uint256 hf, uint256 debtUSD) = adapter.getLiquidationParameters(user);
        uint256 estimateHF = adapter.estimateHF(user);
        assertEq(hf, estimateHF);
        assertGt(hf, 0);
        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user);

        adapter.supply(1000000 ether);
        adapter.borrow("BUSD", 10 ether);

        vm.expectRevert("User has no any rewards");
        adapter.claimRewards();

        vm.roll(10);

        adapter.claimRewards();

        assertGt(rewardToken.balanceOf(user), 0);
        assertGt(adapter.rewardPool(), 0);

        (, , , uint256 rewards, , ) = adapter.userInfo(user);
        assertEq(rewards, 0);

        vm.stopPrank();
    }

    function testAddAndRemoveAsset() public {
        uint256 assetsInitAmount = assetManager.getAssetsNames().length;

        assetManager.addAsset(address(dai), address(vddai), 8);

        assertEq(assetManager.getAssetsNames().length, assetsInitAmount + 1);

        assetManager.removeAsset("DAI");

        assertEq(assetManager.getAssetsNames().length, assetsInitAmount);

        vm.expectRevert("There is no such asset");
        assetManager.removeAsset("DAI");
    }

    function testWithdrawRevenue() public {
        vm.startPrank(user);
        adapter.supply(1000 ether);
        adapter.borrow("BUSD", 10 ether);
        vm.roll(10);
        adapter.claimRewards();
        vm.stopPrank();
        uint256 amount = adapter.revenuePool();
        adapter.withdrawRevenue(amount);
        vm.expectRevert("Should be greater than zero");
        adapter.withdrawRevenue(0);
        vm.expectRevert("Not enough SIO2 revenue tokens");
        adapter.withdrawRevenue(amount);
        assertEq(rewardToken.balanceOf(address(this)), amount);
    }

    function testAddSTokens() public {
        uint256 amount = 10 ether;
        vm.startPrank(user);
        vm.expectRevert("Not enough sTokens on user balance");
        adapter.addSTokens(amount);
        nastr.approve(address(pool), amount);
        pool.deposit(address(nastr), amount, user, 0);
        assertGt(snastr.balanceOf(user), 0);
        assertEq(snastr.balanceOf(address(adapter)), 0);
        snastr.approve(address(adapter), amount);
        adapter.addSTokens(amount / 2);
        adapter.addSTokens(amount / 2);
        assertEq(snastr.balanceOf(user), 0);
        assertGt(snastr.balanceOf(address(adapter)), 0);
        vm.stopPrank();
    }

    function testLiquidationCall() public {
        vm.startPrank(user);
        adapter.supply(100 ether);

        vm.expectRevert("User has no debts");
        adapter.getLiquidationParameters(user);

        vm.expectRevert("User has no debts");
        adapter.estimateHF(user);

        (uint256 availableToBorrow, ) = adapter.availableCollateralUSD(user);

        adapter.borrow("BUSD", availableToBorrow);

        vm.stopPrank();

        vm.startPrank(liquidator);
        priceOracle.setAssetPrice(address(busd), 110992110);

        uint256 debtToCover = adapter.debts(user, "BUSD");
        busd.approve(address(adapter), 1e36);

        vm.expectRevert(
            "Debt to cover need to be lower than 50% of users debt"
        );
        adapter.liquidationCall("BUSD", user, debtToCover - 1e17);

        vm.expectRevert("_debtToCover exceeds the user's debt amount");
        adapter.liquidationCall("BUSD", user, debtToCover + 1e17);

        uint256 debt = adapter.debts(user, "BUSD");

        uint256 col = adapter.getUser(user).collateralAmount;

        adapter.liquidationCall("BUSD", user, debtToCover / 2);
        vm.stopPrank();
    }

    function testAvailableCollateralUSD() public {
        vm.prank(user);
        adapter.supply(1 ether);

        (, uint256 availableColToWithdraw) = adapter.availableCollateralUSD(
            user
        );

        (, , uint256 col, , , ) = adapter.userInfo(user);
    }
}
