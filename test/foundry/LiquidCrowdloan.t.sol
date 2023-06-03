// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "./mocs/MockERC20Upgradeable.sol";
import "./mocs/MockDappsStaking.sol";
import "../src/ALGMVesting.sol";
import "../src/LiquidCrowdloan.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract LiquidCrowdloanTest is Test {
    address public user;
    address public user2;
    address public user3;
    address public owner;

    LiquidCrowdloan public cl;
    ALGMVesting public vesting;
    MockDappsStaking public dappsStaking;
    MockERC20Upgradeable public aastr;
    MockERC20Upgradeable public algm;

    function setUp() public {
        user = vm.addr(1);
        user2 = vm.addr(2);
        user3 = vm.addr(4);
        owner = vm.addr(3);

        vm.startPrank(owner);

        algm = new MockERC20Upgradeable();
        algm.initialize("Algem token", "ALGM");

        aastr = new MockERC20Upgradeable();
        aastr.initialize("aASTR token", "aASTR");

        dappsStaking = new MockDappsStaking();

        vesting = new ALGMVesting();
        vesting.initialize(algm);

        cl = new LiquidCrowdloan();
        cl.initialize(
            vesting,
            address(1),
            address(aastr),
            address(algm),
            address(dappsStaking)
        );

        algm.mint(address(vesting), 1e36);

        vesting.addManager(address(cl));

        vm.stopPrank();

        vm.deal(user, 1e36 ether); // add ether to user
        vm.deal(user2, 1e36 ether); // add ether to user2
        vm.deal(address(dappsStaking), 1e18 ether);
    }

    function testStake() public {
        vm.startPrank(user);
        cl.stake{value: 1000 ether}();

        vm.expectRevert("Need more ASTR");
        cl.stake{value: 1 ether}();

        vm.expectRevert("Too large deposit");
        cl.stake{value: 100_000_000 ether}();
        vm.stopPrank();

        vm.prank(owner);
        cl.closeCrowdloan();

        assertEq(aastr.balanceOf(user), 1000 ether);
    }

    function testCloseCrowdloan() public {
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        cl.closeCrowdloan();

        vm.startPrank(owner);
        cl.closeCrowdloan();
        assertEq(cl.closed(), true);

        vm.expectRevert("Crowdloan closed");
        cl.closeCrowdloan();

        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.prank(user);
        cl.stake{value: 1000 ether}(); // user gets 1000 aastr and locks his astr
        vm.prank(user2);
        cl.stake{value: 1000 ether}();

        vm.prank(owner);
        cl.closeCrowdloan(); // starts vesting period

        vm.startPrank(user);
        
        vm.warp(4 weeks + 1); // after one week
        uint256 availableRewards = cl.getUserAvailableRewards(user);
        cl.claimRewards();
        uint256 part1 = cl.ALGM_REWARDS_AMOUNT() / 6 / 2;
        assertEq(part1, availableRewards);
        assertEq(algm.balanceOf(user), part1);

        vm.warp(6 * 4 weeks + 1); // after 6 weeks user can claim his locked astr and claim algm rewards

        cl.claimRewards();

        uint256 part2 = cl.ALGM_REWARDS_AMOUNT() / 2;
        assertEq(algm.balanceOf(user) + 1, part2);
    }

    function testUnstake() public {
        vm.startPrank(user);
        cl.stake{value: 1000 ether}();

        vm.expectRevert("Crowdloan still open");
        cl.unstake();
        vm.stopPrank();

        vm.prank(owner);
        cl.closeCrowdloan();

        vm.prank(user);
        vm.expectRevert("Locking period has not yet passed");
        cl.unstake();

        vm.warp(7 * 4 weeks);

        vm.prank(user3);
        vm.expectRevert("User has no any aASTR");
        cl.unstake();

        vm.startPrank(user);
        cl.claimRewards();
        cl.unstake();
        vm.stopPrank();

        assertEq(aastr.balanceOf(user), 0);

        (uint256 val, , ) = cl.withdrawals(user, 0);
        assertEq(val, 1000 ether);
    }

    function testWithdraw() public {
        uint256 time;

        vm.prank(user);
        cl.stake{value: 1000 ether}();
        vm.deal(address(cl), 0); //needed to imitate dappsStaking behavior

        vm.prank(owner);
        cl.closeCrowdloan();
        
        time = 6 * 4 weeks + 1;
        vm.warp(time);

        vm.startPrank(user);
        cl.unstake();

        vm.expectRevert("Not enough eras passed!");
        cl.withdraw(0);

        vm.warp(time + 15 days);

        uint256 balBefore = user.balance;

        cl.withdraw(0);
        assertEq(user.balance, balBefore + 1000 ether);
    }

    function testClaimDappStakingRewards() public {
        uint256 time;

        vm.prank(user);
        cl.stake{value: 1000 ether}();
        vm.deal(address(cl), 0); //needed to imitate dappsStaking behavior

        vm.prank(owner);
        cl.closeCrowdloan();
        
        time = 6 * 4 weeks + 1;
        vm.warp(time);
        vm.roll(30);

        vm.startPrank(owner);
        cl.claimDappStakingRewards();

        cl.setClaimingTxLimit(200);
        cl.claimDappStakingRewards();

        vm.expectRevert("All rewards already claimed");
        cl.claimDappStakingRewards();

        uint256 amount = cl.totalStakingRewards();
        cl.withdrawStakingRewardsAdmin();
        assertEq(owner.balance, amount);
        vm.stopPrank();
    }

    function testGlobalUnstakeAdmin() public {
        vm.expectRevert("No any unstakes");
        vm.prank(owner);
        cl.globalUnstakeAdmin();

        vm.prank(user);
        cl.stake{value: 1000 ether}();

        vm.prank(user2);
        cl.stake{value: 1000 ether}();

        vm.prank(owner);
        cl.closeCrowdloan();
        
        vm.warp(6 * 4 weeks + 1);

        vm.prank(user);
        cl.unstake();

        vm.prank(owner);
        vm.expectRevert("No any unstakes");
        cl.globalUnstakeAdmin();
        
        vm.prank(user2);
        cl.unstake();
    
        vm.prank(owner);
        vm.expectRevert("There was already globalUnstake in this period of time");
        cl.globalUnstakeAdmin();

        vm.warp(6 * 4 weeks + 15 days);

        vm.prank(owner);
        cl.globalUnstakeAdmin();
    }

    function testGetStakers() public {
        vm.prank(user);
        cl.stake{value: 1000 ether}();

        vm.prank(user2);
        cl.stake{value: 1000 ether}();

        address[] memory arr = new address[](2);
        arr = cl.getStakers();
        assertEq(arr[0], user);
        assertEq(arr[1], user2);
    }

    function testInitialize() public {
        vm.prank(user);
        vm.expectRevert("Initializable: contract is already initialized");
        cl.initialize(
            vesting,
            address(1),
            address(aastr),
            address(algm),
            address(dappsStaking)
        );
    }
}