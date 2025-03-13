//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

abstract contract V3Caller0 {
    struct PositionParameters {
        uint24 fee;
        uint160 priceLimit;
        int24 tickL;
        int24 tickU;
        int24 tickS;
    }

    PositionParameters public positionParameters;

    address public WRAPPED;
    address public pairToken;
    bool public isWtoken0;

    IUniswapV3Pool public v3pool;

    /// @notice uniswapV3Pool callback
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(msg.sender == address(v3pool));
        if (amount0 > 0) IERC20(isWtoken0 ? WRAPPED : pairToken).transfer(msg.sender, amount0);
        if (amount1 > 0) IERC20(isWtoken0 ? pairToken : WRAPPED).transfer(msg.sender, amount1);
    }

    /// @notice uniswapV3Pool callback
    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
        require(msg.sender == address(v3pool));
        if (amount0 > 0) IERC20(isWtoken0 ? WRAPPED : pairToken).transfer(msg.sender, uint256(amount0));
        if (amount1 > 0) IERC20(isWtoken0 ? pairToken : WRAPPED).transfer(msg.sender, uint256(amount1));
    }

    /// @notice collect tokens from v3 pool
    /// @param _amount0 desired
    /// @param _amount1 desired
    /// @return amount0_ actual
    /// @return amount1_ actual
    function collect(uint128 _amount0, uint128 _amount1) internal returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) = v3pool.collect(
            address(this),
            positionParameters.tickL,
            positionParameters.tickU,
            isWtoken0 ? _amount1 : _amount0,
            isWtoken0 ? _amount0 : _amount1
        );
        if (isWtoken0) return (amount1, amount0);
        else return (amount0, amount1);
    }

    /// @notice increase position liquidity
    /// @param _amount0 to add
    /// @param _amount1 to add
    /// @return amount0_ actually added
    /// @return amount1_ actually added
    function increaseLiquidity(uint256 _amount0, uint256 _amount1) internal returns (uint256, uint256) {
        uint128 l = calculateAddLiquidity(_amount0, _amount1);
        (uint256 amount0, uint256 amount1) = v3pool.mint(
            address(this),
            positionParameters.tickL,
            positionParameters.tickU,
            l,
            abi.encode(address(this))
        );
        if (isWtoken0) return (amount1, amount0);
        else return (amount0, amount1);
    }

    /// @notice decrease position liquidity
    /// @param _liquidity to burn
    /// @return amount0_ returned
    /// @return amount1_ returned
    function decreaseLiquidity(uint128 _liquidity) internal returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) =
            v3pool.burn(positionParameters.tickL, positionParameters.tickU, _liquidity);
        return collect(isWtoken0 ? uint128(amount1) : uint128(amount0), isWtoken0 ? uint128(amount0) : uint128(amount1));
    }

    /// @notice swap tokens
    /// @param _amountIn exact input (positive), or exact output (negative)
    /// @param _toWrapped true if buying WRAPPED paid in pairToken, false otherwise
    /// @return amount0_ delta balance of the pool (pairToken)
    /// @return amount1_ delta balance of the pool (WRAPPED)
    function swap(int256 _amountIn, bool _toWrapped) internal returns (int256 amount0_, int256 amount1_) {
        if (isWtoken0) _toWrapped = !_toWrapped;
        uint160 price = getPrice();
        (amount0_, amount1_) = v3pool.swap(
            address(this),
            _toWrapped,
            _amountIn,
            _toWrapped
                ? price - price / 100 * positionParameters.priceLimit
                : price + price / 100 * positionParameters.priceLimit,
            abi.encode(address(this))
        );
        if (isWtoken0) (amount0_, amount1_) = (amount1_, amount0_);
    }

    /// @notice Get the info of the given position
    /// @return liquidity_ The amount of liquidity of the position
    /// @return tokensOwed0_ Amount of token0 owed
    /// @return tokensOwed1_ Amount of token1 owed
    function _position() internal view returns (uint256, uint128, uint128) {
        /// @dev for some reason using abi.encodePacked does not work for this dApp
        bytes32 pk = keccak256(abi.encodePacked(address(this), positionParameters.tickL, positionParameters.tickU));
        (uint256 liquidity,,, uint128 tokensOwed0, uint128 tokensOwed1) = v3pool.positions(pk);
        if (isWtoken0) return (liquidity, tokensOwed1, tokensOwed0);
        else return (liquidity, tokensOwed0, tokensOwed1);
    }

    /// @notice calculate the amount of liquidity for given amounts
    /// @param _amount0 token amount
    /// @param _amount1 wrapped amount
    /// @return liquidity_ amount of liquidity
    function calculateAddLiquidity(uint256 _amount0, uint256 _amount1) public view returns (uint128 liquidity_) {
        uint160 sqrtRatioX96 = getPrice();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(positionParameters.tickL);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(positionParameters.tickU);

        liquidity_ = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, isWtoken0 ? _amount1 : _amount0, isWtoken0 ? _amount0 : _amount1
        );
    }

    /// @notice calculate the amount of tokens for given liquidity
    /// @param _liquidity amount of liquidity
    /// @return amounts_ [0] - pairToken amount, [1] - wrapped amount
    function calculateRemoveLiquidity(uint128 _liquidity) public view returns (uint256[2] memory amounts_) {
        uint160 sqrtRatioX96 = getPrice();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(positionParameters.tickL);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(positionParameters.tickU);

        (amounts_[0], amounts_[1]) =
            LiquidityAmounts.getAmountsForLiquidity(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, _liquidity);
        if (isWtoken0) (amounts_[0], amounts_[1]) = (amounts_[1], amounts_[0]);
    }

    /// @notice calculate pair price based on sqrtPrice
    /// @param _sqrtRatioX96 current x96 price
    /// @param _baseAmount amount in
    /// @param _inverse true for wrapped -> pairToken
    /// @return quoteAmount_ amount out
    function getQuoteFromSqrtRatioX96(
        uint160 _sqrtRatioX96,
        uint128 _baseAmount,
        bool _inverse
    )
        internal
        pure
        returns (uint256 quoteAmount_)
    {
        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (_sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(_sqrtRatioX96) * _sqrtRatioX96;
            quoteAmount_ = !_inverse
                ? FullMath.mulDiv(ratioX192, _baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, _baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(_sqrtRatioX96, _sqrtRatioX96, 1 << 64);
            quoteAmount_ = !_inverse
                ? FullMath.mulDiv(ratioX128, _baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, _baseAmount, ratioX128);
        }
    }

    /// @notice convert price at given tick
    /// @param _tick to calculate
    /// @return uint256 amount of pairTokens for 1 WRAPPED
    function getPriceAtTick(int24 _tick) external view returns (uint256) {
        return getQuoteFromSqrtRatioX96(TickMath.getSqrtRatioAtTick(_tick), 1 ether, !isWtoken0);
    }

    /// @notice returns optimal amounts based on input token amounts
    /// @param _amount0 input token0
    /// @param _amount1 input token1
    /// @return amount0_ optimal token0
    /// @return amount1_ optimal token1
    function getInputAmounts(
        uint256 _amount0,
        uint256 _amount1
    )
        public
        view
        returns (uint256 amount0_, uint256 amount1_)
    {
        uint256[2] memory a = calculateRemoveLiquidity(calculateAddLiquidity(_amount0, _amount1));
        amount0_ = a[0];
        amount1_ = a[1];
    }

    /// @notice get equal amount of token based on price
    /// @param _baseAmount amount in
    /// @param _toWrapped true if token -> wrapped needed
    /// @return amount_ amount out
    function getSecondAmount(uint128 _baseAmount, bool _toWrapped) public view returns (uint256 amount_) {
        amount_ = getQuoteFromSqrtRatioX96(getPrice(), _baseAmount, isWtoken0 ? _toWrapped : !_toWrapped);
    }

    /// @notice helper function to get price from slot0()
    /// @return price from pool.slot0()
    function getPrice() internal view returns (uint160 price) {
        (price,,,,,,) = v3pool.slot0();
    }
}
