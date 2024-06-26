// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "solady/tokens/ERC20.sol";

abstract contract PoolCreatableErc20i is ERC20 {
    error NotPairCreator();
    error AlreadyStarted();

    address internal immutable _pairCreator;

    address public pool;
    bool internal _feeLocked;
    uint256 internal _startTime;

    constructor(address pairCreator) payable {
        _pairCreator = pairCreator;
    }

    function launch(address poolAddress) external payable {
        address pairCreator = _pairCreator;

        assembly {
            // We reduce a bit bytecode by packing reverts err codes in mem as this fn won't be much triggered
            mstore(returndatasize(), 0x189117a41fbde445) // packed NotPairCreator() and AlreadyStarted()

            if iszero(eq(caller(), pairCreator)) {
                revert(0x18, 0x4) // NotPairCreator()
            }

            if gt(sload(pool.slot), returndatasize()) {
                revert(0x1c, 0x4) // AlreadyStarted()
            }
        }

        _startTime = block.timestamp;
        pool = poolAddress;
    }
}
