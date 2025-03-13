pragma solidity ^0.8.0;

import "script/Workbench.s.sol";
import "src/dApps/Kyo/LFxKyoV3Vault0.sol";
import "src/dApps/Kyo/LFxKyoV3Pool.sol";
import "src/LWRAPPED.sol";

contract Deployer is Workbench {
    function deployLWRAPPED() public {
        string memory name = vm.prompt("LWRAPPED name");
        string memory symbol = vm.prompt("LWRAPPED symbol");
        _deployLWRAPPED(name, symbol);
    }

    function _deployLWRAPPED(string memory name, string memory symbol) internal {
        lfcfg.lwrapped = address(new LWRAPPED(name, symbol));
    }

    function deployVault() public {
        address unipool = vm.parseAddress(vm.prompt("dApp pool address"));
        _deployVault(unipool);
    }

    function _deployVault(address unipool) internal {
        (bool success, bytes memory data) = address(unipool).staticcall(abi.encodeWithSignature("token0()"));
        bool isW0 = cfg.wrapped == abi.decode(data, (address));

        vm.startBroadcast();
        (, address sender,) = vm.readCallers();
        address v = Upgrades.deployTransparentProxy(
            "LFxKyoV3Vault0.sol:LFxKyoV3Vault0", sender, abi.encodeCall(LFxKyoV3Vault0.initialize, (unipool, isW0))
        );
        vm.stopBroadcast();
    }

    function deployPool() public {
        address pair = vm.parseAddress(vm.prompt("pair token"));
        address master = vm.parseAddress(vm.prompt("LFMaster address"));
        address algm = vm.parseAddress(vm.prompt("ALGM token"));

        _deployPool(pair, master, algm);
    }

    function _deployPool(address pair, address master, address algm) internal {
        vm.startBroadcast();
        (, address sender,) = vm.readCallers();
        address p = Upgrades.deployTransparentProxy(
            "LFxKyoV3Pool.sol:LFxKyoV3Pool", sender, abi.encodeCall(LFxKyoV3Pool.initialize, (pair, master, algm))
        );
        vm.stopBroadcast();
    }

    function addPool() public {
        lfcfg.master = vm.parseAddress(vm.prompt("LFMaster"));
        lfcfg.algm = vm.parseAddress(vm.prompt("ALGM"));
        deployPool();
        uint256 deadline = vm.parseUint(vm.prompt("Pool deadline"));
        string memory dapp = vm.prompt("dapp name");
        string memory pair = vm.prompt("pair name");
        ILFMaster(lfcfg.master).addPool(lfcfg.pool, deadline, dapp, pair);
    }

    function addVault() public {
        lfcfg.master = vm.parseAddress(vm.prompt("LFMaster"));
        lfcfg.algm = vm.parseAddress(vm.prompt("ALGM"));
        lfcfg.pool = vm.parseAddress(vm.prompt("LF Pool"));
        deployLWRAPPED();
        deployVault();
        uint256 share = vm.parseUint(vm.prompt("Vault share"));
        int24 tickL = int24(vm.parseInt(vm.prompt("Tick Lower")));
        int24 tickU = int24(vm.parseInt(vm.prompt("Tick Upper")));
        int24 tickS = int24(vm.parseInt(vm.prompt("Tick Spacing")));
        uint24 fee = uint24(vm.parseUint(vm.prompt("Pool fee")));

        vm.startBroadcast();
        LFxKyoV3Pool(lfcfg.pool).addVault(lfcfg.vault, share);
        LFxKyoV3Vault0(payable(lfcfg.vault)).initParams(tickL, tickU, tickS, fee);

        uint256 start = vm.parseUint(vm.prompt("vault start TS"));
        uint256 round = vm.parseUint(vm.prompt("vault round duration"));
        uint256 totalRounds = vm.parseUint(vm.prompt("vault total rounds"));

        LFxKyoV3Vault0(payable(lfcfg.vault)).initVault(
            lfcfg.lwrapped, lfcfg.algm, lfcfg.pool, start, round, totalRounds
        );
        ILWRAPPED(lfcfg.lwrapped).transferOwnership(lfcfg.vault);
        vm.stopBroadcast();
    }
}
