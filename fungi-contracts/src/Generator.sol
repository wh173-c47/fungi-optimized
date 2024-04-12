// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/Ownable.sol";

uint256 constant _LEVELS_COUNT = 5;
uint256 constant _BC_GROUNDS_COUNT = 6;
uint256 constant _GROUNDS_COUNT = 2;
uint8 constant _PIXELS_COUNT = 24;
// Allows a max seed value of 4294967296
uint32 constant _SEED_LEVEL1 = 21000;
uint32 constant _SEED_LEVEL2 = 525000;
uint32 constant _SEED_LEVEL3 = 1050000;
uint32 constant _SEED_LEVEL4 = 1575000;
uint32 constant _SEED_LEVEL5 = 2100000;
string constant _DESCRIPTION = "Fungi, $FUNGI. The First ERC-20i with Native Inscriptions.";
string constant _WEB = "https://fungifungi.art/";

struct MushroomData {
    uint8 lvl;
    uint8 ground;
    uint8 stem;
    uint8 cap;
    bool hasDots;
    byte8 background;
    byte8 groundColor;
    byte8 stemColor;
    byte8 capColor;
    byte8 dotsColor;
}

struct Rect {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct FileData {
    uint8 lvl;
    uint248 file;
    Rect[] rects;
}

struct ColorsData {
    bytes8[] lvl0;
    bytes8[] lvl1;
    bytes8[] lvl2;
    bytes8[] lvl3;
    bytes8[] lvl4;
}

struct SeedData {
    uint32 seed;
    uint128 extra;
}

struct Rand {
    uint32 seed;
    uint96 nonce;
    uint128 extra;
}

library StringLib {
    function _toString(
        uint256 value
    ) private pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
        // The maximum value of a uint256 contains 78 digits
        // (1 byte per digit), but we allocate 0xa0 bytes to keep the free
        // memory pointer 32-byte word aligned.
        // We will need 1 word for the trailing zeros padding,
        // 1 word for the length, and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
        // Update the free memory pointer to allocate.
            mstore(0x40, add(str, 0x20))
        // Zeroize the slot after the string.
            mstore(str, 0)

        // Cache the end of the memory to calculate the length later.
            let end := str

            let w := not(0) // Tsk.
        // We write the string from rightmost digit to leftmost digit.
        // The following is essentially a do-while loop that also handles
        // the zero case.
            for { let temp := value } 1 {} {
                str := add(str, w) // `sub(str, 1)`.
            // Write the character to the pointer.
            // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
        // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
        // Store the length.
            mstore(str, length)
        }
    }
}

library RandLib {
    function next(Rand memory rnd) internal pure returns (uint256) {
        uint256 baseRdm;

        // allows ops to overflow, avoiding a DOS
        unchecked {
            baseRdm = rnd.nonce + rnd.seed - 1 + rnd.extra;

            ++rnd.nonce;
        }

        return keccakU256(baseRdm);
    }

    function lvl(Rand memory rnd) internal pure returns (uint256) {
        if (rnd.seed < _SEED_LEVEL1) return 0;
        if (rnd.seed < _SEED_LEVEL2) return 1;
        if (rnd.seed < _SEED_LEVEL3) return 2;
        if (rnd.seed < _SEED_LEVEL4) return 3;
        if (rnd.seed < _SEED_LEVEL5) return 4;
        return 5;
    }

    function random(
        bytes8[] memory data,
        Rand memory rnd
    ) internal pure returns (bytes8) {
        return data[randomIndex(data, rnd)];
    }

    function randomIndex(
        bytes8[] memory data,
        Rand memory rnd
    ) internal pure returns (uint256) {
        return next(rnd) % data.length;
    }

    function keccakU256(uint256 input) internal pure returns (uint256 output) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, input)
            output := keccak256(0x0, 0x20)
        }
    }
}

library LayersLib {
    function setLayers(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        FileData[] calldata data
    ) internal {
        for (uint256 i = 0; i < data.length; ++i) {
            setFile(rects, data[i]);
        }
    }

    function setFile(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        FileData calldata input
    ) internal {
        Rect[] storage storageFile = rects[input.lvl][input.file];
        for (uint256 i = 0; i < input.rects.length; ++i) {
            storageFile.push(input.rects[i]);
        }
    }

    function getLvl(
        mapping(uint256 => mapping(uint256 => Rect[])) storage rects,
        uint256 lvl
    ) internal view returns (mapping(uint256 => Rect[]) storage) {
        return rects[lvl];
    }

    function toLvl1(uint256 l) internal pure returns (uint256) {
        if (l > 0) --l;
        return l;
    }
}

