pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/LWRAPPED.sol";
import "script/Workbench.s.sol";

contract LWRAPPEDTest is Test, Workbench {
    LWRAPPED lwrapped;

    function setUp() public {
        lwrapped = new LWRAPPED("Test LWRAPPED", "LWRAPPED");
    }
    // MINT/BURN

    function testMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0);
        lwrapped.mint(to, amount);
        assertEq(lwrapped.balanceOf(to), amount);
        lwrapped.burn(to, amount);
        assertEq(lwrapped.balanceOf(to), 0);
    }

    function testMintNonOwner() public {
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        lwrapped.mint(address(1), 1 ether);
        vm.stopPrank();

        lwrapped.mint(address(1), 1 ether);
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        lwrapped.burn(address(1), 1 ether);
        vm.stopPrank();
    }
}
