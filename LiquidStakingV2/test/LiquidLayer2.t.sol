// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CCIPLocalSimulator, IRouterClient, LinkToken } from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { WETH9 } from "@chainlink/local/src/shared/WETH9.sol";

import { ILiquidStakingLayer2 as LSL2 } from "../src/interfaces/ILiquidStakingLayer2.sol";
import { LiquidStakingStorage as LS } from "../src/LiquidStaking/LiquidStakingStorage.sol";
import { ILiquidStakingEvents as LSEvents } from "../src/interfaces/ILiquidStakingEvents.sol";

import { Base, console } from "./Base.sol";


contract LiquidLayer2Test is Base {
    CCIPLocalSimulator public ccipLocalSimulator;
    
    WETH9 wastrL2;

    address routerL2;
    address routerAstar;

    function setUp() public {
        user = makeAddr("user");
        receiver = makeAddr("receiver");
        deployer = makeAddr("deployer");
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        userC = makeAddr("userC");

        ccipLocalSimulator = new CCIPLocalSimulator();
        (
            uint64 _chainSelector, // selector of the destination chain (Astar in our case)
            IRouterClient sourceRouter, // Layer2's router
            IRouterClient destinationRouter, // Astar's router
            WETH9 wrappedNative, // wastr on Layer2
            LinkToken linkToken,
            ,

        ) = ccipLocalSimulator.configuration();

        (wastrL2, routerL2, routerAstar) = (wrappedNative, address(sourceRouter), address(destinationRouter));
        chainSelector = _chainSelector;

        sprank(deployer);

        _deployLiquidStakingAstar(address(linkToken), address(destinationRouter), wrappedNative);
        _deployLiquidStakingLayer2(
            _chainSelector, 
            address(linkToken), 
            address(sourceRouter), 
            payable(address(wrappedNative)), 
            address(xnastr), 
            address(veWrappedProxy)
        );

        liquidAdmin.setCCIPParams(_chainSelector, address(liquidL2), makeAddr("feeToken"));

        vm.deal(user, type(uint256).max);
        vm.deal(userA, type(uint256).max);
        vm.deal(userB, type(uint256).max);
        vm.deal(userC, type(uint256).max);
        sprank(user); 
        address(wastrL2).call{value: 1e36}("");
        doVoting();
        sprank(userA); address(wastrL2).call{value: 1e36}("");
        sprank(userB); address(wastrL2).call{value: 1e36}("");
        sprank(userC); address(wastrL2).call{value: 1e36}("");
    }

    function test_PauseUnpause() public {
        sprank(deployer); liquidL2.pause();
        sprank(userA);
        wastrL2.approve(address(liquidL2), 100e18); 
        vm.expectRevert(LSL2.NotAllowedWhenPaused.selector);
        liquidL2.stake(100e18);

        sprank(deployer); liquidL2.unpause();
        sprank(userA);
        wastrL2.approve(address(liquidL2), 100e18); 
        assertTrue(xnastr.balanceOf(userA) == 0);
        liquidL2.stake(100e18);
        assertTrue(xnastr.balanceOf(userA) > 0);        
    }

    function test_ErrorWhenPaused() public {
        sprank(deployer);
        liquidWrappedProxy.pause();

        uint256 balanceBefore = wastrL2.balanceOf(userA);
        stake(userA, 100e18);
        assertEq(wastrL2.balanceOf(userA), balanceBefore);
        assertEq(xnastr.balanceOf(userA), 0);

        sprank(deployer);
        liquidWrappedProxy.unpause();
        liquidWrappedProxy.setPauseOnFunc(0x26476204, true);

        stake(userA, 100e18);
        assertEq(wastrL2.balanceOf(userA), balanceBefore);
        assertEq(xnastr.balanceOf(userA), 0);
    }

    function test_CCIPUnstaking() public {
        uint256 oneEra = 7200 * 2;
        uint256 oneChunk = 8100 * 2;
        uint256 eras = oneEra * 5;
        uint256 unlockingPeriod = 64800 * 2;
        uint256 chunkLen = 8100 * 2;

        stake(userA, 100e18);

        // after one era userA makes unstake
        mine(oneEra);
        unstake(userA, 50e18, false);

        // LSL2.Unstake[] memory unstakes = liquidL2.getUnstakes(userA);
        // LS.Withdrawal[] memory withdrawals = liquidMain.getUserWithdrawalsArray(address(liquidL2));

        // after one era we need to do sync to initiate unlocking process from ds
        mine(oneEra); // 14400
        sync();

        mine(unlockingPeriod);
        // after unlocking process userA can withdraw his astr
        withdraw(userA, 0);

        mine(oneEra);
        stake(userB, 200e18);
        stake(userC, 250e18);
        
        mine(eras);
        unstake(userB, 10e18, false); // since last unstake makes before unstake in updates, lag == 16200

        mine(oneChunk);
        sync();

        mine(unlockingPeriod); // 64800 * 2
        withdraw(userB, 0);        

        unstake(userC, 10e18, false);

        mine(oneChunk);
        sync();

        mine(unlockingPeriod);
        withdraw(userC, 0);

        unstake(userA, xnastr.balanceOf(userA), false);
        assertEq(xnastr.balanceOf(userA), 0);

        mine(oneChunk);
        sync();

        mine(unlockingPeriod);
        withdraw(userA, 1);

        uint256 wastrBalBefore = wastrL2.balanceOf(userA);
        uint256 xnastrEstimated = liquidMain.getXNASTRValue(100e18);
        stake(userA, 100e18);
        assertEq(xnastrEstimated, xnastr.balanceOf(userA) + wastrL2.balanceOf(userA) - (wastrBalBefore - 100e18));

        mine(eras);
        sync();

        mine(eras);
        
        wastrBalBefore = wastrL2.balanceOf(userA);
        uint256 xnastrBalBefore = xnastr.balanceOf(userA);
        
        unstake(userA, xnastrBalBefore, false);
        assertEq(xnastr.balanceOf(userA), 0);
        uint256 remains = wastrL2.balanceOf(userA) - wastrBalBefore;
        uint256 wastrEstimated = liquidMain.getASTRValue(xnastrBalBefore); 

        mine(oneChunk);       
        sync();

        mine(unlockingPeriod);
        
        withdraw(userA, 2);
        assertEq(wastrL2.balanceOf(userA), wastrBalBefore + wastrEstimated);
    }

    ///@dev Stake to liquidL2 
    function stake(address who, uint256 amount) internal {
        sprank(who);
        wastrL2.approve(address(liquidL2), amount); 
        liquidL2.stake(amount);
    }

    ///@dev Unstake from liquidL2
    function unstake(address who, uint256 amount, bool immediate) internal {
        sprank(who);
        xnastr.approve(address(liquidL2), amount);
        liquidL2.unstake(amount, immediate);
    }

    ///@dev Make updates in LS for currentEra
    function sync() internal {
        sprank(deployer);
        liquidMain.sync(liquidMain.currentEra());
    }

    function withdraw(address who, uint256 index) internal {
        sprank(who);
        liquidL2.withdraw(index);
    }

    function test_Stake() public {
        uint256 minAmount = liquidL2.minStakeAmount();
        sprank(user);

        // stake 100 ASTR
        wastrL2.approve(address(liquidL2), minAmount); 

        // revert if stake less than minStakeAmount
        vm.expectRevert(LSL2.WrongStakeAmount.selector);
        liquidL2.stake(99 ether);
        
        uint256 wastrBalanceBefore = wastrL2.balanceOf(user);

        // stake min amount 100 ASTR
        liquidL2.stake(minAmount);

        // check if state has changd correctly
        uint256 stakeAmount = liquidL2.stakes(user);
        assertEq(liquidL2.stakes(user), wastrBalanceBefore - wastrL2.balanceOf(user));
        // check if user got xnastr
        assertGt(xnastr.balanceOf(user), 0);
        assertEq(xnastr.balanceOf(user), xnastr.totalSupply(), "minted xnastr should be eq to xnastr total supply"); 
        assertEq(liquidMain.getXNASTRValue(stakeAmount), xnastr.balanceOf(user), "user's received xnastr converted to astr should be eq to stake amount");
        assertEq(liquidMain.totalStaked(), stakeAmount, "totalStaked should be eq to user's stake");
        assertEq(liquidL2.stakes(user), liquidL2.totalStaked());
    }

    function test_Stake_Fail() public {
        sprank(deployer);
        // make impossible to stake with 100 ASTR
        liquidAdmin.setMinStakeAmount(200 ether);

        uint256 wastrBalanceBefore = wastrL2.balanceOf(user);
        sprank(user);
        // stake 100 ASTR
        wastrL2.approve(address(liquidL2), 100 ether); 
        liquidL2.stake(100 ether);
        assertEq(wastrL2.balanceOf(user), wastrBalanceBefore, "user's wastr balance should remain the same");
        assertEq(xnastr.totalSupply(), 0);
    }

    function test_Unstake() public {
        test_Stake();

        uint256 unstakeAmount = xnastr.balanceOf(user);
        xnastr.approve(address(liquidL2), unstakeAmount);

        // check if the tx will be reverted with zero or too small unstake amount 
        vm.expectRevert(LSL2.WrongUnstakeAmount.selector);
        liquidL2.unstake(0, false);
        vm.expectRevert(LSL2.WrongUnstakeAmount.selector);
        liquidL2.unstake(unstakeAmount + 1, false);

        vm.expectEmit();
        emit LSEvents.Unstaked(address(liquidL2), 99999999999999999998, false);
        liquidL2.unstake(unstakeAmount, false);
        assertEq(liquidMain.totalStaked(), 0, "totalStaked should be reset to zero");
        assertEq(xnastr.balanceOf(user), 0, "xnastr user's balance should be burned");
        assertEq(xnastr.totalSupply(), 0, "totalSupply should be zero");

        // get LSAstar withdrawals for LSLayer2
        LS.Withdrawal[] memory wls = liquidAdmin.getUserWithdrawalsArray(address(liquidL2));
        assertTrue(wls.length == 1, "Withdrawals for liquidL2 should be added");
        
        uint256 val = wls[0].val;
        uint256 lag = wls[0].lag;

        assertEq(val, unstakeAmount, "LiquidL2 withdraw amout should be eq to unstakeAmount");

        LSL2.Unstake memory unstake = liquidL2.getUnstakes(user)[0];
        assertEq(unstake.amount, unstakeAmount, "User's unstake amount should be eq to unstakeAmount");
        assertGt(unstake.duration, 0);
    }

    function test_Unstake_Immediate() public {
        test_Stake();

        uint256 amountToUnstake = xnastr.balanceOf(user) / 10;

        // make rewards pool filled
        sprank(deployer);
        mine(999999 * 10000); // block num should be increased significantly to collect enough astr rewards
        liquidMain.sync(liquidMain.currentEra());

        sprank(user);
        xnastr.approve(address(liquidL2), amountToUnstake);
        xnastr.approve(address(liquidMain), amountToUnstake);
        uint256 wastrBefore = wastrL2.balanceOf(user);
        uint256 expectedAmount = liquidMain.getASTRValue(amountToUnstake);
        liquidL2.unstake(amountToUnstake, true);

        assertGt(wastrL2.balanceOf(user), wastrBefore);
        assertEq(wastrL2.balanceOf(user), wastrBefore + expectedAmount);
    }

    function test_Unstake_Fail() public {
        test_Stake();

        uint256 balanceBefore = xnastr.balanceOf(user);
        uint256 stakeBefore = liquidL2.stakes(user);

        // unstake 90 ASTR
        xnastr.approve(address(liquidL2), 1e14);
        liquidL2.unstake(1e14, false);

        assertEq(xnastr.balanceOf(user), balanceBefore, "xnastr balance after eq to balance before");
        assertEq(liquidL2.stakes(user), stakeBefore, "Stake after eq to stake before");
    }

    function test_Withdraw_Success() public {
        uint256 wastrBalanceBefore = wastrL2.balanceOf(user);
        
        test_Unstake();

        LSL2.Unstake memory _unstake = liquidL2.getUnstakes(user)[0];
        // console.log("wastrBalanceBefore", wastrBalanceBefore); // wastrBalanceBefore 500000000000000000000
        // console.log("unstake amount", _unstake.amount); //   unstake amount 99999999999999999998
        // console.log("unstake duration", _unstake.duration); //   unstake duration 145799
        
        // go to the next era and skip one chunk len
        mine(8100 * 2);
        
        // neet to sync to initiate unlocking period for unstake
        sprank(deployer);
        liquidMain.sync(liquidMain.currentEra());

        LSL2.Unstake memory unstake = liquidL2.getUnstakes(user)[0];
        assertEq(unstake.amount, wastrBalanceBefore - wastrL2.balanceOf(user));
        assertFalse(unstake.inWithdrawProcess);
        assertGt(unstake.startTime, 0);

        sprank(user);
        vm.expectRevert(LSL2.UnstakeStillLocked.selector);
        liquidL2.withdraw(0);          

        // skip unlocking time and collect unlocked astr
        mine(64801 * 2 + 16200); // 145 802

        sprank(deployer);
        liquidMain.sync(liquidMain.currentEra());

        sprank(user);
        liquidL2.withdraw(0);

        unstake = liquidL2.getUnstakes(user)[0];
        assertEq(unstake.startTime, 0);
        assertEq(wastrL2.balanceOf(user), wastrBalanceBefore);
    }

    function test_Withdraw_Fail() public {
        uint256 wastrBalanceBefore = wastrL2.balanceOf(user);

        test_Unstake();
        mine(8100 * 2);

        // start unlocking process
        sprank(deployer);
        liquidMain.sync(liquidMain.currentEra());

        // collect unlocked astr
        mine(64801 * 2 + 16200); // 145 802
        liquidMain.sync(liquidMain.currentEra());

        LSL2.Unstake memory unstake = liquidL2.getUnstakes(user)[0];
        assertGt(unstake.startTime, 0);
        assertEq(wastrL2.balanceOf(user), wastrBalanceBefore - unstake.amount);

        sprank(user);
        liquidL2.withdraw(0);

        vm.expectRevert(LSL2.AlreadyClaimed.selector);
        liquidL2.withdraw(0);        
    }

    function test_Vote() public {
        uint256 initialPower = liquidL2.availableVotePower(user);
        uint256 lockedBefore = liquidL2.lockedVotePower(user);
        uint256 totalVoteBefore = liquidMain.totalVoted();
        uint256 userVotesBefore = liquidMain.userVotes(user);

        sprank(user);
        liquidL2.vote(10e18, 0);
        assertEq(initialPower, liquidL2.availableVotePower(user) + 10e18);
        assertEq(liquidL2.lockedVotePower(user), lockedBefore + 10e18);
        assertEq(liquidMain.totalVoted(), totalVoteBefore + 10e18);
        assertEq(liquidMain.userVotes(user), userVotesBefore + 10e18);
    }

    function test_Vote_Fail() public {
        uint256 initialPower = liquidL2.availableVotePower(user);
        uint256 lockedBefore = liquidL2.lockedVotePower(user);
        uint256 totalVoteBefore = liquidMain.totalVoted();
        uint256 userVotesBefore = liquidMain.userVotes(user);

        sprank(user);
        // using a non-existent id to fail tx
        liquidL2.vote(10e18, 99);

        assertEq(initialPower, liquidL2.availableVotePower(user));
        assertEq(liquidL2.lockedVotePower(user), lockedBefore);
        assertEq(liquidMain.totalVoted(), totalVoteBefore);
        assertEq(liquidMain.userVotes(user), userVotesBefore);
    }

    function test_Unvote() public {
        uint256 votesAmount = 10e18;
        uint256 dappId = 0;

        sprank(user);
        liquidL2.vote(votesAmount, dappId);

        vm.expectRevert(LSL2.NotEnoughVotes.selector);
        liquidL2.unvote(votesAmount + 2e18, dappId);

        uint256 totalUsedBefore = liquidMain.userVotes(user);
        uint256 totalVotedToDappByUserBefore = liquidVoting.getVoteToDapp(user, dappId);
        uint256 dappVotesBefore = liquidMain.dappVotes(dappId);
        uint256 totalVotedBefore = liquidMain.totalVoted();

        uint256 lockedBefore = liquidL2.lockedVotePower(user);

        // check if vote state is eq in both chains
        assertEq(totalUsedBefore, liquidL2.userVotes(user));
        assertEq(totalVotedToDappByUserBefore, liquidL2.getVoteToDapp(user, dappId));
        assertEq(dappVotesBefore, liquidL2.dappVotes(dappId));

        liquidL2.unvote(votesAmount, dappId);

        // check LiquidAstar state
        assertEq(
            totalUsedBefore - votesAmount, liquidMain.userVotes(user),
            "totalUsed should decrease by votesAmount"
        );
        assertEq(
            totalVotedToDappByUserBefore - votesAmount, liquidVoting.getVoteToDapp(user, dappId),
            "votes to dapp should decrease by votesAmount"
        );
        assertEq(dappVotesBefore - votesAmount, liquidMain.dappVotes(dappId));
        assertEq(totalVotedBefore - votesAmount, liquidMain.totalVoted());

        // check LiquidLayer2 state
        assertEq(totalUsedBefore - votesAmount, liquidL2.userVotes(user));
        assertEq(totalVotedToDappByUserBefore - votesAmount, liquidL2.getVoteToDapp(user, dappId));
        assertEq(dappVotesBefore - votesAmount, liquidL2.dappVotes(dappId));
        assertEq(
            lockedBefore - votesAmount, liquidL2.lockedVotePower(user), 
            "locked vote power should decrease correctly"
        );
    }

    function test_Unvote_Fail() public {
        uint256 votesAmount = 10e18;
        uint256 dappId = 0;

        // vote for the dapp first
        sprank(user);
        liquidL2.vote(votesAmount, dappId);

        // make first dapp unavailable
        sprank(deployer);
        uint256[] memory newWeights = new uint256[](5);
        (newWeights[0], newWeights[1], newWeights[2], newWeights[3], newWeights[4]) = (0, 2500, 2500, 2500, 2500);

        liquidVoting.toggleDappAvailability("Algem", newWeights);
        assertFalse(liquidMain.isActive("Algem"));

        // state before
        uint256 totalUsedBefore = liquidMain.userVotes(user);
        uint256 totalVotedToDappByUserBefore = liquidVoting.getVoteToDapp(user, dappId);
        uint256 dappVotesBefore = liquidMain.dappVotes(dappId);
        uint256 totalVotedBefore = liquidMain.totalVoted();

        uint256 lockedBefore = liquidL2.lockedVotePower(user);

        // check if vote state is eq in both chains
        assertEq(totalUsedBefore, liquidL2.userVotes(user));
        assertEq(totalVotedToDappByUserBefore, liquidL2.getVoteToDapp(user, dappId));
        assertEq(dappVotesBefore, liquidL2.dappVotes(dappId));

        sprank(user);

        // check if right event will be emitted
        vm.expectEmit();
        emit LSL2.UnvoteFailed(user, votesAmount, dappId);
 
        liquidL2.unvote(votesAmount, dappId);

        // check if state remains unchanged
        assertEq(totalUsedBefore, liquidMain.userVotes(user));
        assertEq(totalUsedBefore, liquidL2.userVotes(user));
        assertEq(totalVotedToDappByUserBefore, liquidVoting.getVoteToDapp(user, dappId));
        assertEq(totalVotedToDappByUserBefore, liquidL2.getVoteToDapp(user, dappId));
        assertEq(dappVotesBefore, liquidMain.dappVotes(dappId));
        assertEq(dappVotesBefore, liquidL2.dappVotes(dappId));
        assertEq(totalVotedBefore, liquidMain.totalVoted());
    }

    function test_SendingXnastr() public {
        sprank(user);
        assertEq(xnastr.balanceOf(user), 0);
        uint256 mintedXnastr = liquidMain.stake{value: 100 ether}();
        uint256 xnastrBalance = xnastr.balanceOf(user);
        assertGt(xnastrBalance, 0);
        assertEq(xnastrBalance, mintedXnastr);

        // send xnastr to LSLayer2
        bytes memory msgData = abi.encode("Anybody here?");
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: msgData,
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 10_000_000})),
            feeToken: liquidMain.linkAddr()
        });
        message.tokenAmounts[0] = Client.EVMTokenAmount(address(xnastr), 10 ether);
        uint256 fee = IRouterClient(routerAstar).getFee(chainSelector, message);

        LinkToken(liquidMain.linkAddr()).approve(address(routerAstar), fee);
        xnastr.approve(routerAstar, mintedXnastr);

        IRouterClient(routerAstar).ccipSend(
            chainSelector,
            message
        );
    }
}