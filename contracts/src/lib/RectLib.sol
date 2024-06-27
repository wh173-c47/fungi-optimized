// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Rect, Rand} from "./Types.sol";
import {RectLib} from "./RectLib.sol";
import {StringLib} from "./StringLib.sol";

uint32 constant _SEED_LEVEL1 = 21000;
uint32 constant _SEED_LEVEL2 = 525000;
uint32 constant _SEED_LEVEL3 = 1050000;
uint32 constant _SEED_LEVEL4 = 1575000;
uint32 constant _SEED_LEVEL5 = 2100000;

library RectLib {
    using RectLib for Rect;
    using StringLib for uint8;

    function toSvg(Rect memory r, bytes3 color)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<rect x='",
                r.x._toString(),
                "' y='",
                r.y._toString(),
                "' width='",
                r.width._toString(),
                "' height='",
                r.height._toString(),
                "' fill='#",
                bytes3ToHexString(color),
                "'/>"
            )
        );
    }
    // TODO: See logic / use of this function previously
    //    function toSvg(
    //        Rect[] storage rects,
    //        bytes3[] storage colors,
    //        Rand memory rnd
    //    ) internal view returns (string memory) {
    //        string memory res;
    //        uint max = rects.length;
    //
    //        for (uint256 i; i < max; ++i) {
    //            res = string(
    //                abi.encodePacked(res, rects[i].toSvg(colors.random(rnd)))
    //            );
    //        }
    //
    //        return res;
    //    }

    function toSvg(Rect[] storage rects, bytes3 color)
        internal
        view
        returns (string memory)
    {
        string memory res;
        uint256 max = rects.length;

        for (uint256 i; i < max; ++i) {
            res = string(abi.encodePacked(res, rects[i].toSvg(color)));
        }

        return res;
    }

    function bytes3ToHexString(bytes3 data)
        internal
        pure
        returns (string memory str)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Allocate 64 bytes of memory (0x20 bytes for length + 0x20 bytes for the content).
            str := mload(0x40)
            mstore(0x40, add(str, 0x40))

            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // Process each byte of the `bytes3o` input.
            for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                let b := byte(i, data)
                let mo := mul(i, 2)

                mstore8(add(add(str, 0x20), mo), mload(and(shr(4, b), 0x0f)))
                mstore8(add(add(str, 0x21), mo), mload(and(b, 0x0f)))
            }

            // Store the length of the resulting string.
            mstore(str, 8)
        }
    }

    function safeRdmItemAtIndex(bytes3[] memory data, uint256 rdmIndex)
        internal
        pure
        returns (bytes3)
    {
        return data[rdmIndex % data.length];
    }

    function lvl(Rand memory rnd) internal pure returns (uint8 res) {
        if (rnd.seed < _SEED_LEVEL1) return 0;
        if (rnd.seed < _SEED_LEVEL2) return 1;
        if (rnd.seed < _SEED_LEVEL3) return 2;
        if (rnd.seed < _SEED_LEVEL4) return 3;
        if (rnd.seed < _SEED_LEVEL5) return 4;

        return 5;
    }
}
