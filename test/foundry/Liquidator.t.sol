// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../contracts/Sio2Adapter.sol";
import "../../contracts/Sio2AdapterAssetManager.sol";
import "../../contracts/Liquidator.sol";
import "../../contracts/interfaces/ISio2LendingPoolAddressesProvider.sol";
import "../../contracts/interfaces/ISio2LendingPool.sol";
import "../../contracts/interfaces/ISio2PriceOracle.sol";
import "../../contracts/interfaces/IPancakeRouter01.sol";
import "../../contracts/interfaces/IPancakePair.sol";

contract LiquidatorTest is Test {
    Sio2Adapter adapter;
    Sio2AdapterAssetManager assetManager;
    Liquidator liquidator;
    ISio2LendingPool pool = ISio2LendingPool(0x4df48B292C026f0340B60C582f58aa41E09fF0de);

    address provider;
    address user;

    // Astar addresses
    address dot = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF; // 10
    address wastr = 0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720; // 18
    address bai = 0x733ebcC6DF85f8266349DEFD0980f8Ced9B45f35; // 18
    address usdc = 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98; // 6
    address usdt = 0x3795C36e7D12A8c252A20C5a7B455f7c57b60283; // 6
    address busd = 0x4Bf769b05E832FCdc9053fFFBC78Ca889aCb5E1E; // 18
    address dai = 0x6De33698e9e9b787e09d3Bd7771ef63557E148bb; // 18
    address weth = 0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c; // 18
    address wbtc = 0xad543f18cFf85c77E140E3E5E3c3392f6Ba9d5CA; // 8
    address bnb = 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52; // 18

    ERC20 dotT = ERC20(dot);
    ERC20 wastrT = ERC20(wastr);
    ERC20 baiT = ERC20(bai);
    ERC20 usdcT = ERC20(usdc);
    ERC20 usdtT = ERC20(usdt);
    ERC20 busdT = ERC20(busd);
    ERC20 daiT = ERC20(dai);
    ERC20 wethT = ERC20(weth);
    ERC20 wbtcT = ERC20(wbtc);
    ERC20 bnbT = ERC20(bnb);

    address vddot = 0x63C401475D645AA56477C6D43D4C75459497A7bE;
    address vdwastr = 0x36100c348c201A7D8242E4CC7BC3Df1e8560f0C1;
    address vdbai = 0xcED7df1329AD6e0fA7E9547131a531323B6e6fF5;
    address vdusdc = 0xa940ff06c2D0a3668CAae8fEfdff3f466d3B1878;
    address vdusdt = 0x47c06b78B97321A7cD95608a0e8677d08868DD9A;
    address vdbusd = 0xC4Cf823f6A94699d9C6D22Aec73522D4c00867C8;
    address vddai = 0x05F3Ca23EB9A2B9142Fb10CDaB1750B4D2162aC2;
    address vdweth = 0x7757B40400377eb19b1Cd6976e964FE51ac2e092;
    address vdwbtc = 0x0efb38754A70c543c0902f7207dd0bABf83Ed822;
    address vdbnb = 0x65D26B766e16874DfFf44D170a8b73A3D4cf887e;

    // sets collateral token
    address col = dai;
    ERC20 scol;
    ERC20 colT = daiT;

    function setUp() public {
        scol = new ERC20("Collateral token sDAI", "sDAI");

        assetManager = new Sio2AdapterAssetManager();
        assetManager.initialize(pool, address(scol));

        adapter = new Sio2Adapter();
        adapter.initialize(
            pool,
            IERC20Upgradeable(col),
            IERC20Upgradeable(address(scol)),
            ISio2IncentivesController(0xc41e6Da7F6E803514583f3b22b4Ff660CCD39B03),
            IERC20Upgradeable(0xcCA488aEEf7A1D5C633f877453784F025e7cF160),
            assetManager,
            ISio2PriceOracle(0x5f7c3639A854a27DFf64B320De5C9CAF9C4Bd323)
        );

        assetManager.setAdapter(adapter);

        liquidator = new Liquidator(
            ISio2LendingPool(0x4df48B292C026f0340B60C582f58aa41E09fF0de),
            Sio2Adapter(address(adapter)),
            Sio2AdapterAssetManager(address(assetManager)),
            ISio2LendingPoolAddressesProvider(0x2660e0668dd5A18Ed092D5351FfF7B0A403f9721),
            col
        );

        assetManager.addAsset(busd, vdbusd, 8);
        assetManager.addAsset(bnb, vdbnb, 12);

        user = 0x7ECD92b9835E0096880bF6bA778d9eA40d1338B5;
        vm.deal(user, 5e36);
        deal(col, user, 1e36 ether);
    }

    function liquidationsPreset() public {
        assetManager.addAsset(address(weth), address(vdweth), 8);

        vm.startPrank(user);
        colT.approve(address(adapter), UINT256_MAX);
        adapter.supply(70 ether);

        adapter.borrow("BUSD", 0.2 ether);
        adapter.borrow("BNB", 0.1 ether);
        adapter.borrow("WETH", 0.01 ether);
        vm.stopPrank();
    }    

    function testMergeArrays() public {
        liquidationsPreset();

        (string[] memory names, uint256[] memory debts) = assetManager
            .getAvailableTokensToRepay(user);

        (
            Liquidator.DebtAsset[] memory debtAssets,
            uint256 totalSumUSD
        ) = liquidator.mergeArraysAndCalcSumUSD(names, debts);

        assertEq(names.length, debtAssets.length, "Wrong length of debtsAssets array");
        assertGt(totalSumUSD, 0);
    }

    function testToDescendingOrder() public {
        assetManager.addAsset(address(weth), address(vdweth), 8);
        assetManager.addAsset(address(usdc), address(vdusdc), 8);
        assetManager.addAsset(address(usdt), address(vdusdt), 8);

        vm.startPrank(user);
        colT.approve(address(adapter), UINT256_MAX);
        adapter.supply(1e18 ether);
        adapter.borrow("BUSD", 2 ether);
        adapter.borrow("BNB", 5 ether);
        adapter.borrow("WETH", 0.5 ether);
        adapter.borrow("USDC", 1 ether);
        adapter.borrow("USDT", 10 ether);

        (string[] memory names, uint256[] memory debts) = assetManager
            .getAvailableTokensToRepay(user);

        (Liquidator.DebtAsset[] memory debtAssets, ) = liquidator.mergeArraysAndCalcSumUSD(names, debts);
        Liquidator.DebtAsset[] memory sorted = liquidator.toDescendingOrder(debtAssets);

        assertEq(sorted[0].debt, 5 ether);
        assertEq(sorted[1].debt, 0.5 ether);
        assertEq(sorted[2].debt, 10 ether);
        assertEq(sorted[3].debt, 2 ether);
        assertEq(sorted[4].debt, 1 ether);

        vm.stopPrank();
    }

    // function testSwapCollateralToASTR() public {
    //     deal(dai, address(liquidator), 1e18);
    //     console.log("liquidator collateral bal:", daiT.balanceOf(address(liquidator)));
    //     liquidator.swapCollateralToASTR();

    //     assertEq(colT.balanceOf(address(liquidator)), 0);
    //     assertGt(address(this).balance, 0);
    // }

    function testFlashloan() public {
        deal(weth, address(liquidator), 1e18);
        deal(busd, address(liquidator), 1e18);
        deal(dai, address(liquidator), 1e18);

        vm.startPrank(user);
        
        address[] memory assets = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        (assets[0], assets[1], assets[2]) = (weth, busd, dai);
        (amounts[0], amounts[1], amounts[2]) = (1 ether, 2 ether, 3 ether);

        liquidator.flashloan(assets, amounts);

        assertEq(wethT.balanceOf(address(liquidator)), 1e18 - amounts[0] * 9 / 10000);
        assertEq(busdT.balanceOf(address(liquidator)), 1e18 - amounts[1] * 9 / 10000);
        assertEq(daiT.balanceOf(address(liquidator)), 1e18 - amounts[2] * 9 / 10000);
        
        vm.stopPrank();
    }

    function testFillAssetsToLiquidate() public {
        Liquidator.DebtAsset[] memory debtAssets = new Liquidator.DebtAsset[](3);
        debtAssets[0] = Liquidator.DebtAsset("BUSD", 5 + 2629 ether );
        debtAssets[1] = Liquidator.DebtAsset("BNB", 1 ether);
        debtAssets[2] = Liquidator.DebtAsset("WETH", 0.5 ether);

        (address[] memory assets, uint256[] memory amounts) =
        liquidator.fillAssetsToLiquidate(
            debtAssets,
            ((1250 + 2634) / 2) * 1e18
        );
    }

    function addLiquidityToMaticWeth() public {
        // matic weth pair 0x66fD9a8eacC51dCA17c823a35b6f743Bb05ff221
        deal(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF, address(this), 1000000 ether); // mint matic
        deal(0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c, address(this), 10000 ether); // mint weth
        vm.deal(address(this), 10 ether);

        IPancakeRouter01 router = IPancakeRouter01(0xE915D2393a08a00c5A463053edD31bAe2199b9e7);
        IPancakePair pair = IPancakePair(0x66fD9a8eacC51dCA17c823a35b6f743Bb05ff221);

        ERC20(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF).approve(address(router), UINT256_MAX);
        ERC20(0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c).approve(address(router), UINT256_MAX);

        router.addLiquidity(
            0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c,
            0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF,
            10000 ether,
            1000000 ether,
            1,
            1,
            address(this),
            1e18
        );

        (uint256 res1, uint256 res2,) = pair.getReserves();

        console.log("res1 =>", res1);
        console.log("res2 =>", res2);
    }

    function addLiquidityToMaticSdn() public {
        // matic sdn pair 0x1cFD05d568e25b4402604FC8Db249934e1236DEd
        deal(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF, address(this), 1000000 ether); // mint matic
        deal(0x75364D4F779d0Bd0facD9a218c67f87dD9Aff3b4, address(this), 1000000 ether); // mint sdn
        vm.deal(address(this), 10 ether);

        IPancakeRouter01 router = IPancakeRouter01(0xE915D2393a08a00c5A463053edD31bAe2199b9e7);
        IPancakePair pair = IPancakePair(0x1cFD05d568e25b4402604FC8Db249934e1236DEd);

        ERC20(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF).approve(address(router), UINT256_MAX);
        ERC20(0x75364D4F779d0Bd0facD9a218c67f87dD9Aff3b4).approve(address(router), UINT256_MAX);

        router.addLiquidity(
            0x75364D4F779d0Bd0facD9a218c67f87dD9Aff3b4,
            0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF,
            1000000 ether,
            1000000 ether,
            1,
            1,
            address(this),
            1e18
        );

        (uint256 res1, uint256 res2,) = pair.getReserves();
    }

    function addLiquidityToMaticBnb() public {
        // matic bnb pair 0x7701Ed46d705e7D743c194f5Eeb926c5545D64b9
        deal(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF, address(this), 1000000 ether); // mint matic
        deal(0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52, address(this), 1000000 ether); // mint bnb
        vm.deal(address(this), 10 ether);

        IPancakeRouter01 router = IPancakeRouter01(0xE915D2393a08a00c5A463053edD31bAe2199b9e7);
        IPancakePair pair = IPancakePair(0x1cFD05d568e25b4402604FC8Db249934e1236DEd);

        ERC20(0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF).approve(address(router), UINT256_MAX);
        ERC20(0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52).approve(address(router), UINT256_MAX);

        router.addLiquidity(
            0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52,
            0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF,
            1000000 ether,
            1000000 ether,
            1,
            1,
            address(this),
            1e18
        );

        (uint256 res1, uint256 res2,) = pair.getReserves();
    }

    function testLiquidator() public {
        liquidationsPreset();
        addLiquidityToMaticWeth();
        addLiquidityToMaticSdn();
        addLiquidityToMaticBnb();
        
        // vm.deal(address(liquidator), 500_000 ether);

        uint256 hf = adapter.estimateHF(user);
        console.log("initial hf is:", hf);

        (uint256 availableToBorrowUSD, ) = adapter.availableCollateralUSD(user);
        console.log("available to borrow usd:", availableToBorrowUSD);

        uint256 wethAmountToBorrow = adapter.fromUSD(weth, availableToBorrowUSD);
        console.log("busdAmountToBorrow is:", wethAmountToBorrow);

        vm.prank(user);
        adapter.borrow("WETH", wethAmountToBorrow);

        console.log("hf after borrow busd:", adapter.estimateHF(user));

        adapter.setLT(adapter.collateralLT() * 80 / 100);

        console.log("hf after lt setting:", adapter.estimateHF(user));

        liquidator.liquidate(user);

        console.log("hf after liquidation:", adapter.estimateHF(user));

        console.log("liquidator balance is:", address(liquidator).balance);

        console.log("---");

        while (adapter.estimateHF(user) < 1 ether) {
            Sio2Adapter.User memory userStruct = adapter.getUser(user);
            if (userStruct.collateralAmount > 1 ether) {
                liquidator.liquidate(user);
            }
            console.log("hf after liquidation ===>", adapter.estimateHF(user));
        }
    }

    function testAssetParameters() public {
        (, uint256 liquidationPenalty, ) = adapter.getAssetParameters(busd);
        console.log("=>", liquidationPenalty);
    }
}