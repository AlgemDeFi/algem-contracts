//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Sio2AdapterAssetManager.sol";
import "./Sio2Adapter.sol";

contract Sio2AdapterData is Initializable {
    Sio2Adapter private adapter;
    Sio2AdapterAssetManager private assetManager;

    uint256 private constant RISK_PARAMS_PRECISION = 1e4;

    uint256 private collateralLT;
    uint256 private collateralLTV;

    address private collateralAddr;

    function initialize(Sio2Adapter _adapter, Sio2AdapterAssetManager _assetManager) external initializer {
        adapter = _adapter;
        assetManager = _assetManager;
        collateralLT = adapter.collateralLT();
        collateralLTV = adapter.collateralLTV();
        collateralAddr = address(adapter.nastr());
    }

    function estimateHF(address _user) external view returns (uint256 hf) {
        uint256 collateralUSD = adapter.calcEstimateUserCollateralUSD(_user);

        // get est borrowed accRPS for assets
        // calc est user's debt
        uint256 debtUSD = adapter.calcEstimateUserDebtUSD(_user);

        require(debtUSD > 0, "User has no debts");

        hf = (collateralUSD * collateralLT * 1e18) /
            RISK_PARAMS_PRECISION / debtUSD;
    }

    function supplyWithdrawShift(address _user, uint256 _amount, bool isSupply) external view returns (
        uint256[] memory,
        uint256[] memory
    ) {
        uint256[] memory before = new uint256[](3);
        uint256[] memory later = new uint256[](3);
        
        // 0 - borrow available
        // 1 - borrow limit used
        // 2 - health factor

        (uint256 availableToBorrowUSD, uint256 availableToWithdrawUSD) = adapter.availableCollateralUSD(_user);
        uint256 inputDelta = adapter.toUSD(collateralAddr, _amount);
        uint256 inputDeltaLTV = inputDelta * collateralLTV / RISK_PARAMS_PRECISION;
        uint256 currentDebtUSD = adapter.calcEstimateUserDebtUSD(_user);
        uint256 currentCollateralUSD = adapter.calcEstimateUserCollateralUSD(_user);

        before[0] = availableToBorrowUSD; 
        before[1] = currentDebtUSD * 1e18 / availableToBorrowUSD;
        before[2] = currentCollateralUSD * collateralLT * 1e18 / RISK_PARAMS_PRECISION / currentDebtUSD;

        if (isSupply) {
            later[0] = availableToBorrowUSD + inputDeltaLTV;
            later[1] = currentDebtUSD * 1e18 / (availableToBorrowUSD + inputDeltaLTV);
            later[2] = (currentCollateralUSD + inputDelta) * collateralLT * 1e18 / RISK_PARAMS_PRECISION / currentDebtUSD;
        } else {
            availableToBorrowUSD >= inputDeltaLTV ? 
                later[0] = availableToBorrowUSD - inputDeltaLTV :
                later[0] = 0;
            availableToBorrowUSD > currentDebtUSD + inputDeltaLTV ?
                later[1] = currentDebtUSD * 1e18 / (availableToBorrowUSD - inputDeltaLTV) :
                later[1] = 1e18;
            currentCollateralUSD >= inputDelta + currentDebtUSD * RISK_PARAMS_PRECISION / collateralLT / 1e18 ?
                later[2] = (currentCollateralUSD - inputDelta) * collateralLT * 1e18 / RISK_PARAMS_PRECISION / currentDebtUSD :
                later[2] = 0;
        }

        return (before, later);
    }

    function borrowRepayShift(
        address _user, 
        uint256 _amount, 
        string memory _assetName,
        bool isBorrow
    ) external view returns (
        uint256[] memory,
        uint256[] memory
    ) {
        uint256[] memory before = new uint256[](3);
        uint256[] memory later = new uint256[](3);

        // 0 - borrowed
        // 1 - borrow limit used
        // 2 - health factor

        Sio2AdapterAssetManager.Asset memory asset = assetManager.getAssetInfo(_assetName);
        (uint256 availableToBorrowUSD, uint256 availableToWithdrawUSD) = adapter.availableCollateralUSD(_user);
        uint256 debtUSD = adapter.calcEstimateUserDebtUSD(_user);
        uint256 amountUSD = adapter.toUSD(asset.addr, _amount);
        uint256 currentCollateralUSD = adapter.calcEstimateUserCollateralUSD(_user);

        if (debtUSD == 0) debtUSD = 1;

        before[0] = debtUSD;
        before[1] = debtUSD * 1e18 / availableToBorrowUSD;
        before[2] = currentCollateralUSD * collateralLT * 1e18 / RISK_PARAMS_PRECISION / debtUSD;

        if (isBorrow) {
            later[0] = debtUSD + amountUSD;
            later[1] = (debtUSD + amountUSD) * 1e18 / availableToBorrowUSD;
            later[2] = currentCollateralUSD * collateralLT * 1e18 / RISK_PARAMS_PRECISION / (debtUSD + amountUSD);
        } else {
            if (debtUSD > amountUSD) {
                later[0] = debtUSD - amountUSD;
                later[1] = (debtUSD - amountUSD) * 1e18 / availableToBorrowUSD;
                later[2] = currentCollateralUSD * collateralLT * 1e18 / RISK_PARAMS_PRECISION / (debtUSD - amountUSD);
            } else {
                later[0] = 0;
                later[1] = 0;
                later[2] = 10e18;
            }
        }

        return (before, later);
    }
}