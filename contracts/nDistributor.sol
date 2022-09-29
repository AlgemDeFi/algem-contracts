// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IDNT.sol";
import "./interfaces/ILiquidStaking.sol";

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

    // @notice needs for fast search in array
    mapping(address => mapping(string => uint256)) public userUtitliesIdx;
    mapping(address => mapping(string => uint256)) public userDntsIdx;

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
    event AddDnt(string indexed newDnt, address indexed dntAddress);
    event ChangeDntAddress(string indexed dnt, address indexed addr);
    event SetUtilityStatus(uint256 indexed id, bool indexed state, string indexed utilityName);
    event SetDntStatus(uint256 indexed id, bool indexed state, string indexed dntName);
    event SetLiquidStaking(address indexed liquidStakingAddress);
    event TransferDntContractOwnership(address indexed to, string indexed dnt);
    event AddUtility(string indexed newUtility);

    using AddressUpgradeable for address;

    // MODIFIERS
    //
    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- MODIFIERS
    // -------------------------------------------------------------------------------------------------------
    modifier dntInterface(string memory _dnt) {
        _setDntInterface(_dnt);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // FUNCTIONS
    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    // @notice Needed for upgrade contract, by setting the initial values to added variables
    function initialize2() external onlyRole(MANAGER) {
        require(!isCalled, "Already called");
        isCalled = true;
        isUtility["LiquidStaking"] = true;
        isUtility["null"] = true;
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Role managment
    // -------------------------------------------------------------------------------------------------------

    // @notice changes owner roles
    // @param  [address] _newOwner => new contract owner
    function changeOwner(address _newOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newOwner != address(0), "Zero address alarm!");
        require(_newOwner != owner, "Trying to set the same owner");
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        owner = _newOwner;
    }

    // @notice returns the list of all managers
    function listManagers() external view returns (address[] memory) {
        return managers;
    }

    // @notice adds manager role
    // @param  [address] _newManager => new manager to add
    function addManager(address _newManager)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newManager != address(0), "Zero address alarm!");
        require(!hasRole(MANAGER, _newManager), "Already manager");
        managerIds[_newManager] = managers.length;
        managers.push(_newManager);
        _grantRole(MANAGER, _newManager);
    }

    // @notice removes manager role
    // @param  [address] _newManager => new manager to remove
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
    }

    // @notice removes manager role
    // @param  [address] _oldAddress => old manager address
    // @param  [address] _newAddress => new manager address
    function changeManagerAddress(address _oldAddress, address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newAddress != address(0), "Zero address alarm!");
        removeManager(_oldAddress);
        addManager(_newAddress);
    }

    function addUtilityToDisalowList(string memory _utility)
        public
        onlyRole(MANAGER)
    {
        disallowList[_utility] = true;
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Asset managment (utilities and DNTs tracking)
    // -------------------------------------------------------------------------------------------------------

    // @notice returns the list of all utilities
    function listUtilities() external view returns (string[] memory) {
        return utilities;
    }

    // @notice returns the list of all DNTs
    function listDnts() external view returns (string[] memory) {
        return dnts;
    }

    // @notice adds new utility to the DB, activates it by default
    // @param  [string] _newUtility => name of the new utility
    function addUtility(string memory _newUtility)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!isUtility[_newUtility], "Utility already added");
        uint lastId = utilityDB.length;
        utilityId[_newUtility] = lastId;
        utilityDB.push(Utility(_newUtility, true));
        utilities.push(_newUtility);
        isUtility[_newUtility] = true;
        emit AddUtility(_newUtility);
    }

    // @notice adds new DNT to the DB, activates it by default
    // @param  [string] _newDnt => name of the new DNT
    function addDnt(string memory _newDnt, address _dntAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_dntAddress.isContract(), "_dntaddress should be contract");
        require(dntContracts[_newDnt] != _dntAddress, "Dnt already added");
        uint lastId = dntDB.length;

        dntId[_newDnt] = lastId;
        dntDB.push(Dnt(_newDnt, true));
        dnts.push(_newDnt);
        dntContracts[_newDnt] = _dntAddress;
        emit AddDnt(_newDnt, _dntAddress);
    }

    // @notion allows to change DNT asset contract address
    // @param  [string] _dnt => name of the DNT
    // @param  [address] _address => new address
    function changeDntAddress(string memory _dnt, address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address.isContract(), "_address should be contract address");
        dntContracts[_dnt] = _address;
        emit ChangeDntAddress(_dnt, _address);
    }

    // @notice allows to activate\deactivate utility
    // @param  [uint256] _id => utility id
    // @param  [bool] _state => desired state
    function setUtilityStatus(uint256 _id, bool _state)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_id < utilityDB.length, "Not found utility with such id");
        utilityDB[_id].isActive = _state;
        emit SetUtilityStatus(_id, _state, utilityDB[_id].utilityName);
    }

    // @notice allows to activate\deactivate DNT
    // @param  [uint256] _id => DNT id
    // @param  [bool] _state => desired state
    function setDntStatus(uint256 _id, bool _state)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_id < dntDB.length, "Not found dnt with such id");
        dntDB[_id].isActive = _state;
        emit SetDntStatus(_id, _state, dntDB[_id].dntName);
    }

    // @notice returns a list of user's DNT tokens in possession
    // @param  [address] _user => user address
    function listUserDnts(address _user) public view returns (string[] memory) {
        return users[_user].userDnts;
    }

    // @notice returns ammount of DNT toknes of user in utility
    // @param  [address] _user => user address
    // @param  [string] _util => utility name
    // @param  [string] _dnt => DNT token name
    function getUserDntBalanceInUtil(
        address _user,
        string memory _util,
        string memory _dnt
    ) public view returns (uint256) {
        return users[_user].dnt[_dnt].dntInUtil[_util];
    }

    // @notice returns which utilities are used with specific DNT token
    // @param  [address] _user => user address
    // @param  [string] _dnt => DNT token name
    function getUserUtilsInDnt(address _user, string memory _dnt)
        public
        view
        returns (string[] memory)
    {
        return users[_user].dnt[_dnt].userUtils;
    }

    // @notice returns user's DNT balance
    // @param  [address] _user => user address
    // @param  [string] _dnt => DNT token name
    function getUserDntBalance(address _user, string memory _dnt)
        public
        dntInterface(_dnt)
        returns (uint256)
    {
        require(_user != address(0), "Shouldn't be zero address");
        return DNTContract.balanceOf(_user);
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Distribution logic
    // -------------------------------------------------------------------------------------------------------

    // @notice issues new tokens
    // @param  [address] _to => token recepient
    // @param  [uint256] _amount => amount of tokens to mint
    // @param  [string] _utility => minted dnt utility
    // @param  [string] _dnt => minted dnt
    function issueDnt(
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external dntInterface(_dnt) {
        require(_to != address(0), "Zero address alarm!");
        require(msg.sender == address(liquidStaking), "Only for LiquidStaking");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        if (!userHasDnt[_to][_dnt]) {
            _addDntToUser(_dnt, users[_to].userDnts, _to);
            userHasDnt[_to][_dnt] = true;
        }
        if (!userHasUtility[_to][_utility]) {
            _addUtilityToUser(_utility, users[_to].userUtilities, _to);
            _addUtilityToUser(_utility, users[_to].dnt[_dnt].userUtils, _to);
            userHasUtility[_to][_utility] = true;
        }

        users[_to].dnt[_dnt].dntInUtil[_utility] += _amount;
        DNTContract.mintNote(_to, _amount);

        totalDntInUtil[_utility] += _amount;
        liquidStaking.addToBuffer(_to, _amount);

        emit IssueDnt(_to, _amount, _utility, _dnt);
    }

    // @notice issues new transfer tokens
    // @param  [address] _to => token recepient
    // @param  [uint256] _amount => amount of tokens to mint
    // @param  [string] _utility => minted dnt utility
    // @param  [string] _dnt => minted dnt
    function issueTransferDnt(
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) private dntInterface(_dnt) {
        require(_to != address(0), "Zero address alarm!");
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        users[_to].dnt[_dnt].dntInUtil[_utility] += _amount;
    }

    // @notice adds dnt string to user array of dnts for tracking which assets are in possession
    // @param  [string] _dnt => name of the dnt token
    // @param  [string[] ] localUserDnts => array of user's dnts
    function _addDntToUser(string memory _dnt, string[] storage localUserDnts, address _user)
        internal
        onlyRole(MANAGER)
    {
        require(dntDB[dntId[_dnt]].isActive == true, "Invalid DNT!");

        localUserDnts.push(_dnt);
        userDntsIdx[_user][_dnt] = localUserDnts.length - 1;
    }

    // @notice adds utility string to user array of utilities for tracking which assets are in possession
    // @param  [string] _utility => name of the utility token
    // @param  [string[] ] localUserUtilities => array of user's utilities
    function _addUtilityToUser(
        string memory _utility,
        string[] storage localUserUtilities,
        address _user
    ) internal onlyRole(MANAGER) {
        uint id = utilityId[_utility];
        require(utilityDB[id].isActive == true, "Invalid utility!");

        localUserUtilities.push(_utility);
        userUtitliesIdx[_user][_utility] = localUserUtilities.length - 1;
    }

    // @notice removes tokens from circulation
    // @param  [address] _account => address to burn from
    // @param  [uint256] _amount => amount of tokens to burn
    // @param  [string] _utility => minted dnt utility
    // @param  [string] _dnt => minted dnt
    function removeDnt(
        address _account,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external onlyRole(MANAGER) dntInterface(_dnt) {
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        require(
            users[_account].dnt[_dnt].dntInUtil[_utility] >= _amount,
            "Not enough DNT in utility!"
        );

        totalDntInUtil[_utility] -= _amount;

        DNTContract.burnNote(_account, _amount);
    }

    // @notice removes transfer tokens from circulation
    // @param  [address] _account => address to burn from
    // @param  [uint256] _amount => amount of tokens to burn
    // @param  [string] _utility => minted dnt utility
    // @param  [string] _dnt => minted dnt
    function removeTransferDnt(
        address _account,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) private dntInterface(_dnt) {
        require(
            utilityDB[utilityId[_utility]].isActive == true,
            "Invalid utility!"
        );

        require(
            users[_account].dnt[_dnt].dntInUtil[_utility] >= _amount,
            "Not enough DNT in utility!"
        );

        users[_account].dnt[_dnt].dntInUtil[_utility] -= _amount;

        // if user balance in util is zero, we need to update info about util and dnt
        if (users[_account].dnt[_dnt].dntInUtil[_utility] == 0) {
            if (userHasDnt[_account][_dnt]) _removeDntFromUser(_dnt, users[_account].userDnts, _account);
            if (userHasUtility[_account][_utility]) _removeUtilityFromUser(_utility, users[_account].userUtilities, _account);
            userHasDnt[_account][_dnt] = false;
            userHasUtility[_account][_utility] = false;
        }
    }

    // @notice removes utility string from user array of utilities
    // @param  [string] _utility => name of the utility token
    // @param  [string[] ] localUserUtilities => array of user's utilities
    function _removeUtilityFromUser(
        string memory _utility,
        string[] storage localUserUtilities,
        address _user
    ) internal onlyRole(MANAGER) {
        uint lastIdx = localUserUtilities.length - 1;
        uint idx = userUtitliesIdx[_user][_utility];

        localUserUtilities[idx] = localUserUtilities[lastIdx];
        localUserUtilities.pop();
    }

    // @notice removes DNT string from user array of DNTs
    // @param  [string] _dnt => name of the DNT token
    // @param  [string[] ] localUserDnts => array of user's DNTs
    function _removeDntFromUser(
        string memory _dnt,
        string[] storage localUserDnts,
        address _user
    ) internal onlyRole(MANAGER) {
        uint lastIdx = localUserDnts.length - 1;
        uint idx = userDntsIdx[_user][_dnt];

        localUserDnts[idx] = localUserDnts[lastIdx];
        localUserDnts.pop();
    }

    // @notice transfers tokens between users
    // @param  [address] _from => token sender
    // @param  [address] _to => token recepient
    // @param  [uint256] _amount => amount of tokens to send
    // @param  [string] _utility => transfered dnt utility
    // @param  [string] _dnt => transfered DNT
    function transferDnt(
        address _from,
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external {
        require(msg.sender == dntContracts[_dnt], "Allowed only for DNT contract");
        uint senderBalance = users[_from].dnt[_dnt].dntInUtil[_utility];
        uint senderBuffer = liquidStaking.buffer(
            _from,
            liquidStaking.currentEra()
        );
        require(senderBalance >= _amount, "Not enough DNT tokens in utility!");
        require(_to != address(0), "Shouldn't be zero address");

        liquidStaking.addToBuffer(_to, _amount);

        // Checks if buffer bigger than rest sender tokens
        // if it is true, set senders buffer
        if (senderBalance - _amount < senderBuffer) {
            liquidStaking.setBuffer(_from, senderBalance - _amount);
        }

        // checks if recepient of dnt already in stakers list
        // add it to list if not
        if (!liquidStaking.isStaker(_to)) {
            liquidStaking.addStaker(_to, _utility, _dnt);
        }

        removeTransferDnt(_from, _amount, _utility, _dnt);
        // check needed so that during the burning of tokens, they are not issued to the zero address
        if (_to != address(0)) issueTransferDnt(_to, _amount, _utility, _dnt);

        emit Transfer(_from, _to, _amount, _utility, _dnt);
    }

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Admin
    // -------------------------------------------------------------------------------------------------------

    // @notice allows to specify DNT token contract address
    // @param  [address] _contract => nASTR contract address
    function _setDntInterface(string memory _dnt) internal onlyRole(MANAGER) {
        address contractAddr = dntContracts[_dnt];

        require(contractAddr != address(0x00), "Invalid address!");
        require(dntDB[dntId[_dnt]].isActive == true, "Invalid Dnt!");

        DNTContract = IDNT(contractAddr);
    }

    // @notice allows to transfer ownership of the DNT contract
    // @param  [address] _to => new owner
    // @param  [string] _dnt => name of the dnt token contract
    function transferDntContractOwnership(address _to, string memory _dnt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        dntInterface(_dnt)
    {
        require(_to != address(0), "Zero address alarm!");
        DNTContract.transferOwnership(_to);
        emit TransferDntContractOwnership(_to, _dnt);
    }

    // @notice overrides required by Solidity
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // @notice sets Liquid Staking contract
    function setLiquidStaking(address _liquidStaking)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_liquidStaking.isContract(), "_liquidStaking should be contract");
        require(address(liquidStaking) == address(0), "Already set");
        liquidStaking = ILiquidStaking(_liquidStaking);
        emit SetLiquidStaking(_liquidStaking);
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
}
