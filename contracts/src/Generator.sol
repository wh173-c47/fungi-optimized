// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "./lib/Ownable.sol";
import {StringLib} from "./lib/StringLib.sol";
import {LayersLib} from "./lib/LayersLib.sol";
import {RandLib} from "./lib/RandLib.sol";
import {RectLib} from "./lib/RectLib.sol";
import {Rect, Rand, FileData, SeedData, MushroomData} from "./lib/Types.sol";

uint256 constant _LEVELS_COUNT = 5;
uint256 constant _BC_GROUNDS_COUNT = 6;
uint256 constant _GROUNDS_COUNT = 2;
uint8 constant _PIXELS_COUNT = 24;
// Allows a max seed value of 4294967296

string constant _DESCRIPTION = "Fungi, $FUNGI. The First ERC-20i with Native Inscriptions.";
string constant _WEB = "https://fungifungi.art/";

contract Generator is Ownable {
    using LayersLib for mapping(uint256 => mapping(uint256 => Rect[]));
    using LayersLib for mapping(uint256 => bytes3[]);
    using LayersLib for uint256;
    using LayersLib for uint8;
    using StringLib for uint8;
    using RectLib for Rect;
    using RectLib for Rect[];
    using RectLib for bytes3;
    using RandLib for Rand;
    using RandLib for bytes3[];

    uint8 private constant _SPORES_COUNT = 7;

    uint8[_LEVELS_COUNT] private _stemLevelCounts = [5, 5, 5, 6, 10];
    uint8[_LEVELS_COUNT] private _capLevelCounts = [5, 7, 10, 10, 10];
    uint8[_LEVELS_COUNT] private _dotLevelCounts = [5, 7, 10, 10, 10];

    mapping(uint256 => Rect[]) private _spores;
    mapping(uint256 => mapping(uint256 => Rect[])) private _stems;
    mapping(uint256 => mapping(uint256 => Rect[])) private _caps;
    mapping(uint256 => mapping(uint256 => Rect[])) private _dots;
    mapping(uint256 => Rect[]) private _grounds;

    // TODO: See how to optimize it, storage is expensive
    bytes3[] private _backgroundColors0 = [
        bytes3(0x000000),
        0x493114,
        0x1d772f,
        0x38166a,
        0xdb4161,
        0x7c288a,
        0x4141ff,
        0xff61b2,
        0x8f3bc2,
        0xa2a2a2,
        0xbfca87,
        0x92dcba,
        0xa2fff3,
        0xfddad5
    ];

    bytes3[] private _backgroundColors1 = [
        bytes3(0x453879),
        0x184b5b,
        0x447f60,
        0xe35100,
        0xff7930,
        0xe43b44,
        0xeedc59,
        0xf279ca,
        0x4deae9,
        0xffdba2,
        0xa2baff,
        0xca90ff
    ];

    bytes3[] private _backgroundColors2 = [
        bytes3(0x231b32),
        0x3f1164,
        0x28426a,
        0x9a2079,
        0xd45e4e,
        0x79dfac,
        0x1fabe0,
        0xe8a2bf,
        0x849be4,
        0xe3b2ff
    ];

    bytes3[] private _backgroundColors3 = [
        bytes3(0x291970),
        0x413c5d,
        0xa44c4c,
        0xf8972a,
        0xa271ff,
        0x4192c3,
        0x5182ff,
        0xffb2a7
    ];

    bytes3[] private _backgroundColors4 = [
        bytes3(0x0f0c45),
        0x560e43,
        0xb21030,
        0xff6e69,
        0x534fed,
        0x7cb8ff
    ];

    bytes3[] private _groundColors0 = [
        bytes3(0x000000),
        0x1d730e,
        0x525050,
        0xb21030,
        0xff7930,
        0x925f4f,
        0xdb4161,
        0x9aeb00,
        0xd8cc33,
        0x2800ba,
        0xf361ff,
        0x4192c3,
        0xd0c598,
        0xf4c09a,
        0xe3b2ff
    ];

    bytes3[] private _groundColors1 = [
        bytes3(0x020104),
        0x493114,
        0x74254d,
        0x453879,
        0x306141,
        0x83376e,
        0xe59220,
        0x7377a0,
        0x30b7c0,
        0x86b4bb,
        0xffa9a9,
        0xf7e2c5
    ];

    bytes3[] private _groundColors2 = [
        bytes3(0x495900),
        0x395844,
        0xd47642,
        0x719767,
        0x8a8a00,
        0x806a9c,
        0xa2a2a2,
        0x86d48e,
        0xc3e88d,
        0xc3b2ff
    ];

    bytes3[] private _groundColors3 = [
        bytes3(0x253d2d),
        0x515130,
        0x384f7a,
        0x49a269,
        0xb18b57,
        0xfff392,
        0xb4edcd,
        0xffffff
    ];

    bytes3[] private _groundColors4 = [
        bytes3(0x663a13),
        0x137d5a,
        0x974700,
        0x49aa10,
        0x99ba5a,
        0xade151
    ];

    bytes3[] private _mushroomColors0 = [
        bytes3(0x000000),
        0x1d730e,
        0x525050,
        0xb21030,
        0xff7930,
        0x925f4f,
        0xdb4161,
        0x9aeb00,
        0xd8cc33,
        0x2800ba,
        0xf361ff,
        0x4192c3,
        0xd0c598,
        0xf4c09a,
        0xe3b2ff
    ];

    bytes3[] private _mushroomColors1 = [
        bytes3(0x020104),
        0x493114,
        0x74254d,
        0x453879,
        0x306141,
        0x83376e,
        0xe59220,
        0x7377a0,
        0x30b7c0,
        0x86b4bb,
        0xffa9a9,
        0xf7e2c5
    ];

    bytes3[] private _mushroomColors2 = [
        bytes3(0x495900),
        0x395844,
        0xd47642,
        0x719767,
        0x8a8a00,
        0x806a9c,
        0xa2a2a2,
        0x86d48e,
        0xc3e88d,
        0xc3b2ff
    ];

    bytes3[] private _mushroomColors3 = [
        bytes3(0x253d2d),
        0x515130,
        0x384f7a,
        0x49a269,
        0xb18b57,
        0xfff392,
        0xb4edcd,
        0xffffff
    ];

    bytes3[] private _mushroomColors4 = [
        bytes3(0x663a13),
        0x137d5a,
        0x974700,
        0x49aa10,
        0x99ba5a,
        0xade151
    ];

    constructor() {
        _grounds[0].push(Rect(0, 17, 24, 7));
        _grounds[1].push(Rect(0, 17, 24, 8));
        _grounds[1].push(Rect(0, 17, 24, 1));
        _grounds[1].push(Rect(0, 18, 24, 1));
    }

    function setSpores(FileData[] calldata data) external {
        _onlyOwner();

        uint256 dataLength = data.length;
        for (uint256 i; i < dataLength; ++i) {
            FileData memory file = data[i];
            Rect[] storage storageFile = _spores[file.file];
            uint256 fileLength = file.rects.length;

            for (uint256 j; j < fileLength; ++j) {
                storageFile.push(file.rects[j]);
            }
        }
    }

    function setStems(FileData[] calldata data) external {
        _onlyOwner();

        _stems.setLayers(data);
    }

    function setCaps(FileData[] calldata data) external {
        _onlyOwner();

        _caps.setLayers(data);
    }

    function setDots(FileData[] calldata data) external {
        _onlyOwner();

        _dots.setLayers(data);
    }

    function getMushroom(
        SeedData calldata seedData
    ) public view returns (MushroomData memory) {
        Rand memory rnd = Rand(seedData.seed, 0, seedData.extra);
        MushroomData memory data;
        uint256 rdm = rnd.rdm();
        uint8 level = rnd.lvl().toLvl1();

        data.lvl = level;

        // we will unpack the rdm number in order to to avoid regen while large enough
        // bit structure:
        // 0x00...0x07 -> background -> 1 byte
        // 0x08...0x0f -> ground -> 1 byte
        // 0x10...0x17 -> groundColor -> 1 byte
        // 0x18...0x1f -> stem -> 1 byte
        // 0x20...0x27 -> stemColor -> 1 byte
        // 0x28...0x2f -> cap -> 1 byte
        // 0x30...0x37 -> capColor -> 1 byte
        // 0x38...0x39 -> hasDots -> 2 bits
        // 0x40...0x48 -> dotsColor -> 1 byte

        // sets background
        data.background = _backgroundColors(level).safeRdmItemAtIndex(rdm & 0xff);

        // sets ground
        data.ground = uint8(((rdm >> 0x8) & 0xff) % _GROUNDS_COUNT);
        data.groundColor = _groundColors(level).safeRdmItemAtIndex((rdm >> 0x10) & 0xff);

        if (data.lvl == 0) {
            // sets spores
            data.stem = uint8(((rdm >> 0x18) & 0xff) % _SPORES_COUNT);
            data.stemColor = _mushroomColors(level).safeRdmItemAtIndex((rdm >> 0x20) & 0xff);
        } else {
            // sets stems (same as spores, same packing too)
            data.stem = uint8(((rdm >> 0x18) & 0xff) % _stemLevelCounts[level]);
            data.stemColor = _mushroomColors(level).safeRdmItemAtIndex((rdm >> 0x20) & 0xff);

            // sets cap
            data.cap = uint8(((rdm >> 0x28) & 0xff) % _capLevelCounts[level]);
            data.capColor = _mushroomColors(level.toLvl1()).safeRdmItemAtIndex((rdm >> 0x30) & 0xff);
            data.hasDots = ((rdm >> 0x38) & 0x3) == 0;

            if (data.hasDots) {
                data.dotsColor = _mushroomColors(rnd.lvl().toLvl1()).safeRdmItemAtIndex((rdm >> 0x40) & 0xff);
            }
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
        MushroomData memory data = getMushroom(seedData);
        bytes memory lvl = abi.encodePacked('"level":', data.lvl._toString());
        bytes memory background = abi.encodePacked(
            ',"background":"#',
            data.background.bytes3ToHexString(),
            '"'
        );
        bytes memory ground = abi.encodePacked(
            ',"groundColor":"#',
            data.groundColor.bytes3ToHexString(),
            '"'
        );
        bytes memory stem = abi.encodePacked(
            ',"stem":',
            data.stem._toString(),
            ',"stemColor":"#',
            data.stemColor.bytes3ToHexString(),
            '"'
        );
        bytes memory cap = abi.encodePacked(
            ',"cap":',
            data.cap._toString(),
            ',"capColor":"#',
            data.capColor.bytes3ToHexString(),
            '"'
        );
        bytes memory capDots = abi.encodePacked(
            ',"hasDots":',
            data.hasDots ? "true" : "false",
            ',"dotsColor":"#',
            data.dotsColor.bytes3ToHexString(),
            '",'
        );
        bytes memory webText = abi.encodePacked('"web":"', _WEB, '",');
        bytes memory descriptionText = abi.encodePacked(
            '"description":"',
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
                webText,
                descriptionText,
                "}"
            )
        );
    }

    function _backgroundColors(
        uint256 index
    ) private view returns (bytes3[] storage) {
        if (index == 0) return _backgroundColors0;
        if (index == 1) return _backgroundColors1;
        if (index == 2) return _backgroundColors2;
        if (index == 3) return _backgroundColors3;
        if (index == 4) return _backgroundColors4;

        return _backgroundColors0;
    }

    function _groundColors(
        uint256 index
    ) private view returns (bytes3[] storage) {
        if (index == 0) return _groundColors0;
        if (index == 1) return _groundColors1;
        if (index == 2) return _groundColors2;
        if (index == 3) return _groundColors3;
        if (index == 4) return _groundColors4;

        return _groundColors0;
    }

    function _mushroomColors(
        uint8 index
    ) private view returns (bytes3[] storage) {
        if (index == 0) return _mushroomColors0;
        if (index == 1) return _mushroomColors1;
        if (index == 2) return _mushroomColors2;
        if (index == 3) return _mushroomColors3;
        if (index == 4) return _mushroomColors4;

        return _mushroomColors0;
    }

    function _toSvg(
        MushroomData memory data
    ) private view returns (string memory) {
        string memory pixelsCount = _PIXELS_COUNT._toString();
        bytes memory svgStart = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0",
            " ",
            pixelsCount,
            " ",
            pixelsCount,
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
                data.dotsColor
            );

            return string(abi.encodePacked(cap, _dotsSvg));
        } else {
            return string(cap);
        }
    }
}
