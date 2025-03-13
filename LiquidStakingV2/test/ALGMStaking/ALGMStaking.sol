//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILLMaster} from "./interfaces/ILLMaster.sol";
import {IVeALGM} from "./interfaces/IVeALGM.sol";

contract ALGMStaking is Ownable2StepUpgradeable, PausableUpgradeable {
    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                     STRUCTS                     */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /**
     * @dev Datatype for user stakes.
     *      ALGM and veALGM amount is added/substracted respectively.
     *      If qty in withdrawal request is equal to ALGM qty of implying stake,
     *      the record of stake is deleted.
     */
    struct Stake {
        uint256 algmQty;
        uint256 veAlgmQty;
    }

    /**
     * @dev Datatype for withdraw requests.
     *      Pretty straight logic: Each request gets ID,
     *      which is used in withdraw function, when unbond period is over.
     */
    struct WithdrawalRequest {
        uint256 id;
        uint256 qty; // ALGM
        uint256 withdrawAfter; // timestamp
        uint256 poolID; // ID of pool withdrawing from
    }

    /**
     * @dev Datatype for staking pools.
     */
    struct Pool {
        uint256 shareOfRewardsPool; // bps
        uint256 veAlgmPerStake; // bps
        uint256 unbondPeriod; // days
        uint256 totalStaked; // ALGM
    }

    /**
     * @dev Datatype for rewards that will be distributed withing specified timeframe.
     *      Rewards in ASTR, which is a native token, are stored as address from `ASTR` constant.
     */
    struct TimeDistributedReward {
        bytes4 id;
        address token; // reward token
        uint256 qty; // token amount
        uint256 startAt; // timestamp
        uint256 timeframe; // sec
        uint256 slicesDistributed; // slice == 1 sec
        uint256 sliceValue;
        uint256[3] poolsWeights;
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                    CONSTANTS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    address constant ASTR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant MAX_BPS = 10000;
    uint256 constant PRECISION = 1e12;
    uint256 constant MIN_STAKE = 10e18;

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                     STORAGE                     */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /// @notice Information about RewardsPool balances and ARPS for each token.
    /// Balances for each token. ASTR is referenced as address from `ASTR` constant.
    mapping(address => uint256) public rpTokensQty; // (token => qty)
    /// Accumulated rewards per share for each token. ASTR is referenced as address from `ASTR` constant.
    mapping(uint256 => mapping(address => uint256)) public rpTokensARPS; // (poolID => token => arps)
    /// Time distributed rewards
    TimeDistributedReward[] public rpTimeDistRewards;
    mapping(bytes4 => uint256) idToIndexTDR;
    uint256 idSeedTDR;

    /// @notice RewardsPool surplus.
    mapping(address => uint256) public rpSurplus;

    /// @notice Rewards & Reward debts for each user.
    /// (staker => poolID => token => qty)
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public rewards;
    /// (staker => poolID => token => qty)
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public rewardDebts;

    /// @notice Information about partners' tokens.
    /// (token => index)
    mapping(address => uint256) public partnerTokenAddrToIndex;
    /// (token => isPresent)
    mapping(address => bool) public isPartnerToken;
    IERC20[] public partnerTokens;

    /// @notice User pools.
    Pool[] public pools;
    uint256 public totalAlgmStaked;

    /// @notice Information about stakers, their stakes, etc.
    mapping(uint256 => mapping(address => Stake)) public stakes; // (poolID => staker)
    mapping(address => WithdrawalRequest[]) public withdrawalRequests;
    mapping(address => uint256) stakerAddrToIndex;
    address[] stakers;
    uint256 withdrawalRequestID;
    uint256 totalStakers;

    /// @notice Addresses of contracts, etc.
    address[] public authorizedList;
    ILLMaster public liqlend;
    IVeALGM public veAlgm;
    IERC20 public algm;

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                     EVENTS                      */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    event Staked(
        address indexed staker,
        uint256 poolID,
        uint256 algmQty,
        uint256 veAlgmQty
    );

    event Unstaked(
        address indexed staker,
        uint256 poolID,
        uint256 algmQty,
        uint256 withdrawAfter,
        uint256 withdrawalRequestID
    );

    event Withdrawn(
        address indexed staker,
        uint256 withdrawalRequestID,
        uint256 qty
    );

    event ClaimedRewards(
        address indexed staker,
        uint256 poolID,
        uint256 astr,
        IERC20[] tokensList,
        uint256[] tokensQty
    );

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                    MODIFIERS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    modifier onlyAuthorized() {
        _revertIfNotAuthorized();
        _;
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                   INITIALIZE                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    function initialize(IERC20 _algm, IVeALGM _veAlgm) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();

        // set ALGM contract addr
        algm = _algm;

        // set veALGM contract addr
        veAlgm = _veAlgm;

        // create pools
        pools.push( // 1st
            Pool({
                shareOfRewardsPool: 1000,
                veAlgmPerStake: 2000,
                unbondPeriod: 10 days,
                totalStaked: 0
            })
        );

        pools.push( // 2nd
            Pool({
                shareOfRewardsPool: 3000,
                veAlgmPerStake: 5000,
                unbondPeriod: 30 days,
                totalStaked: 0
            })
        );

        pools.push( // 3rd
            Pool({
                shareOfRewardsPool: 6000,
                veAlgmPerStake: 10000,
                unbondPeriod: 60 days,
                totalStaked: 0
            })
        );
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                 STAKING & REL.                  */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /**
     * @dev Stake ALGM and receive veALGM & rewards from RewardsPool.
     *
     * @param poolID ID of pool to stake in
     * @param stakeQty ALGM amount to be staked
     */
    function stake(uint256 poolID, uint256 stakeQty) external whenNotPaused {
        require(poolID < pools.length, "Wrong poolID");
        require(stakeQty >= MIN_STAKE, "Insufficient Qty");
        require(algm.balanceOf(msg.sender) >= stakeQty, "Insufficient Funds");

        require(
            _checkIfAllowedToStakeInPool(msg.sender, poolID),
            "Not Main Product User"
        );

        _updateTimeDistRewards();
        _updateStakerRewardsInPool(msg.sender, poolID, stakeQty, true);
        _addStakerIfNecessary(msg.sender);

        algm.transferFrom(msg.sender, address(this), stakeQty);

        stakes[poolID][msg.sender].algmQty += stakeQty;
        pools[poolID].totalStaked += stakeQty;
        totalAlgmStaked += stakeQty;

        uint256 veAlgmQty = _calculateVeALGM(stakeQty, poolID);
        stakes[poolID][msg.sender].veAlgmQty += veAlgmQty;
        veAlgm.mint(msg.sender, veAlgmQty);

        emit Staked(msg.sender, poolID, stakeQty, veAlgmQty);
    }

    /**
     * @dev Create ALGM withdrawal request and lose veALGM.
     *      Rewards are accumulated until unbond period expires.
     *
     * @param poolID ID of pool to unstake from
     * @param unstakeQty ALGM amount to be unstaked
     */
    function unstake(uint256 poolID, uint256 unstakeQty) external whenNotPaused {
        require(poolID < pools.length, "Wrong poolID");
        require(unstakeQty > 0, "Zero Qty");

        Stake storage _stake = stakes[poolID][msg.sender];
        uint256 stakedQty = _stake.algmQty;

        require(stakedQty >= unstakeQty, "Qty Exceeds Stake");

        uint256 withdrawAfter = block.timestamp + pools[poolID].unbondPeriod;

        withdrawalRequests[msg.sender].push(
            WithdrawalRequest({
                id: ++withdrawalRequestID,
                qty: unstakeQty,
                withdrawAfter: withdrawAfter,
                poolID: poolID
            })
        );

        _updateTimeDistRewards();

        uint256 veAlgmQty;
        if (stakedQty == unstakeQty) {
            veAlgmQty = _stake.veAlgmQty;
        } else {
            veAlgmQty = _calculateVeALGM(unstakeQty, poolID);
        }

        _stake.veAlgmQty -= veAlgmQty;
        veAlgm.burn(msg.sender, veAlgmQty);

        emit Unstaked(
            msg.sender,
            poolID,
            unstakeQty,
            withdrawAfter,
            withdrawalRequestID
        );
    }

    /**
     * @dev Withdraw ALGM after unbond period expires.
     *      Rewards will no longer be accumulated.
     *
     * @param id WithdrawalRequestID from webapp
     */
    function withdraw(uint256 id) external whenNotPaused {
        require(withdrawalRequests[msg.sender].length > 0, "No Pending Requests");

        uint256 reqIndex = _getWithdrawalRequestIndexById(msg.sender, id);
        WithdrawalRequest memory req = withdrawalRequests[msg.sender][reqIndex];
        Stake storage _stake = stakes[req.poolID][msg.sender];

        require(block.timestamp > req.withdrawAfter, "Active Unbond Period");

        _updateTimeDistRewards();
        _updateStakerRewardsInPool(msg.sender, req.poolID, req.qty, false);

        pools[req.poolID].totalStaked -= req.qty;
        totalAlgmStaked -= req.qty;

        if (req.qty == _stake.algmQty) {
            delete stakes[req.poolID][msg.sender];
        } else {
            _stake.algmQty -= req.qty;
        }

        algm.transfer(msg.sender, req.qty);

        _delStakerIfNecessary(msg.sender);
        _delWithdrawalRequestByIndex(msg.sender, reqIndex);

        emit Withdrawn(msg.sender, id, req.qty);
    }

    /**
     * @dev Claim available rewards from staking
     *
     * @param poolID ID of pool
     */
    function claimRewards(uint256 poolID) external whenNotPaused {
        require(poolID < pools.length, "Wrong poolID");

        _updateTimeDistRewards();

        (
            uint256 astrQty,
            IERC20[] memory tokensList,
            uint256[] memory tokensQty,
            bool rewardsAvailableFlag
        ) = calculateRewards(msg.sender, poolID);

        if (!rewardsAvailableFlag) revert("Nothing To Claim");

        uint256 currStake = stakes[poolID][msg.sender].algmQty;

        if (astrQty > 0) {
            uint256 astrARPS = rpTokensARPS[poolID][ASTR];
            rewards[msg.sender][poolID][ASTR] = 0;
            rewardDebts[msg.sender][poolID][ASTR] =
                (currStake * astrARPS) /
                PRECISION;

            rpTokensQty[ASTR] -= astrQty;

            (bool sent, ) = msg.sender.call{value: astrQty}("");
            require(sent, "ASTR Transfer Failed");
        }

        for (uint i; i < tokensList.length; i++) {
            address token = address(partnerTokens[i]);

            if (tokensQty[i] > 0) {
                uint256 tokenARPS = rpTokensARPS[poolID][token];
                rewards[msg.sender][poolID][token] = 0;
                rewardDebts[msg.sender][poolID][token] =
                    (currStake * tokenARPS) /
                    PRECISION;

                rpTokensQty[token] -= tokensQty[i];

                IERC20(token).transfer(msg.sender, tokensQty[i]);
            }
        }

        emit ClaimedRewards(msg.sender, poolID, astrQty, tokensList, tokensQty);
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                   VIEW FUNCS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /**
     * @dev Calculate available rewards before claiming
     *
     * @param staker Stakers' address
     * @param poolID ID of pool
     *
     * @return - Rewards in ASTR
     * @return - Array of Partners' Tokens addresses
     * @return - Array of balances for those tokens
     * @return - True if there are rewards to claim
     */
    function calculateRewards(
        address staker,
        uint256 poolID
    ) public view returns (uint256, IERC20[] memory, uint256[] memory, bool) {
        bool rewardsAvailableFlag;

        (
            uint256 astrQtyGeneral,
            ,
            uint256[] memory tokensQtyGeneral
        ) = _calculateRewards(staker, poolID);

        (
            uint256 astrQtyTimeDist,
            ,
            uint256[] memory tokensQtyTimeDist
        ) = _calculateTimeDistRewards(staker, poolID);

        uint256 astrRewards = astrQtyGeneral + astrQtyTimeDist;
        if (astrRewards > 0) rewardsAvailableFlag = true;

        uint256 totalPartnerTokens = partnerTokens.length;
        uint256[] memory tokenBalances = new uint256[](totalPartnerTokens);

        for (uint256 i; i < totalPartnerTokens; i++) {
            tokenBalances[i] = tokensQtyGeneral[i] + tokensQtyTimeDist[i];

            if (!rewardsAvailableFlag) {
                if (tokenBalances[i] > 0) rewardsAvailableFlag = true;
            }
        }

        return (
            astrRewards,
            getPartnerTokensList(),
            tokenBalances,
            rewardsAvailableFlag
        );
    }

    /**
     * @dev Retrieve pending withdrawal requests.
     *
     * @param addr Address to query for
     * @return Arary of pending requests
     */

    function getPendingWithdrawalRequests(
        address addr
    ) external view returns (WithdrawalRequest[] memory) {
        return withdrawalRequests[addr];
    }

    /**
     * @dev Retrieve list of active stakers.
     *
     * @return Total stakers amount and array of their addresses
     */
    function getStakers() external view returns (uint256, address[] memory) {
        return (totalStakers, stakers);
    }

    /**
     * @dev Retrieve list of partners' tokens.
     *      Rewards in those tokens are to be accumulated.
     *
     * @return Array of token addresses wrapped in interface
     */
    function getPartnerTokensList() public view returns (IERC20[] memory) {
        return partnerTokens;
    }

    /**
     * @dev Get list of addresses authorized to call top up func.
     */
    function getAuthorizedList() external view returns (address[] memory) {
        return authorizedList;
    }

    /**
     * @dev Get list of time distributed rewards present in RewardPool.
     */
    function getTimeDistRewards()
        public
        view
        returns (TimeDistributedReward[] memory)
    {
        return rpTimeDistRewards;
    }

    /**
     * @dev Get the actual staked amount.
     *      It is a difference between whole staked amount in pool
     *      and amount from pending withdrawal requests in that pool,
     *      if there are any.
     *
     * @param staker Staker address
     * @param poolID ID of pool
     * @return ALGM amount
     */
    function getActualStakeQty(
        address staker,
        uint256 poolID
    ) external view returns (uint256) {
        uint256 stakedQty = stakes[poolID][staker].algmQty;

        uint256 l = withdrawalRequests[staker].length;
        for (uint i; i < l; i++) {
            if (withdrawalRequests[staker][i].poolID == poolID)
                stakedQty -= withdrawalRequests[staker][i].qty;
        }

        return stakedQty;
    }

    /**
     * @dev Check if user is allowed to stake in 2 & 3 pools.
     *
     * @param staker Address being checked
     * @param poolID ID of pool
     * @return True if allowed, false otherwise
     */
    function checkIfAllowedToStakeInPool(
        address staker,
        uint256 poolID
    ) external view returns (bool) {
        return _checkIfAllowedToStakeInPool(staker, poolID);
    }

    /**
     * @dev Check whether address is active staker.
     */
    function checkIfStaker(address user) external view returns (bool) {
        if (stakers.length == 0) return false;
        else if (stakers[0] == user) return true;
        else return stakerAddrToIndex[user] != 0;
    }

    /**
     * @dev Get current pools weights.
     *
     * @return Array of weights of each pool.
     */
    function getPoolsWeights() external view returns (uint256[3] memory) {
        return _getPoolsWeights();
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                 OWNER & AUTH.                   */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /**
     * @dev Top up RewardsPool with ASTR or one of partners' tokens.
     *      When topping up with ASTR provide address from `ASTR` constant as `token`
     *      argument and arbitrary non-zero uint as `qty`.
     *      Applicable `msg.value` would be accounted instead.
     *      Contracts' functions that gonna call this function
     *      have to `IERC20(token).approve(address(this), qty)`
     *      before actually calling this function.
     *
     * @param token Address of token being added
     * @param qty Amount of token
     */
    function topUpRewardsPool(
        address token,
        uint256 qty
    ) external payable onlyAuthorized {
        require(token == ASTR || isPartnerToken[token], "Token Not In List");
        require(qty > 0, "Zero Qty");

        if (token == ASTR) {
            qty = msg.value;
        } else {
            require(msg.value == 0, "Non-zero msg.value");
            IERC20(token).transferFrom(msg.sender, address(this), qty);
        }

        rpTokensQty[token] += qty;
        _updateTokenARPSinPools(token, qty, _getPoolsWeights());
    }

    /**
     * @dev Top up RewardsPool with ASTR or one of partners' tokens.
     *      This particular reward distribution is specified as `timeframe` argument.
     *      When topping up with ASTR provide address from `ASTR` constant as `token`
     *      argument and arbitrary non-zero uint as `qty`.
     *      Applicable `msg.value` would be accounted instead.
     *      EOA that gonna call this function have to
     *      `IERC20(token).approve(address(this), qty)`
     *      before actually calling this function.
     *
     * @param token Address of token being added
     * @param qty Amount of token
     * @param timeframe Duration of particular reward distribution
     */
    function topUpRewardsPoolFor(
        address token,
        uint256 qty,
        uint256 timeframe
    ) external payable onlyOwner {
        require(token == ASTR || isPartnerToken[token], "Token Not In List");
        require(qty > 0, "Zero Qty");
        require(timeframe > 0, "Zero Timeframe");
        require(qty / timeframe > 0, "Zero Slice Value");

        if (token == ASTR) {
            qty = msg.value;
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), qty);
        }

        uint256 startAt = block.timestamp;
        uint256 indexOfId = rpTimeDistRewards.length;
        bytes4 id = bytes4(keccak256(abi.encodePacked(++idSeedTDR)));

        idToIndexTDR[id] = indexOfId;

        rpTimeDistRewards.push(
            TimeDistributedReward({
                id: id,
                token: token,
                qty: qty,
                startAt: startAt,
                timeframe: timeframe,
                slicesDistributed: 0,
                sliceValue: qty / timeframe,
                poolsWeights: _getPoolsWeights()
            })
        );

        rpTokensQty[token] += qty;
    }

    /**
     * @dev Change how rewards are distributed between pools.
     *
     * @param weights An array of numbers, none of elements of which is zero.
     *                Sum of weights must be equal to `MAX_BPS`.
     */
    function setPoolWeights(uint256[] calldata weights) external onlyOwner {
        uint256 len = pools.length;
        uint256 weightSum;
        for (uint poolID; poolID < len; poolID++) {
            weightSum += weights[poolID];
        }
        require(weightSum == MAX_BPS, "Wrong Weights Ratio");

        for (uint poolID; poolID < len; poolID++) {
            Pool storage pool = pools[poolID];
            pool.shareOfRewardsPool = weights[poolID];
        }
    }

    /**
     * @dev Add ERC20 token address to partners' tokens list,
     *      thus including it to RewardsPool distribution.
     *
     * @param token Address of addend token
     */
    function addPartnerToken(address token) external onlyOwner {
        require(token != address(0), "Zero Address");
        require(!isPartnerToken[token], "Already Used Token");

        isPartnerToken[token] = true;
        partnerTokenAddrToIndex[token] = partnerTokens.length;
        partnerTokens.push(IERC20(token));
    }

    /**
     * @dev Delete ERC20 token address from partners' tokens list,
     *      thus excluding it from distribution as reward asset.
     *
     * @param token Address of deletee token
     */
    function delPartnerToken(address token) external onlyOwner {
        require(isPartnerToken[token], "Token Not Used");
        require(rpTokensQty[token] < PRECISION, "Token Pool Balance Not Empty");

        uint256 deleteeIndex = partnerTokenAddrToIndex[token];
        uint256 lastIndex = partnerTokens.length - 1;
        address lastAddr = address(partnerTokens[lastIndex]);

        partnerTokens[deleteeIndex] = partnerTokens[lastIndex];
        partnerTokens.pop();
        partnerTokenAddrToIndex[lastAddr] = deleteeIndex;
    }

    /**
     * @dev Withdraw ERC20 tokens accidentially sent to this contract.
     *      Will throw if caller tries to withdraw any of partners' tokens
     *      in amount exceeding the difference between `token.balanceOf(address(this))`
     *      and RewardsPool balance of that very token.
     *
     * @param token Address of token
     * @param to Recipient address
     * @param qty Amount being withdrawn
     */
    function withdrawStuck(
        address token,
        address to,
        uint256 qty
    ) external onlyOwner {
        require(to != address(0), "Zero Address");
        require(qty > 0, "Zero Qty");

        if (isPartnerToken[token]) {
            uint256 totalBalance = IERC20(token).balanceOf(address(this));
            uint256 allocatedBalance = rpTokensQty[token] + rpSurplus[token];
            uint256 stuckQty = totalBalance - allocatedBalance;

            require(qty <= stuckQty, "Qty Overflow");

            IERC20(token).transfer(to, qty);
        } else if (token == address(algm)) {
            uint256 totalBalance = IERC20(token).balanceOf(address(this));
            uint256 stuckQty = totalBalance - totalAlgmStaked;

            require(qty <= stuckQty, "Qty Overflow");

            IERC20(token).transfer(to, qty);
        } else {
            uint256 stuckQty = IERC20(token).balanceOf(address(this));

            require(qty <= stuckQty, "Qty Overflow");

            IERC20(token).transfer(to, qty);
        }
    }

    /**
     * @dev Withdraw ASTR or ERC20 tokens sent to RewardPool while there was no stakers.
     *      Will throw if caller tries to withdraw any amount exceeding
     *      `rpSurplus[token]` amount.
     *
     * @param token Address of token
     * @param to Recipient address
     * @param qty Amount being withdrawn
     */
    function withdrawSurplus(
        address token,
        address to,
        uint256 qty
    ) external onlyOwner {
        require(to != address(0), "Zero Address");
        require(qty > 0, "Zero Qty");
        require(qty <= rpSurplus[token], "Qty Overflow");

        if (token == ASTR) {
            rpSurplus[token] -= qty;

            (bool sent, ) = to.call{value: qty}("");
            require(sent, "Transfer Failed");
        } else {
            rpSurplus[token] -= qty;

            IERC20(token).transfer(to, qty);
        }
    }

    /**
     * @dev Replace the contents of `authorizedList` with new addresses.
     *      Addresses from this list can call top up functions.
     *
     * @param authorized Array of addresses
     */
    function updateAuthorizedList(address[] calldata authorized) external onlyOwner {
        require(authorized.length > 0, "Empty List");

        authorizedList = authorized;
    }

    /**
     * @dev Append address to `authorizedList`.
     *      Address can be deleted by submiting
     *      new array w/o deletee addr to `updateAuthorizedList`.
     *
     * @param addr Address to be added
     */
    function appendAuthrizedList(address addr) external onlyOwner {
        require(addr != address(0), "Zero Address");

        authorizedList.push(addr);
    }

    /**
     * @dev Halt execution of all user functions.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Allow execution of all user functions.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Setter func for LiquidLending contract.
     */
    function setLiquidLendingAddr(ILLMaster _liqlend) external onlyOwner {
        require(address(_liqlend) != address(0), "ZeroAddress");
        require(_liqlend != liqlend, "SameAddress");

        liqlend = _liqlend;
    }

    /* • • • • • • • • • • • • • • • • • • • • • • • • */
    /*                    INTERNALS                    */
    /* • • • • • • • • • • • • • • • • • • • • • • • • */

    /**
     * @dev Inline revert function. Used in corresponding modifier.
     */
    function _revertIfNotAuthorized() internal view {
        uint256 l = authorizedList.length;
        for (uint i; i < l; i++) {
            if (msg.sender == authorizedList[i]) return;
        }

        revert("Not In Auth List");
    }

    /**
     * @dev Calculate veALGM qty depending of ALGM qty being staked.
     */
    function _calculateVeALGM(
        uint256 qty,
        uint256 poolID
    ) internal view returns (uint256) {
        if (poolID == pools.length - 1) return qty;

        return ((qty * pools[poolID].veAlgmPerStake) / MAX_BPS);
    }

    /**
     * @dev Get WithdrawalRequest index from array in storage by its' ID.
     */
    function _getWithdrawalRequestIndexById(
        address a,
        uint256 id
    ) internal view returns (uint256) {
        for (uint i; i < withdrawalRequests[a].length; i++) {
            if (withdrawalRequests[a][i].id == id) return i;
        }

        revert("ID not found");
    }

    /**
     * @dev Delete WithdrawalRequest from array in storage by its' index.
     */
    function _delWithdrawalRequestByIndex(address a, uint256 i) internal {
        uint256 l = withdrawalRequests[a].length;

        WithdrawalRequest[] storage list = withdrawalRequests[a];

        list[i] = list[l - 1];
        list.pop();
    }

    /**
     * @dev Add staker address to array in storage on his first stake.
     */
    function _addStakerIfNecessary(address addend) internal {
        uint256 staked;
        uint256 len = pools.length;
        for (uint poolID; poolID < len; poolID++) {
            staked += stakes[poolID][addend].algmQty;
        }

        if (staked == 0) {
            stakers.push(addend);
            stakerAddrToIndex[addend] = totalStakers++;
        }
    }

    /**
     * @dev Delete staker address from array in storage
     *      if he withdraws all remaining staked ALGM.
     */
    function _delStakerIfNecessary(address deletee) internal {
        uint256 staked;
        uint256 len = pools.length;
        for (uint poolID; poolID < len; poolID++) {
            staked += stakes[poolID][deletee].algmQty;
        }

        if (staked == 0) {
            uint256 deleteeIndex = stakerAddrToIndex[deletee];
            uint256 lastIndex = stakers.length - 1;
            address lastAddr = stakers[lastIndex];

            delete stakerAddrToIndex[deletee];
            stakers[deleteeIndex] = stakers[lastIndex];
            stakers.pop();
            stakerAddrToIndex[lastAddr] = deleteeIndex;
            --totalStakers;
        }
    }

    /**
     * @dev Update staker rewards in ASTR and PartnerTokens
     *      from a certain pool when he either
     *      stakes or withdraws ALGM.
     */
    function _updateStakerRewardsInPool(
        address staker,
        uint256 poolID,
        uint256 qty,
        bool adding
    ) internal {
        uint256 currStake = stakes[poolID][staker].algmQty;

        // ASTR
        uint256 currAstrARPS = rpTokensARPS[poolID][ASTR];
        rewards[staker][poolID][ASTR] +=
            (currStake * currAstrARPS) /
            PRECISION -
            rewardDebts[staker][poolID][ASTR];

        if (adding) {
            rewardDebts[staker][poolID][ASTR] =
                ((currStake + qty) * currAstrARPS) /
                PRECISION;
        } else {
            rewardDebts[staker][poolID][ASTR] =
                ((currStake - qty) * currAstrARPS) /
                PRECISION;
        }

        // Partners' tokens
        uint256 totalPartnerTokens = partnerTokens.length;
        for (uint256 i; i < totalPartnerTokens; i++) {
            address token = address(partnerTokens[i]);
            uint256 currTokenARPS = rpTokensARPS[poolID][token];

            rewards[staker][poolID][token] +=
                (currStake * currTokenARPS) /
                PRECISION -
                rewardDebts[staker][poolID][token];

            if (adding) {
                rewardDebts[staker][poolID][token] =
                    ((currStake + qty) * currTokenARPS) /
                    PRECISION;
            } else {
                rewardDebts[staker][poolID][token] =
                    ((currStake - qty) * currTokenARPS) /
                    PRECISION;
            }
        }
    }

    /**
     * @dev Update ARPS for tokens distrubuted within TimeDistRewards.
     *      Also function will delete finished TimeDistRewards entries from storage.
     */
    function _updateTimeDistRewards() internal {
        uint256 rewdLen = rpTimeDistRewards.length;
        if (rewdLen == 0) return;

        bytes4[] memory completedIDs = new bytes4[](rewdLen);

        for (uint256 i; i < rewdLen; i++) {
            TimeDistributedReward storage tdr = rpTimeDistRewards[i];

            if (tdr.timeframe > tdr.slicesDistributed) {
                uint256 slicesPassed = block.timestamp - tdr.startAt;
                uint256 availableSlices = slicesPassed - tdr.slicesDistributed;
                uint256 slicesToAdd = block.timestamp < tdr.startAt + tdr.timeframe
                    ? availableSlices
                    : tdr.timeframe - tdr.slicesDistributed;

                uint256 qtyToAdd = slicesToAdd * tdr.sliceValue;
                _updateTokenARPSinPools(tdr.token, qtyToAdd, tdr.poolsWeights);
                tdr.slicesDistributed += slicesToAdd;
            } else {
                completedIDs[i] = tdr.id;
            }
        }

        for (uint256 i; i < rewdLen; i++) {
            bytes4 id = completedIDs[i];

            if (id != bytes4(0)) _delTimeDistRewardById(id);
        }
    }

    /**
     * @dev Update APRS for specified token when topping up RewardPool.
     *      If any of three existing pools have zero stakes, qty of token
     *      corresponding to pool share will be written as surplus
     *      and be available for withdrawal by contract owner.
     */
    function _updateTokenARPSinPools(
        address token,
        uint256 qty,
        uint256[3] memory weights
    ) internal {
        for (uint256 poolID; poolID < pools.length; poolID++) {
            Pool storage pool = pools[poolID];

            if (pool.totalStaked == 0) {
                uint256 surplusQty = (qty * weights[poolID]) / MAX_BPS;
                rpSurplus[token] += surplusQty;
                rpTokensQty[token] -= surplusQty;
            } else {
                rpTokensARPS[poolID][token] +=
                    ((qty * weights[poolID] * PRECISION) / MAX_BPS) /
                    pool.totalStaked;
            }
        }
    }

    /**
     * @dev Delete TimeDistReward entry from array in storage by it's id.
     */
    function _delTimeDistRewardById(bytes4 deleteeID) internal {
        TimeDistributedReward[] storage rewdList = rpTimeDistRewards;
        uint256 l = rpTimeDistRewards.length;

        uint256 deleteeIndex = idToIndexTDR[deleteeID];
        uint256 lastIndex = l - 1;
        bytes4 lastId = rpTimeDistRewards[lastIndex].id;

        delete idToIndexTDR[deleteeID];
        rewdList[deleteeIndex] = rewdList[lastIndex];
        rewdList.pop();
        idToIndexTDR[lastId] = deleteeIndex;
    }

    /**
     * @dev Calculate available and, if eligible, predictable rewards
     *      for a staker in certain pool.
     */
    function _calculateRewards(
        address staker,
        uint256 poolID
    ) internal view returns (uint256, IERC20[] memory, uint256[] memory) {
        uint256 currStake = stakes[poolID][staker].algmQty;

        bool calcPredicted;
        if (currStake > 0) calcPredicted = true;

        // ASTR
        uint256 astrAvailableRewards = rewards[staker][poolID][ASTR];

        if (calcPredicted) {
            uint256 astrPredictedRewards = (currStake * rpTokensARPS[poolID][ASTR]) /
                PRECISION -
                rewardDebts[staker][poolID][ASTR];

            astrAvailableRewards += astrPredictedRewards;
        }

        // Partner tokens
        uint256[] memory tokenBalances = new uint256[](partnerTokens.length);
        for (uint256 i; i < partnerTokens.length; i++) {
            address token = address(partnerTokens[i]);
            uint256 tokenARPS = rpTokensARPS[poolID][token];
            uint256 tokenAvailableRewards = rewards[staker][poolID][token];

            if (calcPredicted) {
                uint256 currRewardDebt = rewardDebts[staker][poolID][token];
                uint256 tokenPredictedRewards = (currStake * tokenARPS) /
                    PRECISION -
                    currRewardDebt;

                tokenAvailableRewards += tokenPredictedRewards;
            }

            tokenBalances[i] = tokenAvailableRewards;
        }

        return (astrAvailableRewards, getPartnerTokensList(), tokenBalances);
    }

    /**
     * @dev Calculate available time distributed rewards
     *      for a staker in certain pool.
     */
    function _calculateTimeDistRewards(
        address staker,
        uint256 poolID
    ) internal view returns (uint256, IERC20[] memory, uint256[] memory) {
        uint256 currStake = stakes[poolID][staker].algmQty;
        uint256[] memory tokenBalances = new uint256[](partnerTokens.length);

        if (rpTimeDistRewards.length == 0) {
            return (0, new IERC20[](0), tokenBalances);
        }

        uint256 astrRewards;

        for (uint256 i; i < rpTimeDistRewards.length; i++) {
            TimeDistributedReward memory tdr = rpTimeDistRewards[i];

            if (tdr.timeframe > tdr.slicesDistributed) {
                uint256 slicesPassed = block.timestamp - tdr.startAt;
                uint256 availableSlices = slicesPassed - tdr.slicesDistributed;
                uint256 slicesToAdd = block.timestamp < tdr.startAt + tdr.timeframe
                    ? availableSlices
                    : tdr.timeframe - tdr.slicesDistributed;
                uint256 tokenARPS = ((((slicesToAdd * tdr.sliceValue) / MAX_BPS) *
                    tdr.poolsWeights[poolID]) * PRECISION) /
                    pools[poolID].totalStaked;

                if (tdr.token == ASTR) {
                    astrRewards += (tokenARPS * currStake) / PRECISION;
                } else {
                    for (uint j; j < partnerTokens.length; j++) {
                        if (tdr.token == address(partnerTokens[j])) {
                            uint256 tokenRewards = (tokenARPS * currStake) /
                                PRECISION;

                            tokenBalances[j] += tokenRewards;
                        } else {
                            tokenBalances[j] = 0;
                        }
                    }
                }
            }
        }

        return (astrRewards, getPartnerTokensList(), tokenBalances);
    }

    /**
     * @dev Inline function for user permission check.
     */
    function _checkIfAllowedToStakeInPool(
        address staker,
        uint256 poolID
    ) internal view returns (bool) {
        if (poolID != 0) {
            (, uint256[] memory balances) = liqlend.getUserPools(staker);
            return balances.length > 0;
        }

        return true;
    }

    /**
     * @dev Inline funciton returning pools weights.
     */
    function _getPoolsWeights() internal view returns (uint256[3] memory weights) {
        for (uint i; i < pools.length; i++) {
            weights[i] = pools[i].shareOfRewardsPool;
        }
    }
}
