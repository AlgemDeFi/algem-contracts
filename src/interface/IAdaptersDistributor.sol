pragma solidity ^0.8.10;

interface Interface {
    event Initialized(uint8 version);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function ADAPTER() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function MANAGER() external view returns (bytes32);
    function adapterId(string memory) external view returns (uint256);
    function adapters(string memory) external view returns (address contractAddress);
    function adaptersList(uint256) external view returns (string memory);
    function addAdapter(address _contractAddress, string memory _utility) external;
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function getTotalASTR() external view returns (uint256 total);
    function getUserBalanceInAdapters(address user) external view returns (uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function haveAdapter(string memory) external view returns (bool);
    function initialize(address _liquidStaking) external;
    function liquidStaking() external view returns (address);
    function nftDistr() external view returns (address);
    function removeAdapter(string memory _utility) external;
    function renounceRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function setNftDistributor(address _nftDistr) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function totalAmount() external view returns (uint256);
    function updateBalanceInAdapter(string memory _adapter, address user, uint256 amountAfter) external;
    function updateBalances() external;
    function utilName() external view returns (string memory);
}
