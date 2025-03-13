import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILWRAPPED is IERC20Metadata {
    function mint(address, uint256) external;
    function burn(address, uint256) external;

    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
    function renounceOwnership() external returns (bool);
}
