// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Erc20.sol";
import "./PoolCreatableErc20i.sol";
import "../Generator.sol";

library ExtraSeedLibrary {
    function extra(address account) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(account)));
    }

    function seed_data(address account, uint256 seed)
        internal
        pure
        returns (SeedData memory)
    {
        return SeedData(seed, extra(account));
    }
}

abstract contract Mushrooms is PoolCreatableErc20i {
    using ExtraSeedLibrary for address;

    mapping(address owner => uint256) _counts;
    mapping(address owner => mapping(uint256 index => SeedData seed_data))
        _ownedTokens;
    mapping(address owner => mapping(uint256 tokenId => uint256))
        _ownedTokensIndex;
    mapping(address owner => mapping(uint256 => bool)) _owns;
    mapping(address owner => SeedData seed_data) _spores;
    mapping(uint256 index => address user) _holderList;
    mapping(address user => uint256 index) _holderListIndexes;
    uint256 _mushroomsTotalCount;
    uint256 _holdersCount;
    uint256 _sporesTotalCount;

    event OnMushroomTransfer(
        address indexed from, address indexed to, SeedData seed_data
    );
    event OnSporesGrow(address indexed holder, SeedData seed_data);
    event OnSporesShrink(address indexed holder, SeedData seed_data);

    constructor() PoolCreatableErc20i("Fungi", "FUNGI", msg.sender) {}

    modifier holder_calculate(address acc1, address acc2) {
        bool before1 = _isHolder(acc1);
        bool before2 = _isHolder(acc2);
        _;
        bool after1 = _isHolder(acc1);
        bool after2 = _isHolder(acc2);
        if (!before1 && after1) _addHolder(acc1);
        if (before1 && !after1) _removeHolder(acc1);
        if (!before2 && after2) _addHolder(acc2);
        if (before2 && !after2) _removeHolder(acc2);
    }

    function _isHolder(address account) private view returns (bool) {
        if (
            account == address(this) || account == _pool
                || account == address(0)
        ) return false;

        return (_spores[account].seed + this.mushroomCount(account)) > 0;
    }

    function trySeedTransfer(address from, address to, uint256 amount)
        internal
        holder_calculate(from, to)
    {
        if (from == address(this)) return;
        uint256 seed = amount / (10 ** decimals());

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
                SeedData memory data =
                    _ownedTokens[from][_ownedTokensIndex[from][seed]];
                _removeTokenFromOwnerEnumeration(from, seed);
                _addTokenToOwnerEnumeration(to, data);
                emit OnMushroomTransfer(from, to, data);
                return;
            }
        }

        // transfer spores
        uint256 lastBalanceFromSeed = _balances[from] / (10 ** decimals());
        uint256 newBalanceFromSeed =
            (_balances[from] - amount) / (10 ** decimals());
        _removeSeedCount(from, lastBalanceFromSeed - newBalanceFromSeed);
        _addSeedCount(to, seed);
    }

    function _addHolder(address account) private {
        _holderList[_holdersCount] = account;
        _holderListIndexes[account] = _holdersCount;
        ++_holdersCount;
    }

    function _removeHolder(address account) private {
        if (_holdersCount == 0) return;
        --_holdersCount;
        uint256 removingIndex = _holderListIndexes[account];
        _holderList[removingIndex] = _holderList[_holdersCount];
        delete _holderList[_holdersCount];
        delete _holderListIndexes[account];
    }

    function getHolderByIndex(uint256 index) public view returns (address) {
        return _holderList[index];
    }

    function getHoldersList(uint256 startIndex, uint256 count)
        public
        view
        returns (address[] memory)
    {
        address[] memory holders = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            holders[i] = getHolderByIndex(startIndex + i);
        }
        return holders;
    }

    function _addSeedCount(address account, uint256 seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory last = _spores[account];

        _spores[account].seed += seed;
        _spores[account].extra = account.extra();

        if (last.seed == 0 && _spores[account].seed > 0) ++_sporesTotalCount;

        emit OnSporesGrow(account, _spores[account]);
    }

    function _removeSeedCount(address account, uint256 seed) private {
        if (seed == 0) return;
        if (account == _pool) return;
        SeedData memory lastSpores = _spores[account];
        if (_spores[account].seed >= seed) {
            _spores[account].seed -= seed;
            if (lastSpores.seed > 0 && _spores[account].seed == 0) {
                --_sporesTotalCount;
            }
            emit OnSporesShrink(account, _spores[account]);
            return;
        }
        uint256 seedRemains = seed - _spores[account].seed;
        _spores[account].seed = 0;

        // remove mushrooms
        uint256 count = _counts[account];
        uint256 removed;
        for (uint256 i = 0; i < count && removed < seedRemains; ++i) {
            removed += _removeFirstTokenFromOwner(account);
        }

        if (removed > seedRemains) {
            _spores[account].seed += removed - seedRemains;
        }
        if (lastSpores.seed > 0 && _spores[account].seed == 0) {
            --_sporesTotalCount;
        }
        emit OnSporesShrink(account, _spores[account]);
    }

    function _addTokenToOwnerEnumeration(address to, SeedData memory data)
        private
    {
        if (to == _pool) return;
        ++_counts[to];
        ++_mushroomsTotalCount;
        uint256 length = _counts[to] - 1;
        _ownedTokens[to][length] = data;
        _ownedTokensIndex[to][data.seed] = length;
        _owns[to][data.seed] = true;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 seed)
        private
    {
        if (from == _pool) return;
        --_counts[from];
        --_mushroomsTotalCount;
        _owns[from][seed] = false;
        uint256 lastTokenIndex = _counts[from];
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

    function _removeFirstTokenFromOwner(address owner)
        private
        returns (uint256)
    {
        uint256 count = _counts[owner];
        if (count == 0) return 0;
        uint256 seed = _ownedTokens[owner][0].seed;
        _removeTokenFromOwnerEnumeration(owner, seed);
        return seed;
    }

    function isOwnerOf(address owner, uint256 seed)
        external
        view
        returns (bool)
    {
        return _owns[owner][seed];
    }

    function sporesDegree(address owner)
        external
        view
        returns (SeedData memory data)
    {
        return _spores[owner];
    }

    function mushroomCount(address owner) external view returns (uint256) {
        return _counts[owner];
    }

    function mushroomOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (SeedData memory data)
    {
        return _ownedTokens[owner][index];
    }

    function mushroomsTotalCount() external view returns (uint256) {
        return _mushroomsTotalCount;
    }

    function holdersCount() external view returns (uint256) {
        return _holdersCount;
    }

    function sporesTotalCount() external view returns (uint256) {
        return _sporesTotalCount;
    }
}

