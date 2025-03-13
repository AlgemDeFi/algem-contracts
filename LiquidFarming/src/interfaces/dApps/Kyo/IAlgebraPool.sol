/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @dev Initialization should be done in one transaction with pool creation to avoid front-running
    /// @param initialPrice The initial sqrt price of the pool as a Q64.96
    function initialize(uint160 initialPrice) external;

    /// @notice Adds liquidity for the given recipient/bottomTick/topTick position
    /// @dev The caller of this method receives a callback in the form of IAlgebraMintCallback#algebraMintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on bottomTick, topTick, the amount of liquidity, and the current price.
    /// @param leftoversRecipient The address which will receive potential surplus of paid tokens
    /// @param recipient The address for which the liquidity will be created
    /// @param bottomTick The lower tick of the position in which to add liquidity
    /// @param topTick The upper tick of the position in which to add liquidity
    /// @param liquidityDesired The desired amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in
    /// the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in
    /// the callback
    /// @return liquidityActual The actual minted amount of liquidity
    function mint(
        address leftoversRecipient,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 liquidityDesired,
        bytes calldata data
    )
        external
        returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param bottomTick The lower tick of the position for which to collect fees
    /// @param topTick The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    )
        external
        returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param bottomTick The lower tick of the position for which to burn liquidity
    /// @param topTick The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @param data Any data that should be passed through to the plugin
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    )
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#algebraSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input (positive), or
    /// exact output (negative)
    /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback. If using the Router it should contain
    /// SwapRouter#SwapCallbackData
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes calldata data
    )
        external
        returns (int256 amount0, int256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0 with prepayment
    /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#algebraSwapCallback
    /// caller must send tokens in callback before swap calculation
    /// the actually sent amount of tokens is used for further calculations
    /// @param leftoversRecipient The address which will receive potential surplus of paid tokens
    /// @param recipient The address to receive the output of the swap
    /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountToSell The amount of the swap, only positive (exact input) amount allowed
    /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback. If using the Router it should contain
    /// SwapRouter#SwapCallbackData
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swapWithPaymentInAdvance(
        address leftoversRecipient,
        address recipient,
        bool zeroToOne,
        int256 amountToSell,
        uint160 limitSqrtPrice,
        bytes calldata data
    )
        external
        returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback#algebraFlashCallback
    /// @dev All excess tokens paid in the callback are distributed to currently in-range liquidity providers as an
    /// additional fee.
    /// If there are no in-range liquidity providers, the fee will be transferred to the first active provider in the
    /// future
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface IAlgebraPoolErrors {
    // ####  pool errors  ####

    /// @notice Emitted by the reentrancy guard
    error locked();

    /// @notice Emitted if arithmetic error occurred
    error arithmeticError();

    /// @notice Emitted if an attempt is made to initialize the pool twice
    error alreadyInitialized();

    /// @notice Emitted if an attempt is made to mint or swap in uninitialized pool
    error notInitialized();

    /// @notice Emitted if 0 is passed as amountRequired to swap function
    error zeroAmountRequired();

    /// @notice Emitted if invalid amount is passed as amountRequired to swap function
    error invalidAmountRequired();

    /// @notice Emitted if plugin fee param greater than fee/override fee
    error incorrectPluginFee();

    /// @notice Emitted if the pool received fewer tokens than it should have
    error insufficientInputAmount();

    /// @notice Emitted if there was an attempt to mint zero liquidity
    error zeroLiquidityDesired();
    /// @notice Emitted if actual amount of liquidity is zero (due to insufficient amount of tokens received)
    error zeroLiquidityActual();

    /// @notice Emitted if the pool received fewer tokens0 after flash than it should have
    error flashInsufficientPaid0();
    /// @notice Emitted if the pool received fewer tokens1 after flash than it should have
    error flashInsufficientPaid1();

    /// @notice Emitted if limitSqrtPrice param is incorrect
    error invalidLimitSqrtPrice();

    /// @notice Tick must be divisible by tickspacing
    error tickIsNotSpaced();

    /// @notice Emitted if a method is called that is accessible only to the factory owner or dedicated role
    error notAllowed();

    /// @notice Emitted if new tick spacing exceeds max allowed value
    error invalidNewTickSpacing();
    /// @notice Emitted if new community fee exceeds max allowed value
    error invalidNewCommunityFee();

    /// @notice Emitted if an attempt is made to manually change the fee value, but dynamic fee is enabled
    error dynamicFeeActive();
    /// @notice Emitted if an attempt is made by plugin to change the fee value, but dynamic fee is disabled
    error dynamicFeeDisabled();
    /// @notice Emitted if an attempt is made to change the plugin configuration, but the plugin is not connected
    error pluginIsNotConnected();
    /// @notice Emitted if a plugin returns invalid selector after hook call
    /// @param expectedSelector The expected selector
    error invalidHookResponse(bytes4 expectedSelector);

    // ####  LiquidityMath errors  ####

    /// @notice Emitted if liquidity underflows
    error liquiditySub();
    /// @notice Emitted if liquidity overflows
    error liquidityAdd();

    // ####  TickManagement errors  ####

    /// @notice Emitted if the topTick param not greater then the bottomTick param
    error topTickLowerOrEqBottomTick();
    /// @notice Emitted if the bottomTick param is lower than min allowed value
    error bottomTickLowerThanMIN();
    /// @notice Emitted if the topTick param is greater than max allowed value
    error topTickAboveMAX();
    /// @notice Emitted if the liquidity value associated with the tick exceeds MAX_LIQUIDITY_PER_TICK
    error liquidityOverflow();
    /// @notice Emitted if an attempt is made to interact with an uninitialized tick
    error tickIsNotInitialized();
    /// @notice Emitted if there is an attempt to insert a new tick into the list of ticks with incorrect indexes of the
    /// previous and next ticks
    error tickInvalidLinks();

    // ####  SafeTransfer errors  ####

    /// @notice Emitted if token transfer failed internally
    error transferFailed();

    // ####  TickMath errors  ####

    /// @notice Emitted if tick is greater than the maximum or less than the minimum allowed value
    error tickOutOfRange();
    /// @notice Emitted if price is greater than the maximum or less than the minimum allowed value
    error priceOutOfRange();
}

interface IAlgebraPoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swaps cannot be emitted by the pool before Initialize
    /// @param price The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 price, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param liquidityAmount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @param owner The owner of the position for which fees are collected
    /// @param recipient The address that received fees
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param liquidityAmount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    /// @param pluginFee The fee to be sent to the plugin
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1,
        uint24 pluginFee
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param price The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    /// @param overrideFee The fee to be applied to the trade
    /// @param pluginFee The fee to be sent to the plugin
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick,
        uint24 overrideFee,
        uint24 pluginFee
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted when the pool has higher balances than expected.
    /// Any excess of tokens will be distributed between liquidity providers as fee.
    /// @dev Fees after flash also will trigger this event due to mechanics of flash.
    /// @param amount0 The excess of token0
    /// @param amount1 The excess of token1
    event ExcessTokens(uint256 amount0, uint256 amount1);

    /// @notice Emitted when the community fee is changed by the pool
    /// @param communityFeeNew The updated value of the community fee in thousandths (1e-3)
    event CommunityFee(uint16 communityFeeNew);

    /// @notice Emitted when the tick spacing changes
    /// @param newTickSpacing The updated value of the new tick spacing
    event TickSpacing(int24 newTickSpacing);

    /// @notice Emitted when the plugin address changes
    /// @param newPluginAddress New plugin address
    event Plugin(address newPluginAddress);

    /// @notice Emitted when the plugin config changes
    /// @param newPluginConfig New plugin config
    event PluginConfig(uint8 newPluginConfig);

    /// @notice Emitted when the fee changes inside the pool
    /// @param fee The current fee in hundredths of a bip, i.e. 1e-6
    event Fee(uint16 fee);

    /// @notice Emitted when the community vault address changes
    /// @param newCommunityVault New community vault
    event CommunityVault(address newCommunityVault);

    /// @notice Emitted when the plugin does skim the excess of tokens
    /// @param to THe receiver of tokens (plugin)
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    event Skim(address indexed to, uint256 amount0, uint256 amount1);
}

