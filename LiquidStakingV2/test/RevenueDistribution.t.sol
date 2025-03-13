// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract RevenueDistributionTest is Test {
    function setUp() public {}

    /// @dev Testing of revenue distribution by nfts considering amount of locked tokens for each nft
    function test_auto(
        uint256 nft1lock,
        uint256 nft2lock,
        uint256 nft3lock,
        uint256 nft1discount,
        uint256 nft2discount,
        uint256 nft3discount
    ) public {
        vm.assume(nft1lock < 1e18 && nft1lock > 1000);
        vm.assume(nft2lock < 1e18 && nft2lock > 1000);
        vm.assume(nft3lock < 1e18 && nft3lock > 1000);
        vm.assume(nft1discount < 10000 && nft1discount > 100);
        vm.assume(nft2discount < 10000 && nft2discount > 100);
        vm.assume(nft3discount < 10000 && nft3discount > 100);
        vm.assume(nft1discount + nft2discount + nft3discount < 10000);

        uint256 sum = nft1lock + nft2lock + nft3lock;

        uint256 s1 = nft1lock * nft1discount / sum;
        uint256 s2 = nft2lock * nft2discount / sum;
        uint256 s3 = nft3lock * nft3discount / sum;

        uint256 kNorm = (nft1discount + nft2discount + nft3discount) * 10000 / (s1 + s2 + s3);

        uint256 s1Norm = s1 * kNorm / 10000;
        uint256 s2Norm = s2 * kNorm / 10000;
        uint256 s3Norm = s3 * kNorm / 10000;

        assertApproxEqAbs(nft1discount + nft2discount + nft3discount, s1Norm + s2Norm + s3Norm, 10);
    }

    function test_manual(
    ) public {
        uint256 nft1lock = 100;
        uint256 nft2lock = 300;
        uint256 nft3lock = 200;

        uint256 nft1discount = 500;
        uint256 nft2discount = 1500;
        uint256 nft3discount = 1000;

        uint256 sum = nft1lock + nft2lock + nft3lock;

        uint256 s1 = nft1lock * nft1discount / sum;
        uint256 s2 = nft2lock * nft2discount / sum;
        uint256 s3 = nft3lock * nft3discount / sum;

        uint256 kNorm = (nft1discount + nft2discount + nft3discount) * 10000 / (s1 + s2 +s3);

        uint256 s1Norm = s1 * kNorm / 10000;
        uint256 s2Norm = s2 * kNorm / 10000;
        uint256 s3Norm = s3 * kNorm / 10000;

        assertApproxEqAbs(nft1discount + nft2discount + nft3discount, s1Norm + s2Norm + s3Norm, 10);
    }
}