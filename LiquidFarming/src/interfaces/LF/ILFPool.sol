interface ILFPool {
    function vaultsCount() external view returns (uint256);
    function vaults(uint256) external view returns (address);
    function addALGM(uint256 _amount) external;
    function addVault(address, uint256) external;

    function WRAPPED() external view returns (address);
    function pairToken() external view returns (address);

    function harvest() external;
    function getUserBonus(address _user) external view returns (uint256);

    function balances(address) external view returns (uint256);
    function totalBalance() external view returns (uint256);
}
