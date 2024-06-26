// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20, PoolCreatableErc20i} from "./PoolCreatableErc20i.sol";
import {Generator} from "../Generator.sol";
import {ExtraSeedLib} from "../lib/ExtraSeedLib.sol";
import {SeedData} from "../lib/Types.sol";

// Here as there are already much writes, all the holder logic has been removed as those can be fetched through APIs / TheGraph
abstract contract Mushrooms is PoolCreatableErc20i {
    using ExtraSeedLib for address;

    mapping(address owner => uint256) internal _counts;
    mapping(address owner => mapping(uint256 index => SeedData _seedData)) internal _ownedTokens;
    mapping(address owner => mapping(uint256 tokenId => uint)) internal _ownedTokensIndex;
    mapping(address owner => mapping(uint256 => bool)) internal _owns;
    mapping(address owner => SeedData _seedData) internal _spores;
    uint256 public mushroomsTotalCount;
    uint256 internal sporesTotalCount;
    // matching packing in rdm / seed data
    uint128 internal _randomNonce;

    event OnMushroomTransfer(
        address indexed from,
        address indexed to,
        SeedData _seedData
    );
    event OnSporesGrow(address indexed holder, SeedData seedData);
    event OnSporesShrink(address indexed holder, SeedData seedData);

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

    function _trySeedTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(this)) return;

        uint256 cachedDecimals = decimals();
        uint32 seed = uint32(amount / (10 ** cachedDecimals));
        address cachedPool = pool;

        if (seed > 0 && from != cachedPool && to != cachedPool) {
            SeedData memory fromSpores = _spores[from];
            // transfer growing mushroom
            if (fromSpores.seed == seed) {
                _removeSeedCount(from, seed);
                _addTokenToOwnerEnumeration(to, fromSpores);

                emit OnMushroomTransfer(from, to, fromSpores);

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
        if (account == pool) return;

        SeedData memory last = _spores[account];
        uint32 nextSeed = last.seed + seed;

        _spores[account] = SeedData(nextSeed, account.extra(++_randomNonce));

        if (last.seed == 0 && nextSeed > 0) ++sporesTotalCount;

        emit OnSporesGrow(account, _spores[account]);
    }

    function _removeSeedCount(address account, uint32 seed) private {
        if (seed == 0) return;
        if (account == pool) return;

        SeedData memory lastSpores = _spores[account];

        if (lastSpores.seed >= seed) {
            uint32 earlyNextSeed = lastSpores.seed - seed;
            SeedData memory earlyNextSeedData = SeedData(
                earlyNextSeed,
                account.extra(++_randomNonce)
            );

            _spores[account] = earlyNextSeedData;

            if (lastSpores.seed > 0 && earlyNextSeed == 0)
                --sporesTotalCount;

            emit OnSporesShrink(account, earlyNextSeedData);

            return;
        }

        uint32 seedRemains = seed - lastSpores.seed;

        // remove mushrooms
        uint32 removed;

        {
            uint256 count = _counts[account];

            for (uint256 i; i < count && removed < seedRemains; ++i) {
                uint32 removedSeed = _ownedTokens[account][0].seed;

                _removeTokenFromOwnerEnumeration(account, removedSeed);

                removed += seed;
            }
        }

        uint128 nextRdmNonce;
        uint32 nextSeed;

        if (removed > seedRemains) {
            // Allows rdm nonce OF
            unchecked {
                nextRdmNonce = _randomNonce + 2;
            }

            nextSeed = lastSpores.seed + removed - seedRemains;
        } else {
            // Allows rdm nonce OF
            unchecked {
                nextRdmNonce = _randomNonce + 1;
            }

            nextSeed = 0;
        }

        SeedData memory nextSeedData = SeedData(
            nextSeed,
            account.extra(nextRdmNonce)
        );

        _spores[account] = nextSeedData;
        _randomNonce = nextRdmNonce;

        if (lastSpores.seed > 0 && nextSeed == 0) --sporesTotalCount;

        emit OnSporesShrink(account, nextSeedData);
    }

    function _addTokenToOwnerEnumeration(
        address to,
        SeedData memory data
    ) private {
        if (to == pool) return;

        uint256 cachedCount = _counts[to];

        _counts[to] = cachedCount + 1;
        ++mushroomsTotalCount;
        _ownedTokens[to][cachedCount] = data;
        _ownedTokensIndex[to][data.seed] = cachedCount;
        _owns[to][data.seed] = true;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint32 seed) private {
        if (from == pool) return;

        uint256 nextCount = _counts[from] - 1;

        _counts[from] = nextCount;
        --mushroomsTotalCount;
        _owns[from][seed] = false;

        uint256 lastTokenIndex = nextCount;
        uint256 tokenIndex = _ownedTokensIndex[from][seed];
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
        if (pool == address(0)) return _START_TOTAL_SUPPLY;

        uint256 count = _START_MAX_BUY_COUNT +
            (_START_TOTAL_SUPPLY *
            (block.timestamp - _startTime) *
                _ADD_MAX_BUY_PERCENT_PER_SEC) /
            _ADD_MAX_BUY_PRECISION;

        if (count > _START_TOTAL_SUPPLY) count = _START_TOTAL_SUPPLY;

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
        if (pool != address(0)) {
            _trySeedTransfer(from, to, amount);
        } else if (!(from == _owner || to == _owner)) {
            revert NotStarted();
        }

        if (to == address(0)) {
            // burns
            _burn(from, amount);

            return;
        } else if (from == pool) {
            // buys
            _buy(to, amount);

            return;
        }

        // default

        super._transfer(from, to, amount);
    }

    function _buy(
        address to,
        uint256 amount
    ) private {
        if (amount > maxBuy()) revert MaxBuy();

        _feeLocked = true;

        super._transfer(pool, to, amount);

        _feeLocked = false;
    }

    function burnCount() public view returns (uint256) {
        return _START_TOTAL_SUPPLY - totalSupply();
    }
}
