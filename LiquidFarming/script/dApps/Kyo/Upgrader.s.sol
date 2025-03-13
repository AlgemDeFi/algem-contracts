pragma solidity ^0.8.0;

import "script/Workbench.s.sol";

contract Upgrader is Workbench {
    function upgradeVault() public {
        address proxy = vm.parseAddress(vm.prompt("LF Vault proxy"));
        _upgradeVault(proxy);
    }

    function _upgradeVault(address proxy) internal {
        vm.startBroadcast();
        (, address sender,) = vm.readCallers();
        Upgrades.upgradeProxy(proxy, "LFxKyoV3Vault0.sol:LFxKyoV3Vault0", bytes(""), sender);
        vm.stopBroadcast();
    }

    function upgradePool() public {
        address proxy = vm.parseAddress(vm.prompt("LF Pool proxy"));
        _upgradePool(proxy);
    }

    function _upgradePool(address proxy) internal {
        vm.startBroadcast();
        (, address sender,) = vm.readCallers();
        Upgrades.upgradeProxy(proxy, "LFxKyoV3Pool.sol:LFxKyoV3Pool", bytes(""), sender);
        vm.stopBroadcast();
    }
}
