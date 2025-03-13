pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/LWRAPPED.sol";
import "src/LWRAPPEDCentre.sol";
import "script/Workbench.s.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MockLFVault {
    LWRAPPED lwrapped;

    constructor(address _lwrapped) {
        lwrapped = LWRAPPED(_lwrapped);
    }

    function withdraw(uint256 amount) public {
        lwrapped.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).call{value: amount}("");
    }
}

contract LWRAPPEDCentreTest is Test, Workbench {
    LWRAPPED lwrapped;
    LWRAPPEDCentre centre;
    MockLFVault vault;
    ProxyAdmin admin;

    receive() external payable {}

    function setUp() public {
        admin = new ProxyAdmin(address(this));
        lwrapped = new LWRAPPED("Test LWRAPPED", "LWRAPPED");
        lfcfg.lwrapped = address(lwrapped);
        vault = new MockLFVault(lfcfg.lwrapped);

        LWRAPPEDCentre c = new LWRAPPEDCentre();
        TransparentUpgradeableProxy lcp = new TransparentUpgradeableProxy(address(c), address(admin), "");
        centre = LWRAPPEDCentre(payable(address(lcp)));
        centre.initialize();
    }

    // VAULTS
    function testVaultManagement(address v, address l) public {
        vm.assume(v != address(0));
        vm.assume(l != address(0));
        centre.addVault(v, l);

        vm.expectRevert();
        centre.addVault(address(0), l);
        vm.expectRevert();
        centre.addVault(v, address(0));
        vm.expectRevert();
        centre.addVault(v, l);

        vm.expectRevert();
        centre.removeVault(address(0));
        centre.removeVault(v);
        vm.expectRevert();
        centre.removeVault(v);
    }

    // WITHDRAWALS
    function testWithdraw(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 1_000_000_000 ether);
        centre.addVault(address(vault), address(lwrapped));
        vm.deal(address(vault), amount);
        lwrapped.mint(address(this), amount);
        lwrapped.approve(address(centre), amount);
        uint256 b = address(this).balance;
        centre.withdraw(amount, address(vault));
        assertEq(address(this).balance - b, amount);
        assertEq(lwrapped.balanceOf(address(this)), 0);
    }
}
