pragma solidity ^0.8.0;

import "test/dApps/Required.t.sol";
import "script/Workbench.s.sol";
import "src/dApps/Sonus/LFxSonusV3Vault0.sol";
import "src/dApps/Sonus/LFxSonusV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract LFxSonusV3PoolTest is Required, Workbench {
    LFxSonusV3Vault0 v3vault;
    LFxSonusV3Pool v3pool;
    bool isWtoken0;
    int24 mintick = -887_272;
    int24 maxtick = 887_272;

    address user1 = address(0x456);
    address user2 = address(0x789);
    address nonAdmin = address(0xBEEF);
    address user3 = nonAdmin;

    //handy
    function deposit(uint256 wrapped, address sender) public override {
        uint256 pa = v3vault.getSecondAmount(uint128(wrapped), false);
        (uint256 a0, uint256 a1) = v3vault.getInputAmounts(pa, wrapped);
        fund(sender, a1, a0);
        vm.startPrank(sender);
        pair.approve(address(v3vault), a0);
        v3vault.deposit{value: a1}(a0);
        vm.stopPrank();
    }

    function generateRewards(uint256 runs) public override {
        uint256 amnt = 0.25 ether;
        vm.deal(address(this), amnt);
        wrapped.deposit{value: amnt}();
        isWtoken0 = v3vault.isWtoken0();
        int256 a0 = isWtoken0 ? -int256(amnt) : int256(0);
        int256 a1 = isWtoken0 ? int256(0) : -int256(amnt);
        for (uint256 i; i < runs; i++) {
            {
                (bool success, bytes memory data) = address(cfg.pool).staticcall(abi.encodeWithSignature("slot0()"));
                (uint160 price) = abi.decode(data, (uint160));
                (a0, a1) = IUniswapV3Pool(v3vault.v3pool()).swap(
                    address(this),
                    isWtoken0,
                    isWtoken0 ? -a0 : -a1,
                    isWtoken0 ? price / 10 : price + price / 10,
                    abi.encode(address(this))
                );
            }
            {
                (bool success, bytes memory data) = address(cfg.pool).staticcall(abi.encodeWithSignature("slot0()"));
                (uint160 price) = abi.decode(data, (uint160));
                (a0, a1) = IUniswapV3Pool(v3vault.v3pool()).swap(
                    address(this),
                    !isWtoken0,
                    isWtoken0 ? -a1 : -a0,
                    isWtoken0 ? price + price / 10 : price / 10,
                    abi.encode(address(this))
                );
            }
        }
    }

    function warpRounds(uint256 rounds) public override {
        uint256 rd = v3vault.roundDuration();
        vm.warp(block.timestamp + rd * rounds);
        vm.roll(block.number + rounds * 100);
    }

    function fund(address to, uint256 w, uint256 p) public override {
        vm.deal(to, w);
        vm.startPrank(cfg.pairwhale);
        pair.transfer(to, p);
        vm.stopPrank();
    }

    function priceImpact(address user) public {
        LFxSonusV3Vault0.userVaultInfo memory info = v3vault.getVaultUserInfo(user);
        while (info.hf >= v3vault.LIQUIDATION_THRESHOLD()) {
            uint256 amnt = 30_000 ether;
            vm.startPrank(cfg.pairwhale);
            pair.transfer(address(this), amnt);
            vm.stopPrank();

            (bool success, bytes memory data) = address(v3vault.v3pool()).staticcall(abi.encodeWithSignature("slot0()"));
            (uint160 price) = abi.decode(data, (uint160));
            IUniswapV3Pool(v3vault.v3pool()).swap(
                address(this),
                !v3vault.isWtoken0(),
                int256(amnt),
                v3vault.isWtoken0() ? price + price / 10 : price / 10,
                abi.encode(address(this))
            );

            info = v3vault.getVaultUserInfo(user);
            console.log(info.hf);
        }
    }
    //^handy

    //dandy
    function pancakeV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        if (amount0 > 0) IERC20(isWtoken0 ? cfg.wrapped : cfg.pair).transfer(msg.sender, amount0);
        if (amount1 > 0) IERC20(isWtoken0 ? cfg.pair : cfg.wrapped).transfer(msg.sender, amount1);
    }

    /// @notice uniswapV3Pool callback
    function pancakeV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
        if (amount0 > 0) IERC20(isWtoken0 ? cfg.wrapped : cfg.pair).transfer(msg.sender, uint256(amount0));
        if (amount1 > 0) IERC20(isWtoken0 ? cfg.pair : cfg.wrapped).transfer(msg.sender, uint256(amount1));
    }
    //^dandy

    function setUp() public {
        _chooseConfig("script/cfg/Minato/dApps/Sonus/", 0);
        admin = new ProxyAdmin(address(this));
        wrapped = IWETH9(cfg.wrapped);
        lwrapped = new LWRAPPED("LWRAPPED test", "LWRAPPED");
        lfcfg.lwrapped = address(lwrapped);
        algm = new LWRAPPED("ALGM token", "ALGM");
        lfcfg.algm = address(algm);
        pair = LWRAPPED(cfg.pair);
        uint256 round = 1 days;
        uint256 start = block.timestamp + 2 * round;
        uint256 totalrounds = 100;

        LFMaster m = new LFMaster();
        TransparentUpgradeableProxy lfm = new TransparentUpgradeableProxy(address(m), address(admin), "");
        lfcfg.master = address(lfm);
        master = LFMaster(address(lfm));
        master.initialize(lfcfg.algm, "Testnet");
        master.setRound(block.timestamp + round, round);

        LFxSonusV3Pool p = new LFxSonusV3Pool();
        TransparentUpgradeableProxy lkp = new TransparentUpgradeableProxy(address(p), address(admin), "");
        lfcfg.pool = address(lkp);
        v3pool = LFxSonusV3Pool(address(lkp));
        v3pool.initialize(cfg.pair, lfcfg.master, lfcfg.algm);

        vm.warp(block.timestamp + round);
        master.addPool(lfcfg.pool, totalrounds, "Kyo", "ETH/KYO");
        algm.mint(address(this), 1_000_000 ether);
        algm.approve(lfcfg.master, 1_000_000 ether);
        master.addALGM(0, 1_000_000 ether);

        LFxSonusV3Vault0 v = new LFxSonusV3Vault0();
        TransparentUpgradeableProxy lvp = new TransparentUpgradeableProxy(address(v), address(admin), "");
        lfcfg.vault = address(lvp);
        isWtoken0 = false;
        v3vault = LFxSonusV3Vault0(payable(address(lvp)));
        v3vault.initialize(cfg.pool, false);

        lwrapped.transferOwnership(lfcfg.vault);
        v3pool.addVault(lfcfg.vault, 100);

        v3vault.initVault(lfcfg.lwrapped, lfcfg.algm, lfcfg.pool, start, round, totalrounds);
        (bool success, bytes memory data) = cfg.pool.staticcall(abi.encodeWithSignature("tickSpacing()"));
        int24 spacing = abi.decode(data, (int24));
        mintick = mintick - (mintick % spacing);
        maxtick = maxtick - (maxtick % spacing);
        (success, data) = cfg.pool.staticcall(abi.encodeWithSignature("fee()"));
        uint16 fee = abi.decode(data, (uint16));

        v3vault.initParams(mintick, maxtick, spacing, uint24(fee));
        v3vault.setSlippage(uint160(1));
        v3vault.setLiquidation(199);
    }

        function testDepositWithdrawRedeem() public {
        vm.warp(v3vault.START() + 1);

        deposit(8 ether, user1);

        warpRounds(1);
        generateRewards(1);
        v3vault.update();

        vm.prank(user1);
        v3vault.claim(true);

        vm.warp(v3vault.FINISH() - 1);
        generateRewards(65);
        v3vault.update();

        vm.warp(v3vault.FINISH() + 1);
        vm.startPrank(user1);
        v3vault.withdraw(lwrapped.balanceOf(user1));
        vm.warp(block.timestamp + 1);

        console.log("lwrapped.balanceOf(user1) after withdraw", lwrapped.balanceOf(user1));
        console.log("pair in vault", pair.balanceOf(address(v3vault))); 

        v3vault.redeem();

        console.log("pair in vault after redeem", pair.balanceOf(address(v3vault)));
        console.log("user1 pair balance", pair.balanceOf(address(user1)));
        console.log("revenuePool1", v3vault.revenuePool(1));
        console.log("revenuePool0", v3vault.revenuePool(0));
        console.log("rewardPool1", v3vault.rewardPool(1));

        vm.stopPrank();
    }

    function testInitParams() public {
        require(v3vault.owner() == address(this));
        require(address(v3vault.v3pool()) == cfg.pool);
        require(v3vault.WRAPPED() == cfg.wrapped);
        require(v3vault.pairToken() == cfg.pair);
    }

    function testWithdrawAndRedeem() public {
        vm.warp(v3vault.START() + 1);
        deposit(0.1 ether, user1);
        deposit(0.1 ether, user2);
        vm.warp(v3vault.FINISH() + 1);
        vm.startPrank(user1);
        lwrapped.approve(address(v3vault), lwrapped.balanceOf(user1));
        v3vault.withdraw(lwrapped.balanceOf(user1));
        v3vault.redeem();
        vm.stopPrank();
        vm.startPrank(user2);
        lwrapped.approve(address(v3vault), lwrapped.balanceOf(user2));
        v3vault.withdraw(lwrapped.balanceOf(user2));
        v3vault.redeem();
        vm.stopPrank();
    }

    function testMultipleRedeem() public {
        vm.warp(v3vault.START() + 1);
        deposit(1 ether, user1);
        deposit(1 ether, user2);
        deposit(1 ether, user3);

        vm.warp(v3vault.FINISH() + 1);
        generateRewards(1);
        v3vault.update();

        v3vault.previewRewards(user1);
        vm.prank(user1);
        v3vault.redeem();
        v3vault.previewRewards(user2);
        vm.prank(user2);
        v3vault.redeem();
        v3vault.previewRewards(user3);
        vm.prank(user3);
        v3vault.redeem();
    }

    function testFailDepositUnclaimed() public {
        vm.warp(v3vault.START() + 1);
        deposit(10_000 gwei, user1);
        warpRounds(1);
        deposit(10_000 gwei, user1);
    }

    function testDepositClaimDeposit() public {
        vm.warp(v3vault.START() + 1);
        deposit(10_000 gwei, user1);
        // 5 Days
        vm.warp(block.timestamp + (86_400 * 5));
        // Account 2 deposit, claim, deposit
        deposit(10_000 gwei, user2);
        // 2 Days
        vm.warp(block.timestamp + (86_400 * 2));
        vm.prank(user2);
        v3vault.claim(false);
        deposit(10_000 gwei, user2);
    }

    function testProperALGMDistribution() public {
        uint256 totalPaid;
        vm.warp(v3vault.START() + 1);
        require(v3vault.algmRewardPool() == 0);
        warpRounds(10);

        for (uint256 i = v3vault.getCurrentRound(); i < v3vault.totalRounds(); i++) {
            warpRounds(1);
            v3vault.update();
        }
        for (uint256 i = 1; i <= v3vault.totalRounds(); i++) {
            //console.log("Round", i);
            //console.log("Rewards", v3vault.algmRewards(i));
            totalPaid += v3vault.algmRewards(i);
        }
        require(totalPaid == 1_000_000 ether);
    }

    //////////////////////////////////////DEPOSIT
    function testDepositDefault(uint256 input) public {
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        vm.warp(v3vault.START() + 1);

        deposit(input, user1);
        require(lwrapped.balanceOf(user1) > 0);
    }

    function testFailDepositRandom(uint256 w, uint256 a) public {
        vm.assume(w > 0 && w < wrapped.balanceOf(cfg.pool) / 10);
        vm.assume(a > 0 && a < pair.balanceOf(cfg.pool) / 10);
        fund(user1, w, a);
        vm.startPrank(user1);
        pair.approve(address(v3vault), a);
        v3vault.deposit{value: w}(a);
        vm.stopPrank();
    }

    function testDepositEachRound(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);

        deposit(input, user1);
        for (uint256 i = 1; i < v3vault.totalRounds() - 1; i++) {
            generateRewards(5);
            warpRounds(1);
            vm.prank(user1);
            v3vault.claim(true);
            deposit(input, user1);
        }
    }

    //basically uniswappool reverts most of the value combinations except provided by v3vault.getInputAmounts()
    function testFailDepositM01() public {
        vm.warp(v3vault.START() + 1);
        fund(address(this), 10 ether, 10 ether);
        pair.approve(address(v3vault), 10 wei);
        v3vault.deposit{value: 0.28 ether}(10 wei);
        (uint256 wrppd1,, uint256 start,,,) = v3vault.positions(address(this));

        console.log("Position User1", wrppd1);
        console.log("Position Start", start);
        generateRewards(1);
        warpRounds(1);
        v3vault.update();
        v3vault.claim(true);
        pair.approve(address(v3vault), 1 ether);
        v3vault.deposit{value: 0.28 ether}(1 ether);
        (uint256 wrppd11,, uint256 start11,,,) = v3vault.positions(address(this));
        console.log("Position User1", wrppd11);
        console.log("Position Start", start11);

        generateRewards(1);
        warpRounds(1);
        v3vault.update();
        v3vault.redeem();
    }

    function testFailDepositBeforeStart(uint256 input) public {
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
    }

    function testFailDepositOnExpire(uint256 input) public {
        vm.warp(v3vault.FINISH() - v3vault.roundDuration() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
    }

    function testFailDepositLiquidated(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        priceImpact(user1);
        v3vault.liquidate(user1);
        v3vault.getVaultUserInfo(user1);
        deposit(input, user1);
    }

    function testFailDepositWithUnclaimed(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);

        generateRewards(5);
        warpRounds(1);
        v3vault.update();
        deposit(input, user1);
    }

    function testFailDepositZeroValue() public {
        vm.warp(v3vault.START() + 1);
        deposit(0, user1);
    }
    //////////////////////////////////////REDEEM

    function testRedeemDefault(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        vm.prank(user1);
        v3vault.redeem();
        require(lwrapped.balanceOf(user1) == 0);
    }

    function testRedeemLiquidated(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        priceImpact(user1);
        v3vault.liquidate(user1);
        vm.prank(user1);
        v3vault.redeem();
    }

    function testRedeemWithoutLToken(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        vm.startPrank(user1);
        lwrapped.transfer(user2, lwrapped.balanceOf(user1));
        uint256 bb = user1.balance;
        v3vault.redeem();
        vm.stopPrank();
        require(user1.balance - bb == 0);
    }

    //////////////////////////////////////WITHDRAW

    function testFailWithdrawNotExpired(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        vm.startPrank(user1);
        lwrapped.transfer(user2, lwrapped.balanceOf(user1));
        vm.stopPrank();
        vm.startPrank(user2);
        lwrapped.approve(address(v3vault), lwrapped.balanceOf(user2));
        v3vault.withdraw(lwrapped.balanceOf(user2));
        vm.stopPrank();
    }

    function testWithdrawDefault(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        vm.warp(v3vault.FINISH() + 1);
        v3vault.update();
        vm.startPrank(user1);
        lwrapped.transfer(user2, lwrapped.balanceOf(user1));
        vm.stopPrank();
        vm.startPrank(user2);
        lwrapped.approve(address(v3vault), lwrapped.balanceOf(user2));
        v3vault.withdraw(lwrapped.balanceOf(user2));
        vm.stopPrank();
    }

    //////////////////////////////////////LIQUIDATE
    function testLiquidation(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        priceImpact(user1);
        v3vault.getVaultUserInfo(user1);
        v3vault.liquidate(user1);
        LFxSonusV3Vault0.userVaultInfo memory info = v3vault.getVaultUserInfo(user1);
        require(info.liquidated);
    }

    //////////////////////////////////////CLAIM
    function testClaimRestake(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        uint256 b0 = pair.balanceOf(user1);
        uint256 b1 = user1.balance;
        uint256 b2 = v3vault.userALGMBalance(user1);

        generateRewards(5);
        warpRounds(1);
        v3vault.update();
        vm.prank(user1);
        v3vault.claim(true);
        b0 = pair.balanceOf(user1) - b0;
        b1 = user1.balance - b1;
        b2 = v3vault.userALGMBalance(user1) - b2;
        require(b0 > 0);
        require(b1 > 0);
        require(b2 > 0);
    }

    function testClaimUnstake(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        uint256 b0 = pair.balanceOf(user1);
        uint256 b1 = user1.balance;
        uint256 b2 = algm.balanceOf(user1);

        generateRewards(5);
        warpRounds(1);
        v3vault.update();
        vm.prank(user1);
        v3vault.claim(false);
        b0 = pair.balanceOf(user1) - b0;
        b1 = user1.balance - b1;
        b2 = algm.balanceOf(user1) - b2;
        require(b0 > 0);
        require(b1 > 0);
        require(b2 > 0);
    }

    function testClaimMath(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        deposit(input, user2);
        for (uint256 i = 1; i <= v3vault.totalRounds(); i++) {
            generateRewards(5);
            warpRounds(1);
            v3vault.update();
            (uint256[2] memory c1, uint256 a1) = v3vault.previewRewards(user1);
            (uint256[2] memory c2, uint256 a2) = v3vault.previewRewards(user2);
            if (i == v3vault.totalRounds() / 2) {
                require(c1[0] > c2[0]);
                require(c1[1] > c2[1]);
            }
            if (i == v3vault.totalRounds()) {
                require(0 == c2[0]);
                require(0 == c2[1]);
            }
            vm.prank(user1);
            v3vault.claim(true);
            vm.prank(user2);
            v3vault.claim(false);
        }
    }
    //////////////////////////////////////ALGM

    function testUnstakeALGMDefault(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);

        generateRewards(5);
        warpRounds(1);
        v3vault.update();
        vm.startPrank(user1);
        v3vault.claim(false);
        v3vault.unstakeALGM(v3vault.userALGMBalance(user1));
        vm.stopPrank();
    }

    //////////////////////////////////////REBALANCE
    function testRebalanceDefault(uint256 input) public {
        vm.warp(v3vault.START() + 1);
        vm.assume(input > 1000 gwei);
        vm.assume(input < 0.5 ether);
        deposit(input, user1);
        deposit(input, user2);
        uint256 b0 = pair.balanceOf(address(v3vault));
        uint256 b1 = address(v3vault).balance;

        (bool success, bytes memory data) = cfg.pool.staticcall(abi.encodeWithSignature("tickSpacing()"));
        int24 spacing = abi.decode(data, (int24));
        int24 mintick = -69_420 + 69_420 % spacing;
        int24 maxtick = 69_420 - 69_420 % spacing;
        v3vault.rebalance(mintick, maxtick);
        console.log("b0 diff:", pair.balanceOf(address(v3vault)) - b0);
        console.log("b1 diff:", address(v3vault).balance - b1);
    }
}
