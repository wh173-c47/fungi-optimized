// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SeedData} from "./Types.sol";

library ExtraSeedLib {
    function extra(address account) internal pure returns (uint128 res) {
        assembly {
            // Clears upper bits and keccak packed address
            mstore(0x0, shr(96, account))
            res := keccak256(0x0, 0x14)
        }
    }
}
