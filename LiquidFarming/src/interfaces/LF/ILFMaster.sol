interface ILFMaster {
    function poolCount() external view returns (uint256);
    function pools(uint256)
        external
        view
        returns (address, uint256, uint256, uint256, uint256, uint256, string memory, string memory);
    function addPool(address, uint256, string memory, string memory) external view;
    function harvest() external;

    function getUserBonus(address _user) external view returns (uint256);
    function distribute() external;
}
