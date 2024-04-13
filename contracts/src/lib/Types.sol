// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

struct MushroomData {
    uint8 lvl;
    uint8 ground;
    uint8 stem;
    uint8 cap;
    bool hasDots;
    bytes6 background;
    bytes6 groundColor;
    bytes6 stemColor;
    bytes6 capColor;
    bytes6 dotsColor;
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
    bytes6[] lvl0;
    bytes6[] lvl1;
    bytes6[] lvl2;
    bytes6[] lvl3;
    bytes6[] lvl4;
}

struct SeedData {
    uint32 seed; // enough for a supply of max 4,294,967,295
    uint128 extra;
}

struct Rand {
    uint32 seed;
    uint96 nonce;
    uint128 extra;
}
