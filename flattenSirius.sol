// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol@v4.7.1

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/interfaces/ISiriusFarm.sol


pragma solidity 0.8.4;

interface ISiriusFarm {
    function deposit(
        uint256 value,
        address account,
        bool _claimRewards
    ) external;

    function withdraw(uint256 value, bool _claimRewards) external;

    function claimRewards(address _addr, address _receiver) external;

    function claimableTokens(address _addr) external returns (uint256);
}


// File contracts/interfaces/ISiriusPool.sol


pragma solidity 0.8.4;

interface ISiriusPool {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] memory minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityImbalance(
        uint256[] memory amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityOneCoin(
        uint256 tokenAmount,
        uint256 tokenIndex,
        uint256 minAmount,
        address receiver
    ) external;

    function getA() external view returns (uint8 A);

    function getVirtualPrice() external view returns (uint);

    function getTokenBalance(uint8) external view returns (uint);

    function getTokenIndex(
        address tokenAddress
    ) external view returns (uint8 tokenIndex);

    function calculateTokenAmount(
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(
        uint256 amount
    ) external view returns (uint256[] memory);
}


// File contracts/interfaces/IMinter.sol


pragma solidity 0.8.4;

interface IMinter {
    function mint(address gaugeToken) external;
}


// File contracts/interfaces/IAdaptersDistributor.sol


pragma solidity 0.8.4;

interface IAdaptersDistributor {
    function getUserBalanceInAdapters(
        address user
    ) external view returns (uint256);

    function updateBalanceInAdapter(
        string memory _adapter,
        address user,
        uint256 amountAfter
    ) external;
}


// File @openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol@v4.7.1


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol@v4.7.1


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/proxy/Proxy.sol@v4.7.0


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}


// File contracts/interfaces/DappsStaking.sol



pragma solidity >=0.7.0;

/// Interface to the precompiled contract on Shibuya/Shiden/Astar
/// Predeployed at the address 0x0000000000000000000000000000000000005001
interface DappsStaking {
    // Storage getters

    /// @notice Read current era.
    /// @return era, The current era
    function read_current_era() external view returns (uint256);

    /// @notice Read unbonding period constant.
    /// @return period, The unbonding period in eras
    function read_unbonding_period() external view returns (uint256);

    /// @notice Read Total network reward for the given era
    /// @return reward, Total network reward for the given era
    function read_era_reward(uint32 era) external view returns (uint128);

    /// @notice Read Total staked amount for the given era
    /// @return staked, Total staked amount for the given era
    function read_era_staked(uint32 era) external view returns (uint128);

    /// @notice Read Staked amount for the staker
    /// @param staker in form of 20 or 32 hex bytes
    /// @return amount, Staked amount by the staker
    function read_staked_amount(
        bytes calldata staker
    ) external view returns (uint128);

    /// @notice Read Staked amount on a given contract for the staker
    /// @param contract_id contract evm address
    /// @param staker in form of 20 or 32 hex bytes
    /// @return amount, Staked amount by the staker
    function read_staked_amount_on_contract(
        address contract_id,
        bytes calldata staker
    ) external view returns (uint128);

    /// @notice Read the staked amount from the era when the amount was last staked/unstaked
    /// @return total, The most recent total staked amount on contract
    function read_contract_stake(
        address contract_id
    ) external view returns (uint128);

    // Extrinsic calls

    /// @notice Register provided contract.
    function register(address) external;

    /// @notice Stake provided amount on the contract.
    function bond_and_stake(address, uint128) external;

    /// @notice Start unbonding process and unstake balance from the contract.
    function unbond_and_unstake(address, uint128) external;

    /// @notice Withdraw all funds that have completed the unbonding process.
    function withdraw_unbonded() external;

    /// @notice Claim one era of unclaimed staker rewards for the specifeid contract.
    ///         Staker account is derived from the caller address.
    function claim_staker(address) external;

    /// @notice Claim one era of unclaimed dapp rewards for the specified contract and era.
    function claim_dapp(address, uint128) external;

    /// Instruction how to handle reward payout for staker.
    /// `FreeBalance` - Reward will be paid out to the staker (free balance).
    /// `StakeBalance` - Reward will be paid out to the staker and is immediately restaked (locked balance)
    enum RewardDestination {
        FreeBalance,
        StakeBalance
    }

    /// @notice Set reward destination for staker rewards
    /// @param reward_destination instruction on how the reward payout should be handled
    function set_reward_destination(
        RewardDestination reward_destination
    ) external;

    /// @notice Withdraw staked funds from an unregistered contract.
    /// @param smart_contract smart contract address
    function withdraw_from_unregistered(address smart_contract) external;

    /// @notice Transfer part or entire nomination from origin smart contract to target smart contract
    /// @param origin_smart_contract origin smart contract address
    /// @param amount amount to transfer from origin to target
    /// @param target_smart_contract target smart contract address
    function nomination_transfer(
        address origin_smart_contract,
        uint128 amount,
        address target_smart_contract
    ) external;
}


// File contracts/interfaces/IDNT.sol


pragma solidity 0.8.4;

// @notice DNT token contract interface
interface IDNT {
    function mintNote(
        address to,
        uint256 amount,
        string memory utility
    ) external;

    function burnNote(
        address account,
        uint256 amount,
        string memory utility
    ) external;

    function snapshot() external returns (uint256);

    function pause() external;

    function unpause() external;

    function transferOwnership(address to) external;

    function balanceOf(address account) external view returns (uint256);

    function balanceOfAt(
        address account,
        uint256 snapshotId
    ) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}


// File contracts/interfaces/ILiquidStaking.sol


pragma solidity 0.8.4;

interface ILiquidStaking {
    function addStaker(address, string memory) external;

    function isStaker(address) external view returns (bool);

    function currentEra() external view returns (uint);

    function updateUserBalanceInUtility(string memory, address) external;

    function updateUserBalanceInAdapter(string memory, address) external;

    function REVENUE_FEE() external view returns (uint8);

    function sync(uint256 _era) external;
}


// File contracts/NDistributor.sol


pragma solidity 0.8.4;






/*
 * @notice ERC20 DNT token distributor contract
 *
 * Features:
 * - Initializable
 * - AccessControlUpgradeable
 */
