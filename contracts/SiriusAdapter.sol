//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/ISiriusPool.sol";
import "./interfaces/ISiriusFarm.sol";
import "./interfaces/IDNT.sol";

contract SiriusAdapter {

    mapping(address => uint256) public lpBalances;
    mapping(address => uint256) public nBalances;
    mapping(address => uint256) public balances;

    //Interfaces
    ISiriusPool public pool;
    ISiriusFarm public farm;
    IDNT public lp;
    IDNT public nToken;

    constructor(ISiriusPool _pool, ISiriusFarm _farm, IDNT _lp, IDNT _nToken) {
        pool = _pool;
        farm = _farm;
        lp = _lp;
        nToken = _nToken;
    }

    function approveForSirius() external {
        nToken.approve(address(pool), type(uint256).max);
    }

    // @notice Add liquidity to the pool with the given amounts of tokens
    // @param _amounts the amounts of each token to add, in their native precision
    //        idx 0 is ASTR, idx 1 is nASTR

    // additional tasks:
    // check if idx 0 is astr and idx 1 is nASTR
    function addLiquidity(uint256[] calldata _amounts) external payable {
        uint256 tokenAmount = _amounts[0];
        uint256 nTokenAmount = _amounts[1];

        nBalances[msg.sender] += _amounts[1];
        balances[msg.sender] += _amounts[0];

        uint256 balanceBefore = lp.balanceOf(address(this));
        pool.addLiquidity(_amounts, _amounts[0] + _amounts[1], block.timestamp + 1200);
        uint256 balanceAfter = lp.balanceOf(address(this));

        uint256 receivedLP = balanceAfter - balanceBefore;
        lpBalances[msg.sender] += receivedLP;
    }

    function removeLiquidity() external {

    }

    function depositLP() external {

    }

    function claim() external {

    }

    function getShare() external view returns (uint) {

    }

    function getUserBalances(address _user) external view returns (uint256 astr, uint256 nAstr, uint256 lp) {
        astr = balances[_user];
        nAstr = nBalances[_user];
        lp = lpBalances[_user];
    }

    receive() external payable {}
}

// pool 0xEEa640c27620D7C448AD655B6e3FB94853AC01e3
    // addLiquidity(uint256[] amounts, uint256 minToMint, uint256 deadline);
    // removeLiquidity(uint256 amount, uint256[] minAmounts,uint256 deadline);
    // removeLiquidityImbalance(uint256[] amounts, uint256 maxBurnAmount, uint256 deadline);
    // removeLiquidityOneCoin(uint256 tokenAmount, uint256 tokenIndex, uint256 minAmount, address receiver);
// farm 0xdCfFa5a92ef31DCc8979Ab44A0406859d7763c45
    // deposit(uint256 value, address account, bool claimRewards);
    // withdraw(uint256 value,bool claimRewards);

// lp 0xcB274236fBA7B873FC8F154bb0475a166C24B119
