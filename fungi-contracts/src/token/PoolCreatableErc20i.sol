// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";

abstract contract PoolCreatableErc20i is ERC20 {
    error NotPairCreator();
    error AlreadyStarted();

    address internal _pool;
    uint256 internal _startTime;
    bool internal _feeLocked;
    address internal immutable _pairCreator;

    constructor(
        string memory name_,
        string memory symbol_,
        address pairCreator
    ) ERC20(name_, symbol_) payable {
        _pairCreator = pairCreator;
    }

    function launch(address poolAddress) external payable {
        if (msg.sender != _pairCreator) revert NotPairCreator();
        if (_isStarted()) revert AlreadyStarted();

        _pool = poolAddress;
        _startTime = block.timestamp;
    }

    function pool() external view returns (address) {
        return _pool;
    }

    function _isStarted() internal view returns (bool) {
        return _pool != address(0);
    }
}
