// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Rect, Rand} from "./Types.sol";
import {RectLib} from "./RectLib.sol";
import {RandLib} from "./RandLib.sol";
import {StringLib} from "./StringLib.sol";

library RectLib {
    using RectLib for Rect;
    using RandLib for Rand;
    using RandLib for bytes6[];
    using StringLib for uint8;

    function toSvg(
        Rect memory r,
        bytes6 color
    ) internal pure returns (string memory) {
        return
            string(
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
                color,
                "'/>"
            )
        );
    }

    function toSvg(
        Rect[] storage rects,
        bytes6[] storage colors,
        Rand memory rnd
    ) internal view returns (string memory) {
        string memory res;
        for (uint256 i = 0; i < rects.length; ++i) {
            res = string(
                abi.encodePacked(res, rects[i].toSvg(colors.random(rnd)))
            );
        }
        return res;
    }

    function toSvg(
        Rect[] storage rects,
        bytes6 color
    ) internal view returns (string memory) {
        string memory res;
        for (uint256 i = 0; i < rects.length; ++i) {
            res = string(abi.encodePacked(res, rects[i].toSvg(color)));
        }
        return res;
    }
}
