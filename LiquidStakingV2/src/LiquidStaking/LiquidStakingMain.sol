// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";


contract LiquidStakingMain is AccessControlUpgradeable, LiquidStakingStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    /// @notice updates global balances
    modifier updateAll() {
        uint256 _era = currentEra();
        if (lastUpdated != _era) {
            _updates(_era);
        }
        _;
    }

    /// @notice Allows to stake native ASTR and receive XNASTR tokens in return
    /// @notice XNASTR amount will be calculated according to ratio between XNASTR total supply and (staked ASTR + rewardPool)
    /// @notice Stakes in dapps are calculated based on the number of votes for dapps 
    function stake() external payable returns (uint256 mintedXnastr) {
        (address _staker, uint256 _stakedAstr, uint256 surplus) = _stake(msg.sender);

        if (surplus > 0) {
            // in case when manager restake astr from reward pool
            if (_staker == address(this)) {
                rewardPool += surplus;
            } else {
                payable(_staker).sendValue(surplus);
            }
        }
        
        mintedXnastr = _issue(_staker, _stakedAstr);
        totalStaked += _stakedAstr;

        emit Staked(_staker, _stakedAstr);
    }

    /// @notice Used for crosschain stakes
    function stake(address _staker) external payable returns (uint256, uint256) {
        if (msg.sender != address(this)) revert OnlyForThis();
        ( , uint256 _stakedAstr, uint256 surplus) = _stake(_staker);

        uint256 mintedXnastr = _issue(msg.sender, _stakedAstr);
        totalStaked += _stakedAstr;

        emit Staked(_staker, _stakedAstr);

        return (mintedXnastr, surplus);
    }

    function _stake(address _staker) internal updateAll returns (address, uint256, uint256) {
        uint256 astrAmount = msg.value;

        if (astrAmount == 0) revert ZeroAmountStake();
        if (astrAmount < minStakeAmount) revert InsufficientAmount();

        (
            string[] memory dappsNames,
            uint256[] memory dappsAmounts,
            uint256 surplus
        ) = distributionByWeights(true, astrAmount);

        uint256 stakedAmount;

        for (uint256 i; i < dappsNames.length; i = _uncheckedIncr(i)) {
            if (dappsAmounts[i] > 0) {
                uint256 amountToDapp = dappsAmounts[i];  

                stakedAmount += amountToDapp; 

                // lock total stake amount to further stake
                DAPPS_STAKING.lock(uint128(amountToDapp));

                // stake ASTR to each dapp
                DAPPS_STAKING.stake(
                    DappsStaking.SmartContract(
                        DappsStaking.SmartContractType.EVM,
                        abi.encodePacked(dapps[dappsNames[i]].dappAddress)
                    ),
                    uint128(amountToDapp)
                );

                dapps[dappsNames[i]].stakedBalance += amountToDapp;

                emit StakedInDapp(_staker, dappsNames[i], amountToDapp);
            }
        }

        return (_staker, stakedAmount, surplus);
    }

    /// @notice Initiates unstaking process
    /// @param _immediate true  - Make unstake immediately 
    ///                   false - Start unlocking process
    function unstake(uint256 _xnastrAmount, bool _immediate) external returns (uint256, uint256, uint256) {
        return _unstake(msg.sender, _xnastrAmount, _immediate);
    }

    /// @notice Used for crosschain unstakes
    function unstake(
        address _staker, 
        uint256 _xnastrAmount,
        bool _immediate
    ) external returns (uint256, uint256, uint256) {
        if (msg.sender != address(this)) revert OnlyForThis();
        return _unstake(_staker, _xnastrAmount, _immediate);
    }

    function _unstake(
        address _staker, 
        uint256 _xnastrAmount, 
        bool _immediate
    ) internal updateAll returns (uint256 unstakeId, uint256 astrAmount, uint256 remains) {
        if (_xnastrAmount < minUnstakeAmount) revert TooLowUnstake();
        if (xnASTR.balanceOf(msg.sender) < _xnastrAmount) revert NotEnoughTokenBalance();

        astrAmount = getASTRValue(_xnastrAmount);
        _burn(_staker, _xnastrAmount);

        if (_immediate) {
            if (rewardPool < astrAmount) revert NotEnoughRewardPool();
            uint256 fee = astrAmount / 100; // 1% immediate unstaking fee
            revenuePool += fee;
            rewardPool -= astrAmount;
            if (msg.sender != address(this)) payable(_staker).sendValue(astrAmount - fee);            
            emit ImmediateUnstaked(_staker, astrAmount, _immediate);
            return (0, astrAmount, 0);
        }

        if (astrAmount > totalStaked) {
            remains = astrAmount - totalStaked;
            rewardPool -= remains;
            astrAmount = totalStaked;
            totalStaked = 0;
            if (msg.sender != address(this)) payable(_staker).sendValue(remains);
        } else {
            totalStaked -= astrAmount;
        }

        (
            string[] memory dappsNames,
            uint256[] memory dappsAmounts,
            uint256 surplus
        ) = distributionByWeights(false, astrAmount);

        for (uint256 i; i < dappsNames.length; i = _uncheckedIncr(i)) {
            if (dappsAmounts[i] > 0) {
                dapps[dappsNames[i]].stakedBalance -= dappsAmounts[i];
                dapps[dappsNames[i]].sum2unstake += dappsAmounts[i];

                emit UnstakedFromUtility(
                    _staker,
                    dappsNames[i],
                    dappsAmounts[i],
                    _immediate
                );
            }
        }

        if (surplus > 0) {
            astrAmount -= surplus;
            remains += surplus;
        }

        uint256 _lag;
        uint256 currentBlock = block.number;

        if (lastUnstaked + chunkLen > currentBlock) {
            _lag = lastUnstaked + chunkLen - currentBlock; 
        } // prettier-ignore

        // create a withdrawal to withdraw unlocked
        withdrawals[_staker].push(
            Withdrawal({val: astrAmount, blockReq: currentBlock, lag: _lag})
        );

        unstakeId = withdrawals[_staker].length - 1;

        emit Unstaked(_staker, astrAmount, _immediate);
    }

    /// @notice Withdraw unlocked unstakes
    /// @param _id Withdrawal index
    function withdraw(uint256 _id) external {
        _withdraw(msg.sender, _id);
    }

    /// @notice Used for crosschain withdrawals
    function withdraw(address _staker, uint256 _id) external {
        if (msg.sender != address(this)) revert OnlyForThis();
        _withdraw(_staker, _id);
    }

    function _withdraw(address _staker, uint256 _id) internal updateAll {
        Withdrawal storage withdrawal = withdrawals[_staker][_id];
        uint256 amount = withdrawal.val;
        uint256 currentBlock = block.number;

        if (withdrawal.blockReq == 0) revert AlreadyClaimed();
        if (currentBlock - withdrawal.blockReq < unlockingPeriod + withdrawal.lag) revert NotEnoughBlocksPassed();
        if (unlockedPool < amount) revert UnlockedPoolInsufficientFunds();
        
        unlockedPool -= amount;
        withdrawal.blockReq = 0;

        payable(msg.sender).sendValue(amount);
        emit Withdrawn(_staker, amount);
    }

    /// @notice global updates function
    /// @param _era era to update
    function _updates(uint256 _era) internal {
        _claimUnlocked(_era);
        _claimStakerRewards(_era);
        _initPeriod();
        _globalUnstake(_era);
        lastUpdated = _era;
    }

    //// @notice Claim staker rewards from DappsStaking contract
    /// @param _era => latest era to claim
    function _claimStakerRewards(uint256 _era) internal {
        if (lastUpdated >= _era) return;

        uint256 balance = address(this).balance;
        uint256 receivedRewards;

        try DAPPS_STAKING.claim_staker_rewards() {
            receivedRewards = address(this).balance - balance;
            emit ClaimStakerRewardsSuccess(_era, receivedRewards);
        } catch (bytes memory reason) {
            emit ClaimStakerRewardsError(_era, reason);
            return;
        }

        uint256 commissionPart = receivedRewards / 10;  // <= 10% is cut off as commission
        rewardPool += receivedRewards - commissionPart; // <= 90% of rewards goes to the reward pool
        uint256 revenuePart = commissionPart;

        // replenishment of ALGMStaking's ASTR pool
        if (address(ALGMStaking) != address(0)) {
            uint256 algmStakingPart = commissionPart * algmStakingShare / 10000;
            revenuePart -= algmStakingPart;
            ALGMStaking.topUpRewardsPool{value: algmStakingPart}(
                ALGMStakingASTR,
                algmStakingPart
            );
        }

        revenuePool += revenuePart;

        uint256 totalNftLock;

        // collect total locked amount in all nfts
        for (uint256 i; i < nftList.length(); i = _uncheckedIncr(i)) {
            Nft memory nft = nfts[nftList.at(i)];
            if (nft.totalLocked == 0) continue;
            totalNftLock += nft.totalLocked;   
        }   

        if (totalNftLock == 0) return;        
        
        // update accumulated rewards per share for cashback
        for (uint256 i; i < nftList.length(); i = _uncheckedIncr(i)) {
            Nft storage nft = nfts[nftList.at(i)];
            if (nft.totalLocked == 0) continue;
            uint256 reservedForNft = revenuePart * nft.totalLocked * nft.discount / 10000 / totalNftLock;
            revenuePool -= reservedForNft;
            nft.arps += reservedForNft * REWARDS_PRECISION / nft.totalLocked;
        }
    }

    /// @notice Allows to accumulate cashback by xnASTR and NFT locking
    function addCashbackLock(address _nftAddr, uint256 _amount, uint256 _tokenId) external updateAll {
        IAlgemNFT nftContract = IAlgemNFT(_nftAddr);
        Nft storage nft = nfts[_nftAddr];

        if (!nft.isActive) revert WrongNFTAdding();
        if (_amount == 0 || xnASTR.balanceOf(msg.sender) < _amount) revert WrongLockAmount();

        CashbackLock storage lock = cashbackLocks[msg.sender][_nftAddr];

        if (lock.amount == 0) {
            if (nftContract.balanceOf(msg.sender) == 0) revert NotEnoughNFTForLock();
            lock.tokenId = _tokenId;
            nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        } else {
            collectedCashback[msg.sender] += lock.amount * nft.arps / REWARDS_PRECISION - lock.debt;
        }

        nft.totalLocked += _amount;
        totalCashbackLock += _amount;
        lock.amount += _amount;
        lock.debt = lock.amount * nft.arps / REWARDS_PRECISION;        

        IERC20(xnASTR).safeTransferFrom(msg.sender, address(this), _amount);        

        emit CashbackLockAdded(msg.sender, _nftAddr, _amount, _tokenId);
    }

    /// @notice Unlock cashback
    function releaseCashbackLock(address _nftAddr, uint256 _amount) external updateAll {
        IAlgemNFT nftContract = IAlgemNFT(_nftAddr);
        Nft storage nft = nfts[_nftAddr];
        CashbackLock storage lock = cashbackLocks[msg.sender][_nftAddr];

        if (!nft.isActive) revert WrongNFTRelease();
        if (lock.amount == 0) revert NoCashbackLocks();
        if (_amount > lock.amount) revert NotEnoughLockedALGM();

        collectedCashback[msg.sender] += lock.amount * nft.arps / REWARDS_PRECISION - lock.debt;

        if (_amount == lock.amount) {
            nftContract.safeTransferFrom(address(this), msg.sender, lock.tokenId);
            delete cashbackLocks[msg.sender][_nftAddr];
        } else {
            lock.amount -= _amount;
            lock.debt = lock.amount * nft.arps / REWARDS_PRECISION;
        }

        nft.totalLocked -= _amount;
        totalCashbackLock -= _amount;

        IERC20(xnASTR).safeTransfer(msg.sender, _amount);

        emit CashbackLockReleased(msg.sender, _nftAddr, _amount, lock.tokenId);
    }

    /// @notice Claim cashback
    function claimCashback(address[] memory _nftsAddr) external updateAll {
        uint256 claimable;

        for (uint256 i; i < _nftsAddr.length; i = _uncheckedIncr(i)) {
            CashbackLock storage lock = cashbackLocks[msg.sender][_nftsAddr[i]];
            Nft memory nft = nfts[_nftsAddr[i]];
            if (!nft.isActive) revert WrongNFTClaim();
            claimable += getAccumulatedCashback(msg.sender, _nftsAddr[i]);
            lock.debt = lock.amount * nft.arps / REWARDS_PRECISION;
            collectedCashback[msg.sender] = 0;
        }

        if (claimable != 0) payable(msg.sender).sendValue(claimable);
        else revert ZeroCashback();

        emit CashbackClaimed(msg.sender, claimable);
    }

    /// @notice Withdraw unlocked ASTR
    function _claimUnlocked(uint256 _era) internal {
        uint256 balanceBefore = address(this).balance;

        try DAPPS_STAKING.claim_unlocked() {
            unlockedPool += address(this).balance - balanceBefore;
            emit WithdrawUnbondedSuccess(_era);
        } catch (bytes memory reason) {
            emit WithdrawUnbondedError(_era, reason);
        }
    }

    /// @notice Initiate accumulated unstakes
    function _globalUnstake(uint256 _era) internal {
        uint256 currentBlock = block.number;

        if (currentBlock < (lastUnstaked + chunkLen)) return;
        // unstake from all dapps
        uint256 len = dappsList.length;
        for (uint256 i; i < len; i = _uncheckedIncr(i)) {
            _globalUnstakeForDapp(dappsList[i], _era);
        }

        lastUnstaked = currentBlock;
    }

    /// @notice Unstake from each dapp
    /// @param _utility => utility to unstake
    /// @param _era => latest era to update
    function _globalUnstakeForDapp(
        string memory _utility,
        uint256 _era
    ) internal {
        Dapp storage dapp = dapps[_utility];

        if (dapp.sum2unstake == 0) return;

        try DAPPS_STAKING.unstake(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapp.dappAddress)
                ),
                uint128(dapp.sum2unstake)
            )
        {
            try DAPPS_STAKING.unlock(uint128(dapp.sum2unstake)) {
                dapp.sum2unstake = 0;

                emit UnlockInitiated();
            } catch (bytes memory reason) {
                emit UnlockError(_utility, dapp.sum2unstake, _era, reason);
            }
            emit UnstakeSuccess(_era, dapp.sum2unstake);
        } catch (bytes memory reason) {
            emit UnstakeError(_utility, dapp.sum2unstake, _era, reason);
        } // prettier-ignore
    }

    /// @notice Utility logic in case of excess gas consumption
    function sync(uint256 _era) external onlyRole(MANAGER) {
        require(_era > lastUpdated && _era <= currentEra(), "Wrong era range");
        _updates(_era);

        emit Synchronization(msg.sender, _era);
    }

    /// @notice Calculation of the amounts of tokens that needed to be added
    /// during stakes or subtracted during an unstakes from each utility,
    /// taking into account the established weights and balance ratios
    /// @param _values dapps staking values
    /// @param _weights weights for dapps
    /// @param _sumValues sum of dapps staking values
    /// @param _toStakeOrUnstake value to stake or unstake
    /// @return results amounts of tokens that need to be added
    /// during a stake or subtracted during an unstake
    /// @return remains the remains of the tokens that were not distributed to any dapp
    /// due to the accuracy of the calculation or the peculiarities of the Solidity math
    function _calcWithWeights(
        int256[] memory _values,
        uint256[] memory _weights,
        int256 _sumValues,
        uint256 _toStakeOrUnstake
    ) private view returns (uint256[] memory, uint256) {
        int256 totalTargetValue = _sumValues + int256(_toStakeOrUnstake);
        uint256 totalDiffValue;

        uint256 len = _values.length;
        uint256[] memory diffs = new uint256[](len);

        for (uint256 i; i < len; i = _uncheckedIncr(i)) {
            int256 diff = (int256(_weights[i]) * totalTargetValue) /
                int256(WEIGHTS_PRECISION) -
                _values[i];
            if (diff > 0) {
                diffs[i] = uint256(diff);
                totalDiffValue += diffs[i];
            }
        }

        uint256 remains = _toStakeOrUnstake;
        uint256[] memory results = new uint256[](len);

        for (uint256 i; i < len; i = _uncheckedIncr(i)) {
            if (diffs[i] > 0) {
                uint256 toAdd = (_toStakeOrUnstake * diffs[i]) / totalDiffValue;
                remains -= toAdd;
                results[i] = toAdd;
            }
        }

        return (results, remains);
    }

    /// @notice distributes the stake or unstake value among all dapps
    /// @param _isStake true if stake; else if unstake
    /// @param _amount value to stake or unstake
    /// @return dappsNames dapps list
    /// @return dappsAmounts amounts of tokens that need to be added
    /// during a stake or subtracted during an unstake
    /// @return surplus the remains of the tokens that were not distributed to any dapp
    /// due to the accuracy of the calculation or the peculiarities of the Solidity math
    function distributionByWeights(
        bool _isStake,
        uint256 _amount
    )
        public
        view
        returns (
            string[] memory dappsNames,
            uint256[] memory dappsAmounts,
            uint256 surplus
        )
    {
        string[] memory _dappsList = dappsList;
        uint256 len = _dappsList.length;

        dappsNames = new string[](len);
        uint256[] memory weights = new uint256[](len);
        int256[] memory values = new int256[](len);
        int256 sumValues;

        uint256 k;
        uint256[] memory dappWeights = getDappsWeights();

        for (uint256 i; i < len; i = _uncheckedIncr(i)) {
            if (isActive[_dappsList[i]]) {
                dappsNames[k] = _dappsList[i];

                if (usingVoteWeights) {
                    weights[k] = dappWeights[i];
                } else {
                    weights[k] = defaultWeights[_dappsList[i]];
                }

                // collect dapps's stake amounts into values and these sum to sumValues
                int256 value = int256(dapps[_dappsList[i]].stakedBalance);
                if (!_isStake) value = -value;
                values[k] = value;
                sumValues += value;
                k = _uncheckedIncr(k);
            }
        }

        (dappsAmounts, surplus) = _calcWithWeights(
            values,
            weights,
            sumValues,
            _amount
        );
    }

    /// @notice Performed at the beginning of a new period, restakes ASTR and claims bonus rewards
    function _initPeriod() internal {
        uint256 currentPeriodNumber = currentPeriod();

        if (isPeriodInited[currentPeriodNumber]) return;

        isPeriodInited[currentPeriodNumber] = true;

        // Used to cleanup all expired contract stake entries
        try DAPPS_STAKING.cleanup_expired_entries() {
            emit CleanUpExpiredEntriesSuccess(currentPeriodNumber);
        } catch (bytes memory reason) {
            emit CleanUpExpiredEntriesError(currentPeriodNumber, reason);
        }

        uint256 len = dappsList.length;

        // claim bonus rewards from each dapp
        for (uint256 idx; idx < len; idx = _uncheckedIncr(idx)) {
            Dapp storage dapp = dapps[dappsList[idx]];

            uint256 balanceBefore = address(this).balance;
            try DAPPS_STAKING.claim_bonus_reward(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapp.dappAddress)
                )
            ) {
                uint256 gain = address(this).balance - balanceBefore;
                bonusRewardsPerPeriod[currentPeriodNumber - 1][idx] = gain;
                emit BonusRewardsClaimSuccess(currentPeriodNumber, dappsList[idx], gain);
            } catch (bytes memory reason) {
                emit BonusRewardsClaimError(currentPeriodNumber, dappsList[idx], reason);
            } // prettier-ignore
        }

        // make restake for each dapp
        for (uint256 idx; idx < len; idx = _uncheckedIncr(idx)) {
            Dapp storage dapp = dapps[dappsList[idx]];

            // restake previous stake plus received bonues rewards for previous period
            uint128 toRestake = uint128(dapp.stakedBalance) + uint128(bonusRewardsPerPeriod[currentPeriodNumber - 1][idx]);

            // continue with the next iter if there is not any ASTR to restake
            if (toRestake == 0 || toRestake > address(this).balance) continue;

            DAPPS_STAKING.stake(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapp.dappAddress)
                ),
                toRestake
            );
            
            emit PeriodUpdateStakeSuccess(currentPeriodNumber, dappsList[idx]);
        }
    }

    // READERS /////////////////////////////////////////////////////////////////

    /// @notice Check accumulated cashback amount
    function getAccumulatedCashback(address _user, address _nftAddr) public view returns (uint256) {
        Nft memory nft = nfts[_nftAddr];
        CashbackLock memory lock = cashbackLocks[_user][_nftAddr];
        uint256 notCollectedCashback = lock.amount * nft.arps / REWARDS_PRECISION - lock.debt;
        return notCollectedCashback + collectedCashback[_user];
    }

    /// @notice Get dapps weights for all partners
    /// @return weights Weights list
    function getDappsWeights() public view returns (uint256[] memory weights) {
        return getDappsWeightsInRange(0, dappsList.length);
    }

    /// @notice Get dapps weights for certain range
    /// @param _fromId Initial dapp ID
    /// @param _toId Final dapp ID
    /// @return weights Weights list
    function getDappsWeightsInRange(
        uint256 _fromId,
        uint256 _toId
    ) public view returns (uint256[] memory weights) {
        require(_fromId < _toId, "Wrong range");
        uint256 len = _toId - _fromId;
        weights = new uint256[](len);
        if (totalVoted == 0) return weights;

        uint256 j;

        // convert vote token amounts to weights
        // weight is zero if dapp's vote share lower than 0.01%
        for (uint256 i = _fromId; i < _toId; i = _uncheckedIncr(i)) {
            if (!isActive[dappsList[i]]) continue; // if dapp is not active, its weight considered eq to 0
            weights[j++] = (dappVotes[i] * WEIGHTS_PRECISION) / totalVoted;
        }
    }

    /// @notice Collect info for UI blocks
    /// @param _user User address
    /// @return totalVotesInDapps List with dapps total votes in dappsList order
    /// @return dappsWeights List with dapps weights in dappsList order
    /// @return totalStakedInDapps List with staked ASTR in dapps in dappsList order
    /// @return userVePosInDapps List with user's veASTR position in dappsList order
    function getDappsInfo(
        address _user
    )
        external
        view
        returns (
            uint256[] memory totalVotesInDapps,
            uint256[] memory dappsWeights,
            uint256[] memory totalStakedInDapps,
            uint256[] memory userVePosInDapps
        )
    {
        return getDappsInfoInRange(0, dappsList.length, _user);
    }

    /// @notice Collect info for UI blocks in certain range of dapps IDs
    /// @param _fromId Initial dapp ID
    /// @param _toId Final dapp ID
    function getDappsInfoInRange(
        uint256 _fromId,
        uint256 _toId,
        address _user
    )
        public
        view
        returns (
            uint256[] memory totalVotesInDapps,
            uint256[] memory dappsWeights,
            uint256[] memory totalStakedInDapps,
            uint256[] memory userVePosInDapps
        )
    {
        dappsWeights = getDappsWeightsInRange(_fromId, _toId);
        uint256 len = _toId - _fromId;
        uint256 j;

        totalVotesInDapps = new uint256[](len);
        totalStakedInDapps = new uint256[](len);
        userVePosInDapps = new uint256[](len);

        for (uint256 i = _fromId; i < _toId; i = _uncheckedIncr(i)) {
            totalVotesInDapps[j] = dappVotes[i];
            totalStakedInDapps[j] = dapps[dappsList[i]].stakedBalance;
            userVePosInDapps[j] = userVotes[_user].dapp[i];
            j = _uncheckedIncr(j);
        }
    }

    /// @notice Get list with added NFTs
    function getNftList() external view returns (address[] memory) {
        return nftList.values();
    }

    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked {
            return ++_i;
        }
    }

    // xnASTR handlers /////////////////////////////////////////////////////////

    function getXNASTRValue(uint256 _astrAmount) public view returns (uint256) {
        uint256 totalAstrBalance = totalStaked + rewardPool;

        // Use 1:1 ratio if no xnASTR is minted
        if (xnastrTotalSupply == 0) { return _astrAmount; }
        // Calculate and return

        return _astrAmount * xnastrTotalSupply / totalAstrBalance;
    }

    function getASTRValue(uint256 _xnastrAmount) public view returns (uint256) {
        uint256 totalAstrBalance = totalStaked + rewardPool;

        // Use 1:1 ratio if no xnASTR is minted
        if (xnastrTotalSupply == 0) { return _xnastrAmount; }

        // Calculate and return
        return _xnastrAmount * totalAstrBalance / xnastrTotalSupply;
    }

    function _issue(address _to, uint256 _astrAmount) private returns (uint256 xnastrAmount) {
        // Get xnASTR amount
        xnastrAmount = getXNASTRValue(_astrAmount);

        // accounting of total xnastr supply regardless of network
        xnastrTotalSupply += xnastrAmount;

        // Update balance & supply
        xnASTR.mint(_to, xnastrAmount);

        // Emit tokens minted event
        emit TokensMinted(_to, xnastrAmount, _astrAmount, block.timestamp);
    }

    function _burn(address _to, uint256 _xnastrAmount) private {
        // Get ASTR amount
        uint256 astrAmount = getASTRValue(_xnastrAmount);

        // accounting of total xnastr supply regardless of network
        xnastrTotalSupply -= _xnastrAmount;

        // Update balance & supply
        xnASTR.burnFrom(msg.sender, _xnastrAmount);

        // Emit tokens burned event
        emit TokensBurned(msg.sender, _xnastrAmount, astrAmount, block.timestamp);
    }
}