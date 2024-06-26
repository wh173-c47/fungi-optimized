// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Packing all data
struct MushroomData {
    uint8 lvl;
    uint8 ground;
    uint8 stem;
    uint8 cap;
    bool hasDots;
    bytes3 background;
    bytes3 groundColor;
    bytes3 stemColor;
    bytes3 capColor;
    bytes3 dotsColor;
}

struct Rect {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct FileData {
    uint8 lvl;
    // allows packing while not changing much
    uint248 file;
    Rect[] rects;
}

struct ColorsData {
    bytes3[] lvl0;
    bytes3[] lvl1;
    bytes3[] lvl2;
    bytes3[] lvl3;
    bytes3[] lvl4;
}

// packing below, seed enough for a balance of max 4294967296
struct SeedData {
    uint32 seed;
    uint128 extra;
}

struct Rand {
    // Enough till 4294967296 while seed level 5 is 2100000
    uint32 seed;
    // Others are packed to hold on 32bytes
    uint96 nonce;
    uint128 extra;
}
