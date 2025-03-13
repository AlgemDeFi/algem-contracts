// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/LiquidStaking/LiquidStaking.sol";
import "../src/LiquidStaking/LiquidStakingMain.sol";
import "../src/LiquidStaking/LiquidStakingManager.sol";
import "../src/LiquidStaking/LiquidStakingVoting.sol";
import "../src/XNASTR.sol";
import "../src/Mocks/MockDappsStaking.sol";
import "../src/Mocks/MockVeALGM.sol";

contract MockDappsStakingTest is Test {
    MockDappsStaking ds;

    address user;
    address dapp;

    MockDappsStaking.SmartContract public contr;

    function setUp() public {
        ds = new MockDappsStaking();
        user = vm.addr(1);
        dapp = vm.addr(2);
        contr = MockDappsStaking.SmartContract({
            contract_type: MockDappsStaking.SmartContractType.EVM,
            contract_address: abi.encodePacked(dapp)
        });
        vm.deal(user, 1e36);
        vm.deal(address(ds), 1e36);
    }

    function test_lock_and_stake() public {
        uint128 amount = 1e18;        
        ds.lock(amount);
        ds.stake(contr, amount);
    }

    function test_unstake() public {
        uint128 amount = 1e18;
        vm.startPrank(user);
        ds.lock(amount);
        ds.stake(contr, amount);
        vm.roll(30000);
        ds.unlock(amount);
        ds.unstake(contr, amount);
        vm.roll(60000);
        ds.claim_unlocked();
        vm.stopPrank();
    }

    function test_claim_staker_rewards() public {
        uint128 amount = 1e18;
        vm.startPrank(user);
        ds.lock(amount);
        ds.stake(contr, amount);
        vm.roll(30000);
        ds.claim_staker_rewards();
        vm.stopPrank();
    }

    function test_protocol_state() public {
        (uint256 era, uint256 period, uint256 subperiod) = (0, 0, 0);
        // 0 blocks passed
        (era, period, subperiod) = getStateParams();

        // 7300 blocks passed
        vm.roll(7300);
        (era, period, subperiod) = getStateParams();

        // 1 period || 7200*3 blocks passed
        vm.roll(7200*3);
        (era, period, subperiod) = getStateParams();

    }

    function getStateParams() public view returns (
        uint256 era,
        uint256 period,
        uint256 subperiod
    ) {
        MockDappsStaking.ProtocolState memory state = ds.protocol_state();
        (era, period, subperiod) = (state.era, state.period, uint256(state.subperiod));
    }
}