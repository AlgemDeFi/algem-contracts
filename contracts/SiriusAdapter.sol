//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ISiriusFarm.sol";
import "./interfaces/ISiriusPool.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IAdaptersDistributor.sol";
import "./LiquidStaking/LiquidStaking.sol";

contract SiriusAdapter is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ISiriusPool public pool;
    ISiriusFarm public farm;
    IERC20Upgradeable public lp;
    IERC20Upgradeable public nToken;
    IERC20Upgradeable public gauge;
    IERC20Upgradeable public srs;
    IMinter public minter;

    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations
    uint256 public constant REVENUE_FEE = 10; // 10% of claimed rewards goes to revenue pool

    uint256 public accumulatedRewardsPerShare;
    uint256 public revenuePool;
    uint256 public totalStaked;

    mapping(address => uint256) public lpBalances;
    mapping(address => uint256) public gaugeBalances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardDebt;

    bool public abilityToAddLpAndGauge;

    IAdaptersDistributor public adaptersDistributor;
    string public utilityName;

    bool private _paused;

    event AddLiquidity(
        address indexed user,
        uint256[] indexed amounts,
        bool autoStake,
        uint256 indexed lpAmount
    );
    event RemoveLiquidity(
        address indexed user,
        uint256 amountLP,
        uint256 indexed receivedASTR
    );
    event DepositLP(address indexed, uint256 amount);
    event WithdrawLP(
        address indexed user,
        uint256 indexed amount,
        bool indexed autoWithdraw
    );
    event Claim(address indexed user, uint256 indexed amount);
    event HarvestRewards(
        address indexed user,
        uint256 indexed rewardsToHarvest
    );
    event SetAbilityToAddLpAndGauge(bool indexed _b);
    event UpdateBalSuccess(address user, string utilityName, uint256 amount);
    event UpdateBalError(address user, string utilityName, uint256 amount, string reason);
    event Paused(address account);
    event Unpaused(address account);

    // @notice Updates rewards
    modifier update() {
        // check if there are unclaimed rewards
        uint256 unclaimedRewards = farm.claimableTokens(address(this));
        if (unclaimedRewards > 0) {
            updatePoolRewards();
        }
        harvestRewards();
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!_paused, "Not available when paused");
        _;
    }

    /// @notice Provides access only to managers
    modifier onlyManager() {
        LiquidStaking ls = LiquidStaking(payable(0x70d264472327B67898c919809A9dc4759B6c0f27));
        require(ls.hasRole(ls.MANAGER(), msg.sender), "For MANAGER role only");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        ISiriusPool _pool,
        ISiriusFarm _farm,
        IERC20Upgradeable _lp,
        IERC20Upgradeable _nToken,
        IERC20Upgradeable _gauge,
        IERC20Upgradeable _srs,
        IMinter _minter
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        pool = _pool;
        farm = _farm;
        lp = _lp;
        nToken = _nToken;
        gauge = _gauge;
        srs = _srs;
        minter = _minter;
        setAbilityToAddLpAndGauge(true);
    }

    // @notice To receive funds from pool contrct
    receive() external payable {
        require(msg.sender == address(pool), "Sending tokens not allowed");
    }

    // @notice Withdraw revenue part in SRS tokens
    // @param _amount Amount of funds to withdraw
    function withdrawRevenue(uint256 _amount) external onlyOwner {
        require(
            srs.balanceOf(address(this)) >= _amount,
            "Not enough SRS revenue"
        );
        require(_amount > 0, "Should be greater than zero!");
        revenuePool -= _amount;
        srs.safeTransfer(msg.sender, _amount);
    }

    // @notice After the transition of all users to adapters
    //         addLp() and addGauge() will be disabled by this function
    // @param _b enable or disable functionality
    function setAbilityToAddLpAndGauge(bool _b) public onlyOwner {
        abilityToAddLpAndGauge = _b;
        emit SetAbilityToAddLpAndGauge(_b);
    }

    // @notice Add liquidity to the pool with the given amounts of tokens
    // @param _amounts The amounts of each token to add
    //        idx 0 is ASTR, idx 1 is nASTR
    // @param _autoStake If true, LP tokens go to stake at the same tx
    function addLiquidity(uint256[] calldata _amounts, bool _autoStake)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            msg.value == _amounts[0],
            "Value need to be equal to amount of ASTR tokens"
        );
        require(
            _amounts[0] > 0 && _amounts[1] > 0,
            "Amounts of tokens should be greater than zero"
        );
        require(
            _amounts.length == 2,
            "The length of amounts must be equal to two"
        );

        nToken.safeTransferFrom(msg.sender, address(this), _amounts[1]);

        uint256 calculatedLpAmount = pool.calculateTokenAmount(_amounts, true);
        require(
            calculatedLpAmount > 0,
            "Calculated LP amount should be greater than zero"
        );

        uint256 minToMint = (calculatedLpAmount * 9) / 10; // min amount for slippage control

        // allow the pool take the _amount of nastr
        nToken.approve(address(pool), _amounts[1]);

        uint256 lpAmount = pool.addLiquidity{value: msg.value}(
            _amounts,
            minToMint,
            block.timestamp + 1200
        );
        lpBalances[msg.sender] += lpAmount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        if (_autoStake) {
            depositLP(lpAmount);
        }
        emit AddLiquidity(msg.sender, _amounts, _autoStake, lpAmount);
    }

    // @notice Remove liquidity from the pool
    // @param _amounts Amount of LP tokens to remove
    function removeLiquidity(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Should be greater than zero");
        require(lpBalances[msg.sender] >= _amount, "Not enough LP");

        uint256[] memory minAmounts = calculateRemoveLiquidity(_amount);

        // allow the pool take the _amount of lp
        lp.approve(address(pool), _amount);

        uint256 beforeTokens = address(this).balance;
        uint256 beforeNtokens = nToken.balanceOf(address(this));
        pool.removeLiquidity(_amount, minAmounts, block.timestamp + 1200);
        uint256 afterTokens = address(this).balance;
        uint256 afterNtokens = nToken.balanceOf(address(this));

        uint256 receivedNtokens = afterNtokens - beforeNtokens;
        uint256 receivedTokens = afterTokens - beforeTokens;

        lpBalances[msg.sender] -= _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        nToken.safeTransfer(msg.sender, receivedNtokens);
        payable(msg.sender).sendValue(receivedTokens);
        emit RemoveLiquidity(msg.sender, _amount, receivedTokens);
    }

    // @notice With this function users can transfer LP tokens to their balance in the adapter contract
    //         Needed to move from "handler contracts" to adapters
    // @param _autoDeposit Allows to deposit LP at the same tx
    function addLp(uint256 _amount, bool _autoDeposit) external nonReentrant whenNotPaused {
        require(abilityToAddLpAndGauge, "This functionality disabled");
        require(
            lp.balanceOf(msg.sender) >= _amount,
            "Not enough LP on balance"
        );
        require(_amount > 0, "Shoud be greater than zero");

        lp.safeTransferFrom(msg.sender, address(this), _amount);
        lpBalances[msg.sender] += _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        if (_autoDeposit) {
            depositLP(_amount);
        }
    }

    // @notice Receive Gauge tokens from user
    function addGauge(uint256 _amount) external update nonReentrant whenNotPaused {
        require(abilityToAddLpAndGauge, "Functionality disabled");
        require(
            gauge.balanceOf(msg.sender) >= _amount,
            "Not enough Gauge on balance"
        );
        require(_amount > 0, "Shoud be greater than zero");

        gauge.safeTransferFrom(msg.sender, address(this), _amount);
        gaugeBalances[msg.sender] += _amount;
        totalStaked += _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        // from this moment user can pretend to rewards so set him rewardDebt
        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
    }

    // @notice Deposit LP tokens to farm pool and receives Gauge tokens instead
    // @param _amount Amount of LP tokens
    function depositLP(uint256 _amount) public update whenNotPaused {
        require(lpBalances[msg.sender] >= _amount, "Not enough LP tokens");
        require(_amount > 0, "Should be greater than zero");

        lpBalances[msg.sender] -= _amount;

        // allow the farm take the _amount of lp
        lp.approve(address(farm), _amount);

        uint256 beforeGauge = gauge.balanceOf(address(this));
        farm.deposit(_amount, address(this), false);
        uint256 afterGauge = gauge.balanceOf(address(this));
        uint256 receivedGauge = afterGauge - beforeGauge;

        gaugeBalances[msg.sender] += receivedGauge;

        _updateBalanceInAdaptersDistributor(msg.sender);

        totalStaked += receivedGauge;
        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        emit DepositLP(msg.sender, _amount);
    }

    // @notice Receives LP tokens back instead of Gauge
    // @param _amount Amount of Gauge tokens
    // @param _autoWithdraw If true remove all liquidity at the same tx
    function withdrawLP(uint256 _amount, bool _autoWithdraw) external update whenNotPaused {
        require(
            gaugeBalances[msg.sender] >= _amount,
            "Not enough Gauge tokens"
        );
        require(_amount > 0, "Shoud be greater than zero");

        // allow the farm take the _amount of gauge
        gauge.approve(address(farm), _amount);

        uint256 balBefore = lp.balanceOf(address(this));
        farm.withdraw(_amount, false);
        uint256 balAfter = lp.balanceOf(address(this));
        uint256 receivedAmount = balAfter - balBefore;

        gaugeBalances[msg.sender] -= _amount;
        totalStaked -= _amount;
        lpBalances[msg.sender] += receivedAmount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        rewardDebt[msg.sender] =
            (gaugeBalances[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;

        if (_autoWithdraw) {
            removeLiquidity(_amount);
        }
        emit WithdrawLP(msg.sender, _amount, _autoWithdraw);
    }

    // @notice Collect all rewards by user
    function harvestRewards() private {
        uint256 stakedAmount = gaugeBalances[msg.sender];

        // calculates the user's share of the total number of awards and subtracts from it accumulated rewardDebt
        uint256 rewardsToHarvest = ((stakedAmount *
            accumulatedRewardsPerShare) / REWARDS_PRECISION) -
            rewardDebt[msg.sender];

        rewardDebt[msg.sender] =
            (stakedAmount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;

        // collect user rewards that can be claimed
        rewards[msg.sender] += rewardsToHarvest;

        emit HarvestRewards(msg.sender, rewardsToHarvest);
    }

    // @notice Receives portion of total rewards in SRS tokens from the farm contract
    function updatePoolRewards() private {
        uint256 balBefore = srs.balanceOf(address(this));
        minter.mint(address(gauge));
        uint256 balAfter = srs.balanceOf(address(this));
        uint256 receivedRewards = balAfter > balBefore
            ? balAfter - balBefore
            : 0;
        if (totalStaked == 0) return;

        // increases accumulated rewards per 1 staked token
        accumulatedRewardsPerShare +=
            (receivedRewards * REWARDS_PRECISION) /
            totalStaked;
    }

    // @notice Convert LP tokens to nASTR/ASTR
    // @param _amount Number of LP tokens
    // @return Array of ammounts. ASTR at idx 0, nASTR at idx 1.
    function calculateRemoveLiquidity(uint256 _lpAmount)
        public
        view
        returns (uint256[] memory)
    {
        return pool.calculateRemoveLiquidity(_lpAmount);
    }

    // @notice For claim rewards by users
    function claim() external update nonReentrant whenNotPaused {
        require(rewards[msg.sender] > 0, "User has no any rewards");
        uint256 comissionPart = rewards[msg.sender] / REVENUE_FEE; // 10% comission part which go to revenue pool
        uint256 rewardsToClaim = rewards[msg.sender] - comissionPart;
        revenuePool += comissionPart;
        rewards[msg.sender] = 0;
        srs.safeTransfer(msg.sender, rewardsToClaim);
        emit Claim(msg.sender, rewardsToClaim);
    }

    // @notice update user's nastr balance in AdaptersDistributor
    function _updateBalanceInAdaptersDistributor(address _user) private {
        uint256 nastrBalAfter = calc(_user);
        try adaptersDistributor.updateBalanceInAdapter(utilityName, _user, nastrBalAfter) {
            emit UpdateBalSuccess(_user, utilityName, nastrBalAfter);
        } catch Error(string memory reason) {
            emit UpdateBalError(_user, utilityName, nastrBalAfter, reason);
        }
    }

    // @notice Needs to check user rewards
    // @param _user User address
    // @return sum Amount of penging rewards
    function pendingRewards(address _user) external view returns (uint256 userRewards) {
        uint256 stakedAmount = gaugeBalances[_user];
        if (stakedAmount > 0) {
            userRewards =
                rewards[_user] +
                (stakedAmount * accumulatedRewardsPerShare) /
                REWARDS_PRECISION -
                rewardDebt[_user];
        } else {
            userRewards = rewards[_user];
        }
        uint256 comissionPart = userRewards / REVENUE_FEE;
        userRewards -= comissionPart;
    }

    // @notice Get share of n tokens in pool for user
    // @param _user User's address
    function calc(address _user) public view returns (uint256 nShare) {
        uint256[] memory amounts = new uint256[](2);
        amounts = pool.calculateRemoveLiquidity(
            lpBalances[_user] + gaugeBalances[_user]
        );
        nShare = amounts[1];
    }

    // @notice Disabled functionality to renounce ownership
    function renounceOwnership() public override onlyOwner {
        revert("It is not possible to renounce ownership");
    }

    // @notice shows total staked astr amount
    function totalStakedASTR() public view returns (uint256) {
        uint256[] memory amounts = new uint256[](2);
        uint256 adapterLpBalance = IERC20Upgradeable(lp).balanceOf(address(this));
        amounts = pool.calculateRemoveLiquidity(totalStaked + adapterLpBalance);
        return amounts[0];
    }

    // @notice set adapters distributor by owner
    function setAdaptersDistributor(IAdaptersDistributor _adaptersDistributor) external onlyOwner {
        adaptersDistributor = _adaptersDistributor;
    }

    // @notice set utilityName
    function setUtilityName(string memory _utilityName) external onlyOwner {
        utilityName = _utilityName;
    }

    /// @notice Disabling funcs with the whenNotPaused modifier
    function pause() external onlyManager {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Enabling funcs with the whenNotPaused modifier
    function unpause() external onlyManager {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
