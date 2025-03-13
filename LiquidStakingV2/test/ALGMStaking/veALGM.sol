//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2StepUpgradeable, OwnableUpgradeable} from "@openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract VeALGM is ERC20Upgradeable, Ownable2StepUpgradeable {
    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                     STORAGE                     */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    address public staking;

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                     ERRORS                      */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    error CallerNotAuthorized();
    error InvalidAddress();
    error LockedToken();

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                    MODIFIERS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    modifier locked() {
        _revertIfLocked();
        _;
    }

    modifier authorized(address _a) {
        _revertIfNotAuthorized(_a);
        _;
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                   CONSTRUCTOR                   */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __ERC20_init("veALGM", "veALGM");
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                  MINT & BURN                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function mint(address to, uint256 qty) external authorized(staking) {
        _mint(to, qty);
    }

    function burn(address from, uint256 qty) external authorized(staking) {
        _burn(from, qty);
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                  LOCKED FUNCS                   */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function transfer(
        address to,
        uint256 value
    ) public virtual override locked returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override locked returns (bool) {}

    function approve(
        address spender,
        uint256 value
    ) public virtual override locked returns (bool) {}

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                  OWNER FUNCS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function setStakingAddr(address _staking) external onlyOwner {
        if (_staking == address(0)) revert InvalidAddress();
        if (_staking == staking) revert InvalidAddress();

        staking = _staking;
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                    INTERNALS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function _revertIfLocked() internal pure {
        revert LockedToken();
    }

    function _revertIfNotAuthorized(address _authorized) internal view {
        if (msg.sender != _authorized) revert CallerNotAuthorized();
    }
}
