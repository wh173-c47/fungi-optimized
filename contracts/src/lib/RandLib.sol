// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Rand} from "./Types.sol";

uint32 constant _SEED_LEVEL1 = 21000;
uint32 constant _SEED_LEVEL2 = 525000;
uint32 constant _SEED_LEVEL3 = 1050000;
uint32 constant _SEED_LEVEL4 = 1575000;
uint32 constant _SEED_LEVEL5 = 2100000;

library RandLib {
    function rdm(Rand memory rnd) internal pure returns (uint256 res) {
        assembly {
            mstore(0x0, mload(rnd))
            res := keccak256(0x0, 0x20)
        }
    }

    function lvl(Rand memory rnd) internal pure returns (uint8 res) {
        if (rnd.seed < _SEED_LEVEL1) return 0;
        if (rnd.seed < _SEED_LEVEL2) return 1;
        if (rnd.seed < _SEED_LEVEL3) return 2;
        if (rnd.seed < _SEED_LEVEL4) return 3;
        if (rnd.seed < _SEED_LEVEL5) return 4;

        return 5;
    }

    function safeRdmItemAtIndex(bytes3[] memory data, uint256 rdmIndex)
        internal
        pure
        returns (bytes3)
    {
        return data[rdmIndex % data.length];
    }
}
