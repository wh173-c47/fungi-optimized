// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/Ownable.sol";

uint256 constant levelsCount = 5;
uint256 constant bcgroundsCount = 6;
uint256 constant groundsCount = 2;
uint8 constant pixelsCount = 24;
uint256 constant seedLevel1 = 21000;
uint256 constant seedLevel2 = 525000;
uint256 constant seedLevel3 = 1050000;
uint256 constant seedLevel4 = 1575000;
uint256 constant seedLevel5 = 2100000;

struct MushroomData {
    uint256 lvl;
    string background;
    uint256 ground;
    string groundColor;
    uint256 stem;
    string stemColor;
    uint256 cap;
    string capColor;
    bool hasDots;
    string dotsColor;
}

struct Rect {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct FileData {
    uint256 lvl;
    uint256 file;
    Rect[] rects;
}

struct ColorsData {
    string[] lvl0;
    string[] lvl1;
    string[] lvl2;
    string[] lvl3;
    string[] lvl4;
}

struct SeedData {
    uint256 seed;
    uint256 extra;
}

struct Rand {
    uint256 seed;
    uint256 nonce;
    uint256 extra;
}

library RandLib {
    function next(Rand memory rnd) internal pure returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(rnd.seed + rnd.nonce++ - 1, rnd.extra))
        );
    }

    function lvl(Rand memory rnd) internal pure returns (uint256) {
        if (rnd.seed < seedLevel1) return 0;
        if (rnd.seed < seedLevel2) return 1;
        if (rnd.seed < seedLevel3) return 2;
        if (rnd.seed < seedLevel4) return 3;
        if (rnd.seed < seedLevel5) return 4;
        return 5;
    }

    function random(string[] memory data, Rand memory rnd)
        internal
        pure
        returns (string memory)
    {
        return data[randomIndex(data, rnd)];
    }

    function randomIndex(string[] memory data, Rand memory rnd)
        internal
        pure
        returns (uint256)
    {
        return next(rnd) % data.length;
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

    function to_lvl_1(uint256 l) internal pure returns (uint256) {
        if (l > 0) --l;
        return l;
    }
}

library Converter {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library RectLib {
    using RectLib for Rect;
    using RandLib for Rand;
    using RandLib for string[];
    using Converter for uint8;

    function toSvg(Rect memory r, string memory color)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<rect x='",
                r.x.toString(),
                "' y='",
                r.y.toString(),
                "' width='",
                r.width.toString(),
                "' height='",
                r.height.toString(),
                "' fill='",
                color,
                "'/>"
            )
        );
    }

    function toSvg(
        Rect[] storage rects,
        string[] storage colors,
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

    function toSvg(Rect[] storage rects, string memory color)
        internal
        view
        returns (string memory)
    {
        string memory res;
        for (uint256 i = 0; i < rects.length; ++i) {
            res = string(abi.encodePacked(res, rects[i].toSvg(color)));
        }
        return res;
    }
}

