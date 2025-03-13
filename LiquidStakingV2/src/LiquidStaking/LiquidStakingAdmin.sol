// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";


contract LiquidStakingAdmin is AccessControlUpgradeable, LiquidStakingStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;
    using Address for address;

    /// @notice Allows for manager to restake some part of ASTR from rewardPool
    function restakeFromRewardPool(uint256 _amount) external onlyRole(MANAGER) {
        rewardPool -= _amount;
        (bool ok, ) = address(this).call{value: _amount}(hex"3a4b66f1"); // calling stake()
        if (!ok) revert RestakeFromRewardPoolFailed();
        emit RestakedFromRewardPool(msg.sender, _amount);
    }

    /// @notice Add discount NFT
    function addNft(address _nftAddr) external onlyRole(MANAGER) {
        Nft memory nft = Nft({
            arps: 0,
            totalLocked: 0,
            discount: IAlgemNFT(_nftAddr).discount(),
            isActive: true
        });

        if (!nftList.add(_nftAddr)) revert NftAlreadyAdded();
        nfts[_nftAddr] = nft;

        emit NftAdded(_nftAddr);
    }

    /// @notice Remove discount NFT
    function removeNft(address _nftAddr) external onlyRole(MANAGER) {
        if (!nftList.remove(_nftAddr)) revert NftNotFound();
        delete nfts[_nftAddr];
        
        emit NftRemoved(_nftAddr);
    }

    /// @notice Switch nft activity
    function switchNftAvailability(address _nftAddr) external onlyRole(MANAGER) {
        Nft storage nft = nfts[_nftAddr];
        if (nft.discount == 0) revert WrongNftAddress();
        nft.isActive = !nft.isActive;    
    }

    /// @notice Toggle between default and vote weights
    function toggleWeights() external onlyRole(MANAGER) {
        usingVoteWeights = !usingVoteWeights;

        emit WeightsToggled(usingVoteWeights, block.timestamp);
    }

    /// @notice Sets min stake amount
    function setMinStakeAmount(
        uint256 _amount
    ) external onlyRole(MANAGER) {
        if (_amount == 0) revert ZeroAmountSetMinStake();

        minStakeAmount = _amount;
        emit SetMinStakeAmount(msg.sender, _amount);
    }

    /// @notice Sets min unstake amount
    function setMinUnstakeAmount(
        uint256 _amount
    ) external onlyRole(MANAGER) {
        minUnstakeAmount = _amount;
        emit SetMinUnstakeAmount(msg.sender, _amount);
    }

    /// @notice Sets ASTR share of ALGMStaking for staker rewards distribution
    /// @param _share share of ALGMStaking. E.g. 8000 == 80%
    function setAlgmStakingShare(uint256 _share) external onlyRole(MANAGER) {
        if (_share > 10000) revert TooLargeAlgmStakingShare();
        algmStakingShare = _share;
        emit AlgmStakingShareSetted(msg.sender, _share);
    }

    /// @notice Set ALGMStaking for rewards distribution
    /// @notice If sets to zero, rewards will not be distributed to this address
    function setALGMStaking(address _algmStakingAddr) external onlyRole(MANAGER) {
        ALGMStaking = IALGMStaking(_algmStakingAddr);
        emit ALGMStakingAddressSet(_algmStakingAddr);
    }

    /// @notice Sets crosschain params
    function setCCIPParams(
        uint64 _soneiumChainSelector,
        address _liquidStakingLayer2Addr,
        address _feeToken
    ) external onlyRole(MANAGER) {
        soneiumChainSelector = _soneiumChainSelector;
        liquidStakingLayer2Addr = _liquidStakingLayer2Addr;
        feeToken = _feeToken;
    }

    /// @notice withdraw revenue
    function withdrawRevenue(
        uint256 _amount
    ) external payable onlyRole(MANAGER) {
        if (revenuePool < _amount) revert RevenuePoolInsufficientFunds();

        revenuePool -= _amount;
        payable(msg.sender).sendValue(_amount);

        emit WithdrawRevenue(_amount);
    }

    /// @notice Changing the dapp address in the event of delisting
    function changeDappAddress(
        string memory _dappName,
        address _newAddress
    ) external onlyRole(MANAGER) {
        Dapp storage dapp = dapps[_dappName];
        uint256 toRestake = dapp.stakedBalance + dapp.sum2unstake;

        // unstake from deprecated address
        DAPPS_STAKING.unstake_from_unregistered(
            DappsStaking.SmartContract(
                DappsStaking.SmartContractType.EVM,
                abi.encodePacked(dapp.dappAddress)
            )
        );

        // change address
        dapp.dappAddress = _newAddress;

        // stake unstaked ASTR to new address
        DAPPS_STAKING.stake(
            DappsStaking.SmartContract(
                DappsStaking.SmartContractType.EVM,
                abi.encodePacked(dapp.dappAddress)
            ),
            uint128(toRestake)
        );
    }

    /// @notice Sets max number of allowed dapps
    function setMaxDappNumber(uint256 _dappLimit) external onlyRole(MANAGER) {
        dappLimit = _dappLimit;
    }

    /// @notice The ability to revoke the default admin role is disabled
    function revokeRole(
        bytes32 _role,
        address _account
    ) public override onlyRole(getRoleAdmin(_role)) {
        if (_role == DEFAULT_ADMIN_ROLE) revert NotAllowedForDefaultAdmin();
        _revokeRole(_role, _account);
    }

    /// @notice The ability to renounce the default admin role is disabled
    function renounceRole(bytes32 _role, address _account) public override {
        if (_account != _msgSender()) revert NotAllowedToRenounce();
        if (_role == DEFAULT_ADMIN_ROLE) revert NotAllowedForDefaultAdmin();
        _revokeRole(_role, _account);
    }

    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked {
            return ++_i;
        }
    }
}