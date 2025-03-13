// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20Upgradeable } from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { ERC20PausableUpgradeable } from "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @notice Reward bearing token that represents stake position in LiquidStaking
contract XNASTR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    error SenderNotMinter(address sender);
    error SenderNotBurner(address sender);
    error MaxSupplyExceeded(uint256 supplyAfterMint);

    event MintAccessGranted(address indexed minter);
    event BurnAccessGranted(address indexed burner);
    event MintAccessRevoked(address indexed minter);
    event BurnAccessRevoked(address indexed burner);

    // @dev the allowed minter addresses
    EnumerableSet.AddressSet internal s_minters;
    // @dev the allowed burner addresses
    EnumerableSet.AddressSet internal s_burners;

    /// @dev The number of decimals for the token
    uint8 internal i_decimals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Algem XNASTR", "XNASTR");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(msg.sender);

        i_decimals = 18;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ================================================================
    // |                            ERC20                             |
    // ================================================================

    /// @dev Returns the number of decimals used in its user representation.
    function decimals() public view virtual override returns (uint8) {
        return i_decimals;
    }

    /// @dev Uses OZ ERC20 _transfer to disallow sending to address(0).
    /// @dev Disallows sending to address(this)
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override validAddress(to) {
        super._transfer(from, to, amount);
    }

    /// @dev Uses OZ ERC20 _approve to disallow approving for address(0).
    /// @dev Disallows approving for address(this)
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override validAddress(spender) {
        super._approve(owner, spender, amount);
    }

    /// @dev Exists to be backwards compatible with the older naming convention.
    function decreaseApproval(
        address spender,
        uint256 subtractedValue
    ) external returns (bool success) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /// @dev Exists to be backwards compatible with the older naming convention.
    function increaseApproval(address spender, uint256 addedValue) external {
        _approve(
            _msgSender(),
            spender,
            allowance(_msgSender(), spender) + addedValue
        );
    }

    /// @notice Check if recipient is valid (not this contract address).
    /// @param recipient the account we transfer/approve to.
    /// @dev Reverts with an empty revert to be compatible with the existing link token when
    /// the recipient is this contract address.
    modifier validAddress(address recipient) virtual {
        // solhint-disable-next-line reason-string, custom-errors
        if (recipient == address(this)) revert();
        _;
    }

    function mint(
        address account,
        uint256 amount
    ) external onlyMinter validAddress(account) {
        _mint(account, amount);
    }

    function burn(uint256 amount) public override onlyBurner {
        super.burn(amount);
    }

    function burn(address account, uint256 amount) public virtual {
        burnFrom(account, amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyBurner {
        _burn(account, amount);
    }

    // ================================================================
    // |                            Roles                             |
    // ================================================================

    /// @notice grants both mint and burn roles to `burnAndMinter`.
    /// @dev calls public functions so this function does not require
    /// access controls. This is handled in the inner functions.
    function grantMintAndBurnRoles(address burnAndMinter) external {
        grantMintRole(burnAndMinter);
        grantBurnRole(burnAndMinter);
    }

    /// @notice Grants mint role to the given address.
    /// @dev only the owner can call this function.
    function grantMintRole(address minter) public onlyOwner {
        if (s_minters.add(minter)) {
            emit MintAccessGranted(minter);
        }
    }

    /// @notice Grants burn role to the given address.
    /// @dev only the owner can call this function.
    function grantBurnRole(address burner) public onlyOwner {
        if (s_burners.add(burner)) {
            emit BurnAccessGranted(burner);
        }
    }

    /// @notice Revokes mint role for the given address.
    /// @dev only the owner can call this function.
    function revokeMintRole(address minter) public onlyOwner {
        if (s_minters.remove(minter)) {
            emit MintAccessRevoked(minter);
        }
    }

    /// @notice Revokes burn role from the given address.
    /// @dev only the owner can call this function
    function revokeBurnRole(address burner) public onlyOwner {
        if (s_burners.remove(burner)) {
            emit BurnAccessRevoked(burner);
        }
    }

    /// @notice Returns all permissioned minters
    function getMinters() public view returns (address[] memory) {
        return s_minters.values();
    }

    /// @notice Returns all permissioned burners
    function getBurners() public view returns (address[] memory) {
        return s_burners.values();
    }

    // ================================================================
    // |                            Access                            |
    // ================================================================

    /// @notice Checks whether a given address is a minter for this token.
    /// @return true if the address is allowed to mint.
    function isMinter(address minter) public view returns (bool) {
        return s_minters.contains(minter);
    }

    /// @notice Checks whether a given address is a burner for this token.
    /// @return true if the address is allowed to burn.
    function isBurner(address burner) public view returns (bool) {
        return s_burners.contains(burner);
    }

    /// @notice Checks whether the msg.sender is a permissioned minter for this token
    /// @dev Reverts with a SenderNotMinter if the check fails
    modifier onlyMinter() {
        if (!isMinter(msg.sender)) revert SenderNotMinter(msg.sender);
        _;
    }

    /// @notice Checks whether the msg.sender is a permissioned burner for this token
    /// @dev Reverts with a SenderNotBurner if the check fails
    modifier onlyBurner() {
        if (!isBurner(msg.sender)) revert SenderNotBurner(msg.sender);
        _;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) {
        super._update(from, to, value);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}
