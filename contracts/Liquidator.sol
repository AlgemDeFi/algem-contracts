// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FlashLoanReceiverBase.sol";
import "./interfaces/ISio2LendingPool.sol";
import "./Sio2Adapter.sol";
import "./Sio2AdapterAssetManager.sol";
import "./Sio2AdapterData.sol";
import "./interfaces/IPancakeRouter01.sol";
import "./interfaces/IArthswapFactory.sol";
import "./libraries/ArthswapLibrary.sol";

contract Liquidator is FlashLoanReceiverBase, AccessControl {
    ISio2LendingPool public pool;
    Sio2Adapter public adapter;
    Sio2AdapterAssetManager public assetManager;
    Sio2AdapterData public data;

    IPancakeRouter01 public constant ROUTER =
        IPancakeRouter01(0xE915D2393a08a00c5A463053edD31bAe2199b9e7);
    IArthswapFactory public constant FACTORY =
        IArthswapFactory(0xA9473608514457b4bF083f9045fA63ae5810A03E);

    address public dotAddr = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF; // 10
    address public wastrAddr = 0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720; // 18
    address public baiAddr = 0x733ebcC6DF85f8266349DEFD0980f8Ced9B45f35; // 18
    address public ceusdcAddr = 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98; // 6
    address public ceusdtAddr = 0x3795C36e7D12A8c252A20C5a7B455f7c57b60283; // 6
    address public busdAddr = 0x4Bf769b05E832FCdc9053fFFBC78Ca889aCb5E1E; // 18
    address public daiAddr = 0x6De33698e9e9b787e09d3Bd7771ef63557E148bb; // 18
    address public wethAddr = 0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c; // 18
    address public wbtcAddr = 0xad543f18cFf85c77E140E3E5E3c3392f6Ba9d5CA; // 8
    address public bnbAddr = 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52; // 18
    // address nastrAddr = 0xE511ED88575C57767BAfb72BfD10775413E3F2b0;
    address public nastrAddr;
    address public currentUser;

    bytes32 public constant LIQUIDATOR =
        keccak256(abi.encodePacked("LIQUIDATOR"));

    uint256 private constant DOT_PRECISION = 1e8;

    struct DebtAsset {
        string name;
        uint256 debt;
    }

    DebtAsset[] public assetsToLiquidate;
    address[] public colToASTRPath;

    mapping(address => mapping(address => address[])) public pairToPath;

    event WithdrawToken(address token, uint256 amount);
    event Withdraw(address caller, uint256 amount);

    constructor(
        ISio2LendingPool _pool,
        Sio2Adapter _adapter,
        Sio2AdapterAssetManager _assetManager,
        ISio2LendingPoolAddressesProvider _provider,
        Sio2AdapterData _data,
        address _nastrAddr
    ) FlashLoanReceiverBase(_provider) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LIQUIDATOR, msg.sender);
        pool = _pool;
        adapter = _adapter;
        assetManager = _assetManager;
        nastrAddr = _nastrAddr;
        data = _data;
        /* set path for nastr => astr 👉 */ pairToPath[nastrAddr][wastrAddr] = [
            /* path for DAI => ASTR */ 0x6De33698e9e9b787e09d3Bd7771ef63557E148bb,
            0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98,
            0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720
        ];

        pairToPath[wastrAddr][dotAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF];
        pairToPath[wastrAddr][baiAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x733ebcC6DF85f8266349DEFD0980f8Ced9B45f35];
        pairToPath[wastrAddr][ceusdcAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98];
        pairToPath[wastrAddr][ceusdtAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x3795C36e7D12A8c252A20C5a7B455f7c57b60283];
        pairToPath[wastrAddr][busdAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98, 0x4Bf769b05E832FCdc9053fFFBC78Ca889aCb5E1E];
        pairToPath[wastrAddr][daiAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52, 0xDe2578Edec4669BA7F41c5d5D2386300bcEA4678, 0x6De33698e9e9b787e09d3Bd7771ef63557E148bb];
        pairToPath[wastrAddr][wethAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x75364D4F779d0Bd0facD9a218c67f87dD9Aff3b4, 0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF, 0x81ECac0D6Be0550A00FF064a4f9dd2400585FE9c];
        pairToPath[wastrAddr][wbtcAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52, 0xDe2578Edec4669BA7F41c5d5D2386300bcEA4678, 0xad543f18cFf85c77E140E3E5E3c3392f6Ba9d5CA];
        pairToPath[wastrAddr][bnbAddr] = [0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720, 0x75364D4F779d0Bd0facD9a218c67f87dD9Aff3b4, 0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF, 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52];
    }

    receive() external payable {}

    /* to remove ❗️ */ uint256 public totalDebtUSDglobal;
    /* to remove ❗️ */ uint256 public collBalBeforeLiq;
    /* to remove ❗️ */ uint256 public collBalAfterLiq;
    /* to remove ❗️ */ uint256 public astrBalBeforeSwap;
    /* to remove ❗️ */ uint256 public astrBalAfterSwap;
    /* to remove ❗️ */ address[] public assetsForFlashloan;
    /* to remove ❗️ */ uint256[] public amountsForFlashloan;

    /* to remove ❗️ */ address[] public assetsAfterFlashloan;
    /* to remove ❗️ */ uint256[] public amountsAfterFlashloan;

    /* to remove ❗️ */ function getAssetsForFlashloan() public view returns (address[] memory, uint256[] memory) {
        return (assetsForFlashloan, amountsForFlashloan);
    }

    /* to remove ❗️ */ function getAssetsForFlashloanLength() public view returns (uint256) {
        return assetsForFlashloan.length;
    }

    /* to remove ❗️ */ function getAssetsAfterFlashloan() public view returns (address[] memory, uint256[] memory) {
        return (assetsAfterFlashloan, amountsAfterFlashloan);
    }

    /* to remove ❗️ */ function getAssetsAfterFlashloanLength() public view returns (uint256) {
        return assetsAfterFlashloan.length;
    }

    function liquidate(address _user) public onlyRole(LIQUIDATOR) {
        require(data.estimateHF(_user) < 1e18, "Pos is healthy enough");
        currentUser = _user;

        // get user's debt tokens names and debt amounts
        (string[] memory names, uint256[] memory debts) = assetManager
            .getAvailableTokensToRepay(_user);
        uint256 len = names.length;

        DebtAsset[] memory debtAssets = new DebtAsset[](len);
        uint256 totalDebtUSD;

        // perhaps merging is not needed
        (debtAssets, totalDebtUSD) = mergeArraysAndCalcSumUSD(names, debts);

        /* to remove ❗️ */ totalDebtUSDglobal = totalDebtUSD;

        // to descending order
        DebtAsset[] memory sortedDebtAssets = toDescendingOrder(debtAssets);

        // iter by debt assets in descending order and fill assets array for flashloan
        (
            address[] memory assets,
            uint256[] memory amounts
        ) = fillAssetsToLiquidate(sortedDebtAssets, totalDebtUSD);

        /* to remove ❗️ */ for (uint256 i; i < assets.length; i++) {
            assetsForFlashloan.push(assets[i]);
            amountsForFlashloan.push(amounts[i]);
        }

        flashloan(assets, amounts);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external override returns (bool) {

        /* to remove ❗️ */ for (uint256 i; i < assets.length; i++) {
            assetsAfterFlashloan.push(assets[i]);
            amountsAfterFlashloan.push(amounts[i]);
        }

        collBalBeforeLiq = ERC20(nastrAddr).balanceOf(address(this));

        // do liquidations and collect collateral
        for (uint256 idx; idx < assets.length;) {
            ERC20(assets[idx]).approve(address(adapter), amounts[idx]);
            uint256 receivedCollateral = adapter.liquidationCall(
                ERC20(assets[idx]).symbol(),
                currentUser,
                amounts[idx]
            );

            unchecked { ++idx; }
        }

        collBalAfterLiq = ERC20(nastrAddr).balanceOf(address(this));
        astrBalBeforeSwap = address(this).balance;

        // swap all collateral to native astr
        swapCollateralToASTR();

        astrBalAfterSwap = address(this).balance;

        // swap astr to tokens to repay flashloan
        for (uint256 idx; idx < assets.length;) {
            address tokenB = assets[idx];
            uint256[] memory amountsIn = ROUTER.getAmountsIn(amounts[idx] + premiums[idx], pairToPath[wastrAddr][tokenB]);
            ROUTER.swapETHForExactTokens{value: amountsIn[0]}(
                amounts[idx] + premiums[idx],
                pairToPath[wastrAddr][tokenB],
                address(this),
                block.timestamp + 20 * 60
            );

            // approve amounts to lending pool to transfer debt
            uint256 amountOwing = amounts[idx] + premiums[idx];
            IERC20(assets[idx]).approve(address(LENDING_POOL), amountOwing);

            unchecked { ++idx; }
        }

        return true;
    }

    // function swapASTRtoTokens(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums)

    /* change visibility or access ❗️ */ function swapCollateralToASTR() public { 
        uint256 nastrBalance = ERC20(nastrAddr).balanceOf(address(this));
        uint256[] memory amounts = ArthswapLibrary.getAmountsOut(
            ROUTER.factory(),
            nastrBalance,
            pairToPath[nastrAddr][wastrAddr]
        );
        uint256 amountOutMin = amounts[1];
        ERC20(nastrAddr).approve(address(ROUTER), type(uint256).max);
        ROUTER.swapExactTokensForETH(
            nastrBalance,
            amountOutMin,
            pairToPath[nastrAddr][wastrAddr],
            address(this),
            block.timestamp + 20 * 60
        );
    }

    function mergeArraysAndCalcSumUSD(
        string[] memory _names,
        uint256[] memory _debts
    ) public view returns (DebtAsset[] memory, uint256) {
        uint256 len = _names.length;
        uint256 totalDebtUSD;
        DebtAsset[] memory debtAssets = new DebtAsset[](len);

        for (uint256 idx; idx < len;) {
            debtAssets[idx].name = _names[idx];
            debtAssets[idx].debt = _debts[idx];
            totalDebtUSD += adapter.toUSD(
                addrByName(debtAssets[idx].name),
                debtAssets[idx].debt
            );
            unchecked { ++idx; }
        }

        return (debtAssets, totalDebtUSD);
    }

    function fillAssetsToLiquidate(
        DebtAsset[] memory _sortedDebtAssets,
        uint256 _totalDebtUSD
    ) public view returns (address[] memory, uint256[] memory) {
        uint256 sumToLiquidateUSD = _totalDebtUSD / 2;
        uint256 collectedSumUSD; // sum to flashloan
        uint256 len = _sortedDebtAssets.length;

        address[] memory assetsUncut = new address[](len);
        uint256[] memory amountsUncut = new uint256[](len);

        for (uint256 idx; idx < len; ) {
            uint256 tokenBalUSD = getPriceUSD(_sortedDebtAssets[idx]);
            if (tokenBalUSD <= sumToLiquidateUSD - collectedSumUSD) {
                assetsUncut[idx] = addrByName(_sortedDebtAssets[idx].name);
                amountsUncut[idx] = _sortedDebtAssets[idx].debt;

                collectedSumUSD += tokenBalUSD;
            } else {
                uint256 amount = fromUSD(
                    _sortedDebtAssets[idx].name,
                    sumToLiquidateUSD - collectedSumUSD
                );

                assetsUncut[idx] = addrByName(_sortedDebtAssets[idx].name);
                amountsUncut[idx] = amount;

                collectedSumUSD += sumToLiquidateUSD - collectedSumUSD;
            }

            if (collectedSumUSD >= sumToLiquidateUSD) break;

            unchecked {
                ++idx;
            }
        }

        uint256 trueLen;
        for (uint256 idx; idx < len;) {
            if (amountsUncut[idx] != 0) trueLen++;
            unchecked { ++idx; }
        }

        address[] memory assets = new address[](trueLen);
        uint256[] memory amounts = new uint256[](trueLen);

        for (uint256 idx; idx < trueLen;) {
            assets[idx] = assetsUncut[idx];
            amounts[idx] = amountsUncut[idx];
            unchecked { ++idx; }
        }

        return (assets, amounts);
    }

    function flashloan(
        address[] memory _assets,
        uint256[] memory _amounts
    ) public {
        address receiverAddress = address(this);
        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        uint256[] memory modes = new uint256[](_assets.length);

        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 idx = 0; idx < _assets.length; idx++) {
            modes[idx] = 0;
        }

        LENDING_POOL.flashLoan(
            receiverAddress,
            _assets,
            _amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function setPath(address tokenA, address tokenB, address[] memory path) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenA != address(0) && tokenB != address(0), "Zero address alarm");
        require(path.length > 0, "Path shouldn't be empty");

        pairToPath[tokenA][tokenB] = path;
    }

    function toDescendingOrder(
        DebtAsset[] memory _assets
    ) public view returns (DebtAsset[] memory assets) {
        assets = _assets;
        uint256 len = assets.length;
        bool swapped = false;
        for (uint256 idx; idx < len - 1; ) {
            for (uint256 j; j < len - idx - 1; ) {
                if (getPriceUSD((assets[j])) < getPriceUSD(assets[j + 1])) {
                    swapped = true;
                    DebtAsset memory s = assets[j + 1];
                    assets[j + 1] = assets[j];
                    assets[j] = s;
                }
                unchecked {
                    ++j;
                }
            }

            if (!swapped) {
                return assets;
            }

            unchecked {
                ++idx;
            }
        }
    }

    function addrByName(
        string memory _name
    ) public view returns (address addr) {
        (, , addr, , , , , , , ) = assetManager.assetInfo(_name);
    }

    function getPriceUSD(
        DebtAsset memory _asset
    ) public view returns (uint256) {
        return adapter.toUSD(addrByName(_asset.name), _asset.debt);
    }

    function fromUSD(
        string memory _name,
        uint256 _amount
    ) public view returns (uint256) {
        return adapter.fromUSD(addrByName(_name), _amount);
    }

    /* withdraw balances below */

    function withdrawToken(
        address token,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Not enough tokens"
        );
        IERC20(token).transfer(msg.sender, amount);

        emit WithdrawToken(token, amount);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;

        require(balance > 0, "Zero balance");
        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    event SomeEvent(address caller);

    function eventEmitting() public {
        emit SomeEvent(msg.sender);
    }
}
