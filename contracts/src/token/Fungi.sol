// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20, PoolCreatableErc20i} from "./PoolCreatableErc20i.sol";
import {Generator} from "../Generator.sol";
import {ExtraSeedLib} from "../lib/ExtraSeedLib.sol";
import {SeedData} from "../lib/Types.sol";

abstract contract Mushrooms is PoolCreatableErc20i {
    using ExtraSeedLib for address;

    mapping(address owner => uint256) internal _counts;
    mapping(address owner => mapping(uint256 index => SeedData _seedData)) internal _ownedTokens;
    mapping(address owner => mapping(uint256 tokenId => uint)) internal _ownedTokensIndex;
    mapping(address owner => mapping(uint256 => bool)) internal _owns;
    mapping(address owner => SeedData _seedData) internal _spores;
    uint256 internal _mushroomsTotalCount;
    uint256 internal _sporesTotalCount;
    uint96 internal _randomNonce;

    event OnMushroomTransfer(
        address indexed from,
        address indexed to,
        SeedData _seedData
    );
    event OnSporesGrow(address indexed holder, SeedData _seedData);
    event OnSporesShrink(address indexed holder, SeedData _seedData);

    constructor() PoolCreatableErc20i(msg.sender) {}

    function name() public pure override returns (string memory) {
        return "Fungi";
    }

    function symbol() public pure override returns (string memory) {
        return "FUNGI";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function _trySeedTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 cachedDecimals = decimals();

        if (from == address(this)) return;
        uint32 seed = uint32(amount / (10 ** cachedDecimals));

        if (seed > 0 && from != _pool && to != _pool) {
            // transfer growing mushroom
            if (_spores[from].seed == seed) {
                SeedData memory data = _spores[from];
                _removeSeedCount(from, seed);
                _addTokenToOwnerEnumeration(to, data);
                emit OnMushroomTransfer(from, to, data);
                return;
            }

            // transfer collected mushroom
            if (_owns[from][seed] && !_owns[to][seed]) {
                SeedData memory data = _ownedTokens
                    [from]
                    [_ownedTokensIndex[from][seed]];
                _removeTokenFromOwnerEnumeration(from, seed);
                _addTokenToOwnerEnumeration(to, data);
                emit OnMushroomTransfer(from, to, data);
                return;
            }
        }

        {
            uint256 fromBalance = balanceOf(from);
            // transfer spores
            uint32 lastBalanceFromSeed = uint32(fromBalance / (10 ** cachedDecimals));
            uint32 newBalanceFromSeed = lastBalanceFromSeed - seed;

            _removeSeedCount(from, lastBalanceFromSeed - newBalanceFromSeed);
            _addSeedCount(to, seed);
        }
    }

    function _addSeedCount(address account, uint32 seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory last = _spores[account];

        _spores[account].seed = last.seed + seed;
        _spores[account].extra = account.extra(++_randomNonce);

        if (last.seed == 0 && _spores[account].seed > 0) ++_sporesTotalCount;

        emit OnSporesGrow(account, _spores[account]);
    }

    function _removeSeedCount(address account, uint32 seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory lastSpores = _spores[account];
        if (_spores[account].seed >= seed) {
            _spores[account].seed -= seed;
            _spores[account].extra = account.extra(++_randomNonce);
            if (lastSpores.seed > 0 && _spores[account].seed == 0)
                --_sporesTotalCount;
            emit OnSporesShrink(account, _spores[account]);
            return;
        }
        uint32 seedRemains = seed - _spores[account].seed;
        _spores[account].seed = 0;
        _spores[account].extra = account.extra(++_randomNonce);

        // remove mushrooms
        uint count = _counts[account];
        uint32 removed;

        for (uint i = 0; i < count && removed < seedRemains; ++i) {
            removed += _removeFirstTokenFromOwner(account);
        }

        if (removed > seedRemains) {
            _spores[account].seed += removed - seedRemains;
            _spores[account].extra = account.extra(++_randomNonce);
        }
        if (lastSpores.seed > 0 && _spores[account].seed == 0)
            --_sporesTotalCount;
        emit OnSporesShrink(account, _spores[account]);
    }

    function _addTokenToOwnerEnumeration(
        address to,
        SeedData memory data
    ) private {
        if (to == _pool) return;
        ++_counts[to];
        ++_mushroomsTotalCount;
        uint length = _counts[to] - 1;
        _ownedTokens[to][length] = data;
        _ownedTokensIndex[to][data.seed] = length;
        _owns[to][data.seed] = true;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint32 seed) private {
        if (from == _pool) return;
        --_counts[from];
        --_mushroomsTotalCount;
        _owns[from][seed] = false;
        uint lastTokenIndex = _counts[from];
        uint tokenIndex = _ownedTokensIndex[from][seed];
        SeedData memory data = _ownedTokens[from][tokenIndex];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            SeedData memory lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[from][lastTokenId.seed] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[from][data.seed];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeFirstTokenFromOwner(address owner) private returns (uint32) {
        uint count = _counts[owner];
        if (count == 0) return 0;
        uint32 seed = _ownedTokens[owner][0].seed;
        _removeTokenFromOwnerEnumeration(owner, seed);
        return seed;
    }

    function isOwnerOf(address owner, uint256 seed) external view returns (bool) {
        return _owns[owner][seed];
    }

    function sporesDegree(
        address owner
    ) external view returns (SeedData memory data) {
        return _spores[owner];
    }

    function mushroomCount(address owner) external view returns (uint) {
        return _counts[owner];
    }

    function mushroomOfOwnerByIndex(
        address owner,
        uint index
    ) external view returns (SeedData memory data) {
        return _ownedTokens[owner][index];
    }

    function mushroomsTotalCount() external view returns (uint) {
        return _mushroomsTotalCount;
    }

    function sporesTotalCount() external view returns (uint) {
        return _sporesTotalCount;
    }
}

contract Fungi is Mushrooms, Generator {
    error MaxBuy();
    error NotStarted();

    uint256 private constant _START_TOTAL_SUPPLY = 210e6 * (10 ** 18);
    uint256 private constant _START_MAX_BUY_COUNT = (_START_TOTAL_SUPPLY * 5) / 10000;
    uint256 private constant _ADD_MAX_BUY_PERCENT_PER_SEC = 5; // 100%=_ADD_MAX_BUY_PRECISION add 0.005%/second
    uint256 private constant _ADD_MAX_BUY_PRECISION = 100000;

    constructor() {
        _mint(msg.sender, _START_TOTAL_SUPPLY);
    }

    function maxBuy() public view returns (uint256) {
        uint256 startSupply = _START_TOTAL_SUPPLY;

        if (!_isStarted()) return startSupply;

        uint256 count = _START_MAX_BUY_COUNT +
            (startSupply *
            (block.timestamp - _startTime) *
                _ADD_MAX_BUY_PERCENT_PER_SEC) /
            _ADD_MAX_BUY_PRECISION;
        if (count > startSupply) count = startSupply;
        return count;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(from, to, amount);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (_isStarted()) {
            _trySeedTransfer(from, to, amount);
        } else {
            if (!(from == _owner || to == _owner)) revert NotStarted();
        }

        // allow burning
        if (to == address(0)) {
            _burn(from, amount);
            return;
        }

        // system transfers
        if (from == address(this)) {
            super._transfer(from, to, amount);
            return;
        }

        if (_feeLocked) {
            super._transfer(from, to, amount);
            return;
        } else {
            if (from == _pool) {
                _buy(to, amount);
                return;
            }
        }

        super._transfer(from, to, amount);
    }

    function _buy(
        address to,
        uint256 amount
    ) private {
        if (amount > maxBuy()) revert MaxBuy();

        _feeLocked = true;

        super._transfer(_pool, to, amount);

        _feeLocked = false;
    }

    function burnCount() public view returns (uint256) {
        return _START_TOTAL_SUPPLY - totalSupply();
    }
}
