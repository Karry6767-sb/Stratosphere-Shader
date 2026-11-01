#version 430 compatibility

#include "/lib/options_defaults.glsl"

layout(rgba16f) uniform image2D uimg_bloom;

#include "/lib/bloom_image.glsl"

uniform float viewWidth;
uniform float viewHeight;

layout(local_size_x = 1024) in;
const ivec3 workGroups = ivec3(1, 1, 1);

void bloomUpsampleLevel(int level, vec2 fullSize, uint idx) {
    vec4 dstR = bloomMipRect(level - 1, fullSize);
    uint dstW = uint(max(dstR.z, 1.0));
    uint dstH = uint(max(dstR.w, 1.0));
    uint total = dstW * dstH;

    for (uint t = idx; t < total; t += 1024u) {
        ivec2 p = ivec2(int(t % dstW), int(t / dstW));
        ivec2 dst = ivec2(dstR.xy) + p;
        vec2 uv = (vec2(p) + 0.5) / max(dstR.zw, vec2(1.0));

        vec4 cur = imageLoad(uimg_bloom, dst);
        vec3 up = bloomUpsampleAtlasImage(level, uv, fullSize)
                * bloomMipWeight(level);
        imageStore(uimg_bloom, dst, vec4(cur.rgb + up, cur.a));
    }
}

void main() {
#if BLOOM_MIP_CHAIN == 0
    return;
#else
    vec2 fullSize = max(vec2(viewWidth, viewHeight), vec2(1.0));
    uint idx = gl_LocalInvocationIndex;

#if BLOOM_MIP_LEVELS >= 6
    bloomUpsampleLevel(5, fullSize, idx);
    memoryBarrier(); barrier();
#endif
#if BLOOM_MIP_LEVELS >= 5
    bloomUpsampleLevel(4, fullSize, idx);
    memoryBarrier(); barrier();
#endif
#if BLOOM_MIP_LEVELS >= 4
    bloomUpsampleLevel(3, fullSize, idx);
    memoryBarrier(); barrier();
#endif
#if BLOOM_MIP_LEVELS >= 3
    bloomUpsampleLevel(2, fullSize, idx);
    memoryBarrier(); barrier();
#endif
#if BLOOM_MIP_LEVELS >= 2
    bloomUpsampleLevel(1, fullSize, idx);
    memoryBarrier(); barrier();
#endif
#endif
}