interface IAlgebraPoolImmutables {
    /// @notice The Algebra factory contract, which must adhere to the IAlgebraFactory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

interface IAlgebraPoolPermissionedActions {
    /// @notice Set the community's % share of the fees. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
    /// @param newCommunityFee The new community fee percent in thousandths (1e-3)
    function setCommunityFee(uint16 newCommunityFee) external;

    /// @notice Set the new tick spacing values. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
    /// @param newTickSpacing The new tick spacing value
    function setTickSpacing(int24 newTickSpacing) external;

    /// @notice Set the new plugin address. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
    /// @param newPluginAddress The new plugin address
    function setPlugin(address newPluginAddress) external;

    /// @notice Set new plugin config. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
    /// @param newConfig In the new configuration of the plugin,
    /// each bit of which is responsible for a particular hook.
    function setPluginConfig(uint8 newConfig) external;

    /// @notice Set new community fee vault address. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
    /// @dev Community fee vault receives collected community fees.
    /// **accumulated but not yet sent to the vault community fees once will be sent to the `newCommunityVault`
    /// address**
    /// @param newCommunityVault The address of new community fee vault
    function setCommunityVault(address newCommunityVault) external;

    /// @notice Set new pool fee. Can be called by owner if dynamic fee is disabled.
    /// Called by the plugin if dynamic fee is enabled
    /// @param newFee The new fee value
    function setFee(uint16 newFee) external;