contract NDistributor is Initializable, AccessControlUpgradeable {
    // DECLARATIONS
    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- USER MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice describes DntAsset structure
    // @dev    dntInUtil => describes how many DNTs are attached to specific utility
    struct DntAsset {
        mapping(string => uint256) dntInUtil;
        string[] userUtils;
        uint256 dntLiquid; // <= will be removed in the next update
    }

    // @notice describes user structure
    // @dev    dnt => tracks specific DNT token
    struct User {
        mapping(string => DntAsset) dnt;
        string[] userDnts;
        string[] userUtilities;
    }

    // @dev    users => describes the user and his portfolio
    mapping(address => User) users;

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- UTILITY MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice describes utility (Algem offer\opportunity) struct
    struct Utility {
        string utilityName;
        bool isActive;
    }

    // @notice keeps track of all utilities
    Utility[] public utilityDB;

    // @notice allows to list and display all utilities
    string[] public utilities;

    // @notice keeps track of utility ids
    mapping(string => uint) public utilityId;

    // -------------------------------------------------------------------------------------------------------
    // -------------------------------- DNT TOKENS MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice defidescribesnes DNT token struct
    struct Dnt {
        string dntName;
        bool isActive;
    }

    // @notice keeps track of all DNTs
    Dnt[] public dntDB;

    // @notice allows to list and display all DNTs
    string[] public dnts;

    // @notice keeps track of DNT ids
    mapping(string => uint) public dntId;

    // @notice DNT token contract interface
    IDNT DNTContract;

    // @notice stores DNT contract addresses
    mapping(string => address) public dntContracts;

    // -------------------------------------------------------------------------------------------------------
    // -------------------------------- ACCESS CONTROL ROLES
    // -------------------------------------------------------------------------------------------------------

    // @notice stores current contract owner
    address public owner;

    // @notice stores addresses with privileged access
    address[] public managers;
    mapping(address => uint256) public managerIds;

    // @notice manager contract role
    bytes32 public constant MANAGER = keccak256("MANAGER");

    ILiquidStaking liquidStaking;
    mapping(address => bool) private isPool;

    mapping(string => bool) public disallowList;
    mapping(string => uint) public totalDntInUtil;

    mapping(string => bool) public isUtility;

    // @notice thanks to this varibale the func setup() will be called only once
    bool private isCalled;

    // @notice needed to show if the user has dnt
    mapping(address => mapping(string => bool)) public userHasDnt;

    // @notice needed to show if the user has utility
    mapping(address => mapping(string => bool)) public userHasUtility;

    mapping(address => mapping(string => uint256)) public userUtitliesIdx;
    mapping(address => mapping(string => uint256)) public userDntsIdx;

    // @notice needed to implement grant/claim ownership pattern
    address private _grantedOwner;

    mapping(string => uint256) public totalDnt;

    // @notice needed to update user utility indices
    mapping(address => bool) utilityIdxsUpdated;

    bytes32 public constant MANAGER_CONTRACT = keccak256("MANAGER_CONTRACT");

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _amount,
        string _utility,
        string indexed _dnt
    );
    event IssueDnt(
        address indexed _to,
        uint indexed _amount,
        string _utility,
        string indexed _dnt
    );

    event ChangeDntAddress(string indexed dnt, address indexed addr);
    event SetUtilityStatus(uint256 indexed id, bool indexed state, string indexed utilityName);
    event SetDntStatus(uint256 indexed id, bool indexed state, string indexed dntName);
    event SetLiquidStaking(address indexed liquidStakingAddress);
    event TransferDntContractOwnership(address indexed to, string indexed dnt);
    event AddUtility(string indexed newUtility);
    event OwnershipTransferred(address indexed owner, address indexed grantedOwner);

    using AddressUpgradeable for address;
    using StringsUpgradeable for string;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);
        owner = msg.sender;

        // empty utility needs to start indexing from 1 instead of 0
        // utilities will exclude the "empty" utility,
        // and the index will differ from the one in utilityDB
        utilityDB.push(Utility("empty", false));
        dntDB.push(Dnt("empty", false));

        utilityDB.push(Utility("null", true));
        utilityId["null"] = 1;
        utilities.push("null");
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- MODIFIERS
    // -------------------------------------------------------------------------------------------------------
    modifier dntInterface(string memory _dnt) {
        _setDntInterface(_dnt);
        _;
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Role managment
    // -------------------------------------------------------------------------------------------------------

    /// @notice propose a new owner
    /// @param _newOwner => new contract owner
    function grantOwnership(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOwner != address(0), "Zero address alarm!");
        require(_newOwner != owner, "Trying to set the same owner");
        _grantedOwner = _newOwner;
    }

    /// @notice claim ownership by granted address
    function claimOwnership() external {
        require(_grantedOwner == msg.sender, "Caller is not the granted owner");
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
        emit OwnershipTransferred(owner, _grantedOwner);
    }

    /// @notice returns the list of all managers
    function listManagers() external view returns (address[] memory) {
        return managers;
    }

    /// @notice adds manager role
    /// @param _newManager => new manager to add
    function addManager(address _newManager)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newManager != address(0), "Zero address alarm!");
        require(!hasRole(MANAGER, _newManager), "Allready manager");
        managerIds[_newManager] = managers.length;
        managers.push(_newManager);
        _grantRole(MANAGER, _newManager);
    }

    /// @notice removes manager role
    /// @param _manager => new manager to remove
    function removeManager(address _manager)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(hasRole(MANAGER, _manager), "Address is not a manager");
        uint256 id = managerIds[_manager];

        // delete managers[id];
        managers[id] = managers[managers.length - 1];
        managers.pop();

        _revokeRole(MANAGER, _manager);
        managerIds[_manager] = 0;
        managerIds[managers[id]] = id;
    }

    /// @notice removes manager role
    /// @param _oldAddress => old manager address
    /// @param _newAddress => new manager address
    function changeManagerAddress(address _oldAddress, address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newAddress != address(0), "Zero address alarm!");
        removeManager(_oldAddress);
        addManager(_newAddress);
    }

    function addUtilityToDisallowList(string memory _utility)
        external
        onlyRole(MANAGER)
    {
        disallowList[_utility] = true;
    }

    function removeUtilityFromDisallowList(string memory _utility)
        public
        onlyRole(MANAGER)
    {
        disallowList[_utility] = false;
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Asset managment (utilities and DNTs tracking)
    // -------------------------------------------------------------------------------------------------------

    /// @notice returns the list of all utilities
    function listUtilities() external view returns (string[] memory) {
        return utilities;
    }

    /// @notice returns the list of all DNTs
    function listDnts() external view returns (string[] memory) {
        return dnts;
    }

    /// @notice adds new utility to the DB, activates it by default
    /// @param _newUtility => name of the new utility
    function addUtility(string memory _newUtility)
        external
        onlyRole(MANAGER)
    {
        require(!isUtility[_newUtility], "Utility already added");
        uint lastId = utilityDB.length;
        utilityId[_newUtility] = lastId;
        utilityDB.push(Utility(_newUtility, true));
        utilities.push(_newUtility);
        isUtility[_newUtility] = true;

        emit AddUtility(_newUtility);
    }

    /// @notice allows to change DNT asset contract address
    /// @param _dnt => name of the DNT
    /// @param _address => new address
    function changeDntAddress(string memory _dnt, address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address.isContract(), "_address should be contract address");
        dntContracts[_dnt] = _address;

        emit ChangeDntAddress(_dnt, _address);
    }

    /// @notice allows to activate\deactivate utility
    /// @param _id => utility id
    /// @param _state => desired state
    function setUtilityStatus(uint256 _id, bool _state)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_id < utilityDB.length, "Not found utility with such id!");
        utilityDB[_id].isActive = _state;
        emit SetUtilityStatus(_id, _state, utilityDB[_id].utilityName);
    }

    /// @notice allows to activate\deactivate DNT
    /// @param _id => DNT id
    /// @param _state => desired state
    function setDntStatus(uint256 _id, bool _state)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_id < dntDB.length, "Not found dnt with such id");
        dntDB[_id].isActive = _state;
        emit SetDntStatus(_id, _state, dntDB[_id].dntName);
    }

    /// @notice returns a list of user's DNT tokens in possession
    /// @param _user => user address
    /// @return userDnts => all user dnts
    function listUserDnts(address _user) external view returns (string[] memory) {
        require(_user != address(0), "Shouldn't be zero address");


        return users[_user].userDnts;
    }

    /// @notice returns user utilities by DNT
    /// @param _user => user address
    /// @param _dnt => dnt name
    /// @return userUtils => all user utils in dnt
    function listUserUtilitiesInDnt(address _user, string memory _dnt) public view returns (string[] memory) {
        require(_user != address(0), "Shouldn't be zero address");

        return users[_user].dnt[_dnt].userUtils;
    }

    /// @notice returns user dnt balances in utilities
    /// @param _user => user address
    /// @param _dnt => dnt name
    /// @return dntBalances => dnt balances in utils
    /// @return usrUtils => all user utils in dnt
    function listUserDntInUtils(address _user, string memory _dnt) external view returns (string[] memory, uint256[] memory) {
        require(_user != address(0), "Shouldn't be zero address");

        string[] memory _utilities = listUserUtilitiesInDnt(_user, _dnt);

        uint256 l = _utilities.length;
        require(l > 0, "Have no used utilities");

        DntAsset storage _dntAsset = users[_user].dnt[_dnt];
        uint256[] memory _dnts = new uint256[](l);

        for (uint256 i; i < l; i++) {
            _dnts[i] = _dntAsset.dntInUtil[_utilities[i]];
        }
        return (_utilities, _dnts);
    }

    /// @notice returns ammount of DNT toknes of user in utility
    /// @param _user => user address
    /// @param _util => utility name
    /// @param _dnt => DNT token name
    /// @return dntBalance => user dnt balance in util
    function getUserDntBalanceInUtil(
        address _user,
        string memory _util,
        string memory _dnt
    ) external view returns (uint256) {
        require(_user != address(0), "Shouldn't be zero address");
        return users[_user].dnt[_dnt].dntInUtil[_util];
    }


    /// @notice returns user's DNT balance
    /// @param _user => user address
    /// @param _dnt => DNT token name
    /// @return dntBalance => current user balance in dnt
    function getUserDntBalance(address _user, string memory _dnt)
        external
        dntInterface(_dnt)
        returns (uint256)
    {
        return DNTContract.balanceOf(_user);
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Distribution logic
    // -------------------------------------------------------------------------------------------------------

    /// @notice add to user dnt and util if he doesn't have them
    /// @param _to => user address
    /// @param _dnt => dnt name
    /// @param _utility => util name
    function _addToUser(
        address _to, 
        string memory _dnt, 
        string memory _utility
    ) internal {
        if (!userHasDnt[_to][_dnt]) _addDntToUser(_dnt, users[_to].userDnts, _to);
        if (!userHasUtility[_to][_utility]) _addUtilityToUser(_utility, _dnt, _to);
    }

    /// @notice remove from user dnt and util if he has them
    /// @param _account => user address
    /// @param _dnt => dnt name
    /// @param _utility => util name
    function _removeFromUser(
        address _account, 
        string memory _dnt, 
        string memory _utility
    ) internal {
        if (userHasUtility[_account][_utility]) _removeUtilityFromUser(_utility, _dnt, _account);
        if (userHasDnt[_account][_dnt] && users[_account].dnt[_dnt].userUtils.length == 0) _removeDntFromUser(_dnt, users[_account].userDnts, _account);
    }

    /// @notice issues new tokens
    /// @param _to => token recepient
    /// @param _amount => amount of tokens to mint
    /// @param _utility => minted dnt utility
    /// @param _dnt => minted dnt
    function issueDnt(
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external dntInterface(_dnt) {
        require(_amount > 0, "Amount should be greater than zero");
        require(_to != address(0), "Zero address alarm!");
        require(msg.sender == address(liquidStaking), "Only for LiquidStaking");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        totalDnt[_dnt] += _amount;
        totalDntInUtil[_utility] += _amount;

        DNTContract.mintNote(_to, _amount, _utility);

        emit IssueDnt(_to, _amount, _utility, _dnt);
    }

    /// @notice issues new transfer tokens
    /// @param _to => token recepient
    /// @param _amount => amount of tokens to mint
    /// @param _utility => minted dnt utility
    /// @param _dnt => minted dnt
    function issueTransferDnt(
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) private dntInterface(_dnt) {
        require(_amount > 0, "Amount should be greater than zero");
        require(_to != address(0), "Zero address alarm!");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        _addToUser(_to, _dnt, _utility);
        
        users[_to].dnt[_dnt].dntInUtil[_utility] += _amount;
        liquidStaking.updateUserBalanceInUtility(_utility, _to);
    }


    /// @notice adds dnt string to user array of dnts for tracking which assets are in possession
    /// @param _dnt => name of the dnt token
    /// @param localUserDnts => array of user's dnts
    function _addDntToUser(string memory _dnt, string[] storage localUserDnts, address _user)
        internal
        onlyRole(MANAGER)
    {
        require(dntDB[dntId[_dnt]].isActive == true, "Invalid DNT!");
        userHasDnt[_user][_dnt] = true;

        localUserDnts.push(_dnt);
        userDntsIdx[_user][_dnt] = localUserDnts.length - 1;
    }

    /// @notice adds utility string to user array of utilities for tracking which assets are in possession
    /// @param _utility => name of the utility token
    /// @param _dnt => dnt name
    function _addUtilityToUser(
        string memory _utility,
        string memory _dnt,
        address _user
    ) internal onlyRole(MANAGER) {
        uint id = utilityId[_utility];
        require(utilityDB[id].isActive == true, "Invalid utility!");

        userHasUtility[_user][_utility] = true;

        users[_user].dnt[_dnt].userUtils.push(_utility);
        userUtitliesIdx[_user][_utility] = users[_user].dnt[_dnt].userUtils.length - 1;
    }

    /// @notice removes tokens from circulation
    /// @param _account => address to burn from
    /// @param _amount => amount of tokens to burn
    /// @param _utility => minted dnt utility
    /// @param _dnt => minted dnt
    function removeDnt(
        address _account,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external onlyRole(MANAGER_CONTRACT) dntInterface(_dnt) {
        require(_amount > 0, "Amount should be greater than zero");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        require(
            users[_account].dnt[_dnt].dntInUtil[_utility] >= _amount,
            "Not enough DNT in utility!"
        );
        
        totalDnt[_dnt] -= _amount;
        totalDntInUtil[_utility] -= _amount;

        DNTContract.burnNote(_account, _amount, _utility);
    }

    /// @notice removes transfer tokens from circulation
    /// @param _account => address to burn from
    /// @param _amount => amount of tokens to burn
    /// @param _utility => minted dnt utility
    /// @param _dnt => minted dnt
    function removeTransferDnt(
        address _account,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) private dntInterface(_dnt) {
        require(_amount > 0, "Amount should be greater than zero");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        require(
            users[_account].dnt[_dnt].dntInUtil[_utility] >= _amount,
            "Not enough DNT in utility!"
        );

        users[_account].dnt[_dnt].dntInUtil[_utility] -= _amount;
        liquidStaking.updateUserBalanceInUtility(_utility, _account);

        // if user balance in util is zero, we need to update info about util and dnt
        if (users[_account].dnt[_dnt].dntInUtil[_utility] == 0) {
            _removeFromUser(_account, _dnt, _utility);
        }

    }

    /// @notice removes utility string from user array of utilities
    /// @param _utility => name of the utility token
    /// @param _dnt => dnt name
    function _removeUtilityFromUser(
        string memory _utility,
        string memory _dnt,
        address _user
    ) internal onlyRole(MANAGER) {
        string[] storage utils =  users[_user].dnt[_dnt].userUtils;
        uint256 lastIdx = utils.length - 1;

        // update userUtitliesIdx for user utils if needed
        if (!utilityIdxsUpdated[_user]) {
            for (uint256 i; i < utils.length; i++) {
                string memory utilName = utils[i];
                userUtitliesIdx[_user][utilName] = i;
            }

            utilityIdxsUpdated[_user] = true;
        } 

        userHasUtility[_user][_utility] = false;

        uint256 idx = userUtitliesIdx[_user][_utility];
        userUtitliesIdx[_user][utils[lastIdx]] = idx;

        utils[idx] = utils[lastIdx];
        utils.pop();
    }

    /// @notice removes DNT string from user array of DNTs
    /// @param _dnt => name of the DNT token
    /// @param localUserDnts => array of user's DNTs
    function _removeDntFromUser(
        string memory _dnt,
        string[] storage localUserDnts,
        address _user
    ) internal onlyRole(MANAGER) {
        uint lastIdx = localUserDnts.length - 1;
        uint idx = userDntsIdx[_user][_dnt];

        userHasDnt[_user][_dnt] = false;
        
        userDntsIdx[_user][localUserDnts[lastIdx]] = idx;

        localUserDnts[idx] = localUserDnts[lastIdx];
        localUserDnts.pop(); 
    }

    /// @notice sends the specified number of tokens from the specified utilities
    /// @param _from => who sends
    /// @param _to => who gets
    /// @param _amounts => amounts of token
    /// @param _utilities => utilities to transfer
    /// @param _dnt => dnt to transfer
    function multiTransferDnts(
        address _from,
        address _to,
        uint256[] memory _amounts,
        string[] memory _utilities,
        string memory _dnt
    ) external onlyRole(MANAGER_CONTRACT) returns (uint256) {
        uint256 totalTransferAmount;
        uint256 l = _utilities.length;
        for (uint256 i; i < l; i++) {
            if (_amounts[i] > 0) {
                transferDnt(_from, _to, _amounts[i], _utilities[i], _dnt);
                totalTransferAmount += _amounts[i];
            }
        }
        return totalTransferAmount;
    }

    /// @notice sends the specified amount from all user utilities
    /// @param _from => who sends
    /// @param _to => who gets
    /// @param _amount => amount of token
    /// @param _dnt => dnt to transfer
    function transferDnts(
        address _from,
        address _to,
        uint256 _amount,
        string memory _dnt
    ) external onlyRole(MANAGER_CONTRACT) returns (string[] memory, uint256[] memory) {
        string[] memory _utilities = users[_from].dnt[_dnt].userUtils;
        uint256 l = _utilities.length;

        uint256[] memory amounts = new uint256[](l);

        for (uint256 i; i < l; i++) {
            uint256 senderBalance = users[_from].dnt[_dnt].dntInUtil[_utilities[i]];
            if (senderBalance > 0) {
                uint256 takeFromUtility = _amount > senderBalance ? senderBalance : _amount;

                transferDnt(_from, _to, takeFromUtility, _utilities[i], _dnt);
                _amount -= takeFromUtility;
                amounts[i] = takeFromUtility;

                if (_amount == 0) return (_utilities, amounts);  
            }          
        }
        revert("Not enough DNT");
    }

    /// @notice transfers tokens between users
    /// @param _from => token sender
    /// @param _to => token recepient
    /// @param _amount => amount of tokens to send
    /// @param _utility => transfered dnt utility
    /// @param _dnt => transfered DNT
    function transferDnt(
        address _from,
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) public onlyRole(MANAGER_CONTRACT) dntInterface(_dnt) {
        if (_from == _to) return;
        
         // check needed so that during the burning of tokens, they are not issued to the zero address
        if (_to != address(0)) {
            liquidStaking.addStaker(_to, _utility);
            issueTransferDnt(_to, _amount, _utility, _dnt);
        }

        if (_from != address(0)) removeTransferDnt(_from, _amount, _utility, _dnt);

        emit Transfer(_from, _to, _amount, _utility, _dnt);
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Admin
    // -------------------------------------------------------------------------------------------------------

    /// @notice allows to specify DNT token contract address
    /// @param _dnt => dnt name
    function _setDntInterface(string memory _dnt) internal {
        address contractAddr = dntContracts[_dnt];

        require(contractAddr != address(0x00), "Invalid address!");
        require(dntDB[dntId[_dnt]].isActive == true, "Invalid Dnt!");

        DNTContract = IDNT(contractAddr);
    }

    /// @notice allows to transfer ownership of the DNT contract
    /// @param _to => new owner
    /// @param _dnt => name of the dnt token contract
    function transferDntContractOwnership(address _to, string memory _dnt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        dntInterface(_dnt)
    {
        require(_to != address(0), "Zero address alarm!");
        DNTContract.transferOwnership(_to);

        emit TransferDntContractOwnership(_to, _dnt);
    }

    /// @notice sets Liquid Staking contract
    function setLiquidStaking(address _liquidStaking)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_liquidStaking.isContract(), "_liquidStaking should be contract");

        //revoke previous contract manager role if was set
        if(address(liquidStaking) != address(0)) {
            _revokeRole(MANAGER, address(liquidStaking));
        }
        
        //require(address(liquidStaking) == address(0), "Already set");  // TODO: back
        liquidStaking = ILiquidStaking(_liquidStaking);
        _grantRole(MANAGER, _liquidStaking);
        emit SetLiquidStaking(_liquidStaking);
    }

    /// @notice      disabled revoke ownership functionality
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        require(role != DEFAULT_ADMIN_ROLE, "Not allowed to revoke admin role");
        _revokeRole(role, account);
    }

    /// @notice      disabled revoke ownership functionality
    function renounceRole(bytes32 role, address account) public override {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );
        require(
            role != DEFAULT_ADMIN_ROLE,
            "Not allowed to renounce admin role"
        );
        _revokeRole(role, account);
    }
}


