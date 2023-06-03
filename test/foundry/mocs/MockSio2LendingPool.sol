pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

import "./MockVDToken.sol";
import "./MockSCollateralToken.sol";
import "./MockERC20.sol";
import "../../src/libraries/DataTypes.sol";

contract MockSio2LendingPool {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    MockSCollateralToken public snastr;
    MockERC20 public nastr;
    DataTypes.ReserveConfigurationMap public busdConfigMap;
    MockERC20 public busd;
    MockVDToken public vdbusd;
    MockERC20 public dai;
    MockVDToken public vddai;

    mapping(address => MockERC20) public assets;
    mapping(address => MockVDToken) public debtAssets;

    mapping(address => uint256) public collateralAmount;
    uint256 public borrowAmount;

    constructor(
        MockSCollateralToken _snastr,
        MockERC20 _nastr,
        MockERC20 _busd,
        MockERC20 _dot,
        MockVDToken _vdbusd,
        MockVDToken _vddot,
        MockERC20 _dai,
        MockVDToken _vddai,
        MockERC20 _usdc,
        MockVDToken _vdusdc,
        MockERC20 _usdt,
        MockVDToken _vdusdt
    ) {
        snastr = _snastr;
        busdConfigMap.data = 27671057969860373126976;
        nastr = _nastr;
        assets[address(_busd)] = _busd;
        assets[address(_dot)] = _dot;
        debtAssets[address(_busd)] = _vdbusd;
        debtAssets[address(_dot)] = _vddot;
        assets[address(_dai)] = _dai;
        debtAssets[address(_dai)] = _vddai;
        assets[address(_usdc)] = _usdc;
        debtAssets[address(_usdc)] = _vdusdc;
        assets[address(_usdt)] = _usdt;
        debtAssets[address(_usdt)] = _vdusdt;
    }

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        collateralAmount[msg.sender] += amount;
        snastr.mint(msg.sender, amount);
        nastr.transferFrom(msg.sender, address(this), amount);
    }

    // returns configuration map for busd
    function getConfiguration(
        address asset
    ) external view returns (DataTypes.ReserveConfigurationMap memory) {
        return busdConfigMap;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(
            collateralAmount[msg.sender] >= amount,
            "Mock: Not enough collateral in lending pool"
        );
        collateralAmount[msg.sender] -= amount;
        snastr.burn(msg.sender, amount);
        nastr.transfer(msg.sender, amount);
        return amount;
    }

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        borrowAmount += amount;
        assets[asset].mint(msg.sender, amount);
        debtAssets[asset].mint(msg.sender, amount);
    }

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        ltv = 7750;
        currentLiquidationThreshold = 8250;
    }

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256) {
        borrowAmount -= amount;
        assets[asset].transferFrom(msg.sender, address(this), amount);
        debtAssets[asset].burn(msg.sender, amount);
    }
}