contract Generator is Ownable {
    using LayersLib for mapping(uint256 => mapping(uint256 => Rect[]));
    using LayersLib for mapping(uint256 => string[]);
    using LayersLib for uint256;
    using RectLib for Rect;
    using RectLib for Rect[];
    using RandLib for Rand;
    using RandLib for string[];
    using Converter for uint256;

    uint8 spores_count = 7;
    uint8[levelsCount] stemLevelCounts = [5, 5, 5, 6, 10];
    uint8[levelsCount] capLevelCounts = [5, 7, 10, 10, 10];
    uint8[levelsCount] dotLevelCounts = [5, 7, 10, 10, 10];

    mapping(uint256 => Rect[]) spores;
    mapping(uint256 => mapping(uint256 => Rect[])) stems;
    mapping(uint256 => mapping(uint256 => Rect[])) caps;
    mapping(uint256 => mapping(uint256 => Rect[])) dots;
    mapping(uint256 => Rect[]) grounds;

    string[] private backgroundColors0 = [
        "#000000",
        "#493114",
        "#1d772f",
        "#38166a",
        "#db4161",
        "#7c288a",
        "#4141ff",
        "#ff61b2",
        "#8f3bc2",
        "#a2a2a2",
        "#bfca87",
        "#92dcba",
        "#a2fff3",
        "#fddad5"
    ];

    string[] private backgroundColors1 = [
        "#453879",
        "#184b5b",
        "#447f60",
        "#e35100",
        "#ff7930",
        "#e43b44",
        "#eedc59",
        "#f279ca",
        "#4deae9",
        "#ffdba2",
        "#a2baff",
        "#ca90ff"
    ];

    string[] private backgroundColors2 = [
        "#231b32",
        "#3f1164",
        "#28426a",
        "#9a2079",
        "#d45e4e",
        "#79dfac",
        "#1fabe0",
        "#e8a2bf",
        "#849be4",
        "#e3b2ff"
    ];

    string[] private backgroundColors3 = [
        "#291970",
        "#413c5d",
        "#a44c4c",
        "#f8972a",
        "#a271ff",
        "#4192c3",
        "#5182ff",
        "#ffb2a7"
    ];

    string[] private backgroundColors4 =
        ["#0f0c45", "#560e43", "#b21030", "#ff6e69", "#534fed", "#7cb8ff"];

    string[] private groundColors0 = [
        "#000000",
        "#1d730e",
        "#525050",
        "#b21030",
        "#ff7930",
        "#925f4f",
        "#db4161",
        "#9aeb00",
        "#d8cc33",
        "#2800ba",
        "#f361ff",
        "#4192c3",
        "#d0c598",
        "#f4c09a",
        "#e3b2ff"
    ];

    string[] private groundColors1 = [
        "#020104",
        "#493114",
        "#74254d",
        "#453879",
        "#306141",
        "#83376e",
        "#e59220",
        "#7377a0",
        "#30b7c0",
        "#86b4bb",
        "#ffa9a9",
        "#f7e2c5"
    ];

    string[] private groundColors2 = [
        "#495900",
        "#395844",
        "#d47642",
        "#719767",
        "#8a8a00",
        "#806a9c",
        "#a2a2a2",
        "#86d48e",
        "#c3e88d",
        "#c3b2ff"
    ];

    string[] private groundColors3 = [
        "#253d2d",
        "#515130",
        "#384f7a",
        "#49a269",
        "#b18b57",
        "#fff392",
        "#b4edcd",
        "#ffffff"
    ];

    string[] private groundColors4 =
        ["#663a13", "#137d5a", "#974700", "#49aa10", "#99ba5a", "#ade151"];

    string[] private mushroomColors0 = [
        "#000000",
        "#1d730e",
        "#525050",
        "#b21030",
        "#ff7930",
        "#925f4f",
        "#db4161",
        "#9aeb00",
        "#d8cc33",
        "#2800ba",
        "#f361ff",
        "#4192c3",
        "#d0c598",
        "#f4c09a",
        "#e3b2ff"
    ];

    string[] private mushroomColors1 = [
        "#020104",
        "#493114",
        "#74254d",
        "#453879",
        "#306141",
        "#83376e",
        "#e59220",
        "#7377a0",
        "#30b7c0",
        "#86b4bb",
        "#ffa9a9",
        "#f7e2c5"
    ];

    string[] private mushroomColors2 = [
        "#495900",
        "#395844",
        "#d47642",
        "#719767",
        "#8a8a00",
        "#806a9c",
        "#a2a2a2",
        "#86d48e",
        "#c3e88d",
        "#c3b2ff"
    ];

    string[] private mushroomColors3 = [
        "#253d2d",
        "#515130",
        "#384f7a",
        "#49a269",
        "#b18b57",
        "#fff392",
        "#b4edcd",
        "#ffffff"
    ];

    string[] private mushroomColors4 =
        ["#663a13", "#137d5a", "#974700", "#49aa10", "#99ba5a", "#ade151"];

    constructor() {
        grounds[0].push(Rect(0, 17, 24, 7));
        grounds[1].push(Rect(0, 17, 24, 8));
        grounds[1].push(Rect(0, 17, 24, 1));
        grounds[1].push(Rect(0, 18, 24, 1));
    }

    function backgroundColors(uint256 index)
        private
        view
        returns (string[] storage)
    {
        if (index == 0) return backgroundColors0;
        if (index == 1) return backgroundColors1;
        if (index == 2) return backgroundColors2;
        if (index == 3) return backgroundColors3;
        if (index == 4) return backgroundColors4;
        return backgroundColors0;
    }

    function groundColors(uint256 index)
        private
        view
        returns (string[] storage)
    {
        if (index == 0) return groundColors0;
        if (index == 1) return groundColors1;
        if (index == 2) return groundColors2;
        if (index == 3) return groundColors3;
        if (index == 4) return groundColors4;
        return groundColors0;
    }

    function mushroomColors(uint256 index)
        private
        view
        returns (string[] storage)
    {
        if (index == 0) return mushroomColors0;
        if (index == 1) return mushroomColors1;
        if (index == 2) return mushroomColors2;
        if (index == 3) return mushroomColors3;
        if (index == 4) return mushroomColors4;
        return mushroomColors0;
    }

    function setSpores(FileData[] calldata data) external onlyOwner {
        for (uint256 i = 0; i < data.length; ++i) {
            FileData memory file = data[i];
            Rect[] storage storageFile = spores[file.file];
            for (uint256 j = 0; j < file.rects.length; ++j) {
                storageFile.push(file.rects[j]);
            }
        }
    }

    function setStems(FileData[] calldata data) external onlyOwner {
        stems.setLayers(data);
    }

    function setCaps(FileData[] calldata data) external onlyOwner {
        caps.setLayers(data);
    }

    function setDots(FileData[] calldata data) external onlyOwner {
        dots.setLayers(data);
    }

    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setBcGround(MushroomData memory data, Rand memory rnd)
        private
        view
    {
        data.background = backgroundColors(rnd.lvl().to_lvl_1()).random(rnd);
    }

    function setGround(MushroomData memory data, Rand memory rnd)
        private
        view
    {
        data.ground = rnd.next() % groundsCount;
        data.groundColor = groundColors(rnd.lvl().to_lvl_1()).random(rnd);
    }

    function setSpores(MushroomData memory data, Rand memory rnd)
        private
        view
    {
        data.stem = rnd.next() % spores_count;
        data.stemColor = mushroomColors(rnd.lvl().to_lvl_1()).random(rnd);
    }

    function setStem(MushroomData memory data, Rand memory rnd) private view {
        data.stem = rnd.next() % stemLevelCounts[rnd.lvl().to_lvl_1()];
        data.stemColor = mushroomColors(rnd.lvl().to_lvl_1()).random(rnd);
    }

    function setCap(MushroomData memory data, Rand memory rnd) private view {
        data.cap = rnd.next() % capLevelCounts[rnd.lvl().to_lvl_1()];
        data.capColor = mushroomColors(rnd.lvl().to_lvl_1()).random(rnd);
        data.hasDots = rnd.next() % 4 == 0;
        if (data.hasDots) {
            data.dotsColor = mushroomColors(rnd.lvl().to_lvl_1()).random(rnd);
        }
    }

    function getMushroom(SeedData calldata seed_data)
        external
        view
        returns (MushroomData memory)
    {
        Rand memory rnd = Rand(seed_data.seed, 0, seed_data.extra);
        MushroomData memory data;
        data.lvl = rnd.lvl();
        setBcGround(data, rnd);
        setGround(data, rnd);
        if (data.lvl == 0) {
            setSpores(data, rnd);
        } else {
            setStem(data, rnd);
            setCap(data, rnd);
        }
        return data;
    }

    function getSvg(SeedData calldata seed_data)
        external
        view
        returns (string memory)
    {
        return toSvg(this.getMushroom(seed_data));
    }

    function getMeta(SeedData calldata seed_data)
        external
        view
        returns (string memory)
    {
        MushroomData memory data = this.getMushroom(seed_data);
        bytes memory lvl = abi.encodePacked('"level":', data.lvl.toString());
        bytes memory background =
            abi.encodePacked(',"background":"', data.background, '"');
        bytes memory ground =
            abi.encodePacked(',"groundColor":"', data.groundColor, '"');
        bytes memory stem = abi.encodePacked(
            ',"stem":',
            data.stem.toString(),
            ',"stemColor":"',
            data.stemColor,
            '"'
        );
        bytes memory cap = abi.encodePacked(
            ',"cap":', data.cap.toString(), ',"capColor":"', data.capColor, '"'
        );
        bytes memory capDots = abi.encodePacked(
            ',"hasDots":',
            data.hasDots ? "true" : "false",
            ',"dotsColor":"',
            data.dotsColor,
            '"'
        );

        return string(
            abi.encodePacked(
                "{", lvl, background, ground, stem, cap, capDots, "}"
            )
        );
    }

    function toSvg(MushroomData memory data)
        private
        view
        returns (string memory)
    {
        bytes memory svgStart = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0",
            " ",
            toString(pixelsCount),
            " ",
            toString(pixelsCount),
            "'>"
        );

        if (data.lvl == 0) {
            return string(
                abi.encodePacked(
                    svgStart,
                    backgroundSvg(data),
                    groundSvg(data),
                    stemSvg(data),
                    "</svg>"
                )
            );
        } else {
            return string(
                abi.encodePacked(
                    svgStart,
                    backgroundSvg(data),
                    groundSvg(data),
                    stemSvg(data),
                    capSvg(data),
                    "</svg>"
                )
            );
        }
    }

    function backgroundSvg(MushroomData memory data)
        private
        pure
        returns (string memory)
    {
        Rect memory r = Rect(0, 0, pixelsCount, pixelsCount);
        return r.toSvg(data.background);
    }

    function groundSvg(MushroomData memory data)
        private
        view
        returns (string memory)
    {
        return grounds[data.ground].toSvg(data.groundColor);
    }

    function stemSvg(MushroomData memory data)
        private
        view
        returns (string memory)
    {
        if (data.lvl == 0) return spores[data.stem].toSvg(data.stemColor);
        return stems[data.lvl.to_lvl_1()][data.stem].toSvg(data.stemColor);
    }

    function capSvg(MushroomData memory data)
        private
        view
        returns (string memory)
    {
        string memory cap =
            caps[data.lvl.to_lvl_1()][data.cap].toSvg(data.capColor);
        if (data.hasDots) {
            string memory dotsSvg =
                dots[data.lvl.to_lvl_1()][data.cap].toSvg(data.dotsColor);
            return string(abi.encodePacked(cap, dotsSvg));
        } else {
            return string(cap);
        }
    }
}