// File contracts/interfaces/IPartnerHandler.sol


pragma solidity 0.8.4;

interface IPartnerHandler {
    function calc(address) external view returns (uint256);

    function totalStakedASTR() external view returns (uint256);
}


// File contracts/interfaces/INFTDistributor.sol


pragma solidity 0.8.4;

interface INFTDistributor {
    function getUserEraBalance(string memory utility, address _user, uint256 era) external view returns (uint256, bool);
    function getUserFee(string memory utility, address _user) external view returns (uint8);
    function updateUser(string memory utility, address _user, uint256 era, uint256 value) external;
    function getErasData(uint256 eraBegin, uint256 eraEnd) external returns (uint256[2] memory totalData);
    function isUnique(string memory utility) external view returns (bool);
    function getDefaultUserFee(address _user) external view returns (uint8);
    function updateUserFee(address user, uint8 fee, uint256 era) external;
    function getUserEraFee(address user, uint256 era) external view returns (uint8);
    function getBestUtilFee(string memory utility, uint8 fee) external view returns (uint8);
    function getEra(uint256 era) external view returns (uint256[2] memory);
    function updates() external;
    function transferDnt(string memory utility, address from, address to, uint256 amount) external;
    function multiTransferDnt(string[] memory utilities, address from, address to, uint256[] memory amounts) external;
}


