// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

struct MushroomData {
    uint8 lvl;
    uint8 ground;
    uint8 stem;
    uint8 cap;
    bool hasDots;
    bytes8 background;
    bytes8 groundColor;
    bytes8 stemColor;
    bytes8 capColor;
    bytes8 dotsColor;
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
