//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { IAny2EVMMessageReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import { AccessControlUpgradeable } from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";

import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";

import "./LiquidStakingStorage.sol";


contract LiquidStaking is LiquidStakingStorage, CCIPReceiver, AccessControlUpgradeable, Proxy {

    modifier whenNotPaused() {
        require(!paused || hasRole(MANAGER, msg.sender), "Contract paused"); 
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        XNASTR _xnASTR,
        address _linkAddr,
        address _ccipRouter,
        WETH9 _wastr,
        address _algemDsAddr
    ) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);

        uint256 era = currentEra();
        
        minStakeAmount = 100e18;
        minUnstakeAmount = 1e18;
        dappLimit = 10;
        algmStakingShare = 8000;

        unlockingPeriod = DAPPS_STAKING.unlocking_period();
        maxUnlockingChunks = 8; 
        chunkLen = unlockingPeriod / maxUnlockingChunks;

        lastUpdated = era;
        lastUnstaked = era;

        xnASTR = _xnASTR;
        wastr = _wastr;
        
        // ccip
        i_ccipRouter = _ccipRouter;
        linkAddr = _linkAddr;
        feeToken = _linkAddr; // LINK is fee token by default

        dappsList.push("Algem");
        isActive["Algem"] = true;
        dapps["Algem"].dappAddress = _algemDsAddr;
    }

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (_sourceChainSelector != soneiumChainSelector) revert SourceChainNotAllowed();
        if (_sender != liquidStakingLayer2Addr) revert SenderNotAllowed();
        _;
    }

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

    /// @notice Sets selectors manager
    function setLiquidStakingManager(address _liquidStakingManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_liquidStakingManager == address(0)) revert WrongAddress();
        liquidStakingManager = _liquidStakingManager;

        emit LiquidStakingManagerSet(_liquidStakingManager);
    }

    /// @notice Sets address of CCIP router
    function setCCIPRouter(address _i_ccipRouter) external onlyRole(MANAGER) {
        i_ccipRouter = _i_ccipRouter;
    }

    /// @notice Allows to set on pause certain function
    function setPauseOnFunc(bytes4 _sig, bool _pause) external onlyRole(MANAGER) {
        isPaused[_sig] = _pause;

        emit FunctionPaused(_sig, _pause);
    }

    function _implementation() internal view override whenNotPaused returns (address) {
        return ILiquidStakingManager(liquidStakingManager).getAddress(msg.sig);
    }

    fallback() external payable override {
        bytes4 sig = msg.sig;
        if (isPaused[sig]) revert FunctionIsUnderPause();

        _fallback();
    }

    /// @notice Receiving unwrapped ASTR
    /// @notice And restaking ASTR from reward pool
    receive() external payable {
        if (
            msg.sender != address(wastr) && 
            msg.sender != address(this) &&
            msg.sender != address(DAPPS_STAKING)
        ) revert NotAllowedSender();
    }

    /// CCIP LOGIC

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override onlyAllowlisted(
        message.sourceChainSelector, 
        abi.decode(message.sender, (address))
    ) {
        (bytes4 method, ) = abi.decode(message.data, (bytes4, bytes));

        if (method == 0x10000000) _ccipStake(message, method);    // stake(address)
        else if (method == 0x20000000) _ccipUnstake(message, method);  // unstake(address,uint256,bool)
        else if (method == 0x30000000) _ccipWithdraw(message, method); // withdraw(address,uint256)
        else if (method == 0x40000000) _ccipVote(message, method);     // vote(address,uint256,uint256)
        else if (method == 0x50000000) _ccipUnvote(message, method);   // unvote(address,uint256,uint256)
        else emit InvalidCCIPMethod(message.data);
    }

    function _ccipStake(Client.Any2EVMMessage memory message, bytes4 method) internal {
        // received wastr from LSLayer2
        uint256 wastrAmount = message.destTokenAmounts[0].amount;
        address sender = abi.decode(message.sender, (address));
        ( , bytes memory info) = abi.decode(message.data, (bytes4, bytes));

        // change wastr to astr
        wastr.withdraw(wastrAmount);

        // perform stake and receive xnastr to address(this)
        (bool ok, bytes memory data) = address(this).call{value: wastrAmount}(
            abi.encodeWithSignature("stake(address)", sender)
        );
        if (!ok) {
            // if something wrong send wastr back
            wastr.deposit{value: wastrAmount}();
            Client.EVMTokenAmount[] memory tokensBack = new Client.EVMTokenAmount[](1);
            tokensBack[0] = Client.EVMTokenAmount(address(wastr), wastrAmount);
            _ccipSend(message, tokensBack, abi.encode(false, method, info));
            return;
        }

        (uint256 mintedXnastr, uint256 surplus) = abi.decode(data, (uint256, uint256));

        uint256 tokenArrLen = 1;

        // if there are any returned ASTR, they are sent back to the user
        if (surplus > 0) {
            tokenArrLen = 2;
            wastr.deposit{value: surplus}();
        }

        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](tokenArrLen);
        (tokens[0].token, tokens[0].amount) = (address(xnASTR), mintedXnastr);
        if (surplus > 0) (tokens[1].token, tokens[1].amount) = (address(wastr), surplus);

        // send xnastr to LSLayer2 
        _ccipSend(message, tokens, abi.encode(true, method, info));
    }

    function _ccipUnstake(Client.Any2EVMMessage memory message, bytes4 method) internal {
        uint256 xnastrAmount = message.destTokenAmounts[0].amount;
        address sender = abi.decode(message.sender, (address));
        ( , bytes memory info) = abi.decode(message.data, (bytes4, bytes));
        ( , , bool immediate) = abi.decode(info, (address, uint256, bool));

        (bool ok, bytes memory returnData) = address(this).call(
            abi.encodeWithSignature("unstake(address,uint256,bool)", sender, xnastrAmount, immediate)
        );
        if (!ok) {
            // if something wrong send xnastr back
            Client.EVMTokenAmount[] memory tokensBack = new Client.EVMTokenAmount[](1);
            tokensBack[0] = Client.EVMTokenAmount(address(xnASTR), xnastrAmount);
            info = abi.encode(info, 0); // duration == 0 in fail case
            _ccipSend(message, tokensBack, abi.encode(false, method, info));
            return;
        }
        
        (uint256 unstakeId, uint256 unstakedAmount, uint256 remains) = abi.decode(returnData, (uint256, uint256, uint256));

        if (immediate) {
            wastr.deposit{value: unstakedAmount}();
            Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
            tokens[0] = Client.EVMTokenAmount(address(wastr), unstakedAmount);
            info = abi.encode(info, 0, unstakeId);
            _ccipSend(message, tokens, abi.encode(true, method, info));
            return;
        }

        // calc the estimate unlocking block
        // take the last withdrawal from user's withdrawals array
        uint256 duration = unlockingPeriod + withdrawals[sender][unstakeId].lag;
        info = abi.encode(info, duration, unstakeId, unstakedAmount);

        // send back wastr tokens if there are some remains after unstake
        if (remains > 0) {
            wastr.deposit{value: remains}();
            Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
            tokens[0] = Client.EVMTokenAmount(address(wastr), remains);
            _ccipSend(message, tokens, abi.encode(true, method, info));
        } else {
            _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(true, method, info));
        }        
    }

    function _ccipWithdraw(Client.Any2EVMMessage memory message, bytes4 method) internal {
        ( , bytes memory info) = abi.decode(message.data, (bytes4, bytes));
        (address staker, , uint256 remoteId) = abi.decode(info, (address, uint256, uint256));

        (bool ok, ) = address(this).call(
            abi.encodeWithSignature("withdraw(address,uint256)", abi.decode(message.sender, (address)), remoteId)
        );

        if (!ok) {
            // if fail send msg back with the false flag
            _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(false, method, info));
            return;
        }

        Withdrawal memory wl = withdrawals[abi.decode(message.sender, (address))][remoteId];
        wastr.deposit{value: wl.val}();
        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](1);
        tokens[0] = Client.EVMTokenAmount(address(wastr), wl.val);

        _ccipSend(message, tokens, abi.encode(true, method, info));
    }

    function _ccipVote(Client.Any2EVMMessage memory message, bytes4 method) internal {
        ( , bytes memory info) = abi.decode(message.data, (bytes4, bytes));
        (address staker, uint256 votes, uint256 dappId) = abi.decode(info, (address, uint256, uint256));

        (bool ok, ) = address(this).call(
            abi.encodeWithSignature("vote(address,uint256,uint256)", staker, votes, dappId)
        );

        if (!ok) {
            _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(false, method, info));
            return;
        }

        _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(true, method, info));
    }

    function _ccipUnvote(Client.Any2EVMMessage memory message, bytes4 method) internal {
        ( , bytes memory info) = abi.decode(message.data, (bytes4, bytes));
        (address staker, uint256 votes, uint256 dappId) = abi.decode(info, (address, uint256, uint256));

        (bool ok, ) = address(this).call(
            abi.encodeWithSignature("unvote(address,uint256,uint256)", staker, votes, dappId)
        );

        if (!ok) {
            _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(false, method, info));
            return;
        }

        _ccipSend(message, new Client.EVMTokenAmount[](0), abi.encode(true, method, info));
    }

    function _ccipSend(
        Client.Any2EVMMessage memory message,
        Client.EVMTokenAmount[] memory tokens,
        bytes memory _data
    ) internal {
        uint64 senderChainSelector = message.sourceChainSelector;

        // set message data
        Client.EVM2AnyMessage memory msgBack = Client.EVM2AnyMessage({
            receiver: message.sender,
            data: _data,
            tokenAmounts: tokens,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 500_000})),
            feeToken: feeToken
        });

        // approve tokens for router if there is a need to send it
        if (tokens.length > 0) {
            for (uint256 i; i < tokens.length; i++) {
                ERC20Upgradeable(tokens[i].token).approve(i_ccipRouter, tokens[i].amount);
            }            
        }

        uint256 fee = IRouterClient(i_ccipRouter).getFee(senderChainSelector, msgBack);

        if (fee > 0) ERC20Upgradeable(feeToken).approve(address(i_ccipRouter), fee);

        IRouterClient(i_ccipRouter).ccipSend(
            senderChainSelector,
            msgBack
        );
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(AccessControlUpgradeable, CCIPReceiver) returns (bool) {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}   