// File contracts/LiquidStaking/LiquidStakingStorage.sol


pragma solidity 0.8.4;





abstract contract LiquidStakingStorage {
    DappsStaking public constant DAPPS_STAKING =
        DappsStaking(0x0000000000000000000000000000000000005001);
    bytes32 public constant MANAGER = keccak256("MANAGER");

    /// @notice settings for distributor
    string public utilName;
    string public DNTname;

    /// @notice core values
    uint public totalBalance;
    uint public withdrawBlock;

    /// @notice pool values
    uint public unstakingPool;
    uint public rewardPool;

    /// @notice distributor data
    NDistributor public distr;

    /* unused and will removed with next proxy update */struct Stake { 
    /* unused and will removed with next proxy update */    uint totalBalance;
    /* unused and will removed with next proxy update */    uint eraStarted;
    /* unused and will removed with next proxy update */}
    /* unused and will removed with next proxy update */mapping(address => Stake) public stakes;

    /// @notice user requested withdrawals
    struct Withdrawal {
        uint val;
        uint eraReq;
        uint lag;
    }
    mapping(address => Withdrawal[]) public withdrawals;

    /* unused and will removed with next proxy update */// @notice useful values per era
    /* unused and will removed with next proxy update */struct eraData {
    /* unused and will removed with next proxy update */    bool done;
    /* unused and will removed with next proxy update */    uint val;
    /* unused and will removed with next proxy update */}
    /* unused and will removed with next proxy update */mapping(uint => eraData) public eraUnstaked;
    /* unused and will removed with next proxy update */mapping(uint => eraData) public eraStakerReward; // total staker rewards per era
    /* unused and will removed with next proxy update */mapping(uint => eraData) public eraRevenue; // total revenue per era

    uint public unbondedPool;

    uint public lastUpdated; // last era updated everything

    // Reward handlers
    /* unused and will removed with next proxy update */address[] public stakers;
    /* unused and will removed with next proxy update */address public dntToken;
    mapping(address => bool) public isStaker;

    /* unused and will removed with next proxy update */uint public lastStaked;
    uint public lastUnstaked;

    /// @notice handlers for work with LP tokens
    /* unused and will removed with next proxy update */mapping(address => bool) public isLpToken;
    /* unused and will removed with next proxy update */address[] public lpTokens;

    /* unused and will removed with next proxy update */mapping(uint => uint) public eraRewards;

    uint public totalRevenue;

    /* unused and will removed with next proxy update */mapping(address => mapping(uint => uint)) public buffer;
    mapping(address => mapping(uint => uint[])) public usersShotsPerEra;  /* 1 -> 1.5 will removed with next proxy update */
    mapping(address => uint) public totalUserRewards;
    /* unused and will removed with next proxy update */mapping(address => address) public lpHandlers;

    uint public eraShotsLimit;  /* 1 -> 1.5 will removed with next proxy update */
    /* unused and will removed with next proxy update */uint public lastClaimed;
    uint public minStakeAmount;
    /* remove after migration */uint public sum2unstake;
    /* unused and will removed with next proxy update */bool public isUnstakes;
    /* unused and will removed with next proxy update */uint public claimingTxLimit;  // = 5;

    uint8 public constant REVENUE_FEE = 9; // 9% fee on MANAGEMENT_FEE
    uint8 public constant UNSTAKING_FEE = 1; // 1% fee on MANAGEMENT_FEE
    uint8 public constant MANAGEMENT_FEE = 10; // 10% fee on staking rewards

    // to partners will be added handlers and adapters. All handlers will be removed in future
    /* unused and will removed with next proxy update */mapping(address => bool) public isPartner;
    /* unused and will removed with next proxy update */mapping(address => uint) public partnerIdx;
    address[] public partners;  /* 1 -> 1.5 will removed with next proxy update */
    /* unused and will removed with next proxy update */uint public partnersLimit;  // = 15;

    struct Dapp {
        address dappAddress;
        uint256 stakedBalance;
        uint256 sum2unstake;
        mapping(address => Staker) stakers;
    }

    struct Staker {
        // era => era balance
        mapping(uint256 => uint256) eraBalance;
        // era => is zero balance
        mapping(uint256 => bool) isZeroBalance;

        uint256 rewards;
        uint256 lastClaimedEra;
    }
    uint256 public lastEraTotalBalance;
    uint256[2] public eraBuffer;

    string[] public dappsList;
    // util name => dapp
    mapping(string => Dapp) public dapps;
    mapping(string => bool) public haveUtility;
    mapping(string => bool) public isActive;
    mapping(string => uint256) public deactivationEra;
    mapping(uint256 => uint256) public accumulatedRewardsPerShare;

    uint256 public constant REWARDS_PRECISION = 1e12;

    INFTDistributor public nftDistr;
    IAdaptersDistributor public adaptersDistr;

    address public liquidStakingManager;

    bool public paused;

    event Staked(address indexed user, uint val);
    event StakedInUtility(address indexed user, string indexed utility, uint val);
    event Unstaked(address indexed user, uint amount, bool immediate);
    event UnstakedFromUtility(address indexed user, string indexed utility, uint amount, bool immediate);
    event Withdrawn(address indexed user, uint val);
    event Claimed(address indexed user, uint amount);
    event ClaimedFromUtility(address indexed user, string indexed utility, uint amount);

    event HarvestRewards(address indexed user, string indexed utility, uint amount);

    // events for events handle
    event UnbondAndUnstakeError(string indexed utility, uint sum2unstake, uint indexed era, bytes indexed reason);
    event WithdrawUnbondedError(uint indexed _era, bytes indexed reason);
    event ClaimDappError(uint indexed amount, uint indexed era, bytes indexed reason);
    event SetMinStakeAmount(address indexed sender, uint amount);
    event WithdrawRevenue(uint amount);
    event Synchronization(address indexed sender, uint indexed era);
    event FillUnstaking(address indexed sender, uint value);
    event FillRewardPool(address indexed sender, uint value);
    event FillUnbonded(address indexed sender, uint value);
    event ClaimDappSuccess(uint eraStakerReward, uint indexed _era);
    event WithdrawUnbondedSuccess(uint indexed _era);
    event UnbondAndUnstakeSuccess(uint indexed era, uint sum2unstake);
    event ClaimStakerSuccess(uint indexed era, uint lastClaimed);
    event ClaimStakerError(string indexed utility, uint indexed era, bytes indexed reason);

    /// @notice get current era
    function currentEra() public view returns (uint) {
        return DAPPS_STAKING.read_current_era();
    }
}


