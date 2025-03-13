// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILiquidStakingVoting {
    function vote(uint256 _votes, uint256 _dappId) external;
    function unvote(uint256 _votes, uint256 _dappId) external;
    function addDapp(string memory _dappName, address _dapp, uint256[] memory _wts) external;
    function toggleDappAvailability(string memory _dappName) external;
    function setDefaultWeights(uint256[] memory _wts) external;
}

// ["vote(uint256,uint256)",
// "unvote(uint256,uint256)",
// "addDapp(string,address,uint256[])",
// "toggleDappAvailability(string)",
// "setDefaultWeights(uint256[])"]