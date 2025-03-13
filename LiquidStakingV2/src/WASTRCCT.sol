// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import { ERC20Upgradeable, ERC20BurnableUpgradeable } from "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @dev Added for test purposes
contract WASTRCCT is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 internal i_decimals;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

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

    receive() external payable {
        deposit();
    }

    function initialize() public initializer {
        __ERC20_init("Wrapped ASTR", "WASTR");
        __ERC20Burnable_init();
        __Ownable_init(msg.sender);

        i_decimals = 18;
    }

    modifier onlyMinter() {
        if (!isMinter(msg.sender)) revert SenderNotMinter(msg.sender);
        _;
    }

    modifier onlyBurner() {
        if (!isBurner(msg.sender)) revert SenderNotBurner(msg.sender);
        _;
    }

    /// WETH9 part

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    /// CCIP part

    function mint(
        address account,
        uint256 amount
    ) external onlyMinter {
        _mint(account, amount);
    }

    function burn(
        uint256 amount
    ) public override onlyBurner {
        super.burn(amount);
    }

    function burn(address account, uint256 amount) public virtual {
        burnFrom(account, amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyBurner {
        super.burnFrom(account, amount);
    }

    function grantMintRole(address minter) public onlyOwner {
        if (s_minters.add(minter)) {
            emit MintAccessGranted(minter);
        }
    }

    function grantMintAndBurnRoles(address burnAndMinter) external {
        grantMintRole(burnAndMinter);
        grantBurnRole(burnAndMinter);
    }

    function grantBurnRole(address burner) public onlyOwner {
        if (s_burners.add(burner)) {
            emit BurnAccessGranted(burner);
        }
    }

    function revokeMintRole(address minter) public onlyOwner {
        if (s_minters.remove(minter)) {
            emit MintAccessRevoked(minter);
        }
    }

    function revokeBurnRole(address burner) public onlyOwner {
        if (s_burners.remove(burner)) {
            emit BurnAccessRevoked(burner);
        }
    }

    /// READERS

    function isMinter(address minter) public view returns (bool) {
        return s_minters.contains(minter);
    }

    function isBurner(address burner) public view returns (bool) {
        return s_burners.contains(burner);
    }

    function getMinters() public view returns (address[] memory) {
        return s_minters.values();
    }

    function getBurners() public view returns (address[] memory) {
        return s_burners.values();
    }

    function decimals() public view virtual override returns (uint8) {
        return i_decimals;
    }
}