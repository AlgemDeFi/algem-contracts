//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockDappsStaking is Initializable {
    address public owner;
    ERC20Upgradeable public astr;

    uint256 public constant UNLOCKING_PERIOD = 64800 * 2;
    uint256 public constant MAX_UNLOCKING_CHUNKS = 8;
    uint256 public constant ERA_LENGTH = 7200 * 2;
    uint256 public constant PERIOD_LENGTH = ERA_LENGTH * 3;

    enum Subperiod {Voting, BuildAndEarn}
    enum SmartContractType {EVM, WASM}

    struct ProtocolState {
        uint256 era;
        uint256 period;
        Subperiod subperiod;
    }

    struct SmartContract {
        SmartContractType contract_type;
        bytes contract_address;
    }

    struct Unlock {
        uint128 unlockAmount;
        uint256 blockReq;
    }    

    struct Stake {
        uint256 amount;
    }

    mapping(address => Unlock[]) public unlocks; 
    mapping(address => mapping(bytes => Stake)) public stakes;
    mapping(address => uint256) public locks;
    mapping(address => uint256) public startBlock;
    mapping(address => mapping(bytes => uint256)) public startBlockBonuses;

    uint256 public rewardsMultiplier;

    event UnlockedClaimed(uint256 amount);
    event Unlocked(address sender, uint256 amount, uint256 unlocksLen, uint256 blockReq);
    event DSUnlockedFailed(uint256 blocksPassed, uint256 unlockBlockReq);

    function initialize(address _astr) public initializer {
        astr = ERC20Upgradeable(_astr);
        owner = msg.sender;
    }

    /// ADMIN LOGIC

    function withdrawASTR(address _receiver, uint256 _amount) external {
        require(msg.sender == owner, "Not an owner");
        astr.transfer(_receiver, _amount);
    }

    function setRewardsMultiplier(uint256 _value) external {
        require(msg.sender == owner, "Not an owner");
        rewardsMultiplier = _value;
    }
    
    // Storage getters

    /// @notice Get the current protocol state.
    /// @return (current era, current period number, current subperiod type).
    function protocol_state() external view returns (ProtocolState memory) {
        uint256 currentBlock = block.number;

        ProtocolState memory state = ProtocolState({
            era: currentBlock / ERA_LENGTH + 1,
            period: currentBlock / PERIOD_LENGTH + 1,
            subperiod: currentBlock % PERIOD_LENGTH == 0 || currentBlock < ERA_LENGTH ? Subperiod(0) : Subperiod(1)
        });

        return state;
    }

    /// @notice Get the unlocking period expressed in the number of blocks.
    /// @return period: The unlocking period expressed in the number of blocks.
    function unlocking_period() external view returns (uint256) {
        return UNLOCKING_PERIOD;
    }

    // Extrinsic calls

    /// @notice Lock the given amount of tokens into dApp staking protocol.
    /// @param amount: The amount of tokens to be locked.
    function lock(uint128 amount) external returns (bool) {
        locks[msg.sender] += amount;
    }

    /// @notice Start the unlocking process for the given amount of tokens.
    /// @param amount: The amount of tokens to be unlocked.
    function unlock(uint128 amount) external returns (bool) {
        require(locks[msg.sender] >= amount, "DS: Wrong unlock amount");
        locks[msg.sender] -= amount;
        unlocks[msg.sender].push(Unlock({
            unlockAmount: amount,
            blockReq: block.number
        }));

        emit Unlocked(msg.sender, amount, unlocks[msg.sender].length, block.number);
    }

    /// @notice Claims unlocked tokens, if there are any
    function claim_unlocked() external returns (bool) {
        uint256 currentBlock = block.number;
        Unlock[] storage _unlocks = unlocks[msg.sender];

        for (uint256 i; i < _unlocks.length; i++) {
            Unlock storage _unlock = _unlocks[i]; 

            if (currentBlock - _unlock.blockReq >= UNLOCKING_PERIOD && _unlock.blockReq != 0) {
                (bool ok, ) = payable(msg.sender).call{value: _unlock.unlockAmount}("");
                _unlock.blockReq = 0;
                require(ok, "DS: Not ok during claim unlocked");
                emit UnlockedClaimed(_unlock.unlockAmount);
            } else {
                emit DSUnlockedFailed(currentBlock - _unlock.blockReq, _unlock.blockReq);
            }
        }
    }

    /// @notice Stake the given amount of tokens on the specified smart contract.
    ///         The amount specified must be precise, otherwise the call will fail.
    /// @param smart_contract: The smart contract to be staked on.
    /// @param amount: The amount of tokens to be staked.
    function stake(SmartContract calldata smart_contract, uint128 amount) external returns (bool) {
        Stake storage _stake = stakes[msg.sender][smart_contract.contract_address];
        _stake.amount += amount;
        startBlock[msg.sender] = block.number;
        startBlockBonuses[msg.sender][smart_contract.contract_address] = block.number;
    }

    /// @notice Unstake the given amount of tokens from the specified smart contract.
    ///         The amount specified must be precise, otherwise the call will fail.
    /// @param smart_contract: The smart contract to be unstaked from.
    /// @param amount: The amount of tokens to be unstaked.
    function unstake(SmartContract calldata smart_contract, uint128 amount) external returns (bool) {
        Stake storage _stake = stakes[msg.sender][smart_contract.contract_address];
        require(amount <= _stake.amount, "DS: Wrong unstake amount");
        _stake.amount -= amount;
    }

    /// @notice Claims one or more pending staker rewards.
    function claim_staker_rewards() external returns (bool) {
        uint256 amount = (block.number - startBlock[msg.sender]) * 1e10;
        startBlock[msg.sender] = block.number;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "DS: Something wrong due sending staker rewards");
    }

    /// @notice Claim the bonus reward for the specified smart contract.
    /// @param smart_contract: The smart contract for which the bonus reward should be claimed.
    function claim_bonus_reward(SmartContract calldata smart_contract) external returns (bool) {
        uint256 amount = (block.number - startBlockBonuses[msg.sender][smart_contract.contract_address]) * 1e6;
        startBlockBonuses[msg.sender][smart_contract.contract_address] = block.number;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "DS: Something wrong due sending bonus rewards");
    }

    /// @notice Claim dApp reward for the specified smart contract & era.
    /// @param smart_contract: The smart contract for which the dApp reward should be claimed.
    /// @param era: The era for which the dApp reward should be claimed.
    function claim_dapp_reward(SmartContract calldata smart_contract, uint256 era) external returns (bool) {

    }

    /// @notice Unstake all funds from the unregistered smart contract.
    /// @param smart_contract: The smart contract which was unregistered and from which all funds should be unstaked.
    function unstake_from_unregistered(SmartContract calldata smart_contract) external returns (bool) {

    }

    /// @notice Used to cleanup all expired contract stake entries from the caller.
    function cleanup_expired_entries() external returns (bool) {}

    receive() external payable {}

    function getStakeAmount(address staker) public view returns (uint256) {
        return stakes[staker][abi.encodePacked(staker)].amount;
    }
}