// File contracts/interfaces/ILiquidStakingManager.sol


pragma solidity ^0.8.4;

interface ILiquidStakingManager {
    function getAddress(bytes4 selector) external view returns (address);
}


// File contracts/LiquidStaking/LiquidStaking.sol


pragma solidity 0.8.4;




contract LiquidStaking is AccessControlUpgradeable, LiquidStakingStorage, Proxy {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    modifier whenNotPaused() {
        require(!paused || hasRole(MANAGER, msg.sender), "Contract paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _DNTname,
        string memory _utilName,
        address _distrAddr
    ) external initializer {
        require(_distrAddr.isContract(), "_distrAddr should be contract address");
        DNTname = _DNTname;
        utilName = _utilName;

        uint256 era = currentEra() - 1;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);
        setMinStakeAmount(10);
        withdrawBlock = DAPPS_STAKING.read_unbonding_period();

        distr = NDistributor(_distrAddr);

        lastUpdated = era;
        lastStaked = era;
        lastUnstaked = era;
        lastClaimed = era;

        dappsList.push(_utilName);
        haveUtility[_utilName] = true;
        isActive[_utilName] = true;
        dapps[_utilName].dappAddress = address(this);
    }

    function pause() external onlyRole(MANAGER) {
        require(!paused, "Already paused");
        paused = true;
    }

    function unpause() external onlyRole(MANAGER) {
        require(paused, "Not paused");
        paused = false;
    }


    function setLiquidStakingManager(address _liquidStakingManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_liquidStakingManager != address(0), "Address cant be null");
        require(_liquidStakingManager.isContract(), "Manager should be contract!");
        liquidStakingManager = _liquidStakingManager;
    }

    /// @notice sets min stake amount
    /// @param _amount => new min stake amount
    function setMinStakeAmount(uint _amount) public onlyRole(MANAGER) {
        require(_amount > 0, "Should be greater than zero!");
        minStakeAmount = _amount;
        emit SetMinStakeAmount(msg.sender, _amount);
    }

    function _implementation() internal view override whenNotPaused returns (address) {
        /// @dev address(0) should changed on LiquidStakingManager contract address
        return ILiquidStakingManager(liquidStakingManager).getAddress(msg.sig);
    }

    /// @notice finish previously opened withdrawal
    /// @param _id => withdrawal index
    function withdraw(uint _id) external {
        _delegate(_implementation());
    }

    function getStaker(string memory _utility, address _user, uint256 _era) public view returns (uint256 eraBalance_, bool isZeroBalance_, uint256 rewards_, uint256 lastClaimedEra_) {
        Staker storage s = dapps[_utility].stakers[_user];
        eraBalance_ = s.eraBalance[_era];
        isZeroBalance_ = s.isZeroBalance[_era];
        rewards_ = s.rewards;
        lastClaimedEra_ = s.lastClaimedEra;
    }

        /// @notice returns user active withdrawals
    function getUserWithdrawals() external view returns (Withdrawal[] memory) {
        return withdrawals[msg.sender];
    }

    function getUserWithdrawalsArray(address _user) external view returns (Withdrawal[] memory) {
        return withdrawals[_user];
    }
}


