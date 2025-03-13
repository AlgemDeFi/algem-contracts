//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import { Initializable } from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";

import { IAny2EVMMessageReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ILiquidStakingLayer2 } from "./interfaces/ILiquidStakingLayer2.sol";


contract LiquidStakingLayer2 is ILiquidStakingLayer2, CCIPReceiver, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public MANAGER;

    // base vars
    address public liquidStakingAstar;
    uint256 public minStakeAmount;

    // ccip vars
    // i_ccipRouter declared in CCIPReceiver
    address public linkAddr;
    uint64 public astarChainSelector;

    // ERC20 tokens
    IERC20 public wastr;
    IERC20 public xnastr;
    IERC20 public vealgm;

    // stakes/unstakes info
    mapping(address staker => uint256 amount) public stakes;
    mapping(address staker => Unstake[]) public unstakes;

    uint256 public totalStaked;
    
    // vote vars
    mapping(address => VotesInfo) public userVotes;
    mapping(uint256 => uint256) public dappVotes; // sum dapps votes
    mapping(address staker => uint256 votePower) public lockedVotePower;    

    // internal variables
    bytes4 internal STAKE_SIG;
    bytes4 internal UNSTAKE_SIG;
    bytes4 internal WITHDRAW_SIG;
    bytes4 internal VOTE_SIG;
    bytes4 internal UNVOTE_SIG;
    
    uint256 internal astarBlockCreationTime; // initially eq to 12 sec

    address public feeToken;

    bool public paused;

    uint256 public minUnstakeAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }  

    function initialize(
        address _wastrAddr,
        address _xnastrAddr,
        address _vealgmAddr,
        address _liquidStakingAstar,
        address _linkAddr,
        address _ccipRouter,
        uint64 _astarChainSelector
    ) public initializer {
        if (
            _wastrAddr == address(0) ||
            _xnastrAddr == address(0) ||
            _linkAddr == address(0) ||
            _ccipRouter == address(0)
        ) revert ZeroAddress();

        MANAGER = keccak256("MANAGER");

        wastr = IERC20(_wastrAddr);
        xnastr = IERC20(_xnastrAddr);
        vealgm = IERC20(_vealgmAddr);

        feeToken = _linkAddr; // LINK is fee token by default

        STAKE_SIG = 0x10000000;    
        UNSTAKE_SIG = 0x20000000;  
        WITHDRAW_SIG = 0x30000000; 
        VOTE_SIG = 0x40000000;     
        UNVOTE_SIG = 0x50000000;   

        // ccip initializing
        linkAddr = _linkAddr;
        i_ccipRouter = _ccipRouter;
        astarChainSelector = _astarChainSelector;

        // base values
        minStakeAmount = 100e18; // initially minimum stake and unstake amount eq to 100 WASTR
        minUnstakeAmount = 100e18; 
        liquidStakingAstar = _liquidStakingAstar;
        astarBlockCreationTime = 6;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);
    } 

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (_sourceChainSelector != astarChainSelector) revert SourceChainNotAllowed();
        if (_sender != liquidStakingAstar) revert SenderNotAllowed();
        _;
    }

    /// MAIN LOGIC

    /// @notice Update stake position and get xnASTR
    function stake(uint256 _amount) external {
        /* 
        1. take wastr from user
        3. make ccip call 
        */

        if (_amount < minStakeAmount) revert WrongStakeAmount();

        // take wastr from user
        wastr.safeTransferFrom(msg.sender, address(this), _amount);

        // prepare data for ccip call
        // stake(address) selector and call info
        bytes memory data = abi.encode(STAKE_SIG, abi.encode(msg.sender, _amount));

        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
        tokens[0] = Client.EVMTokenAmount(address(wastr), _amount);

        _ccipSend(tokens, data);

        emit StakeInited(msg.sender, _amount);
    }

    /// @notice The second part of stake, inited after receiving response from Astar 
    /// @dev It is supposed that active stakes will be defined from the addrToStakes and stakes
    /// @dev by excluding not finished ones
    function _finalizeStake(Client.Any2EVMMessage memory message) internal {
        Client.EVMTokenAmount[] memory tokens = message.destTokenAmounts;
        (bool success, , bytes memory info) = abi.decode(message.data, (bool, bytes4, bytes));
        (address staker, uint256 stakeAmount) = abi.decode(info, (address, uint256));

        if (!success) {
            // send wastr back to the user if ccip call fails with any error
            uint256 wastrAmount = message.destTokenAmounts[0].amount;
            wastr.safeTransfer(staker, wastrAmount);
            return;
        }        

        // send ASTR to user if there are received surplus
        if (tokens.length == 2) {
            // subtract ASTR surplus
            stakeAmount -= tokens[1].amount;

            // send wastr surplus to user
            wastr.safeTransfer(staker, tokens[1].amount);
            emit StakeFailed(staker, tokens[1].amount);
        }

        // update user's stake size
        stakes[staker] += stakeAmount;
        totalStaked += stakeAmount;

        // send minted xnastr to user
        xnastr.safeTransfer(staker, tokens[0].amount);
        
        emit Staked(msg.sender, tokens[0].amount);
    }

    /// @notice Start the unstaking process
    function unstake(uint256 _xnastrAmount, bool _immediate) external {
        /* 
        1. take xnastr from user
        2. make ccip call 
        */

        if (_xnastrAmount < minUnstakeAmount || 
            xnastr.balanceOf(msg.sender) < _xnastrAmount
        ) revert WrongUnstakeAmount();
        xnastr.safeTransferFrom(msg.sender, address(this), _xnastrAmount);

        // make ccip call
        bytes memory info = abi.encode(msg.sender, _xnastrAmount, _immediate); // call info
        bytes memory data = abi.encode(UNSTAKE_SIG, info); // unstake(address,uint256,bool) selector and call info

        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
        tokens[0] = Client.EVMTokenAmount(address(xnastr), _xnastrAmount);

        _ccipSend(tokens, data);

        emit UnstakeInited(msg.sender, _xnastrAmount, _immediate);
    }

    /// @notice The second part of unstake, inited after receiving response from Astar 
    function _finalizeUnstake(Client.Any2EVMMessage memory message) internal {        
        (bool success, , bytes memory infoDuration) = abi.decode(message.data, (bool, bytes4, bytes));
        (
            bytes memory info, 
            uint256 duration, 
            uint256 remoteId,
            uint256 astrAmount
        ) = abi.decode(infoDuration, (bytes, uint256, uint256, uint256));
        (address staker, uint256 xnastrAmount, bool immediate) = abi.decode(info, (address, uint256, bool));

        if (!success) {
            // send xnastr back to the user if ccip call fails with any error
            xnastr.safeTransfer(staker, message.destTokenAmounts[0].amount);

            emit UnstakeFailed(staker, xnastrAmount);
            return;
        }

        if (immediate) {
            // send received wastr to the user
            wastr.safeTransfer(staker, message.destTokenAmounts[0].amount);
            return;
        }

        if (message.destTokenAmounts.length > 0) {
            // send back the remains if there are some
            wastr.safeTransfer(staker, message.destTokenAmounts[0].amount);
        }

        totalStaked -= astrAmount;
        
        unstakes[staker].push(Unstake({
            amount: uint128(astrAmount),
            startTime: uint64(block.timestamp),
            duration: uint32(duration),
            inWithdrawProcess: false,
            remoteId: uint16(remoteId)
        }));

        emit Unstaked(staker, astrAmount, duration, immediate);
    }

    /// @notice Allows to withdraw unstaked wASTR
    function withdraw(uint256 _unstakeId) external {
        Unstake storage unstake_ = unstakes[msg.sender][_unstakeId];

        // check if passed enough time approximately
        if (unstake_.startTime == 0) revert AlreadyClaimed();
        if (timeFromBlocks(unstake_.duration) > block.timestamp - unstake_.startTime) revert UnstakeStillLocked();
        if (unstake_.inWithdrawProcess) revert AlreadyBeingWithdrawn();

        unstake_.inWithdrawProcess = true;

        bytes memory data = abi.encode(
            WITHDRAW_SIG, 
            abi.encode(msg.sender, _unstakeId, unstake_.remoteId)
        );
        _ccipSend(new Client.EVMTokenAmount[](0), data);

        emit WithdrawInited(msg.sender, _unstakeId);
    }

    /// @notice The second part of withdraw, inited after receiving response from Astar 
    function _finalizeWithdraw(Client.Any2EVMMessage memory message) internal {
        /* 
        1. set startTime = 0 (means claimed unstake))
        2. send wastr to the user
        */

        (bool success, , bytes memory info) = abi.decode(message.data, (bool, bytes4, bytes));
        (address staker, uint256 unstakeId, ) = abi.decode(info, (address, uint256, uint256));

        Unstake storage unstake_ = unstakes[staker][unstakeId];
        unstake_.inWithdrawProcess = false;

        if (!success) {
            emit WithdrawFailed(staker, unstakeId);
            return;
        }        

        unstake_.startTime = 0; // eq to zero means that unstake is claimed

        // send wastr to the user
        wastr.safeTransfer(staker, unstake_.amount);

        emit Withdrawn(staker, unstake_.amount);
    }

    /// VOTE LOGIC

    /// @notice Vote for the certain dapp and veALGM tokens
    function vote(uint256 _votes, uint256 _dappId) external {
        if (_votes == 0) revert WrongVotesNumber();
        if (_votes > availableVotePower(msg.sender)) revert NotEnoughVotePower();

        lockedVotePower[msg.sender] += _votes;

        bytes memory info = abi.encode(msg.sender, _votes, _dappId);
        bytes memory data = abi.encode(VOTE_SIG, info);

        _ccipSend(new Client.EVMTokenAmount[](0), data);

        emit VoteInited(msg.sender, _votes, _dappId);
    }

    /// @notice The second part of vote process, inited after receiving response from Astar 
    function _finalizeVote(Client.Any2EVMMessage memory message) internal {
        (bool success, , bytes memory info) = abi.decode(message.data, (bool, bytes4, bytes));
        (address staker, uint256 votes, uint256 dappId) = abi.decode(info, (address, uint256, uint256));
        
        if (!success) {
            // restore state if call failed
            lockedVotePower[staker] -= votes;

            emit VoteFailed(staker, votes, dappId);
            return;
        }

        _updateVotes(staker, votes, dappId, true);

        emit Voted(staker, votes, dappId);
    }

    /// @notice Unvote from the certain dapp
    function unvote(uint256 _votes, uint256 _dappId) external {
        uint256 votesToDapp = userVotes[msg.sender].dapp[_dappId];

        if (_votes == 0) revert WrongVotesNumber();
        if (votesToDapp < _votes) revert NotEnoughVotes();

        // update state before unvote process ended to avoid collisions
        _updateVotes(msg.sender, _votes, _dappId, false);

        bytes memory info = abi.encode(msg.sender, _votes, _dappId);
        bytes memory data = abi.encode(UNVOTE_SIG, info);

        _ccipSend(new Client.EVMTokenAmount[](0), data);

        emit UnvoteInited(msg.sender, _votes, _dappId);
    }

    /// @notice The second part of unvote process, inited after receiving response from Astar 
    function _finalizeUnvote(Client.Any2EVMMessage memory message) internal {
        (bool success, , bytes memory info) = abi.decode(message.data, (bool, bytes4, bytes));
        (address staker, uint256 votes, uint256 dappId) = abi.decode(info, (address, uint256, uint256));

        if (!success) {
            // restore back state if call failed
            _updateVotes(staker, votes, dappId, true);

            emit UnvoteFailed(staker, votes, dappId);
            return;
        }
        
        // if unvote process ended well, decrease locked vote power for user
        lockedVotePower[staker] -= votes;

        emit Unvoted(staker, votes, dappId);
    }

    /// @dev Setting vote balances
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
        } else {
            userVotes[_user].totalUsed -= _votes;
            userVotes[_user].dapp[_dappId] -= _votes;
            dappVotes[_dappId] -= _votes;
        }
    }

    /// ADMIN LOGIC

    /// @notice Pause all functionality
    function pause() external onlyRole(MANAGER) {
        if (paused) revert AlreadyPaused();
        paused = true;

        emit Paused(msg.sender);
    }

    /// @notice Unpause all functionality
    function unpause() external onlyRole(MANAGER) {
        if (!paused) revert NotPaused();
        paused = false;

        emit Unpaused(msg.sender);
    }

    function setMinStakeAmount(uint256 _amount) external onlyRole(MANAGER) {
        minStakeAmount = _amount;
    }

    function setMinUnstakeAmount(uint256 _amount) external onlyRole(MANAGER) {
        minUnstakeAmount = _amount;
    }

    /// @dev Needed to calculate the unlock period and added since block creation time in Astar may change
    function setAstarBlockCreationTime(uint256 _time) external onlyRole(MANAGER) {
        if (_time == 0) revert WrongTime();
        astarBlockCreationTime = _time;
    }

    function setVeALGM(address _veALGM) external onlyRole(MANAGER) {
        vealgm = IERC20(_veALGM);
    }

    function setFeeToken(address _feeToken) external onlyRole(MANAGER) {
        feeToken = _feeToken;
    }

    /// READERS

    /// @notice Calculate approximate time from nubmer of Astar's blocks
    function timeFromBlocks(uint256 _numberOfBlocks) public view returns (uint256) {
        return astarBlockCreationTime * _numberOfBlocks;
    }

    /// @notice Get unstakes list for the certain user
    function getUnstakes(
        address _user
    ) public view returns (Unstake[] memory results) {
        return unstakes[_user];
    }

    /// @notice Check user's number of available votes
    function availableVotePower(address _staker) public view returns (uint256 votePower) {
        if (lockedVotePower[_staker] >= vealgm.balanceOf(_staker)) return votePower;
        votePower = vealgm.balanceOf(_staker) - lockedVotePower[_staker];
    }

    /// @dev Get staker's votes to the certain dapp since
    /// @dev it is impossible to do it directly from the mapping
    function getVoteToDapp(address _user, uint256 _dappId) public view returns (uint256) {
        return userVotes[_user].dapp[_dappId];
    }

    /// CCIP LOGIC

    /// @notice Withdraw LINK tokens by manager
    function withdrawLink() external onlyRole(MANAGER) {
        IERC20(linkAddr).safeTransfer(msg.sender, IERC20(linkAddr).balanceOf(address(this)));
    }

    /// @notice Internal logic for sending crosschain message
    function _ccipSend(
        Client.EVMTokenAmount[] memory tokens,
        bytes memory _data
    ) internal {
        if (paused) revert NotAllowedWhenPaused();

        // set message data
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(liquidStakingAstar),
            data: _data,
            tokenAmounts: tokens,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 2_000_000})),
            feeToken: feeToken
        });

        // approve tokens for router if there is a need to send it
        if (tokens.length > 0) {
            for (uint256 i; i < tokens.length; i++) {
                IERC20(tokens[i].token).approve(i_ccipRouter, tokens[i].amount);
            }            
        }

        uint256 fee = IRouterClient(i_ccipRouter).getFee(astarChainSelector, message);

        IERC20(feeToken).approve(address(i_ccipRouter), fee);

        IRouterClient(i_ccipRouter).ccipSend(
            astarChainSelector,
            message
        );
    }

    /// @notice Internal logic for receiving crosschain message
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override onlyAllowlisted(
        message.sourceChainSelector, 
        abi.decode(message.sender, (address))
    ) {
        (bool result, bytes4 method, bytes memory info) = abi.decode(message.data, (bool, bytes4, bytes));

        if (method == STAKE_SIG) _finalizeStake(message);
        else if (method == UNSTAKE_SIG) _finalizeUnstake(message); 
        else if (method == WITHDRAW_SIG) _finalizeWithdraw(message); 
        else if (method == VOTE_SIG) _finalizeVote(message); 
        else if (method == UNVOTE_SIG) _finalizeUnvote(message); 
        else emit InvalidCCIPMethod(message.data);
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(AccessControlUpgradeable, CCIPReceiver) returns (bool) {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
