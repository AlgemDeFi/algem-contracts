pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT

contract MockPriceOracle {
    mapping(address => uint256) public prices;

    constructor(
        address nastr,
        address busdAddr,
        address dot,
        address dai,
        address usdc,
        address usdt
    ) {
        setInitPrices(nastr, busdAddr, dot, dai, usdc, usdt);
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address assetAddr, uint256 price) public {
        prices[assetAddr] = price;
    }

    function setInitPrices(address nastr, address busdAddr, address dot, address dai, address usdc, address usdt) public {
        prices[nastr] = 5340158;
        prices[busdAddr] = 100000000;
        prices[dot] = 535325660;
        prices[dai] = 99945951;
        prices[usdc] = 100000000;
        prices[usdt] = 100000000;
    }
}