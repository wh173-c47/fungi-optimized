// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SeedData} from "./Types.sol";

library ExtraSeedLib {
    function extra(
        address account,
        uint128 extraSeed
    ) internal pure returns (uint128 res) {
        assembly {
            mstore(0x0, add(account, extraSeed))
            res := keccak256(0x0, 0x20)
        }
    }
}