    /// @notice Forces balances to match reserves. Excessive tokens will be distributed between active LPs
    /// @dev Only plugin can call this function
    function sync() external;

    /// @notice Forces balances to match reserves. Excessive tokens will be sent to msg.sender
    /// @dev Only plugin can call this function
    function skim() external;
}

interface IAlgebraPoolState {
    /// @notice Safely get most important state values of Algebra Integral AMM
    /// @dev Several values exposed as a single method to save gas when accessed externally.
    /// **Important security note: this method checks reentrancy lock and should be preferred in most cases**.
    /// @return sqrtPrice The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value
    /// @return tick The current global tick of the pool. May not always be equal to
    /// SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary
    /// @return lastFee The current (last known) pool fee value in hundredths of a bip, i.e. 1e-6 (so '100' is '0.01%').
    /// May be obsolete if using dynamic fee plugin
    /// @return pluginConfig The current plugin config as bitmap. Each bit is responsible for enabling/disabling the
    /// hooks, the last bit turns on/off dynamic fees logic
    /// @return activeLiquidity  The currently in-range liquidity available to the pool
    /// @return nextTick The next initialized tick after current global tick
    /// @return previousTick The previous initialized tick before (or at) current global tick
    function safelyGetStateOfAMM()
        external
        view
        returns (
            uint160 sqrtPrice,
            int24 tick,
            uint16 lastFee,
            uint8 pluginConfig,
            uint128 activeLiquidity,
            int24 nextTick,
            int24 previousTick
        );

    /// @notice Allows to easily get current reentrancy lock status
    /// @dev can be used to prevent read-only reentrancy.
    /// This method just returns `globalState.unlocked` value
    /// @return unlocked Reentrancy lock flag, true if the pool currently is unlocked, otherwise - false
    function isUnlocked() external view returns (bool unlocked);

    // ! IMPORTANT security note: the pool state can be manipulated.
    // ! The following methods do not check reentrancy lock themselves.

    /// @notice The globalState structure in the pool stores many values but requires only one slot
    /// and is exposed as a single method to save gas when accessed externally.
    /// @dev **important security note: caller should check `unlocked` flag to prevent read-only reentrancy**
    /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary
    /// @return lastFee The current (last known) pool fee value in hundredths of a bip, i.e. 1e-6 (so '100' is '0.01%').
    /// May be obsolete if using dynamic fee plugin
    /// @return pluginConfig The current plugin config as bitmap. Each bit is responsible for enabling/disabling the
    /// hooks, the last bit turns on/off dynamic fees logic
    /// @return communityFee The community fee represented as a percent of all collected fee in thousandths, i.e. 1e-3
    /// (so 100 is 10%)
    /// @return unlocked Reentrancy lock flag, true if the pool currently is unlocked, otherwise - false
    function globalState()
        external
        view
        returns (uint160 price, int24 tick, uint16 lastFee, uint8 pluginConfig, uint16 communityFee, bool unlocked);

    /// @notice Look up information about a specific tick in the pool
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @param tick The tick to look up
    /// @return liquidityTotal The total amount of position liquidity that uses the pool either as tick lower or tick
    /// upper
    /// @return liquidityDelta How much liquidity changes when the pool price crosses the tick
    /// @return prevTick The previous tick in tick list
    /// @return nextTick The next tick in tick list
    /// @return outerFeeGrowth0Token The fee growth on the other side of the tick from the current tick in token0
    /// @return outerFeeGrowth1Token The fee growth on the other side of the tick from the current tick in token1
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint256 liquidityTotal,
            int128 liquidityDelta,
            int24 prevTick,
            int24 nextTick,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token
        );

    /// @notice The timestamp of the last sending of tokens to vault/plugin
    /// @return The timestamp truncated to 32 bits
    function lastFeeTransferTimestamp() external view returns (uint32);

