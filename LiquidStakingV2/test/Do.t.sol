// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


import { Test, console2 } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MockDappsStaking } from "../src/Mocks/MockDappsStaking.sol";

interface ILS {
    function unstake(
        string[] memory _utilities,
        uint256[] memory _amounts,
        bool _immediate
    ) external;
    function claimAll() external;
    function previewUserRewards(
        string memory _utility,
        address _user
    ) external view returns (uint256);
    function stake(
        string[] memory _utilities,
        uint256[] memory _amounts
    ) external payable;
}

interface ID {
    function listUserUtilitiesInDnt(address _user, string memory _dnt) external view returns (string[] memory);
    function getUserDntBalanceInUtil(
        address _user,
        string memory _util,
        string memory _dnt
    ) external view returns (uint256);
}

contract DoTest is Test {
    ILS liquidMain;
    ID ndistr;
    MockDappsStaking ds;
    IERC20 nastr;

    address shunp;
    address shunp2;

    uint256 sepoliaFork;
    uint256 astarFork;

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string ASTAR_RPC_URL = vm.envString("ASTAR_RPC_URL");

    function setUp() public {
        shunp = 0xD59C89626A824B530d0657EB64495964755fC007;
        shunp2 = 0x258ec18288f65f2f740F4c0EE0b88D71777A053C;
        liquidMain = ILS(0x70d264472327B67898c919809A9dc4759B6c0f27);
        ndistr = ID(0x460FB32070b77eB4Ff8d8f3EF717972F24433C83);
        nastr = IERC20(0xE511ED88575C57767BAfb72BfD10775413E3F2b0);
    }

    function test_do() public {
        astarFork = vm.createFork(ASTAR_RPC_URL);
        vm.selectFork(astarFork);        

        // == Logs ==
        //   DappsStaking: 0x97Ca75B521FC2Fc1B68b019F4e3e2c9bd3cb43A0
        //   LiquidStaking: 0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91

        // vm.startPrank(0x97Ca75B521FC2Fc1B68b019F4e3e2c9bd3cb43A0);
        // payable(0xeb9b182d7cB101E97D8Dc8cB71BE3B21C1194d91).transfer(1000000);
    }
}
