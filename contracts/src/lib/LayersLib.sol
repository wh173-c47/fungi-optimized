// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Rect, FileData} from "./Types.sol";

library LayersLib {
    function setLayers(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        FileData[] calldata data
    ) internal {
        uint256 max = data.length;

        for (uint256 i = 0; i < max; ++i) {
            setFile(rects, data[i]);
        }
    }

    function setFile(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        FileData calldata input
    ) internal {
        Rect[] storage storageFile = rects[input.lvl][input.file];
        uint256 max = input.rects.length;

        for (uint256 i = 0; i < max; ++i) {
            storageFile.push(input.rects[i]);
        }
    }

    function getLvl(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        uint8 lvl
    ) internal view returns (mapping(uint256 => Rect[]) storage) {
        return rects[lvl];
    }

    function toLvl1(uint8 l) internal pure returns (uint8) {
        if (l > 0) --l;

        return l;
    }
}
