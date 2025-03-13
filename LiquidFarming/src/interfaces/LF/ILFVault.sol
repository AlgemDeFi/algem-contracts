interface ILFVault {
    function START() external view returns (uint256);
    function FINISH() external view returns (uint256);
    function roundDuration() external view returns (uint256);
    function getCurrentRound() external view returns (uint256);

    function withdraw(uint256) external;

    function addALGMRewards(uint256, uint256) external returns (uint256);
    function algmRewards(uint256) external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function positions(address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}
