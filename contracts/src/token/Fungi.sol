// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/Test.sol";
import {ERC20, PoolCreatableErc20i} from "./PoolCreatableErc20i.sol";
import {Generator} from "../Generator.sol";
import {ExtraSeedLib} from "../lib/ExtraSeedLib.sol";
import {SeedData} from "../lib/Types.sol";

// Here as there are already much writes, all the holder logic has been removed as those can be fetched through APIs / TheGraph
abstract contract Mushrooms is PoolCreatableErc20i {
    using ExtraSeedLib for address;

    // SeedData struct is 160 bytes large, packing as much as we can
    struct HolderData {
        // large enough
        uint48 counts;
        // same, off a world pop 8B should be enough
        uint48 listIndex;
        SeedData spores;
    }

    mapping(address owner => HolderData) internal _holdersData;
    // TODO: See if able to combine those, why using 2 addr => tokenid => index => seed see if any point in it
    mapping(address owner => mapping(uint256 index => SeedData _seedData))
        internal _ownedTokens;
    mapping(address owner => mapping(uint256 tokenId => uint256)) internal
        _ownedTokensIndex;
    mapping(address owner => mapping(uint256 => bool)) internal _owns;
    mapping(uint256 index => address user) _holderList;
    // Below should be way enough, could probably pack more
    uint72 public mushroomsTotalCount;
    uint72 public sporesTotalCount;
    uint72 public holdersCount;

    event OnMushroomTransfer(
        address indexed from, address indexed to, SeedData _seedData
    );
    event OnSporesGrow(address indexed holder, SeedData seedData);
    event OnSporesShrink(address indexed holder, SeedData seedData);

    constructor() PoolCreatableErc20i(msg.sender) {}

    function _isHolder(address account) private view returns (bool) {
        return (_holdersData[account].spores.seed + this.mushroomCount(account))
            > 0;
    }

    function name() public pure override returns (string memory) {
        return "Fungi";
    }

    function symbol() public pure override returns (string memory) {
        return "FUNGI";
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function getHolderByIndex(uint256 index) public view returns (address) {
        return _holderList[index];
    }

    function getHoldersList(uint256 startIndex, uint256 count)
        external
        view
        returns (address[] memory)
    {
        address[] memory holders = new address[](count);

        for (uint256 i = 0; i < count; ++i) {
            holders[i] = getHolderByIndex(startIndex + i);
        }

        return holders;
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
        return _holdersData[owner].spores;
    }

    function mushroomCount(address owner) external view returns (uint256) {
        return _holdersData[owner].counts;
    }

    function mushroomOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (SeedData memory data)
    {
        return _ownedTokens[owner][index];
    }

    function _trySeedTransfer(address from, address to, uint256 amount)
        internal
    {
        if (from == address(this)) return;

        address cachedPool = pool;
        bool checkFrom =
            !(from == address(this) || from == cachedPool || from == address(0));
        bool checkTo =
            !(to == address(this) || to == cachedPool || to == address(0));

        bool beforeTo;

        if (!checkTo) beforeTo = _isHolder(to);

        {
            uint256 scale;
            uint32 seed;

            {
                scale = 10 ** decimals();
                seed = uint32(amount / scale);

                if (seed > 0 && from != cachedPool && to != cachedPool) {
                    SeedData memory fromSpores = _holdersData[from].spores;
                    // transfer growing mushroom
                    if (fromSpores.seed == seed) {
                        _removeSeedCount(from, seed);
                        _addTokenToOwnerEnumeration(to, fromSpores);

                        emit OnMushroomTransfer(from, to, fromSpores);

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
            }

            {
                uint256 fromBalance = balanceOf(from);
                // transfer spores
                uint32 lastBalanceFromSeed = uint32(fromBalance / scale);
                uint32 newBalanceFromSeed =
                    uint32((fromBalance - amount) / scale);

                _removeSeedCount(from, lastBalanceFromSeed - newBalanceFromSeed);
                _addSeedCount(to, seed);
            }
        }

        if (checkFrom || checkTo) {
            uint256 localHolderCount = holdersCount;
            uint256 tmpCheck = localHolderCount;

            // from is no longer holder
            if (checkFrom && !_isHolder(from)) {
                if (localHolderCount > 0) {
                    localHolderCount -= 1;

                    _holderList[_holdersData[from].listIndex] =
                        _holderList[localHolderCount];

                    delete _holderList[localHolderCount];

                    _holdersData[from].listIndex = 0;
                }
            }

            // to is a new holder
            if (checkTo && !beforeTo && _isHolder(to)) {
                _holderList[localHolderCount] = to;
                _holdersData[to].listIndex = uint48(localHolderCount);

                localHolderCount = localHolderCount + 1;
            }

            console.log("local holder count", localHolderCount);
            console.log("from balance", balanceOf(from));

            if (localHolderCount != tmpCheck) {
                holdersCount = uint72(localHolderCount);
            }
        }
    }

    function _addSeedCount(address account, uint32 seed) private {
        if (seed == uint256(0) || account == pool) return;

        SeedData memory last = _holdersData[account].spores;
        uint32 nextSeed = last.seed + seed;
        SeedData memory next = SeedData(nextSeed, account.extra());

        _holdersData[account].spores = next;

        if (last.seed == uint256(0) && nextSeed > uint256(0)) {
            ++sporesTotalCount;
        }

        emit OnSporesGrow(account, next);
    }

    function _removeSeedCount(address account, uint32 seed) private {
        if (seed == 0 || account == pool) return;

        SeedData memory lastSpores = _holdersData[account].spores;

        if (lastSpores.seed >= seed) {
            uint32 earlyNextSeed = lastSpores.seed - seed;
            SeedData memory earlyNextSeedData =
                SeedData(earlyNextSeed, lastSpores.extra);

            _holdersData[account].spores = earlyNextSeedData;

            if (lastSpores.seed > 0 && earlyNextSeed == 0) {
                --sporesTotalCount;
            }

            emit OnSporesShrink(account, earlyNextSeedData);

            return;
        }

        uint32 seedRemains = seed - lastSpores.seed;

        // remove mushrooms
        uint32 removed;

        {
            uint256 count = _holdersData[account].counts;

            for (uint256 i; i < count && removed < seedRemains; ++i) {
                uint32 removedSeed = _ownedTokens[account][i].seed;

                _removeTokenFromOwnerEnumeration(account, removedSeed);

                removed += seed;
            }
        }

        uint32 nextSeed;

        if (removed > seedRemains) {
            nextSeed = lastSpores.seed + removed - seedRemains;
        }

        SeedData memory nextSeedData = SeedData(nextSeed, account.extra());

        _holdersData[account].spores = nextSeedData;

        if (lastSpores.seed > 0 && nextSeed == 0) --sporesTotalCount;

        emit OnSporesShrink(account, nextSeedData);
    }

    function _addTokenToOwnerEnumeration(address to, SeedData memory data)
        private
    {
        if (to == pool) return;

        uint256 cachedCount = _holdersData[to].counts;

        _holdersData[to].counts = uint48(cachedCount + 1);
        ++mushroomsTotalCount;
        _ownedTokens[to][cachedCount] = data;
        _ownedTokensIndex[to][data.seed] = cachedCount;
        _owns[to][data.seed] = true;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint32 seed)
        private
    {
        if (from == pool) return;

        uint256 nextCount = _holdersData[from].counts - 1;

        _holdersData[from].counts = uint48(nextCount);
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

    uint256 private constant _START_TOTAL_SUPPLY = 210e6 * (10 ** 9);
    uint256 private constant _START_MAX_BUY_COUNT =
        (_START_TOTAL_SUPPLY * 5) / 10000;
    uint256 private constant _ADD_MAX_BUY_PERCENT_PER_SEC = 5; // 100%=_ADD_MAX_BUY_PRECISION add 0.005%/second
    uint256 private constant _ADD_MAX_BUY_PRECISION = 100000;

    constructor() {
        _mint(msg.sender, _START_TOTAL_SUPPLY);
    }

    function maxBuy() public view returns (uint256) {
        if (pool == address(0)) return _START_TOTAL_SUPPLY;

        uint256 count = _START_MAX_BUY_COUNT
            + (
                _START_TOTAL_SUPPLY * (block.timestamp - _startTime)
                    * _ADD_MAX_BUY_PERCENT_PER_SEC
            ) / _ADD_MAX_BUY_PRECISION;

        return (count < _START_TOTAL_SUPPLY) ? count : _START_TOTAL_SUPPLY;
    }

    function burnCount() public view returns (uint256) {
        return _START_TOTAL_SUPPLY - totalSupply();
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (pool != address(0)) {
            _trySeedTransfer(from, to, amount);
        } else if (!(from == _owner || to == _owner)) {
            revert NotStarted();
        }

        if (to == address(0)) {
            // burns
            _burn(from, amount);

            return;
        } else if (!_feeLocked && from == pool) {
            // buys
            if (amount > maxBuy()) revert MaxBuy();

            _feeLocked = true;

            super._transfer(pool, to, amount);

            _feeLocked = false;

            return;
        }

        // default
        super._transfer(from, to, amount);
    }
}
