// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_LUT_AERIAL_GLSL
#define LIB_ATMOSPHERE_LUT_AERIAL_GLSL

#include "/lib/atmosphere/lut_skyview.glsl"

vec3 atmRaymarchAerialPerspectiveRGB(vec3 rayPos, vec3 rayDir, vec3 sunDir,
                                     float maxDistKm, out float transmittanceOut) {
    transmittanceOut = 1.0;

    float tMax;
    bool groundHit;
    if (!atmSetupRay(rayPos, rayDir, tMax, groundHit)) return vec3(0.0);

    if (maxDistKm <= 1.0e-5) return vec3(0.0);
    if (maxDistKm < tMax) {
        tMax = maxDistKm;
        groundHit = false;
    }

    mat2x3 res = atmScatteringIntegralRGB(rayPos, rayDir, sunDir, tMax, groundHit);
    transmittanceOut = dot(res[1], vec3(0.2126, 0.7152, 0.0722));
    return res[0];
}

void atmDecodeAerialAtlas(ivec2 local, out int slice, out ivec2 bin) {
    slice = (local.y / ATM_AP_BINS) * 2 + (local.x / ATM_AP_BINS);
    bin = ivec2(local.x % ATM_AP_BINS, local.y % ATM_AP_BINS);
}

float atmAerialSliceDistance(float nearKm, float farKm, int slice) {
    float safeNear = max(nearKm, 1.0e-4);
    float safeFar  = max(farKm, safeNear * 1.001);
    float t = (float(slice) + 1.0) / float(ATM_AP_SLICES);
    return safeNear * pow(safeFar / safeNear, t);
}

#endif
