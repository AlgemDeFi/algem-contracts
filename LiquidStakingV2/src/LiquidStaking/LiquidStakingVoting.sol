// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";


contract LiquidStakingVoting is AccessControlUpgradeable, LiquidStakingStorage {

    /// @notice Vote for dapp for ASTR distribution in stakes. Used in ccip calls.
    function vote(address _staker, uint256 _votes, uint256 _dappId) external {
        if (msg.sender != address(this)) revert OnlyForThis();
        if (!isActive[dappsList[_dappId]]) revert DappIsNotActive();
        _updateVotes(_staker, _votes, _dappId, true);
        emit VoteSuccess(_staker, _votes, _dappId);
    }

    /// @notice Unvote from dapp. Used in ccip calls.
    function unvote(address _staker, uint256 _votes, uint256 _dappId) external {
        if (msg.sender != address(this)) revert OnlyForThis();
        if (!isActive[dappsList[_dappId]]) revert DappIsNotActive();
        _updateVotes(_staker, _votes, _dappId, false);
        emit UnvoteSuccess(_staker, _votes, _dappId);
    }

    /// @notice Add a new partner dapp
    /// @param _dappName dapp utility name
    /// @param _dapp dapp address
    /// @param _wts new weights for all dapps
    function addDapp(
        string memory _dappName,
        address _dapp,
        uint256[] memory _wts
    ) external onlyRole(MANAGER) {
        uint256 len = dappsList.length;
        if (_dapp == address(0)) revert IncorrectDappAddr();
        if (len == dappLimit) revert DappLimitReached();

        uint256 newDappId = len;
        dappsList.push(_dappName);
        isActive[_dappName] = true;
        dapps[_dappName] = Dapp({
            id: newDappId,
            dappAddress: _dapp,
            stakedBalance: 0,
            sum2unstake: 0
        });

        _setDefaultWeights(_wts);
    }

    /// @notice Switch dapp status active/inactive. Not available to stake to inactive dapp
    function toggleDappAvailability(
        string memory _dappName,
        uint256[] memory _newDefaultWts
    ) external onlyRole(MANAGER) {
        isActive[_dappName] = !isActive[_dappName];
        _setDefaultWeights(_newDefaultWts);

        /// @dev Total voted need to be adjusted for correct weights counting
        if (isActive[_dappName]) 
            totalVoted += dappVotes[dapps[_dappName].id];
        else
            totalVoted -= dappVotes[dapps[_dappName].id];
    }

    /// @notice Set new weights for dapps
    /// @param _wts new weights for all dapps
    function setDefaultWeights(
        uint256[] memory _wts
    ) external onlyRole(MANAGER) {        
        _setDefaultWeights(_wts);
    }
    
    function _setDefaultWeights(
        uint256[] memory _wts
    ) internal {
        uint256 len = dappsList.length;
        if (len != _wts.length) revert WrongWeightsLength();
        uint256 weightsSumm;
        for (uint256 i; i < len; i = _uncheckedIncr(i)) {
            if (dapps[dappsList[i]].dappAddress == address(0)) revert UnknownDapp();

            if (isActive[dappsList[i]]) {
                defaultWeights[dappsList[i]] = _wts[i];
                weightsSumm += _wts[i];
            } else defaultWeights[dappsList[i]] = 0;            
        }

        if (weightsSumm != WEIGHTS_PRECISION) revert IncorrectWeightsSumm();
    }  

    /// @notice Setting vote balances
    function _updateVotes(
        address _user, 
        uint256 _votes, 
        uint256 _dappId,
        bool _in
    ) internal {
        if (_in) {
            userVotes[_user].totalUsed += _votes;
            userVotes[_user].dapp[_dappId] += _votes;
            dappVotes[_dappId] += _votes;
            totalVoted += _votes;
        } else {
            userVotes[_user].totalUsed -= _votes;
            userVotes[_user].dapp[_dappId] -= _votes;
            dappVotes[_dappId] -= _votes;
            totalVoted -= _votes;
        }
    }

    // READERS /////////////////////////////////////////////////////////////////

    /// @notice Get staker's votes to the certain dapp
    function getVoteToDapp(address _user, uint256 _dappId) public view returns (uint256) {
        return userVotes[_user].dapp[_dappId];
    }
    
    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked { return ++_i; }
    }
}