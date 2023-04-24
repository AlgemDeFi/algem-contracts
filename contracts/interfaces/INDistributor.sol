// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface INDistributor {
    function totalDntInUtil(string memory) external returns (uint256);
    function totalDnt(string memory) external returns (uint256);
    function getUserDntBalanceInUtil(address, string memory, string memory) external returns (uint256);
    function addUtility(string memory) external;
    function issueDnt(address, uint256, string memory, string memory) external;
    function removeDnt(address, uint256, string memory, string memory) external;
    function listUserUtilitiesInDnt(address _user, string memory _dnt) external view returns (string[] memory);
    function transferDnt(
        address _from,
        address _to,
        uint256 _amount,
        string memory _utility,
        string memory _dnt
    ) external; 
    function transferDnts(
        address _from,
        address _to,
        uint256 _amount,
        string memory _dnt
    ) external returns (string[] memory, uint256[] memory);
    function multiTransferDnts(
        address _from,
        address _to,
        uint256[] memory _amounts,
        string[] memory _utilities,
        string memory _dnt
    ) external returns (uint256);
}
