// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/ILiquidStaking.sol";
import "./interfaces/IPartnerHandler.sol";
import "./NFTDistributor.sol";

interface IAdapter {
    function totalStakedASTR() external view returns (uint256);
}
contract AdaptersDistributor is Initializable, AccessControlUpgradeable {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant ADAPTER = keccak256("ADAPTER");

    ILiquidStaking public liquidStaking;
    NFTDistributor public nftDistr;

    string public utilName;

    uint256 public totalAmount;
    mapping(address => uint256) userAmount;

    struct Adapter {
        address contractAddress;
        //uint256 totalAmount;
        mapping(address => uint256) userAmount;
    }

    mapping(string => Adapter) public adapters;
    mapping(string => bool) public haveAdapter;
    mapping(string => uint256) public adapterId;
    string[] public adaptersList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _liquidStaking) public initializer {
        liquidStaking = ILiquidStaking(_liquidStaking);
        utilName = "AdaptersUtility";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender); 
    }  

    function addAdapter(address _contractAddress, string memory _utility) external onlyRole(MANAGER) {
        require(_contractAddress != address(0), "Incorrect address");
        require(!haveAdapter[_utility], "Already have adapter");

        haveAdapter[_utility] = true;

        adapterId[_utility] = adaptersList.length;
        adaptersList.push(_utility);
        

        adapters[_utility].contractAddress = _contractAddress;

        _grantRole(ADAPTER, _contractAddress);
    }

    function removeAdapter(string memory _utility) external onlyRole(MANAGER) {
        require(haveAdapter[_utility], "Adapter not found");

        address adapterAddress = adapters[_utility].contractAddress;

        haveAdapter[_utility] = false;

        uint256 _adapterId = adapterId[_utility];
        adaptersList[_adapterId] = adaptersList[adaptersList.length - 1];
        adapterId[adaptersList[_adapterId]] = _adapterId;
        adaptersList.pop();

        _revokeRole(ADAPTER, adapterAddress);
    }
    
    /// @notice user interface to manually update adapter balances
    function updateBalances() external {
        uint l = adaptersList.length;
        for(uint i; i < l; i++) {
            _updateBalanceInAdapter(
                adaptersList[i], msg.sender,
                IPartnerHandler(adapters[adaptersList[i]].contractAddress).calc(msg.sender)
            );
        }
    }

    function updateBalanceInAdapter(string memory _adapter, address user, uint256 amountAfter) external onlyRole(ADAPTER) {
        _updateBalanceInAdapter(_adapter, user, amountAfter);
    }

    /// @notice function to update user balance in adapters.
    /// @param _adapter => utility name.
    /// @param user => address of user to update.
    /// @param amountAfter => the current balance of the user in the adapter.
    /// @dev the function will call from adapters.
    /// after which the LiquidStaking contract will update the user's balance in the "AdapterUtility".
    function _updateBalanceInAdapter(string memory _adapter, address user, uint256 amountAfter) private {
        uint256 amountBefore = adapters[_adapter].userAmount[user];

        if (amountBefore == amountAfter) return;

        totalAmount = totalAmount + amountAfter - amountBefore;
        userAmount[user] = userAmount[user] + amountAfter - amountBefore;
        adapters[_adapter].userAmount[user] = amountAfter;

        if (amountAfter > amountBefore) {
            nftDistr.transferDnt(utilName, address(0), user, amountAfter - amountBefore);
        } else {
            nftDistr.transferDnt(utilName, user, address(0), amountBefore - amountAfter);    
        }

        liquidStaking.updateUserBalanceInAdapter(utilName, user);
    }

    function getUserBalanceInAdapters(address user) external view returns (uint256) {
        return userAmount[user];
    }

    function getTotalASTR() external view returns (uint256 total) {
        uint l = adaptersList.length;
        for(uint i; i < l; i++) {
            address addr = adapters[adaptersList[i]].contractAddress;
            total += IAdapter(addr).totalStakedASTR();
        }
    }

    function setNftDistributor(address _nftDistr) external onlyRole(MANAGER) {
        nftDistr = NFTDistributor(_nftDistr);
    }
} 
