#version 430 compatibility

#include "/lib/options_defaults.glsl"
#include "/lib/fog/heightmap.glsl"

uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

layout(r32ui) uniform uimage2D uimg_fogHeight;

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(16, 16, 1);

void FogHeightmapObserve(ivec2 cell, uint observedHeightCm,
                         uint originHash, uint frameTag) {
    uint oldPacked = imageLoad(uimg_fogHeight, cell).r;

    for (int attempt = 0; attempt < 16; ++attempt) {
        uint oldOrigin = (oldPacked >> 8u) & 0xFFu;
        uint oldHeightCm = oldPacked >> 16u;

        uint baseHeightCm = 0u;
        if (oldPacked != 0u && oldOrigin == originHash) {
            uint oldFrame = oldPacked & 0xFFu;
            uint age = (frameTag - oldFrame) & 0xFFu;
            uint decayCm = uint(float(age) * FOG_HEIGHTMAP_FORGET_CM + 0.5);
            baseHeightCm = (oldHeightCm > decayCm) ? (oldHeightCm - decayCm) : 0u;
        }

        uint newHeightCm = max(baseHeightCm, observedHeightCm);
        uint newPacked = FogHeightmapPack(newHeightCm, originHash, frameTag);

        uint previous = imageAtomicCompSwap(uimg_fogHeight, cell, oldPacked, newPacked);
        if (previous == oldPacked) return;
        oldPacked = previous;
    }
}

void main() {
#if FOG_HEIGHTMAP == 0
    return;
#else
    ivec2 screenSize = ivec2(viewWidth, viewHeight);
    if (screenSize.x <= 0 || screenSize.y <= 0) return;

    int sampleW = (screenSize.x + 3) / 4;
    int sampleH = (screenSize.y + 3) / 4;
    uint totalSamples = uint(sampleW) * uint(sampleH);

    uint gid = gl_GlobalInvocationID.y * 256u + gl_GlobalInvocationID.x;
    uint originHash = FogHeightmapOriginHash(cameraPosition);
    uint frameTag = FogHeightmapFrameTag(frameCounter);

    for (uint i = gid; i < totalSamples; i += 65536u) {
        ivec2 pixel = ivec2(int(i % uint(sampleW)) * 4,
                            int(i / uint(sampleW)) * 4);
        if (pixel.x >= screenSize.x || pixel.y >= screenSize.y) continue;

        float depth = texelFetch(depthtex1, pixel, 0).r;
        if (depth >= 1.0) continue;

        vec2 ndc = (vec2(pixel) + 0.5) / vec2(screenSize) * 2.0 - 1.0;
        vec4 viewH = gbufferProjectionInverse * vec4(ndc, depth * 2.0 - 1.0, 1.0);
        vec3 viewPos = viewH.xyz / viewH.w;
        vec3 relWorld = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        vec3 worldPos = relWorld + cameraPosition;

        bool validCell;
        ivec2 cell = FogHeightmapCellFromWorld(worldPos, cameraPosition, validCell);
        if (!validCell) continue;

        float heightCm = worldPos.y * 100.0 + FOG_HEIGHTMAP_BIAS_CM;
        uint observedHeightCm = uint(clamp(floor(heightCm + 0.5), 0.0, 65535.0));
        FogHeightmapObserve(cell, observedHeightCm, originHash, frameTag);
    }
#endif
}
