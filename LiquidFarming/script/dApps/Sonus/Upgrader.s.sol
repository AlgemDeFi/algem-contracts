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
        Upgrades.upgradeProxy(proxy, "LFxSonusV3Vault0.sol:LFxSonusV3Vault0", bytes(""), sender);
        vm.stopBroadcast();
    }

    function upgradePool() public {
        address proxy = vm.parseAddress(vm.prompt("LF Pool proxy"));
        _upgradePool(proxy);
    }

    function _upgradePool(address proxy) internal {
        vm.startBroadcast();
        (, address sender,) = vm.readCallers();
        Upgrades.upgradeProxy(proxy, "LFxSonusV3Pool.sol:LFxSonusV3Pool", bytes(""), sender);
        vm.stopBroadcast();
    }
}
