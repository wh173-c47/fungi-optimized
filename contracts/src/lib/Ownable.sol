// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Ownable {
    error NotOwner();

    address internal _owner;

    event RenounceOwnership();

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function ownerRenounce() public {
        _onlyOwner();

        _owner = address(0);

        emit RenounceOwnership();
    }

    function transferOwnership(address newOwner) external {
        _onlyOwner();

        _owner = newOwner;
    }

    function _onlyOwner() internal view {
        if (_owner != msg.sender) revert NotOwner();
    }
}