contract FungiOld is Mushrooms, Generator, ReentrancyGuard {
    uint256 constant _startTotalSupply = 210e6 * (10 ** _decimals);
    uint256 constant _startMaxBuyCount = (_startTotalSupply * 5) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 5; // 100%=_addMaxBuyPrecesion add 0.005%/second
    uint256 constant _addMaxBuyPrecesion = 100000;

    constructor() {
        _mint(msg.sender, _startTotalSupply);
    }

    modifier maxBuyLimit(uint256 amount) {
        require(amount <= maxBuy(), "max buy limit");
        _;
    }

    function maxBuy() public view returns (uint256) {
        if (!isStarted()) return _startTotalSupply;
        uint256 count = _startMaxBuyCount
            + (
                _startTotalSupply * (block.timestamp - _startTime)
                    * _addMaxBuyPercentPerSec
            ) / _addMaxBuyPrecesion;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }

    function _transfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (isStarted()) {
            trySeedTransfer(from, to, amount);
        } else {
            require(from == _owner || to == _owner, "not started");
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
                buy(to, amount);
                return;
            }
        }

        super._transfer(from, to, amount);
    }

    function buy(address to, uint256 amount)
        private
        maxBuyLimit(amount)
        lockFee
    {
        super._transfer(_pool, to, amount);
    }

    function burnCount() public view returns (uint256) {
        return _startTotalSupply - totalSupply();
    }
}
