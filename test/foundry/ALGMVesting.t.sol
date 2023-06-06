// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "./mocs/MockERC20Upgradeable.sol";
import "../../contracts/ALGMVesting.sol";

contract ALGMVestingTest is Test {
    MockERC20Upgradeable public algm;
    ALGMVesting public vesting;

    address public manager;
    address public user1;

    function setUp() public {
        algm = new MockERC20Upgradeable();
        algm.initialize("Algem token", "ALGM");

        vesting = new ALGMVesting();
        vesting.initialize(algm);

        manager = vm.addr(100);
        user1 = vm.addr(1);

        algm.mint(address(vesting), 1e36);
        vesting.addManager(manager);
    }

    function testCreateVesting(uint256 amount) public {
        // uint256 amount = 1e18;
        vm.startPrank(manager);

        vm.assume(amount != 0 && amount < 1e36);

        if (vesting.getWithdrawableAmount() < amount) {
            vm.expectRevert(
                "Cannot create vesting schedule because not sufficient tokens"
            );
        }

        vesting.createVesting(
            user1,
            100, //cliff
            100, //startTime
            6, //duration in months
            100, //slice period
            true, //revokable
            amount //amount
        );

        vm.stopPrank();
    }

    function testRevokeVesting() public {
        uint256 amount = 1e18;
        vm.startPrank(manager);
        console.log("timee before", block.timestamp);
        vesting.createVesting(
            user1,
            0, //cliff
            block.timestamp + 1 weeks, //startTime
            6, //duration in months
            1 weeks, //slice period
            true, //revokable
            amount //amount
        );
        assertEq(vesting.vestingsTotalAmount(), amount);
        vm.warp(2 weeks + 1);

        uint256 count = vesting.getVestingCountByBeneficiary(user1);
        bytes32 id = vesting.computeVestingIdForAddressAndIndex(user1, count - 1);
        uint256 releasable = vesting._computeReleasableAmount(vesting.getVesting(id));
        ALGMVesting.Vesting memory v = vesting.getVesting(id);

        console.log(
            "cliff:",
            v.cliff);
        console.log("start:", v.start);
        console.log("duration:", v.duration);
        console.log("slice:", v.slicePeriod);
        console.log("total amount:", v.amountTotal);
        console.log("relesable:", releasable);
        console.log("relesed:", v.released);
        console.log("cur time", block.timestamp);

        vesting.revokeVesting(id);

        vm.stopPrank();
    }

    function testAddManager() public {
        uint256 initNum = vesting.getManagers().length;
        vm.prank(manager);
        vesting.addManager(user1);

        assertEq(vesting.getManagers().length, initNum + 1);
    }

    function testRevokeManager() public {
        uint256 initNum = vesting.getManagers().length;
        vm.startPrank(manager);
        vesting.addManager(user1);
        vesting.revokeManager(user1);
        assertEq(vesting.getManagers().length, initNum);
        vm.stopPrank();
    }
}
