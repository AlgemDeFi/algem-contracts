//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IPancakeRouter01.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPartnerHandler.sol";
import "./interfaces/IAdaptersDistributor.sol";
import "./LiquidStaking/LiquidStaking.sol";

contract ArthswapAdapter is OwnableUpgradeable, ReentrancyGuardUpgradeable, IPartnerHandler {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    //Interfaces
    IMasterChef public farm;
    IPancakeRouter01 public pool;
    IERC20Upgradeable public lp;
    IPancakePair public pair;
    IERC20Upgradeable public nToken;
    IERC20Upgradeable public arswToken;

    uint256 public constant REVENUE_FEE = 10; // 10% of claimed rewards goes to revenue pool
    uint256 public constant SLIPPAGE_CONTROL = 8; // 0.8% of amounts to slippage control. Same values as in the Arthswap pool
    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations
    uint256 private constant SLIPPAGE_PRECISION = 1000; // needed to get certain slippage percentage

    uint256 public accumulatedRewardsPerShare;
    uint256 public revenuePool;
    uint256 public totalStakedLp;
    uint256 private pid;

    mapping(address => uint256) public lpBalances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public depositedLp;
    mapping(address => uint256) public rewardDebt;

    address public constant WASTR = 0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720;
    IAdaptersDistributor public adaptersDistributor;
    string public utilityName;

    address[] public users;
    mapping(address => bool) public isUser;

    bool public paused;

    //Events
    event AddLiquidity(
        address indexed user,
        uint256 astrAmount,
        uint256 nastrAmount,
        bool indexed autoStake,
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
    event UpdateBalSuccess(address user, string utilityName, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // @notice Updates rewards
    modifier update() {
        // check if there are unclaimed rewards
        uint256 unclaimedRewards = farm.pendingARSW(pid, address(this));
        if (unclaimedRewards > 0) {
            updatePoolRewards();
        }
        harvestRewards();
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Not available when paused");
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
        IMasterChef _farm,
        IPancakeRouter01 _pool,
        IERC20Upgradeable _nToken,
        IERC20Upgradeable _lp,
        IPancakePair _pair,
        IERC20Upgradeable _arswToken,
        uint256 _pid
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        farm = _farm;
        pool = _pool;
        lp = _lp;
        nToken = _nToken;
        pair = _pair;
        arswToken = _arswToken;
        pid = _pid;
    }

    // @notice To receive funds from pool contrct
    receive() external payable {
        require(msg.sender == address(pool), "Sending tokens not allowed");
    }

    // @notice Withdraw revenue part
    // @param _amount Amount of funds to withdraw
    function withdrawRevenue(uint256 _amount) external onlyOwner {
        require(
            arswToken.balanceOf(address(this)) >= _amount,
            "Not enough ARSW revenue"
        );
        require(_amount > 0, "Should be greater than zero");
        require(revenuePool >= _amount, "Insufficient funds in the revenue pool");
        revenuePool -= _amount;
        arswToken.safeTransfer(msg.sender, _amount);
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
            _amounts[1] > 0 && _amounts[0] > 0,
            "Amount of the tokens should be greater than zero"
        );
        require(
            _amounts.length == 2,
            "The length of amounts must be equal to two"
        );

        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        nToken.safeTransferFrom(msg.sender, address(this), _amounts[1]);

        // vars for slippage control
        uint256 amountTokenMin = _amounts[1] -
            (_amounts[1] * SLIPPAGE_CONTROL) /
            SLIPPAGE_PRECISION;
        uint256 amountASTRMin = msg.value -
            (msg.value * SLIPPAGE_CONTROL) /
            SLIPPAGE_PRECISION;

        nToken.approve(address(pool), _amounts[1]);

        (,, uint256 receivedLP) = pool.addLiquidityETH{value: msg.value}(
            address(nToken),
            _amounts[1],
            amountTokenMin,
            amountASTRMin,
            address(this),
            block.timestamp + 1200
        );

        lpBalances[msg.sender] += receivedLP;

        _updateBalanceInAdaptersDistributor(msg.sender);

        if (_autoStake) {
            depositLP(receivedLP);
        }

        emit AddLiquidity(
            msg.sender,
            msg.value,
            _amounts[1],
            _autoStake,
            receivedLP
        );
    }

    // @notice Remove liquidity from the pool
    // @param _amount Number of LP tokens ot remove
    function removeLiquidity(uint256 _amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Should be greater than zero");
        require(lpBalances[msg.sender] >= _amount, "Not enough LP tokens");

        uint256[] memory calculatedAmounts = calculateRemoveLiquidity(_amount);
        (uint256 astrPredicted, uint256 nastrPredicted) = (
            calculatedAmounts[0],
            calculatedAmounts[1]
        );

        uint256 amountNASTRmin = nastrPredicted -
            ((nastrPredicted * SLIPPAGE_CONTROL) / SLIPPAGE_PRECISION);
        uint256 amountASTRmin = astrPredicted -
            ((astrPredicted * SLIPPAGE_CONTROL) / SLIPPAGE_PRECISION);

        // allow the pool take the _amount of lp
        lp.approve(address(pool), _amount);

        (uint amountToken, uint amountASTR) = pool.removeLiquidityETH(
            address(nToken),
            _amount,
            amountNASTRmin,
            amountASTRmin,
            address(this),
            block.timestamp + 1200
        );

        lpBalances[msg.sender] -= _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        nToken.safeTransfer(msg.sender, amountToken);

        payable(msg.sender).sendValue(amountASTR);

        emit RemoveLiquidity(msg.sender, amountToken, amountASTR);
    }

    // @notice With this function users can transfer
    //         LP tokens to their balance in the adapter contract
    // @param _autoDeposit Allows to deposit LP at the same tx
    function addLp(uint256 _amount, bool _autoDeposit)
        external
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Should be greater than zero");
        require(
            _amount <= lp.balanceOf(msg.sender),
            "Not enough LP on balance"
        );

        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        lp.safeTransferFrom(msg.sender, address(this), _amount);
        lpBalances[msg.sender] += _amount;

        _updateBalanceInAdaptersDistributor(msg.sender);

        depositLP(_amount);
    }

    // @notice Deposit LP tokens to ARSW allocation
    // @param _amount Number of LP tokens
    function depositLP(uint256 _amount) public update whenNotPaused {
        require(lpBalances[msg.sender] >= _amount, "Not enough LP tokens");
        require(_amount > 0, "Should be greater than zero");

        lpBalances[msg.sender] -= _amount;

        // allow the farm take the _amount of lp
        lp.approve(address(farm), _amount);

        farm.deposit(pid, _amount, address(this));

        depositedLp[msg.sender] += _amount;
        totalStakedLp += _amount;
 
        _updateBalanceInAdaptersDistributor(msg.sender);

        rewardDebt[msg.sender] =
            (depositedLp[msg.sender] * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;

        emit DepositLP(msg.sender, _amount);
    }

    // @notice Withdraw LP tokens from the pool
    // @param _amount Number of LP
    // @param _autoWithdraw Withdraw LP from farm and remove liquidity
    //                      at same transaction, if true
    function withdrawLP(uint256 _amount, bool _autoWithdraw)
        external
        update
        whenNotPaused
    {
        require(
            depositedLp[msg.sender] >= _amount,
            "Not enough deposited LP tokens"
        );
        require(_amount > 0, "Should be greater than zero");

        depositedLp[msg.sender] -= _amount;
        totalStakedLp -= _amount;

        uint256 beforeLp = lp.balanceOf(address(this));
        farm.withdraw(pid, _amount, address(this));
        uint256 afterLp = lp.balanceOf(address(this));
        uint256 receivedLp = afterLp - beforeLp;

        lpBalances[msg.sender] += receivedLp;

        _updateBalanceInAdaptersDistributor(msg.sender);

        rewardDebt[msg.sender] = depositedLp[msg.sender] * accumulatedRewardsPerShare / REWARDS_PRECISION;

        if (_autoWithdraw) {
            removeLiquidity(_amount);
        }

        emit WithdrawLP(msg.sender, _amount, _autoWithdraw);
    }

    // @notice Collect all rewards by user
    function harvestRewards() private {
        uint256 stakedAmount = depositedLp[msg.sender];

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

    // @notice Receives portion of total rewards in ARSW tokens from the farm contract
    function updatePoolRewards() private {
        if (totalStakedLp == 0) return;

        uint256 beforeArsw = arswToken.balanceOf(address(this));
        farm.harvest(pid, address(this));
        uint256 afterArsw = arswToken.balanceOf(address(this));
        uint256 receivedRewards = afterArsw > beforeArsw
            ? afterArsw - beforeArsw
            : 0;

        // increases accumulated rewards per 1 staked token
        accumulatedRewardsPerShare +=
            (receivedRewards * REWARDS_PRECISION) /
            totalStakedLp;
    }

    // @notice update user's nastr balance in AdaptersDistributor
    function _updateBalanceInAdaptersDistributor(address _user) private {
        uint256 nastrBalAfter = calc(_user);
        adaptersDistributor.updateBalanceInAdapter(utilityName, _user, nastrBalAfter);
        emit UpdateBalSuccess(_user, utilityName, nastrBalAfter);
    }

    // @notice Convert LP tokens to nASTR/ASTR
    // @param _amount Number of LP tokens
    // @return Array of amounts
    //         _amounts[0] => ASTR amount
    //         _amounts[1] => nASTR amount
    function calculateRemoveLiquidity(uint256 _amount)
        public
        view
        returns (uint256[] memory)
    {
        (uint256 reservesASTR, uint256 reservesNASTR) = _getSortedReserves();
        uint256 totalLpSupply = pair.totalSupply();
        uint256 nastrAmount = (_amount * reservesNASTR) / totalLpSupply;
        uint256 astrAmount = (_amount * reservesASTR) / totalLpSupply;
        uint256[] memory amounts = new uint256[](2);
        (amounts[0], amounts[1]) = (astrAmount, nastrAmount);
        return amounts;
    }

    // @notice For claim rewards by users
    function claim() external update nonReentrant whenNotPaused {
        if (rewards[msg.sender] == 0) return;

        // @dev Decrease comission part to zero until the staking launch

        // uint256 comissionPart = rewards[msg.sender] / REVENUE_FEE; // 10% comission part which go to revenue pool
        // uint256 rewardsToClaim = rewards[msg.sender] - comissionPart;
        // revenuePool += comissionPart;

        uint256 rewardsToClaim = rewards[msg.sender];
        
        rewards[msg.sender] = 0;
        arswToken.safeTransfer(msg.sender, rewardsToClaim);
        
        emit Claim(msg.sender, rewardsToClaim);
    }

    // @notice Needs to check user rewards
    // @param _user User address
    // @return sum Amount of penging rewards
    function pendingRewards(address _user) public view returns (uint256 userRewards) {
        uint256 stakedAmount = depositedLp[_user];
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
    function calc(address _user) public override view returns (uint256 nShare) {
        (, uint256 nTokensReserves) = _getSortedReserves();
        nShare =
            ((lpBalances[_user] + depositedLp[_user]) * nTokensReserves) /
            pair.totalSupply();
    }

    // @notice Disabled functionality to renounce ownership
    function renounceOwnership() public override onlyOwner {
        revert("It is not possible to renounce ownership");
    }

    // @notice Calculates amount of second token with the same value
    //         Helper function for front-end
    // @param _amount One of two tokens
    // @param _isAstr If amount of ASTR tokens specified above, then true
    // @return Equal value of second token
    function getSecondAmount(uint256 _amount, bool _isAstr)
        external
        view
        returns (uint256 sum)
    {   
        (uint256 reserve0, uint256 reserve1) = _getSortedReserves();
        sum = _isAstr
            ? pool.quote(_amount, reserve0, reserve1) * 100001 / 100000
            : pool.quote(_amount, reserve1, reserve0);
    }

    // @notice Technical function, that shadows depositedLp functionality
    //         Needed to using the same abi for all adapters
    // @return Amount of depoposited LP by user
    function gaugeBalances(address _user) public view returns (uint256) {
        return depositedLp[_user];
    }

    // @notice To get total amount of locked tokens in pool for front-end
    // @return Total amount of tokens in pool
    function totalReserves() public view returns (uint256 sum) {
        (uint256 astr, uint256 nastr) = _getSortedReserves();
        sum = nastr + astr;
    }

    // @notice To get sorted reserves. WASTR will always at first idx.
    // @param Pair address
    // @return Amount of tokens
    function _getSortedReserves() private view returns (uint256 astr, uint256 nastr) {
        address token0 = pair.token0();
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        return token0 == WASTR ? (res0, res1) : (res1, res0);
    }

    // @notice Used for getting apr and tvl info
    // @param astrprice Actual rate ASTR to USD
    // @return tvl Total locked value
    // @return apr Annual Percentage Rate
    function getInfo(
        uint256 astrPrice
    ) public view returns (uint256 tvl, uint256 apr) {
        require(astrPrice > 0, "Zero address alarm");
        IPancakePair arswAstrPair = IPancakePair(0x50497E7181eB9e8CcD70a9c44FB997742149482a);
        uint256 ARSW_PRICE_PRECISION = 10000;
        
        uint256 arswPerBlock = farm.ARSWPerBlock(farm.getPeriod(block.number));
        uint256 totalAlloc = farm.totalAllocPoint();
        uint64 alloc = farm.poolInfos(39).allocPoint;

        // get arsw price
        (uint256 arswRsrws, uint256 astrRsrws,) = arswAstrPair.getReserves();
        uint256 arswPrice = astrPrice * arswRsrws * ARSW_PRICE_PRECISION / astrRsrws;

        // get tvl
        (uint256 astrReserves, , ) = pair.getReserves();
        tvl = astrReserves * 2 * astrPrice / 1e18;

        // get chef lp balance
        uint256 chefLPBalance = pair.balanceOf(address(farm));
        uint256 chefASTRBalance = calculateRemoveLiquidity(chefLPBalance)[0];
        uint256 chefUSDBalance = chefASTRBalance * 2 * astrPrice / 1e18;

        apr = ((arswPerBlock * alloc / totalAlloc) * (365 * 24 * 3600 / 12) * arswPrice / ARSW_PRICE_PRECISION + chefUSDBalance) / chefUSDBalance * 100;
    }

    // @notice Used to calculate LP amount by giving nASTR and ASTR
    // @param _amounts Amounts of tokens. ASTR amount at idx 0
    // @return LP amount
    function getLpAmount(uint256[] memory _amounts) public view returns (uint256 amount) {
        (uint256 nastrRsrvs, uint256 astrRsrvs,) = pair.getReserves();
        uint256 totalSupply = lp.totalSupply();
        uint256 shareNastr = _amounts[1] * totalSupply / nastrRsrvs;
        uint256 shareAstr = _amounts[0] * totalSupply / astrRsrvs;
        return shareNastr < shareAstr ? shareNastr : shareAstr;
    }

    // @notice shows total staked astr amount
    function totalStakedASTR() public override view returns (uint256) {
        uint256[] memory amounts = new uint256[](2);
        uint256 adapterLpBalance = IERC20Upgradeable(lp).balanceOf(address(this));
        amounts = calculateRemoveLiquidity(totalStakedLp + adapterLpBalance);
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

    // @notice returns users list
    function getUsers() external view returns (address[] memory) {
        return users;
    }

    /// @notice Disabling funcs with the whenNotPaused modifier
    function pause() external onlyManager {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Enabling funcs with the whenNotPaused modifier
    function unpause() external onlyManager {
        paused = false;
        emit Unpaused(msg.sender);
    }
}