#ifndef LIB_FOG_HEIGHTMAP_GLSL
#define LIB_FOG_HEIGHTMAP_GLSL

#include "/lib/options_defaults.glsl"

const int   FOG_HEIGHTMAP_SIZE = 128;
const float FOG_HEIGHTMAP_HALF_SIZE = 64.0;

vec2 FogHeightmapGridOrigin(vec3 cameraPos) {
    vec2 snappedCentre = floor(cameraPos.xz / FOG_HEIGHTMAP_CENTER_QUANTUM)
                       * FOG_HEIGHTMAP_CENTER_QUANTUM;
    return snappedCentre - FOG_HEIGHTMAP_HALF_SIZE * FOG_HEIGHTMAP_CELL_SIZE;
}
uint FogHeightmapOriginHash(vec3 cameraPos) {
    ivec2 c = ivec2(floor(cameraPos.xz / FOG_HEIGHTMAP_CENTER_QUANTUM));
    uint h = uint(c.x) * 0x9E3779B1u ^ uint(c.y) * 0x85EBCA77u;
    h ^= h >> 13u;
    h *= 0xC2B2AE3Du;
    h ^= h >> 16u;
    return h & 0xFFu;
}

ivec2 FogHeightmapCellFromWorld(vec3 worldPos, vec3 cameraPos, out bool valid) {
    vec2 rel = (worldPos.xz - FogHeightmapGridOrigin(cameraPos))
             / FOG_HEIGHTMAP_CELL_SIZE;
    ivec2 cell = ivec2(floor(rel));
    valid = cell.x >= 0 && cell.x < FOG_HEIGHTMAP_SIZE &&
            cell.y >= 0 && cell.y < FOG_HEIGHTMAP_SIZE;
    return clamp(cell, ivec2(0), ivec2(FOG_HEIGHTMAP_SIZE - 1));
}

uint FogHeightmapFrameTag(int frameIndex) {
    return uint(frameIndex) & 0xFFu;
}

uint FogHeightmapPack(uint heightCm, uint originHash, uint frameTag) {
    return (min(heightCm, 65535u) << 16u)
         | ((originHash & 0xFFu) << 8u)
         | (frameTag & 0xFFu);
}

bool FogHeightmapDecodeGroundY(uint packedCell, vec3 cameraPos, int frameIndex,
                               out float groundY) {
    groundY = 0.0;
    if (packedCell == 0u) return false;

    uint storedOrigin = (packedCell >> 8u) & 0xFFu;
    if (storedOrigin != FogHeightmapOriginHash(cameraPos)) return false;

    uint storedFrame = packedCell & 0xFFu;
    uint age = (FogHeightmapFrameTag(frameIndex) - storedFrame) & 0xFFu;
    if (age > uint(FOG_HEIGHTMAP_MAX_AGE)) return false;

    float heightCm = float(packedCell >> 16u) - FOG_HEIGHTMAP_BIAS_CM;
    heightCm -= float(age) * FOG_HEIGHTMAP_FORGET_CM;
    groundY = heightCm * 0.01;
    return true;
}

#endif
