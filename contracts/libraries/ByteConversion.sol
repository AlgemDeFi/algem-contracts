//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library ByteConversion {
    function toString(bytes3 self) internal pure returns (string memory output) {
        bytes6 result = (bytes6(self) & 0xFFF000000000) |
                ((bytes6(self) & 0x000FFF000000) >> 12);
        result = (result & 0xFF0000FF0000) | ((result & 0x00F00000F000) >> 8);
        result = (result & 0xF000F0F000F0) | ((result & 0x0F00000F0000) >> 4);
        result = (result & 0xF0F0F0F0F0F0) >> 4;
        result = bytes6(
            0x303030303030 +
                uint48(result) +
                (((uint48(result) + 0x060606060606) >> 4) & 0x0F0F0F0F0F0F) *
                7
        );

        output = string(abi.encodePacked(result));
    }
}
