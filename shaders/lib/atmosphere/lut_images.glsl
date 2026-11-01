// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_LUT_IMAGES_GLSL
#define LIB_ATMOSPHERE_LUT_IMAGES_GLSL

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/lut_common.glsl"

#ifndef ATM_LUT_IMAGE_ATM_DECL
layout(rgba16f) uniform readonly image2D uimg_atm;
#define ATM_LUT_IMAGE_ATM_DECL
#endif
#ifndef ATM_LUT_IMAGE_MSLUT_DECL
layout(rgba16f) uniform readonly image2D uimg_mslut;
#define ATM_LUT_IMAGE_MSLUT_DECL
#endif

#ifndef ATM_TLUT_Y_OFFSET
#define ATM_TLUT_Y_OFFSET (256 - ATM_TLUT_H)
#endif

vec4 atmBilinearImageLoadAtlas(ivec2 size, vec2 uv, int yOffset) {
    vec2 pos = uv * vec2(size) - 0.5;
    ivec2 i0 = ivec2(floor(pos));
    vec2 f = fract(pos);
    ivec2 i1 = min(i0 + ivec2(1), size - ivec2(1));
    i0 = clamp(i0, ivec2(0), size - ivec2(1));

    vec4 c00 = imageLoad(uimg_atm, ivec2(i0.x, i0.y + yOffset));
    vec4 c10 = imageLoad(uimg_atm, ivec2(i1.x, i0.y + yOffset));
    vec4 c01 = imageLoad(uimg_atm, ivec2(i0.x, i1.y + yOffset));
    vec4 c11 = imageLoad(uimg_atm, ivec2(i1.x, i1.y + yOffset));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

vec4 atmReadTransmittanceLUTImage(float r, float mu) {
    vec2 uv = atmTransmittanceParamsToUv(r, mu);
    return atmBilinearImageLoadAtlas(ivec2(ATM_TLUT_W, ATM_TLUT_H), uv, ATM_TLUT_Y_OFFSET);
}

vec4 atmTransmittanceToSun(float r, float mu) {
    vec4 T = atmReadTransmittanceLUTImage(r, clamp(mu, -1.0, 1.0));
    if (T.a <= 0.0) T = atmBakeTransmittance(r, clamp(mu, -1.0, 1.0));
    return T;
}

vec4 atmTransmittanceToSun(vec3 p, vec3 dir) {
    vec3 d = normalize(dir);
    float r = max(length(p), ATM_PLANET_R);
    float mu = clamp(dot(p / r, d), -1.0, 1.0);
    return atmTransmittanceToSun(r, mu);
}

vec4 atmTransmittanceToSunShadowed(float r, float mu) {
    vec4 T = atmTransmittanceToSun(r, clamp(mu, -1.0, 1.0));
    float sinThetaH = clamp(ATM_PLANET_R / max(r, ATM_PLANET_R), 0.0, 1.0);
    float cosThetaH = sqrt(max(1.0 - sinThetaH * sinThetaH, 0.0));
    float halfWidth = max(sinThetaH * ATM_SUN_ANGULAR_RADIUS, 1.0e-6);
    float refractionLift = (ATM_REFRACTION == 1) ? ATM_REFRACTION_MAX : 0.0;
    float earthShadow = atmLinearstep(-halfWidth, halfWidth, mu + cosThetaH + refractionLift);
    return T * earthShadow;
}

vec4 atmTransmittanceToSunShadowed(vec3 p, vec3 dir) {
    vec3 d = normalize(dir);
    float r = max(length(p), ATM_PLANET_R);
    float mu = clamp(dot(p / r, d), -1.0, 1.0);
    return atmTransmittanceToSunShadowed(r, mu);
}

vec3 atmReadMultiScatteringImage(float r, float mu) {
    vec2 uv = vec2(clamp(0.5 + 0.5 * mu, 0.0, 1.0),
                   clamp((r - ATM_PLANET_R) / max(ATM_ATMO_R - ATM_PLANET_R, 1.0e-6), 0.0, 1.0));
    vec2 pos = uv * float(ATM_MSLUT_SIZE) - 0.5;
    ivec2 i0 = ivec2(floor(pos));
    vec2 f = fract(pos);
    ivec2 i1 = min(i0 + ivec2(1), ivec2(ATM_MSLUT_SIZE - 1));
    i0 = clamp(i0, ivec2(0), ivec2(ATM_MSLUT_SIZE - 1));

    vec3 c00 = imageLoad(uimg_mslut, ivec2(i0.x, i0.y)).rgb;
    vec3 c10 = imageLoad(uimg_mslut, ivec2(i1.x, i0.y)).rgb;
    vec3 c01 = imageLoad(uimg_mslut, ivec2(i0.x, i1.y)).rgb;
    vec3 c11 = imageLoad(uimg_mslut, ivec2(i1.x, i1.y)).rgb;
    return max(mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y), vec3(0.0));
}

#endif
