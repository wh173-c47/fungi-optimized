// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SeedData} from "./Types.sol";
import {RandLib} from "./RandLib.sol";

library ExtraSeedLib {
    using RandLib for uint256;

    function extra(
        address account,
        uint128 extraSeed
    ) internal pure returns (uint128) {
        uint256 baseRdm;

        assembly {
            baseRdm := add(account, extraSeed)
        }

        return uint128(baseRdm.keccakU256());
    }

    function _seedData(
        address account,
        uint32 seed,
        uint128 extraSeed
    ) internal pure returns (SeedData memory) {
        return SeedData(seed, extra(account, extraSeed));
    }
}
