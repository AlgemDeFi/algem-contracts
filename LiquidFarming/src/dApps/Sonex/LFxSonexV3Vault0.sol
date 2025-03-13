//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "src/Vault.sol";
import "src/dApps/Sonex/V3Caller0.sol";
import "src/interfaces/IWETH9.sol";

/// @title Vault contract which takes liquidity from the user
///        and deposit it to dedicated pool to receive and distribute farming & ALGM rewards
/// @custom:oz-upgrades-from LFxSonexV3Vault0
contract LFxSonexV3Vault0 is Vault, V3Caller0 {
    using Address for address payable;
    using SafeERC20 for IERC20;

    struct userVaultInfo {
        uint256 lp;
        uint256 algm;
        uint256[2] rewards;
        uint256 rewardsALGM;
        uint256 hf;
        bool liquidated;
    }

    struct vaultInfo {
        uint256 totalBalance;
        uint256 totalALGMBalance;
        address lwrapped;
    }

    struct Position {
        uint256 wrapped;
        uint256 token;
        uint256 start;
        uint256 roundStart;
        uint256 finish;
        uint256 roundClaimed;
    }

    uint256 supp;

    uint256[2] public rewardPool;
    uint256[2] public revenuePool;

    mapping(address => Position) public positions;
    mapping(uint256 => uint256[2]) public farmingRewards;
    mapping(uint256 => uint256) public roundBalance;

    event Deposit(address indexed user, uint256 wrapped, uint256 token);
    event Redeem(address indexed user, uint256 wrapped, uint256 token);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimFarming(address indexed user, address indexed token, uint256 amount);
    event ClaimALGM(address indexed user, uint256 amount);
    event HarvestFarming(uint256 round, address indexed token, uint256 amount);
    event Liquidated(address indexed user, uint256 wrapped, uint256 pair);
    event Expired(uint256 amount0, uint256 amount1);
    event Rebalanced(int24 tickL, int24 tickU, uint256 lp);

    receive() external payable {
        require(msg.sender == WRAPPED || msg.sender == owner());
    }

    modifier updater() {
        update();
        _;
    }

    ////INIT FUNCTIONS////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice init called by proxyAdmin
    /// @param _pool uniswap pool to work with
    function initialize(address _pool, bool _isW0) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();

        rewardFee = 10;

        v3pool = IUniswapV3Pool(_pool);

        isWtoken0 = _isW0;
        WRAPPED = _isW0 ? v3pool.token0() : v3pool.token1();
        pairToken = _isW0 ? v3pool.token1() : v3pool.token0();
    }

    /// @notice set initial liquidity parameters
    /// @param _tickL:lowest allowed pool tick
    /// @param _tickU: upmost allowed pool tick
    /// @param _tickS: tick spacing
    /// @param _fee fee tier of the pool
    function initParams(int24 _tickL, int24 _tickU, int24 _tickS, uint24 _fee) external onlyOwner {
        if (positionParameters.tickL != 0 || positionParameters.tickU != 0 || positionParameters.tickS != 0) revert();
        require(_tickL < _tickU, "TickL must be less than TickU");
        require(_tickS > 0);
        positionParameters.tickL = _tickL;
        positionParameters.tickU = _tickU;
        positionParameters.tickS = _tickS;
        positionParameters.fee = _fee;
    }

    /// @notice set vault-specific parameters which depend on chain/dapp/pair
    /// @param _lwrapped: vault must be able to mint/burn this token
    /// @param _algm: ALGM rewards token
    /// @param _pool: Pool contract to get bonus data
    /// @param _start: vault start timestamp
    /// @param _round: vault round duration
    /// @param _totalRounds: vault total rounds count
    function initVault(
        address _lwrapped,
        address _algm,
        address _pool,
        uint256 _start,
        uint256 _round,
        uint256 _totalRounds
    )
        external
        onlyOwner
    {
        if (START != 0) revert();
        START = _start;
        roundDuration = _round;
        FINISH = START + roundDuration * _totalRounds;

        lWRAPPED = ILWRAPPED(_lwrapped);
        ALGM = IERC20(_algm);
        pool = ILFPool(_pool);
    }

    ////INTERNAL FUNCTIONS////
    function _expire() internal {
        if (expired) return;
        expired = true;
        (uint256 amount1, uint256 amount0) = decreaseLiquidity(uint128(totalBalance()));

        uint256 supply = lWRAPPED.totalSupply();

        if (amount0 > supply) {
            (int256 amount1Delta,) = swap(int256(amount0 - supply), false);
            amount1 += uint256(-amount1Delta);
        } else if (amount0 < supply) {
            (int256 amount1Delta,) = swap(-int256(supply - amount0), true);
            amount1 -= uint256(amount1Delta);
        }

        totalWRAPPEDBalance += supply;
        totalTokenBalance += amount1;

        emit Expired(amount0, amount1);
    }

    function _harvest(uint256 _round) internal {
        uint256 rFee = rewardFee;
        if (expired) {
            return;
        }
        if (totalBalance() > 0) {
            v3pool.burn(positionParameters.tickL, positionParameters.tickU, 0);
        }

        (uint256 received1, uint256 received0) = collect(type(uint128).max, type(uint128).max);
        if (received0 + received1 > 0) {
            revenuePool[0] += rFee * received0 / 100;
            revenuePool[1] += rFee * received1 / 100;

            received0 -= rFee * received0 / 100;
            received1 -= rFee * received1 / 100;

            rewardPool[0] += received0;
            rewardPool[1] += received1;

            farmingRewards[_round][0] += received0;
            farmingRewards[_round][1] += received1;

            if (received0 > 0) {
                emit HarvestFarming(_round, WRAPPED, received0);
            }
            if (received1 > 0) {
                emit HarvestFarming(_round, pairToken, received1);
            }
        }
        if (roundBalance[_round] == 0) roundBalance[_round] = lWRAPPED.totalSupply();
        if (roundALGMStaked[_round] == 0) roundALGMStaked[_round] = totalALGMStaked;
    }

    function _claim(address _user, bool _restake) internal updater {
        (uint256[2] memory f, uint256 a) = previewRewards(_user);
        if (f[0] + f[1] > 0) {
            if (f[0] > 0) rewardPool[0] -= f[0];
            if (f[1] > 0) rewardPool[1] -= f[1];

            IWETH9(WRAPPED).withdraw(f[0]);
            payable(_user).sendValue(f[0]);
            IERC20(pairToken).safeTransfer(_user, f[1]);

            if (f[0] > 0) {
                emit ClaimFarming(_user, WRAPPED, f[0]);
            }
            if (f[1] > 0) {
                emit ClaimFarming(_user, pairToken, f[1]);
            }
        }
        if (a > 0) {
            algmRewardPool -= a;
            if (_restake) {
                _restakeALGM(_user, a);
            } else {
                ALGM.safeTransfer(_user, a);
            }
            emit ClaimALGM(_user, a);
        }
        positions[_user].roundClaimed = getCurrentRound() - 1;
    }

    ////UPDATE FUNCTIONS////
    /// @notice harvest algm and farming rewards if possible
    function harvest() public {
        uint256 round = getCurrentRound();

        pool.harvest();
        if (round < 2) return;

        round -= 1;

        if (farmingRewards[round][0] + farmingRewards[round][1] > 0) return;

        _harvest(round);
    }

    /// @notice updates vault state on new round
    function update() public {
        if (block.timestamp >= START) {
            harvest();
            if (block.timestamp >= FINISH) {
                _expire();
            }
        }
    }

    ////USER FUNCTIONS////
    /// @notice deposit both tokens (preferably) optimal ratio
    /// @param _amount pairToken amount
    function deposit(uint256 _amount) external payable whenNotPaused updater {
        uint256 cr = getCurrentRound();
        if (START == 0 || expired || block.timestamp < START || block.timestamp > FINISH - roundDuration) {
            revert Expiration();
        } // deposits closed 1 round before expire
        Position storage p = positions[msg.sender];
        if (p.roundStart > 0) {
            require(p.roundClaimed == cr - 1, "Claim first");
        }

        if (p.finish != 0 && p.finish != FINISH) {
            revert Liquidation();
        }

        if (msg.value == 0 && _amount == 0) revert InvalidAmount();

        if (msg.value > 0) {
            IWETH9(WRAPPED).deposit{value: msg.value}();
        }
        if (_amount > 0) {
            IERC20(pairToken).safeTransferFrom(msg.sender, address(this), _amount);
        }

        (uint256 amount0, uint256 amount1) = increaseLiquidity(_amount, msg.value);
        uint256 wa = (amount1 + getSecondAmount(uint128(amount0), true)) / 2;
        p.wrapped += wa;

        if (p.start == 0) {
            p.start = block.timestamp;
            p.finish = FINISH;
        }

        if (p.roundStart == 0) {
            p.roundStart = cr;

            if (cr > 1) {
                p.roundClaimed = cr;
            }
        }
        supp += wa;
        lWRAPPED.mint(msg.sender, wa);

        if (amount1 < msg.value) {
            IWETH9(WRAPPED).withdraw(msg.value - amount1);
            payable(msg.sender).sendValue(msg.value - amount1);
        }

        if (amount0 < _amount) {
            IERC20(pairToken).safeTransfer(msg.sender, _amount - amount0);
        }

        emit Deposit(msg.sender, wa, amount0);
    }

    /// @notice redeem the position, claim rewards if any, unstake algm if any
    function redeem() external nonReentrant updater {
        _claim(msg.sender, false);
        Position storage p = positions[msg.sender];
        uint256 tokenToPay;

        if (p.finish != FINISH) {
            //liquidated
            tokenToPay = p.token;
        } else if (expired) {
            tokenToPay = totalTokenBalance * p.wrapped / supp;
        } else {
            (uint256 amountToken, uint256 amountWRAPPED) = decreaseLiquidity(getUserLP(msg.sender));

            if (amountWRAPPED < p.wrapped) {
                (int256 amountIn,) = swap(-int256(p.wrapped - amountWRAPPED), true);
                tokenToPay = amountToken - uint256(amountIn);
            } else if (amountWRAPPED > p.wrapped) {
                (int256 amountOut,) = swap(int256(amountWRAPPED - p.wrapped), false);
                tokenToPay = amountToken + uint256(-amountOut);
            }
            totalWRAPPEDBalance += p.wrapped;
            totalTokenBalance += tokenToPay;
        }

        if (tokenToPay > 0) {
            totalTokenBalance -= tokenToPay;
            IERC20(pairToken).safeTransfer(msg.sender, tokenToPay);
        }

        supp -= p.wrapped;
        if (lWRAPPED.balanceOf(msg.sender) < p.wrapped) {
            p.wrapped = lWRAPPED.balanceOf(msg.sender);
        }
        if (p.wrapped > 0) {
            totalWRAPPEDBalance -= p.wrapped;
            lWRAPPED.burn(msg.sender, p.wrapped);
            IWETH9(WRAPPED).withdraw(p.wrapped);
            payable(msg.sender).sendValue(p.wrapped);
        }

        if (userALGMBalance[msg.sender] > 0) {
            _unstakeALGM(msg.sender, userALGMBalance[msg.sender]);
        }

        emit Redeem(msg.sender, p.wrapped, tokenToPay);

        //delete the position
        delete positions[msg.sender];
    }

    //claim
    /// @notice claim rewards
    /// @param _restake restake/unstake algm
    function claim(bool _restake) external nonReentrant {
        _claim(msg.sender, _restake);
    }

    /// @notice unstake algm
    /// @param _amount amount to unstake
    function unstakeALGM(uint256 _amount) external updater {
        _unstakeALGM(msg.sender, _amount);
    }

    /// @notice burn LWRAPPED token after expiration, retrieve base token
    /// @param  _amount of tokens to burn
    function withdraw(uint256 _amount) external nonReentrant updater {
        if (!expired) {
            revert Expiration();
        }

        if (lWRAPPED.balanceOf(msg.sender) < _amount || totalWRAPPEDBalance < _amount) {
            revert InvalidAmount();
        }

        totalWRAPPEDBalance -= _amount;
        lWRAPPED.burn(msg.sender, _amount);

        IWETH9(WRAPPED).withdraw(_amount);

        payable(msg.sender).sendValue(_amount);

        emit Withdraw(msg.sender, _amount);
    }

    ////VIEW FUNCTIONS////
    /// @notice vault info frontend getter
    /// @return info_ composed info
    function getVaultInfo() external view returns (vaultInfo memory info_) {
        info_.totalBalance = supp;
        info_.totalALGMBalance = totalALGMStaked;
        info_.lwrapped = address(lWRAPPED);
    }

    /// @notice user info frontend getter
    /// @param _user to look for
    /// @return info_ composed info
    function getVaultUserInfo(address _user) external view returns (userVaultInfo memory info_) {
        Position memory p = positions[_user];
        info_.lp = p.wrapped;
        info_.algm = userALGMBalance[_user];
        if (info_.lp > 0) {
            (info_.rewards, info_.rewardsALGM) = previewRewards(_user);
            info_.hf = getHF(_user);
        }
        info_.liquidated = (p.finish != FINISH) && (p.start != 0);
    }

    /// @notice preview user's unclaimed algm rewards at given round
    /// @param _user user to calculate
    /// @return a_ rewards amount
    function previewALGM(address _user) internal view returns (uint256 a_) {
        Position storage p = positions[_user];
        uint256 roundStart = p.roundClaimed == 0 ? p.roundStart : p.roundClaimed + 1;
        uint256 cr = getCurrentRound();
        uint256 bonus = pool.getUserBonus(_user);

        for (; roundStart < cr; roundStart++ ) {
            uint256 algmRewardsShare;
            uint256 balance;

            if (roundBalance[roundStart] > 0) {
                balance = roundBalance[roundStart];
            } else {
                continue;
            }

            algmRewardsShare = (p.wrapped * bonus / 100) * REWARDS_PRECISION / balance;
            a_ += algmRewardsShare * algmRewards[roundStart] / REWARDS_PRECISION;
        }
    }

    /// @notice preview user's unclaimed farming rewards at given round
    /// @param _user user to calculate
    /// @return comms_ [0] -- wrapped; [1] -- pairToken
    function previewFarming(address _user) internal view returns (uint256[2] memory comms_) {
        Position storage p = positions[_user];
        uint256 roundStart = p.roundClaimed == 0 ? p.roundStart : p.roundClaimed + 1;
        uint256 cr = getCurrentRound();
        uint256 tr = totalRounds();

        for (; roundStart < cr;) {
            uint256 farmingRewardsShare;

            uint256 a = 10_000 * (roundStart - p.roundStart) / (tr - p.roundStart);

            if (roundBalance[roundStart] > 0) {
                farmingRewardsShare = REWARDS_PRECISION * (10_000 - a) * p.wrapped / roundBalance[roundStart];
            }

            if (roundALGMStaked[roundStart] > 0) {
                farmingRewardsShare += REWARDS_PRECISION * a * userALGMBalance[_user] / roundALGMStaked[roundStart];
            }

            comms_[0] += farmingRewardsShare * farmingRewards[roundStart][0] / REWARDS_PRECISION / 10_000;
            comms_[1] += farmingRewardsShare * farmingRewards[roundStart][1] / REWARDS_PRECISION / 10_000;
            unchecked {
                ++roundStart;
            }
        }
    }

    /// @notice preview all unclaimed user rewards
    /// @param _user user to calculate
    /// @return comms_ same as previewRoundFarming
    /// @return algm_ same as previewRoundALGM
    function previewRewards(address _user) public view returns (uint256[2] memory comms_, uint256 algm_) {
        comms_ = previewFarming(_user);
        algm_ = previewALGM(_user);
    }

    /// @notice calculate user position health factor
    /// @param _user user to calculate
    /// @return uint256 health factor
    function getHF(address _user) internal view returns (uint256) {
        uint256[2] memory amounts = calculateRemoveLiquidity(getUserLP(_user));
        return (amounts[1] + getSecondAmount(uint128(amounts[0]), true)) * 100 / positions[_user].wrapped;
    }

    /// @notice total lp of vault's position
    /// @return liquidity_ amount
    function totalBalance() public view returns (uint256 liquidity_) {
        (liquidity_,,) = _position();
    }

    /// @notice calculates uniswap LP amount of a user based on his share
    /// @param _user to calculate for
    /// @return lp_ converted lp
    function getUserLP(address _user) public view returns (uint128 lp_) {
        if (supp == 0) {
            return 0;
        }
        lp_ = uint128(totalBalance() * positions[_user].wrapped / supp);
    }

    ////////ADMIN FUNCTIONS////////
    /// @notice change slippage
    /// @param _limit price limit %
    function setSlippage(uint160 _limit) external onlyOwner {
        require(_limit > 0);
        positionParameters.priceLimit = _limit;
    }

    /// @notice withdraw collected revenue
    function withdrawRevenue() external override onlyOwner {
        if (revenuePool[0] > 0) {
            if (revenueSplit < 100) algmStaking.topUpRewardsPool(ASTR, revenuePool[0] * (100 - revenueSplit) / 100);
            IERC20(WRAPPED).safeTransfer(msg.sender, revenuePool[0] * revenueSplit / 100);
            revenuePool[0] = 0;
        }
        if (revenuePool[1] > 0) {
            if (revenueSplit < 100) {
                algmStaking.topUpRewardsPool(pairToken, revenuePool[1] * (100 - revenueSplit) / 100);
            }
            IERC20(pairToken).safeTransfer(msg.sender, revenuePool[1] * revenueSplit / 100);
            revenuePool[1] = 0;
        }
    }

    /// @notice used to keep 1:1 WRAPPED/LWRAPPED ratio. If HF is below `LIQUIDATION_THRESHOLD`
    ///         liquidating the position would exchange user's LP back to liquidity
    ///         so the user could not farm any more rewards but has option to redeem the position
    /// @param _user to liquidate
    function liquidate(address _user) external updater {
        Position storage p = positions[_user];

        uint256 hf = getHF(_user);
        if (hf < LIQUIDATION_THRESHOLD) {
            _claim(_user, false);
            _unstakeALGM(_user, userALGMBalance[_user]);

            p.finish = block.timestamp;
            (uint256 amount0, uint256 amount1) = decreaseLiquidity(getUserLP(_user));
            (int256 amount0Delta,) = swap(-int256(p.wrapped - amount1), true);
            amount0 -= uint256(amount0Delta);
            p.token = amount0;
            totalTokenBalance += amount0;
            totalWRAPPEDBalance += p.wrapped;
        }
    }

    /// @notice change vault position range
    /// @param _newTickL new lower tick
    /// @param _newTickU new upper tick
    function rebalance(int24 _newTickL, int24 _newTickU) external onlyOwner {
        require(_newTickL < _newTickU);
        update();
        uint256 amount0;
        uint256 amount1;
        if (totalBalance() > 0) {
            (amount0, amount1) = decreaseLiquidity(uint128(totalBalance()));
        }
        positionParameters.tickL = _newTickL;
        positionParameters.tickU = _newTickU;
        if (amount0 > 0 || amount1 > 0) {
            increaseLiquidity(amount0, amount1);
        }
    }
}