library RectLib {
    using RectLib for Rect;
    using RandLib for Rand;
    using RandLib for bytes8[];
    using StringLib for uint256;

    function toSvg(
        Rect memory r,
        bytes8 color
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<rect x='",
                    uint256(r.x)._toString(),
                    "' y='",
                    uint256(r.y)._toString(),
                    "' width='",
                    uint256(r.width)._toString(),
                    "' height='",
                    uint256(r.height)._toString(),
                    "' fill='#",
                    color,
                    "'/>"
                )
            );
    }

    function toSvg(
        Rect[] storage rects,
        bytes8[] storage colors,
        Rand memory rnd
    ) internal view returns (string memory) {
        string memory res;
        for (uint256 i = 0; i < rects.length; ++i) {
            res = string(
                abi.encodePacked(res, rects[i].toSvg(colors.random(rnd)))
            );
        }
        return res;
    }

    function toSvg(
        Rect[] storage rects,
        bytes8 memory color
    ) internal view returns (string memory) {
        string memory res;
        for (uint256 i = 0; i < rects.length; ++i) {
            res = string(abi.encodePacked(res, rects[i].toSvg(color)));
        }
        return res;
    }
}

contract Generator is Ownable {
    using LayersLib for mapping(uint256 => mapping(uint256 => Rect[]));
    using LayersLib for mapping(uint256 => bytes8[]);
    using LayersLib for uint256;
    using RectLib for Rect;
    using RectLib for Rect[];
    using RandLib for Rand;
    using RandLib for bytes8[];

    uint8 private _sporesCount = 7;
    uint8[_LEVELS_COUNT] private _stemLevelCounts = [5, 5, 5, 6, 10];
    uint8[_LEVELS_COUNT] private _capLevelCounts = [5, 7, 10, 10, 10];
    uint8[_LEVELS_COUNT] private _dotLevelCounts = [5, 7, 10, 10, 10];

    mapping(uint256 => Rect[]) private _spores;
    mapping(uint256 => mapping(uint256 => Rect[])) private _stems;
    mapping(uint256 => mapping(uint256 => Rect[])) private _caps;
    mapping(uint256 => mapping(uint256 => Rect[])) private _dots;
    mapping(uint256 => Rect[]) private _grounds;

    bytes8[] private _backgroundColors0 = [
        bytes8("000000"),
        "493114",
        "1d772f",
        "38166a",
        "db4161",
        "7c288a",
        "4141ff",
        "ff61b2",
        "8f3bc2",
        "a2a2a2",
        "bfca87",
        "92dcba",
        "a2fff3",
        "fddad5"
    ];

    bytes8[] private _backgroundColors1 = [
        bytes8("453879"),
        "184b5b",
        "447f60",
        "e35100",
        "ff7930",
        "e43b44",
        "eedc59",
        "f279ca",
        "4deae9",
        "ffdba2",
        "a2baff",
        "ca90ff"
    ];

    bytes8[] private _backgroundColors2 = [
        bytes8("231b32"),
        "3f1164",
        "28426a",
        "9a2079",
        "d45e4e",
        "79dfac",
        "1fabe0",
        "e8a2bf",
        "849be4",
        "e3b2ff"
    ];

    bytes8[] private _backgroundColors3 = [
        bytes8("291970"),
        "413c5d",
        "a44c4c",
        "f8972a",
        "a271ff",
        "4192c3",
        "5182ff",
        "ffb2a7"
    ];

    bytes8[] private _backgroundColors4 = [
        bytes8("0f0c45"),
        "560e43",
        "b21030",
        "ff6e69",
        "534fed",
        "7cb8ff"
    ];

    bytes8[] private _groundColors0 = [
        bytes8("000000"),
        "1d730e",
        "525050",
        "b21030",
        "ff7930",
        "925f4f",
        "db4161",
        "9aeb00",
        "d8cc33",
        "2800ba",
        "f361ff",
        "4192c3",
        "d0c598",
        "f4c09a",
        "e3b2ff"
    ];

    bytes8[] private _groundColors1 = [
        bytes8("020104"),
        "493114",
        "74254d",
        "453879",
        "306141",
        "83376e",
        "e59220",
        "7377a0",
        "30b7c0",
        "86b4bb",
        "ffa9a9",
        "f7e2c5"
    ];

    bytes8[] private _groundColors2 = [
        bytes8("495900"),
        "395844",
        "d47642",
        "719767",
        "8a8a00",
        "806a9c",
        "a2a2a2",
        "86d48e",
        "c3e88d",
        "c3b2ff"
    ];

    bytes8[] private _groundColors3 = [
        bytes8("253d2d"),
        "515130",
        "384f7a",
        "49a269",
        "b18b57",
        "fff392",
        "b4edcd",
        "ffffff"
    ];

    bytes8[] private _groundColors4 = [
        bytes8("663a13"),
        "137d5a",
        "974700",
        "49aa10",
        "99ba5a",
        "ade151"
    ];

    bytes8[] private _mushroomColors0 = [
        bytes8("000000"),
        "1d730e",
        "525050",
        "b21030",
        "ff7930",
        "925f4f",
        "db4161",
        "9aeb00",
        "d8cc33",
        "2800ba",
        "f361ff",
        "4192c3",
        "d0c598",
        "f4c09a",
        "e3b2ff"
    ];

    bytes8[] private _mushroomColors1 = [
        bytes8("020104"),
        "493114",
        "74254d",
        "453879",
        "306141",
        "83376e",
        "e59220",
        "7377a0",
        "30b7c0",
        "86b4bb",
        "ffa9a9",
        "f7e2c5"
    ];

    bytes8[] private _mushroomColors2 = [
        bytes8("495900"),
        "395844",
        "d47642",
        "719767",
        "8a8a00",
        "806a9c",
        "a2a2a2",
        "86d48e",
        "c3e88d",
        "c3b2ff"
    ];

    bytes8[] private _mushroomColors3 = [
        bytes8("253d2d"),
        "515130",
        "384f7a",
        "49a269",
        "b18b57",
        "fff392",
        "b4edcd",
        "ffffff"
    ];

    bytes8[] private _mushroomColors4 = [
        bytes8("663a13"),
        "137d5a",
        "974700",
        "49aa10",
        "99ba5a",
        "ade151"
    ];

    constructor() {
        _grounds[0].push(Rect(0, 17, 24, 7));
        _grounds[1].push(Rect(0, 17, 24, 8));
        _grounds[1].push(Rect(0, 17, 24, 1));
        _grounds[1].push(Rect(0, 18, 24, 1));
    }

    function _setSpores(FileData[] calldata data) external {
        _onlyOwner();

        for (uint256 i = 0; i < data.length; ++i) {
            FileData memory file = data[i];
            Rect[] storage storageFile = _spores[file.file];
            for (uint256 j = 0; j < file.rects.length; ++j) {
                storageFile.push(file.rects[j]);
            }
        }
    }

    function _setStems(FileData[] calldata data) external {
        _onlyOwner();

        _stems.setLayers(data);
    }

    function _setCaps(FileData[] calldata data) external {
        _onlyOwner();

        _caps.setLayers(data);
    }

    function setDots(FileData[] calldata data) external {
        _onlyOwner();

        _dots.setLayers(data);
    }

    function getMushroom(
        SeedData calldata seedData
    ) external view returns (MushroomData memory) {
        Rand memory rnd = Rand(seedData.seed, 0, seedData.extra);
        MushroomData memory data;
        data.lvl = rnd.lvl();
        _setBcGround(data, rnd);
        _setGround(data, rnd);
        if (data.lvl == 0) {
            _setSpores(data, rnd);
        } else {
            _setStem(data, rnd);
            _setCap(data, rnd);
        }
        return data;
    }

    function getSvg(
        SeedData calldata seedData
    ) external view returns (string memory) {
        return _toSvg(this.getMushroom(seedData));
    }

    function getMeta(
        SeedData calldata seedData
    ) external view returns (string memory) {
        MushroomData memory data = this.getMushroom(seedData);
        bytes memory lvl = abi.encodePacked('"level":', _toString(uint256(data.lvl)));
        bytes memory background = abi.encodePacked(
            ',"background":"#',
            data.background,
            '"'
        );
        bytes memory ground = abi.encodePacked(
            ',"groundColor":"#',
            data.groundColor,
            '"'
        );
        bytes memory stem = abi.encodePacked(
            ',"stem":',
            _toString(uint256(data.stem)),
            ',"stemColor":"#',
            data.stemColor,
            '"'
        );
        bytes memory cap = abi.encodePacked(
            ',"cap":',
            _toString(uint256(data.cap)),
            ',"capColor":"#',
            data.capColor,
            '"'
        );
        bytes memory capDots = abi.encodePacked(
            ',"hasDots":',
            data.hasDots ? "true" : "false",
            ',"_dotsColor":"#',
            data.dotsColor,
            '",'
        );
        bytes memory _WEB_text = abi.encodePacked('"_WEB":"', _WEB, '",');
        bytes memory _DESCRIPTION_text = abi.encodePacked(
            '"_DESCRIPTION":"',
            _DESCRIPTION,
            '"'
        );

        return
            string(
            abi.encodePacked(
                "{",
                lvl,
                background,
                ground,
                stem,
                cap,
                capDots,
                _WEB_text,
                _DESCRIPTION_text,
                "}"
            )
        );
    }

    function _backgroundColors(
        uint256 index
    ) private view returns (bytes8[] storage) {
        if (index == 0) return _backgroundColors0;
        if (index == 1) return _backgroundColors1;
        if (index == 2) return _backgroundColors2;
        if (index == 3) return _backgroundColors3;
        if (index == 4) return _backgroundColors4;
        return _backgroundColors0;
    }

    function _groundColors(
        uint256 index
    ) private view returns (bytes8[] storage) {
        if (index == 0) return _groundColors0;
        if (index == 1) return _groundColors1;
        if (index == 2) return _groundColors2;
        if (index == 3) return _groundColors3;
        if (index == 4) return _groundColors4;
        return _groundColors0;
    }

    function _mushroomColors(
        uint256 index
    ) private view returns (bytes8[] storage) {
        if (index == 0) return _mushroomColors0;
        if (index == 1) return _mushroomColors1;
        if (index == 2) return _mushroomColors2;
        if (index == 3) return _mushroomColors3;
        if (index == 4) return _mushroomColors4;
        return _mushroomColors0;
    }
    
    function _setBcGround(
        MushroomData memory data,
        Rand memory rnd
    ) private view {
        data.background = _backgroundColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setGround(MushroomData memory data, Rand memory rnd) private view {
        data.ground = rnd.next() % _GROUNDS_COUNT;
        data.groundColor = _groundColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setSpores(MushroomData memory data, Rand memory rnd) private view {
        data.stem = rnd.next() % _sporesCount;
        data.stemColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setStem(MushroomData memory data, Rand memory rnd) private view {
        data.stem = rnd.next() % _stemLevelCounts[rnd.lvl().toLvl1()];
        data.stemColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setCap(MushroomData memory data, Rand memory rnd) private view {
        data.cap = rnd.next() % _capLevelCounts[rnd.lvl().toLvl1()];
        data.capColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
        data.hasDots = rnd.next() % 4 == 0;
        if (data.hasDots) {
            data.dotsColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
        }
    }

    function _toSvg(
        MushroomData memory data
    ) private view returns (string memory) {
        bytes memory svgStart = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0",
            " ",
            _toString(_PIXELS_COUNT),
            " ",
            _toString(_PIXELS_COUNT),
            "'>"
        );

        if (data.lvl == 0) {
            return
                string(
                    abi.encodePacked(
                        svgStart,
                        _backgroundSvg(data),
                        _groundSvg(data),
                        _stemSvg(data),
                        "</svg>"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        svgStart,
                        _backgroundSvg(data),
                        _groundSvg(data),
                        _stemSvg(data),
                        _capSvg(data),
                        "</svg>"
                    )
                );
        }
    }

    function _backgroundSvg(
        MushroomData memory data
    ) private pure returns (string memory) {
        Rect memory r = Rect(0, 0, _PIXELS_COUNT, _PIXELS_COUNT);
        return r.toSvg(data.background);
    }

    function _groundSvg(
        MushroomData memory data
    ) private view returns (string memory) {
        return _grounds[data.ground].toSvg(data.groundColor);
    }

    function _stemSvg(
        MushroomData memory data
    ) private view returns (string memory) {
        if (data.lvl == 0) return _spores[data.stem].toSvg(data.stemColor);
        return _stems[data.lvl.toLvl1()][data.stem].toSvg(data.stemColor);
    }

    function _capSvg(
        MushroomData memory data
    ) private view returns (string memory) {
        string memory cap = _caps[data.lvl.toLvl1()][data.cap].toSvg(
            data.capColor
        );
        if (data.hasDots) {
            string memory _dotsSvg = _dots[data.lvl.toLvl1()][data.cap].toSvg(
                data._dotsColor
            );
            return string(abi.encodePacked(cap, _dotsSvg));
        } else {
            return string(cap);
        }
    }
}
