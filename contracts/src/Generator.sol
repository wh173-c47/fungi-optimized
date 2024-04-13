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
    using LayersLib for mapping(uint256 => bytes6[]);
    using LayersLib for uint256;
    using LayersLib for uint8;
    using StringLib for uint8;
    using RectLib for Rect;
    using RectLib for Rect[];
    using RandLib for Rand;
    using RandLib for bytes6[];

    uint8 private _sporesCount = 7;
    uint8[_LEVELS_COUNT] private _stemLevelCounts = [5, 5, 5, 6, 10];
    uint8[_LEVELS_COUNT] private _capLevelCounts = [5, 7, 10, 10, 10];
    uint8[_LEVELS_COUNT] private _dotLevelCounts = [5, 7, 10, 10, 10];

    mapping(uint256 => Rect[]) private _spores;
    mapping(uint256 => mapping(uint256 => Rect[])) private _stems;
    mapping(uint256 => mapping(uint256 => Rect[])) private _caps;
    mapping(uint256 => mapping(uint256 => Rect[])) private _dots;
    mapping(uint256 => Rect[]) private _grounds;

    bytes6[] private _backgroundColors0 = [
        bytes6("000000"),
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

    bytes6[] private _backgroundColors1 = [
        bytes6("453879"),
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

    bytes6[] private _backgroundColors2 = [
        bytes6("231b32"),
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

    bytes6[] private _backgroundColors3 = [
        bytes6("291970"),
        "413c5d",
        "a44c4c",
        "f8972a",
        "a271ff",
        "4192c3",
        "5182ff",
        "ffb2a7"
    ];

    bytes6[] private _backgroundColors4 = [
        bytes6("0f0c45"),
        "560e43",
        "b21030",
        "ff6e69",
        "534fed",
        "7cb8ff"
    ];

    bytes6[] private _groundColors0 = [
        bytes6("000000"),
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

    bytes6[] private _groundColors1 = [
        bytes6("020104"),
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

    bytes6[] private _groundColors2 = [
        bytes6("495900"),
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

    bytes6[] private _groundColors3 = [
        bytes6("253d2d"),
        "515130",
        "384f7a",
        "49a269",
        "b18b57",
        "fff392",
        "b4edcd",
        "ffffff"
    ];

    bytes6[] private _groundColors4 = [
        bytes6("663a13"),
        "137d5a",
        "974700",
        "49aa10",
        "99ba5a",
        "ade151"
    ];

    bytes6[] private _mushroomColors0 = [
        bytes6("000000"),
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

    bytes6[] private _mushroomColors1 = [
        bytes6("020104"),
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

    bytes6[] private _mushroomColors2 = [
        bytes6("495900"),
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

    bytes6[] private _mushroomColors3 = [
        bytes6("253d2d"),
        "515130",
        "384f7a",
        "49a269",
        "b18b57",
        "fff392",
        "b4edcd",
        "ffffff"
    ];

    bytes6[] private _mushroomColors4 = [
        bytes6("663a13"),
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
        bytes memory lvl = abi.encodePacked('"level":', data.lvl._toString());
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
            data.stem._toString(),
            ',"stemColor":"#',
            data.stemColor,
            '"'
        );
        bytes memory cap = abi.encodePacked(
            ',"cap":',
            data.cap._toString(),
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
    ) private view returns (bytes6[] storage) {
        if (index == 0) return _backgroundColors0;
        if (index == 1) return _backgroundColors1;
        if (index == 2) return _backgroundColors2;
        if (index == 3) return _backgroundColors3;
        if (index == 4) return _backgroundColors4;
        return _backgroundColors0;
    }

    function _groundColors(
        uint256 index
    ) private view returns (bytes6[] storage) {
        if (index == 0) return _groundColors0;
        if (index == 1) return _groundColors1;
        if (index == 2) return _groundColors2;
        if (index == 3) return _groundColors3;
        if (index == 4) return _groundColors4;
        return _groundColors0;
    }

    function _mushroomColors(
        uint256 index
    ) private view returns (bytes6[] storage) {
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
        data.ground = uint8(rnd.next() % _GROUNDS_COUNT);
        data.groundColor = _groundColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setSpores(MushroomData memory data, Rand memory rnd) private view {
        data.stem = uint8(rnd.next() % _sporesCount);
        data.stemColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setStem(MushroomData memory data, Rand memory rnd) private view {
        data.stem = uint8(rnd.next() % _stemLevelCounts[rnd.lvl().toLvl1()]);
        data.stemColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
    }

    function _setCap(MushroomData memory data, Rand memory rnd) private view {
        data.cap = uint8(rnd.next() % _capLevelCounts[rnd.lvl().toLvl1()]);
        data.capColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
        data.hasDots = rnd.next() % 4 == 0;
        if (data.hasDots) {
            data.dotsColor = _mushroomColors(rnd.lvl().toLvl1()).random(rnd);
        }
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
