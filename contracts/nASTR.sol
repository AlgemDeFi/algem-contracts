// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/INDistributor.sol";
import "./interfaces/INFTDistributor.sol";

contract NASTR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    ERC20PermitUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using AddressUpgradeable for address;
    
    bytes32 public constant DISTR_ROLE = keccak256("DISTR_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    INDistributor public distributor;

    bool private isMultiTransfer;
    bool private isNote;
    string private utilityToTransfer;

    INFTDistributor public nftDistr;

    bytes32 public constant MULTITEST_ROLE = keccak256("MULTITEST_ROLE"); //Currently unused

    /* unused */ uint256 counter;

    // @notice stores current contract owner
    address public owner;

    // @notice needed to implement grant/claim ownership pattern
    address private _grantedOwner;

    event OwnershipTransferred(address indexed owner, address indexed grantedOwner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
		_disableInitializers();
	}

    function initialize(address _distributor) public initializer {
        require(_distributor.isContract(), "_distributor should be contract address");

        __ERC20_init("Astar Note", "nASTR");
        __ERC20Permit_init("Astar Note");
        __Pausable_init();
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DISTR_ROLE, _distributor);
        _grantRole(OWNER_ROLE, msg.sender);

        distributor = INDistributor(_distributor);
    }

    modifier noteTransfer(string memory utility) {
        utilityToTransfer = utility;
        isNote = true;
        _;
        isNote = false;
    }

    function setNftDistributor(address _nftDistr) external onlyRole(OWNER_ROLE) {
        nftDistr = INFTDistributor(_nftDistr);
    }

    // @param       issue DNT token
    // @param       [address] to => token reciever
    // @param       [uint256] amount => amount of tokens to issue
    function mintNote(address to, uint256 amount, string memory utility)
        external
        onlyRole(DISTR_ROLE)
        noteTransfer(utility)
    {
        _mint(to, amount);
    }

    /// @notice destroy DNT token
    /// @param account => token holder to burn from
    /// @param amount => amount of tokens to burn
    /// @param utility => utility to burn
    function burnNote(address account, uint256 amount, string memory utility)
        external
        onlyRole(DISTR_ROLE)
        noteTransfer(utility)
    {
        _burn(account, amount);
    }

    // @param       pause the token
    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    // @param       resume token if paused
    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    // @notice propose a new owner
    // @param _newOwner => new contract owner
    function grantOwnership(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOwner != address(0), "Zero address alarm!");
        require(_newOwner != owner, "Trying to set the same owner");
        _grantedOwner = _newOwner;
    }

    // @notice claim ownership by granted address
    function claimOwnership() external {
        require(_grantedOwner == msg.sender, "Caller is not the granted owner");
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
        emit OwnershipTransferred(owner, _grantedOwner);
    }

    // @notice      disabled revoke ownership functionality
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        require(role != DEFAULT_ADMIN_ROLE, "Not allowed to revoke admin role");
        _revokeRole(role, account);
    }

    // @notice      disabled revoke ownership functionality
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

    // @param       checks if token is active
    // @param       [address] from => address to transfer tokens from
    // @param       [address] to => address to transfer tokens to
    // @param       [uint256] amount => amount of tokens to transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20SnapshotUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (isNote) {
            distributor.transferDnt(from, to, amount, utilityToTransfer, "nASTR");
            nftDistr.transferDnt(utilityToTransfer, from, to, amount);
        } else if (!isMultiTransfer) {
            (string[] memory utilities, uint256[] memory amounts) = distributor.transferDnts(from, to, amount, "nASTR");
            nftDistr.multiTransferDnt(utilities, from, to, amounts);
        }

    }

    /* 1.5 upd */
    /// @notice transfer totens from selected utilities
    /// @param to => receiver address
    /// @param amounts => amounts of tokens to transfer
    /// @param utilities => utilities to transfer
    function transferFromUtilities(address to, uint256[] memory amounts, string[] memory utilities) external {
        require(utilities.length > 0, "Incorrect utilities array");
        require(utilities.length == amounts.length, "Incorrect arrays length");

        uint256 transferAmount = distributor.multiTransferDnts(msg.sender, to, amounts, utilities, "nASTR");
        require(transferAmount > 0, "Nothing to transfer");

        /// @dev set flag to ignore default _beforeTokenTransfer
        isMultiTransfer = true;
        _transfer(msg.sender, to, transferAmount);
        isMultiTransfer = false;

        nftDistr.multiTransferDnt(utilities, msg.sender, to, amounts);
    }
}