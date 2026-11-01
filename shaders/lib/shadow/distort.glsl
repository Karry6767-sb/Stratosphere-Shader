#ifndef LIB_SHADOW_DISTORT_GLSL
#define LIB_SHADOW_DISTORT_GLSL
#include "/lib/distort.glsl"

vec2 shadowDistortTexelScale(vec2 clipPos) {
    vec2 factor = ShadowDistortFactor(clipPos);
    float oneMinusD = max(1.0 - SHADOW_DISTORT_FACTOR, 1e-4);
    return 2.0 * factor * factor / (oneMinusD * float(shadowMapResolution));
}

float shadowTexelWorldSize(vec2 clipPos) {
    vec2 factor = ShadowDistortFactor(clipPos);
    float ax = max(abs(shadowProjection[0].x), 1e-6);
    float ay = max(abs(shadowProjection[1].y), 1e-6);
    float oneMinusD = max(1.0 - SHADOW_DISTORT_FACTOR, 1e-4);
    float dx = (2.0 * factor.x * factor.x) / (ax * oneMinusD * float(shadowMapResolution) + 1e-5);
    float dy = (2.0 * factor.y * factor.y) / (ay * oneMinusD * float(shadowMapResolution) + 1e-5);
    return max(dx, dy);
}

const float SHADOW_DEPTH_NDC_SCALE = 0.5;

float shadowDepthGapToWorld(float depthGap) {
    float slope = SHADOW_DEPTH_NDC_SCALE * SHADOW_Z_COMPRESS
                * max(abs(shadowProjection[2].z), 1e-6);
    return depthGap / max(slope, 1e-6);
}

float shadowDepthGapFromWorld(float worldGap) {
    float slope = SHADOW_DEPTH_NDC_SCALE * SHADOW_Z_COMPRESS
                * max(abs(shadowProjection[2].z), 1e-6);
    return slope * worldGap;
}

#endif
