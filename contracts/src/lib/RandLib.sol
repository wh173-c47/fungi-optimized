// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Rand} from "./Types.sol";

uint32 constant _SEED_LEVEL1 = 21000;
uint32 constant _SEED_LEVEL2 = 525000;
uint32 constant _SEED_LEVEL3 = 1050000;
uint32 constant _SEED_LEVEL4 = 1575000;
uint32 constant _SEED_LEVEL5 = 2100000;

library RandLib {
    function next(Rand memory rnd) internal pure returns (uint256) {
        uint256 baseRdm;

        // allows ops to overflow, avoiding a DOS
        unchecked {
            baseRdm = rnd.nonce + rnd.seed - 1 + rnd.extra;

            ++rnd.nonce;
        }

        return keccakU256(baseRdm);
    }

    function lvl(Rand memory rnd) internal pure returns (uint8) {
        if (rnd.seed < _SEED_LEVEL1) return 0;
        if (rnd.seed < _SEED_LEVEL2) return 1;
        if (rnd.seed < _SEED_LEVEL3) return 2;
        if (rnd.seed < _SEED_LEVEL4) return 3;
        if (rnd.seed < _SEED_LEVEL5) return 4;

        return 5;
    }

    function random(
        bytes6[] memory data,
        Rand memory rnd
    ) internal pure returns (bytes6) {
        return data[randomIndex(data, rnd)];
    }

    function randomIndex(
        bytes6[] memory data,
        Rand memory rnd
    ) internal pure returns (uint256) {
        return next(rnd) % data.length;
    }

    function keccakU256(uint256 input) internal pure returns (uint256 output) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, input)
            output := keccak256(0x0, 0x20)
        }
    }
}
