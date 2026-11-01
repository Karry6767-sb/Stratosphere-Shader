// Algorithm structure after Eclipse-Shader-Unstable (Chocapic13, all rights reserved); reimplemented, no code copied.

#ifndef LIB_WTR_WAVES_GLSL
#define LIB_WTR_WAVES_GLSL

#include "/lib/water/settings.glsl"
#include "/lib/water/noise.glsl"

const float WTR_TWO_PI = 6.28318530718;

float WtrPatchField(vec2 pXZ) {
    float large = WtrValueNoise(pXZ / 600.0);
    float curved = pow(1.0 - pow(1.0 - large, 2.5), 4.5);
    return mix(1.0 - curved, curved, clamp(WTR_PATCHY, 0.0, 1.0));
}

vec2 WtrWavePlane(vec3 absWorldPos, vec3 geomNormal) {
    if (abs(geomNormal.y) > 0.9) return absWorldPos.xz;
    if (abs(geomNormal.x) > 0.5) return absWorldPos.zy;
    return absWorldPos.xy;
}

float WtrGeometryHeight(vec2 pXZ, float t) {
    float move = t * 0.16 * WTR_GEO_SPEED;
    vec2 p = WTR_ROT * pXZ;
    float a = WtrValueNoiseRaw(p / vec2(4.2, 2.6) + move);
    p = WTR_ROT * p;
    float b = WtrValueNoiseRaw(p / vec2(1.7, 1.15) + move * 1.6);
    return (a * 0.65 + b * 0.35 - 0.5) * 2.0;
}

void WtrAddRidgeWave(vec2 p, float t, float angle,
                     float wavelength, float slope, float phase0,
                     float viewLen, inout vec2 grad) {
    vec2 d = vec2(cos(angle), sin(angle));
    float k = WTR_TWO_PI / max(wavelength, 0.05);
    float omega = sqrt(9.81 * k);
    float phase = k * dot(d, p) - omega * t + phase0;

    float ridged = exp(sin(phase) - 1.0);
    float waveLod = 1.0 - smoothstep(wavelength * 16.0,
                                     wavelength * 64.0, viewLen);
    grad += d * (slope * ridged * cos(phase) * waveLod);
}

vec3 WtrWaveNormal(vec2 pXZ, float viewLen, float t) {
    float ts = t * WTR_SPEED * 0.65;

    vec2 pw = pXZ + 0.12 * vec2(sin(pXZ.y * 0.21 + ts * 0.06),
                                cos(pXZ.x * 0.19 - ts * 0.05));

    float pa = 0.5 + 0.5 * sin(dot(pXZ, vec2(0.031, 0.019)) + ts * 0.035);
    float pb = 0.5 + 0.5 * sin(dot(pXZ, vec2(-0.023, 0.041)) - ts * 0.027);
    float patchField = 0.72 + 0.28 * pa * pb;
    float energy = mix(1.0, patchField, clamp(WTR_PATCHY, 0.0, 1.0));

    float slopeScale = clamp(WTR_AMP, 0.0, 2.0) * energy * 3.5;
    vec2 grad = vec2(0.0);

    WtrAddRidgeWave(pw, ts, 0.20, 5.50, 0.020 * slopeScale, 0.4, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 1.10, 4.20, 0.023 * slopeScale, 2.1, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 2.25, 3.20, 0.026 * slopeScale, 4.4, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 3.55, 2.40, 0.029 * slopeScale, 1.2, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 4.35, 1.80, 0.032 * slopeScale, 5.1, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 5.25, 1.35, 0.034 * slopeScale, 0.9, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 0.75, 1.00, 0.034 * slopeScale, 3.3, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 1.85, 0.75, 0.032 * slopeScale, 6.0, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 2.95, 0.56, 0.030 * slopeScale, 2.8, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 4.05, 0.42, 0.028 * slopeScale, 4.9, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 5.15, 0.31, 0.025 * slopeScale, 1.7, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 0.45, 0.23, 0.022 * slopeScale, 5.6, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 1.45, 0.17, 0.014 * slopeScale, 2.4, viewLen, grad);
    WtrAddRidgeWave(pw, ts, 3.90, 0.13, 0.011 * slopeScale, 4.0, viewLen, grad);

    return normalize(vec3(-grad.x, 1.0, -grad.y));
}

#endif
