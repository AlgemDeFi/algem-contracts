// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// External libraries
import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {XNASTR} from "../src/XNASTR.sol";

contract XNASTRTest is Test {
    ProxyAdmin admin;

    address liquidStaking;
    address user;
    address deployer;

    XNASTR xnastr;
    XNASTR xnastrImpl;
    TransparentUpgradeableProxy xnastrProxy;

    function setUp() public {
        liquidStaking = makeAddr("liquidStaking");
        user = makeAddr("user");
        deployer = makeAddr("deployer");

        switchPrank(deployer);
        
        xnastrImpl = new XNASTR();
        xnastrProxy = new TransparentUpgradeableProxy(
            address(xnastrImpl),
            deployer,
            ""
        );
        xnastr = XNASTR(address(xnastrProxy));
        xnastr.initialize();
        xnastr.grantMintAndBurnRoles(liquidStaking);
    }

    function test_deploy() public {
        assertEq(xnastr.name(), "Algem XNASTR");
        assertEq(xnastr.symbol(), "XNASTR");
        assertEq(xnastr.decimals(), 18);
        assertTrue(xnastr.isMinter(liquidStaking));
        assertTrue(xnastr.isBurner(liquidStaking));
        assertTrue(xnastr.owner() == deployer);
    }

    function test_mint() public {
        switchPrank(user);
        vm.expectRevert();
        xnastr.mint(user, 1 ether);

        switchPrank(liquidStaking);
        xnastr.mint(user, 1 ether);
        assertEq(xnastr.balanceOf(user), 1 ether);
        assertEq(xnastr.totalSupply(), 1 ether);
    }

    function test_burn() public {
        switchPrank(user);
        vm.expectRevert();
        xnastr.burn(liquidStaking, 1 ether);

        switchPrank(liquidStaking);
        xnastr.mint(liquidStaking, 1 ether);
        xnastr.burn(liquidStaking, 1 ether);
        assertEq(xnastr.balanceOf(liquidStaking), 0);

        xnastr.mint(user, 10 ether);
        assertEq(xnastr.balanceOf(user), 10 ether);

        xnastr.burn(user, 5 ether);
        assertEq(xnastr.balanceOf(user), 5 ether);
    }

    function switchPrank(address addr) internal {
        vm.stopPrank();
        vm.startPrank(addr);
    }
}
