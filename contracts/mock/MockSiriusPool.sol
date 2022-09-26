//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MockERC20.sol";

contract MockSiriusPool {
    MockERC20 public lp;
    MockERC20 public nastr;

    uint256 public reservesN;
    uint256 public reservesT;

    constructor(
        MockERC20 _lp,
        MockERC20 _nastr
    ) {
        lp = _lp;
        nastr = _nastr;
        reservesN = 100 ether;
        reservesT = 100 ether;
    }

    receive() external payable {}

    function addLiquidity(uint256[] calldata amounts, uint256 minToMint, uint256 deadline) external payable returns (uint256) {
        nastr.transferFrom(msg.sender, address(this), amounts[1]);
        uint256 lpAmount = amounts[0] + amounts[1];
        reservesN += amounts[1];
        reservesT += amounts[0];
        lp.mint(msg.sender, lpAmount);
        return lpAmount;
    }

    function removeLiquidity(uint256 amount, uint256[] memory minAmounts, uint256 deadline) external returns (uint256[] memory) {
        uint256 totalLiquidity = lp.totalSupply();
        lp.burn(msg.sender, amount);

        uint256 amountT = reservesT * amount / totalLiquidity;
        uint256 amountN = reservesN * amount / totalLiquidity;

        reservesT -= amountT;
        reservesN -= amountN;

        nastr.transfer(msg.sender, amountN);
        payable(msg.sender).transfer(amountT);
    }

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256) {
        return amounts[0] + amounts[1];
    }

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory) {
        uint256 totalLiquidity = lp.totalSupply();

        uint256 amountT = reservesT * amount / totalLiquidity;
        uint256 amountN = reservesN * amount / totalLiquidity;

        uint256[] memory amounts = new uint256[](2);
        (amounts[0], amounts[1]) = (amountT, amountN);
        return amounts;
    }
}