    /// @notice The amounts of token0 and token1 that will be sent to the vault
    /// @dev Will be sent FEE_TRANSFER_FREQUENCY after communityFeeLastTimestamp
    /// @return communityFeePending0 The amount of token0 that will be sent to the vault
    /// @return communityFeePending1 The amount of token1 that will be sent to the vault
    function getCommunityFeePending()
        external
        view
        returns (uint128 communityFeePending0, uint128 communityFeePending1);

    /// @notice The amounts of token0 and token1 that will be sent to the plugin
    /// @dev Will be sent FEE_TRANSFER_FREQUENCY after feeLastTransferTimestamp
    /// @return pluginFeePending0 The amount of token0 that will be sent to the plugin
    /// @return pluginFeePending1 The amount of token1 that will be sent to the plugin
    function getPluginFeePending() external view returns (uint128 pluginFeePending0, uint128 pluginFeePending1);

    /// @notice Returns the address of currently used plugin
    /// @dev The plugin is subject to change
    /// @return pluginAddress The address of currently used plugin
    function plugin() external view returns (address pluginAddress);

    /// @notice The contract to which community fees are transferred
    /// @return communityVaultAddress The communityVault address
    function communityVault() external view returns (address communityVaultAddress);

    /// @notice Returns 256 packed tick initialized boolean values. See TickTree for more information
    /// @param wordPosition Index of 256-bits word with ticks
    /// @return The 256-bits word with packed ticks info
    function tickTable(int16 wordPosition) external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the
    /// pool
    /// @dev This value can overflow the uint256
    /// @return The fee growth accumulator for token0
    function totalFeeGrowth0Token() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the
    /// pool
    /// @dev This value can overflow the uint256
    /// @return The fee growth accumulator for token1
    function totalFeeGrowth1Token() external view returns (uint256);

    /// @notice The current pool fee value
    /// @dev In case dynamic fee is enabled in the pool, this method will call the plugin to get the current fee.
    /// If the plugin implements complex fee logic, this method may return an incorrect value or revert.
    /// In this case, see the plugin implementation and related documentation.
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return currentFee The current pool fee value in hundredths of a bip, i.e. 1e-6
    function fee() external view returns (uint16 currentFee);

    /// @notice The tracked token0 and token1 reserves of pool
    /// @dev If at any time the real balance is larger, the excess will be transferred to liquidity providers as
    /// additional fee.
    /// If the balance exceeds uint128, the excess will be sent to the communityVault.
    /// @return reserve0 The last known reserve of token0
    /// @return reserve1 The last known reserve of token1
    function getReserves() external view returns (uint128 reserve0, uint128 reserve1);

    /// @notice Returns the information about a position by the position's key
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @param key The position's key is a packed concatenation of the owner address, bottomTick and topTick indexes
    /// @return liquidity The amount of liquidity in the position
    /// @return innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke
    /// @return innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke
    /// @return fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke
    /// @return fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint256 liquidity,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks.
    /// Returned value cannot exceed type(uint128).max
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return The current in range liquidity
    function liquidity() external view returns (uint128);

    /// @notice The current tick spacing
    /// @dev Ticks can only be initialized by new mints at multiples of this value
    /// e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
    /// However, tickspacing can be changed after the ticks have been initialized.
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The current tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The previous initialized tick before (or at) current global tick
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return The previous initialized tick
    function prevTickGlobal() external view returns (int24);

    /// @notice The next initialized tick after current global tick
    /// @dev **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return The next initialized tick
    function nextTickGlobal() external view returns (int24);

    /// @notice The root of tick search tree
    /// @dev Each bit corresponds to one node in the second layer of tick tree: '1' if node has at least one active bit.
    /// **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return The root of tick search tree as bitmap
    function tickTreeRoot() external view returns (uint32);

    /// @notice The second layer of tick search tree
    /// @dev Each bit in node corresponds to one node in the leafs layer (`tickTable`) of tick tree: '1' if leaf has at
    /// least one active bit.
    /// **important security note: caller should check reentrancy lock to prevent read-only reentrancy**
    /// @return The node of tick search tree second layer
    function tickTreeSecondLayer(int16) external view returns (uint256);
}

interface IAlgebraPool is
    IAlgebraPoolImmutables,
    IAlgebraPoolState,
    IAlgebraPoolActions,
    IAlgebraPoolPermissionedActions,
    IAlgebraPoolEvents,
    IAlgebraPoolErrors
{
// used only for combining interfaces
}