// File contracts/SiriusAdapter.sol


pragma solidity 0.8.4;









contract SiriusAdapter is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ISiriusPool public pool;
    ISiriusFarm public farm;
    IERC20Upgradeable public lp;
    IERC20Upgradeable public nToken;
    IERC20Upgradeable public gauge;
    IERC20Upgradeable public srs;
    IMinter public minter;

    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations
    uint256 public constant REVENUE_FEE = 10; // 10% of claimed rewards goes to revenue pool

    uint256 public accumulatedRewardsPerShare;
    uint256 public revenuePool;
    uint256 public totalStaked;

    mapping(address => uint256) public lpBalances;
    mapping(address => uint256) public gaugeBalances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardDebt;

    bool public abilityToAddLpAndGauge;

    IAdaptersDistributor public adaptersDistributor;
    string public utilityName;

    bool public paused;

    event AddLiquidity(
        address indexed user,
        uint256[] indexed amounts,
        bool autoStake,
        uint256 indexed lpAmount
    );
    event RemoveLiquidity(
        address indexed user,
        uint256 amountLP,
        uint256 indexed receivedASTR
    );
    event DepositLP(address indexed, uint256 amount);
    event WithdrawLP(
        address indexed user,
        uint256 indexed amount,
        bool indexed autoWithdraw
    );
    event Claim(address indexed user, uint256 indexed amount);
    event HarvestRewards(
        address indexed user,
        uint256 indexed rewardsToHarvest
    );
    event SetAbilityToAddLpAndGauge(bool indexed _b);
    event UpdateBalSuccess(address user, string utilityName, uint256 amount);
    event UpdateBalError(address user, string utilityName, uint256 amount, string reason);
    event Paused(address account);
    event Unpaused(address account);

    // @notice Updates rewards
    modifier update() {
        // check if there are unclaimed rewards
        uint256 unclaimedRewards = farm.claimableTokens(address(this));
        if (unclaimedRewards > 0) {
            updatePoolRewards();
        }
        harvestRewards();
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Not available when paused");
        _;
    }

    /// @notice Provides access only to managers
    modifier onlyManager() {
        LiquidStaking ls = LiquidStaking(payable(0x70d264472327B67898c919809A9dc4759B6c0f27));
        require(ls.hasRole(ls.MANAGER(), msg.sender), "For MANAGER role only");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        ISiriusPool _pool,
        ISiriusFarm _farm,
        IERC20Upgradeable _lp,
        IERC20Upgradeable _nToken,
        IERC20Upgradeable _gauge,
        IERC20Upgradeable _srs,
        IMinter _minter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        pool = _pool;
        farm = _farm;
        lp = _lp;
        nToken = _nToken;
        gauge = _gauge;
        srs = _srs;
        minter = _minter;
        setAbilityToAddLpAndGauge(true);
    }

    // @notice To receive funds from pool contrct
    receive() external payable {
        require(msg.sender == address(pool), "Sending tokens not allowed");
    }

    // @notice Withdraw revenue part in SRS tokens
    // @param _amount Amount of funds to withdraw
    function withdrawRevenue(uint256 _amount) external onlyOwner {
        require(
            srs.balanceOf(address(this)) >= _amount,
            "Not enough SRS revenue"
        );
        require(_amount > 0, "Should be greater than zero!");
        revenuePool -= _amount;
        srs.safeTransfer(msg.sender, _amount);
    }

    // @notice After the transition of all users to adapters
    //         addLp() and addGauge() will be disabled by this function
    // @param _b enable or disable functionality
    function setAbilityToAddLpAndGauge(bool _b) public onlyOwner {
        abilityToAddLpAndGauge = _b;
        emit SetAbilityToAddLpAndGauge(_b);
    }

    // @notice Add liquidity to the pool with the given amounts of tokens
    // @param _amounts The amounts of each token to add
    //        idx 0 is ASTR, idx 1 is nASTR
    // @param _autoStake If true, LP tokens go to stake at the same tx
    function addLiquidity(uint256[] calldata _amounts, bool _autoStake)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            msg.value == _amounts[0],
            "Value need to be equal to amount of ASTR tokens"
        );
        require(
            _amounts[0] > 0 && _amounts[1] > 0,
            "Amounts of tokens should be greater than zero"
        );
        require(
            _amounts.length == 2,
            "The length of amounts must be equal to two"
        );

        nToken.safeTransferFrom(msg.sender, address(this), _amounts[1]);

        uint256 calculatedLpAmount = pool.calculateTokenAmount(_amounts, true);
        require(
            calculatedLpAmount > 0,
            "Calculated LP amount should be greater than zero"
        );

        uint256 minToMint = (calculatedLpAmount * 9) / 10; // min amount for slippage control

        // allow the pool take the _amount of nastr
        nToken.approve(address(pool), _amounts[1]);

        uint256 lpAmount = pool.addLiquidity{value: msg.value}(
            _amounts,
            minToMint,
            block.timestamp + 1200
        );
        lpBalances[msg.sender] += lpAmount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        if (_autoStake) {
            depositLP(lpAmount);
        }
        emit AddLiquidity(msg.sender, _amounts, _autoStake, lpAmount);
    }

    // @notice Remove liquidity from the pool
    // @param _amounts Amount of LP tokens to remove
    function removeLiquidity(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Should be greater than zero");
        require(lpBalances[msg.sender] >= _amount, "Not enough LP");

        uint256[] memory minAmounts = calculateRemoveLiquidity(_amount);

        // allow the pool take the _amount of lp
        lp.approve(address(pool), _amount);

        uint256 beforeTokens = address(this).balance;
        uint256 beforeNtokens = nToken.balanceOf(address(this));
        pool.removeLiquidity(_amount, minAmounts, block.timestamp + 1200);
        uint256 afterTokens = address(this).balance;
        uint256 afterNtokens = nToken.balanceOf(address(this));

        uint256 receivedNtokens = afterNtokens - beforeNtokens;
        uint256 receivedTokens = afterTokens - beforeTokens;

        lpBalances[msg.sender] -= _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        nToken.safeTransfer(msg.sender, receivedNtokens);
        payable(msg.sender).sendValue(receivedTokens);
        emit RemoveLiquidity(msg.sender, _amount, receivedTokens);
    }

    // @notice With this function users can transfer LP tokens to their balance in the adapter contract
    //         Needed to move from "handler contracts" to adapters
    // @param _autoDeposit Allows to deposit LP at the same tx
    function addLp(uint256 _amount, bool _autoDeposit) external nonReentrant whenNotPaused {
        require(abilityToAddLpAndGauge, "This functionality disabled");
        require(
            lp.balanceOf(msg.sender) >= _amount,
            "Not enough LP on balance"
        );
        require(_amount > 0, "Shoud be greater than zero");

        lp.safeTransferFrom(msg.sender, address(this), _amount);
        lpBalances[msg.sender] += _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        if (_autoDeposit) {
            depositLP(_amount);
        }
    }

    // @notice Receive Gauge tokens from user
    function addGauge(uint256 _amount) external update nonReentrant whenNotPaused {
        require(abilityToAddLpAndGauge, "Functionality disabled");
        require(
            gauge.balanceOf(msg.sender) >= _amount,
            "Not enough Gauge on balance"
        );
        require(_amount > 0, "Shoud be greater than zero");

        gauge.safeTransferFrom(msg.sender, address(this), _amount);
        gaugeBalances[msg.sender] += _amount;
        totalStaked += _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        // from this moment user can pretend to rewards so set him rewardDebt
        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
    }

    // @notice Deposit LP tokens to farm pool and receives Gauge tokens instead
    // @param _amount Amount of LP tokens
    function depositLP(uint256 _amount) public update whenNotPaused {
        require(lpBalances[msg.sender] >= _amount, "Not enough LP tokens");
        require(_amount > 0, "Should be greater than zero");

        lpBalances[msg.sender] -= _amount;

        // allow the farm take the _amount of lp
        lp.approve(address(farm), _amount);

        uint256 beforeGauge = gauge.balanceOf(address(this));
        farm.deposit(_amount, address(this), false);
        uint256 afterGauge = gauge.balanceOf(address(this));
        uint256 receivedGauge = afterGauge - beforeGauge;

        gaugeBalances[msg.sender] += receivedGauge;

        _updateBalanceInAdaptersDistributor(msg.sender);

        totalStaked += receivedGauge;
        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        emit DepositLP(msg.sender, _amount);
    }

    // @notice Receives LP tokens back instead of Gauge
    // @param _amount Amount of Gauge tokens
    // @param _autoWithdraw If true remove all liquidity at the same tx
    function withdrawLP(uint256 _amount, bool _autoWithdraw) external update whenNotPaused {
        require(
            gaugeBalances[msg.sender] >= _amount,
            "Not enough Gauge tokens"
        );
        require(_amount > 0, "Shoud be greater than zero");

        // allow the farm take the _amount of gauge
        gauge.approve(address(farm), _amount);

        uint256 balBefore = lp.balanceOf(address(this));
        farm.withdraw(_amount, false);
        uint256 balAfter = lp.balanceOf(address(this));
        uint256 receivedAmount = balAfter - balBefore;

        gaugeBalances[msg.sender] -= _amount;
        totalStaked -= _amount;
        lpBalances[msg.sender] += receivedAmount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;

        if (_autoWithdraw) {
            removeLiquidity(_amount);
        }
        emit WithdrawLP(msg.sender, _amount, _autoWithdraw);
    }

    // @notice Collect all rewards by user
    function harvestRewards() private {
        uint256 stakedAmount = gaugeBalances[msg.sender];

        // calculates the user's share of the total number of awards and subtracts from it accumulated rewardDebt
        uint256 rewardsToHarvest = ((stakedAmount *
            accumulatedRewardsPerShare) / REWARDS_PRECISION) -
            rewardDebt[msg.sender];

        rewardDebt[msg.sender] =
            (stakedAmount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;

        // collect user rewards that can be claimed
        rewards[msg.sender] += rewardsToHarvest;

        emit HarvestRewards(msg.sender, rewardsToHarvest);
    }

    // @notice Receives portion of total rewards in SRS tokens from the farm contract
    function updatePoolRewards() private {
        uint256 balBefore = srs.balanceOf(address(this));
        minter.mint(address(gauge));
        uint256 balAfter = srs.balanceOf(address(this));
        uint256 receivedRewards = balAfter > balBefore
            ? balAfter - balBefore
            : 0;
        if (totalStaked == 0) return;

        // increases accumulated rewards per 1 staked token
        accumulatedRewardsPerShare +=
            (receivedRewards * REWARDS_PRECISION) /
            totalStaked;
    }

    // @notice Convert LP tokens to nASTR/ASTR
    // @param _amount Number of LP tokens
    // @return Array of ammounts. ASTR at idx 0, nASTR at idx 1.
    function calculateRemoveLiquidity(uint256 _lpAmount)
        public
        view
        returns (uint256[] memory)
    {
        return pool.calculateRemoveLiquidity(_lpAmount);
    }

    // @notice For claim rewards by users
    function claim() external update nonReentrant whenNotPaused {
        require(rewards[msg.sender] > 0, "User has no any rewards");
        uint256 comissionPart = rewards[msg.sender] / REVENUE_FEE; // 10% comission part which go to revenue pool
        uint256 rewardsToClaim = rewards[msg.sender] - comissionPart;
        revenuePool += comissionPart;
        rewards[msg.sender] = 0;
        srs.safeTransfer(msg.sender, rewardsToClaim);
        emit Claim(msg.sender, rewardsToClaim);
    }

    // @notice update user's nastr balance in AdaptersDistributor
    function _updateBalanceInAdaptersDistributor(address _user) private {
        uint256 nastrBalAfter = calc(_user);
        try adaptersDistributor.updateBalanceInAdapter(utilityName, _user, nastrBalAfter) {
            emit UpdateBalSuccess(_user, utilityName, nastrBalAfter);
        } catch Error(string memory reason) {
            emit UpdateBalError(_user, utilityName, nastrBalAfter, reason);
        }
    }

    // @notice Needs to check user rewards
    // @param _user User address
    // @return sum Amount of penging rewards
    function pendingRewards(address _user) external view returns (uint256 userRewards) {
        uint256 stakedAmount = gaugeBalances[_user];
        if (stakedAmount > 0) {
            userRewards =
                rewards[_user] +
                (stakedAmount * accumulatedRewardsPerShare) /
                REWARDS_PRECISION -
                rewardDebt[_user];
        } else {
            userRewards = rewards[_user];
        }
        uint256 comissionPart = userRewards / REVENUE_FEE;
        userRewards -= comissionPart;
    }

    // @notice Get share of n tokens in pool for user
    // @param _user User's address
    function calc(address _user) public view returns (uint256 nShare) {
        uint256[] memory amounts = new uint256[](2);
        amounts = pool.calculateRemoveLiquidity(
            lpBalances[_user] + gaugeBalances[_user]
        );
        nShare = amounts[1];
    }

    // @notice Disabled functionality to renounce ownership
    function renounceOwnership() public override onlyOwner {
        revert("It is not possible to renounce ownership");
    }

    // @notice shows total staked astr amount
    function totalStakedASTR() public view returns (uint256) {
        uint256[] memory amounts = new uint256[](2);
        uint256 adapterLpBalance = IERC20Upgradeable(lp).balanceOf(address(this));
        amounts = pool.calculateRemoveLiquidity(totalStaked + adapterLpBalance);
        return amounts[0];
    }

    // @notice set adapters distributor by owner
    function setAdaptersDistributor(IAdaptersDistributor _adaptersDistributor) external onlyOwner {
        adaptersDistributor = _adaptersDistributor;
    }

    // @notice set utilityName
    function setUtilityName(string memory _utilityName) external onlyOwner {
        utilityName = _utilityName;
    }

    /// @notice Disabling funcs with the whenNotPaused modifier
    function pause() external onlyManager {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Enabling funcs with the whenNotPaused modifier
    function unpause() external onlyManager {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
