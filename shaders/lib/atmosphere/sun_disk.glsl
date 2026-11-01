// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef ATM_SUN_ACTIVE_SCALE
#define ATM_SUN_ACTIVE_SCALE 2.5
#endif
#ifndef ATM_SUN_SPOT_SCALE
#define ATM_SUN_SPOT_SCALE 16.0
#endif

#ifndef LIB_ATMOSPHERE_SUN_DISK_GLSL
#define LIB_ATMOSPHERE_SUN_DISK_GLSL

#include "/lib/atmosphere/geometry.glsl"

float sunHash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float sunValueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = sunHash21(i + vec2(0.0, 0.0));
    float b = sunHash21(i + vec2(1.0, 0.0));
    float c = sunHash21(i + vec2(0.0, 1.0));
    float d = sunHash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float sunGranulePattern(vec2 uv) {
    vec2 q = uv * ATM_SUN_GRANULE_SCALE;
    float n = sunValueNoise(q);
    n += 0.45 * sunValueNoise(q * 2.13 + vec2(17.3, 9.1));
    n /= 1.45;
    return n;
}

float sunActiveRegion(vec2 uv) {
    vec2 q = uv * ATM_SUN_ACTIVE_SCALE + 3.1;
    float n = sunValueNoise(q);
    float thr = 0.90 - 0.06 * ATM_SUN_SPOT_AMOUNT;
    return smoothstep(thr, thr + 0.10, n);
}

vec2 sunSpotStructure(vec2 uv, float region) {
    vec2 q = uv * ATM_SUN_SPOT_SCALE * 1.6 + 8.4;
    float n = sunValueNoise(q) * 0.65 + sunValueNoise(q * 2.1 + 5.0) * 0.35;

    float thr = 0.86 - 0.22 * region;

    float pen = smoothstep(thr - 0.22, thr + 0.08, n) * region;
    float umb = smoothstep(thr + 0.02, thr + 0.12, n) * region;
    return vec2(umb, pen);
}

vec3 sunDiskDetail(vec2 uv, float centerToEdge) {
    float factor = 1.0;

#if ATM_SUN_GRANULATION == 1
    float g = sunGranulePattern(uv);
    factor += (g - 0.5) * 2.0 * ATM_SUN_GRANULE_CONTRAST;
    factor = mix(1.0, factor, 1.0 - centerToEdge * centerToEdge);
#endif

#if ATM_SUN_SPOTS == 1
    float region = sunActiveRegion(uv);
    vec2 spot = sunSpotStructure(uv, region);
    float umbra = spot.x;
    float penumbra = spot.y;

    factor *= 1.0 - 0.35 * penumbra;
    factor *= 1.0 - 0.80 * umbra;
#endif

    return vec3(factor);
}

#endif
