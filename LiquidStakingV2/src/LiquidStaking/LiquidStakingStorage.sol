// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {WETH9} from "@chainlink/local/src/shared/WETH9.sol";

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/DappsStaking.sol";
import "../interfaces/ILiquidStakingEvents.sol";
import "../interfaces/ILiquidStakingErrors.sol";
import "../interfaces/IALGMStaking.sol";
import "../interfaces/IAlgemNFT.sol";
import "../XNASTR.sol";


abstract contract LiquidStakingStorage is
    ILiquidStakingEvents,
    ILiquidStakingErrors
{
    DappsStaking public constant DAPPS_STAKING =
        DappsStaking(0x0000000000000000000000000000000000005001);

    bytes32 public constant MANAGER = keccak256("MANAGER");

    uint256 public constant REWARDS_PRECISION = 1e12;
    uint256 public constant WEIGHTS_PRECISION = 10000;

    XNASTR public xnASTR;
    IALGMStaking public ALGMStaking;
    address public liquidStakingManager;

    /// @dev maximum number of dapps to stake and vote
    uint256 public dappLimit;

    /// @dev Entire amount of staked ASTR to Astar's DappsStaking
    uint256 public totalStaked;

    /// @dev Total XNASTR supply regardless of network
    uint256 public xnastrTotalSupply;

    // Dapps params
    struct Dapp {
        uint256 id;
        address dappAddress;
        uint256 stakedBalance;
        uint256 sum2unstake;
    }

    string[] public dappsList;
    mapping(string => Dapp) public dapps;
    mapping(string => bool) public isActive;

    struct Withdrawal {
        uint256 val;
        uint256 blockReq;
        uint256 lag;
    }

    /// @dev User's ASTR withdrawals
    mapping(address => Withdrawal[]) public withdrawals;

    /// @dev Bonus rewards per period for each dapp ID
    mapping(uint256 => mapping(uint256 => uint256))
        public bonusRewardsPerPeriod;

    /// @dev Pools
    uint256 public unlockedPool;
    uint256 public revenuePool;
    uint256 public rewardPool;

    /// @dev Last era sync with DappsStaking was performed
    uint256 public lastUpdated;

    uint256 public lastUnstaked;

    uint256 public minStakeAmount;
    uint256 public minUnstakeAmount;
    uint256 public algmStakingShare; // Share of comission for ALGMStaking, eq 80% by default

    // DappsStaking v3 update
    mapping(uint256 => bool) public isPeriodInited;

    uint256 public unlockingPeriod; // eq to 64800 or 9 eras in b2e period
    uint256 public maxUnlockingChunks; // 8
    uint256 public chunkLen; // one chunk length, eq to unlockingPeriod divided by maxUnlockingChunks(8) or 8100 blocks

    // ALGMStaking params
    address public constant ALGMStakingASTR =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // address for filling ALGMStaking's ASTR pool

    // Vote params
    uint256 public totalVoted;

    bool public usingVoteWeights;

    mapping(string => uint256) public defaultWeights;
    mapping(address => VotesInfo) public userVotes;
    mapping(uint256 => uint256) public dappVotes; // sum dapps votes

    struct VotesInfo {
        uint256 totalUsed;
        mapping(uint256 => uint256) dapp;
    }

    // Cashback params
    uint256 public totalCashbackLock;

    EnumerableSet.AddressSet internal nftList;

    mapping(address => Nft) public nfts;
    mapping(address => mapping(address => CashbackLock)) public cashbackLocks;
    mapping(address => uint256) public collectedCashback;

    // CCIP params
    address public linkAddr; // address of link token
    WETH9 public wastr;

    struct CashbackLock {
        uint256 amount;
        uint256 tokenId;
        uint256 debt;
    }

    struct Nft {
        uint256 arps;
        uint256 totalLocked;
        uint256 discount;
        bool isActive;
    }

    // Pause params
    mapping(bytes4 => bool) public isPaused;
    bool public paused;

    // CCIP params
    uint64 public soneiumChainSelector;
    address public liquidStakingLayer2Addr;
    
    address public feeToken;

    /// @notice The part of ERC721 standard needed for token transfers
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // READERS ////////////////////////////////////////////////////////////////////

    /// @notice get current period
    function currentPeriod() public view returns (uint256) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.period;
    }

    /// @notice get current era
    function currentEra() public view returns (uint256) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.era;
    }

    /// @notice get current subperiod
    /// @return "true" if current subperiod is "Voting"
    ///         "false" if current subperiod is "BuildAndEarn"
    function voteSubperiod() public view returns (bool) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.subperiod == DappsStaking.Subperiod.Voting;
    }

    /// @notice returns user active withdrawals
    function getUserWithdrawals() external view returns (Withdrawal[] memory) {
        return withdrawals[msg.sender];
    }

    function getUserWithdrawalsArray(
        address _user
    ) public view returns (Withdrawal[] memory) {
        return withdrawals[_user];
    }

    /// @notice Get list with dapps names
    function getDappsList() external view returns (string[] memory) {
        return dappsList;
    }
}