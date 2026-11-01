// Standard GGX/Smith/Schlick microfacet BRDF and Beer-Lambert absorption.

#ifndef LIB_WTR_OPTICS_GLSL
#define LIB_WTR_OPTICS_GLSL

#include "/lib/water/settings.glsl"
#include "/lib/water/waves.glsl"

vec3 WtrSigmaA() {
    return max(WTR_SIGMA_A * WTR_ABSORB_SCALE, vec3(WTR_MIN_ABSORB));
}

vec3 WtrBodyTransmittance(float dist) {
    return exp(-WtrSigmaA() * max(dist, 0.0));
}

vec3 WtrDirtScatter() {
    return WTR_DIRT * exp(-WtrSigmaA() * WTR_SCATTER_DIST);
}

vec3 WtrCausticFactor(vec3 pWorld, vec3 sunDirWorld, float depthBelowSurface,
                      float t, float viewDist) {
    if (WTR_CAUSTICS == 0) return vec3(1.0);

    vec3 sunDir = normalize(sunDirWorld);
    float sunY = max(abs(sunDir.y), 0.08);
    float depth = max(depthBelowSurface, 0.0);

    vec2 pos = (pWorld.xz + (sunDir.xz / sunY) * depth) * WTR_CAUSTIC_SCALE;

    vec2 q = pos + 0.35 * vec2(sin(pos.y * 0.21 + t * 0.07),
                               cos(pos.x * 0.19 - t * 0.06));
    float ridgeSharp = 3.0 + 2.0 * WtrPatchField(pos * 0.5);
    float sum = 0.0;
    sum += exp(-abs(sin(dot(q, vec2( 0.719,  0.695)) * 2.10 + t * 0.90)) * ridgeSharp);
    sum += exp(-abs(sin(dot(q, vec2(-0.600,  0.800)) * 2.70 - t * 1.15)) * ridgeSharp);
    sum += exp(-abs(sin(dot(q, vec2( 0.930, -0.365)) * 3.30 + t * 0.70)) * ridgeSharp);
    sum += exp(-abs(sin(dot(q, vec2( 0.220,  0.975)) * 4.10 - t * 1.40)) * ridgeSharp);
    sum += exp(-abs(sin(dot(q, vec2(-0.860, -0.510)) * 5.00 + t * 0.55)) * ridgeSharp);
    sum += exp(-abs(sin(dot(q, vec2( 0.480, -0.877)) * 6.20 - t * 1.70)) * ridgeSharp);
    float pattern = 0.18 + 1.55 * (sum / 6.0);
    float caustic = pow(max(pattern * WTR_CAUSTIC_BRIGHT, 0.0), WTR_CAUSTIC_POWER);
    caustic = min(caustic, 3.0);

    float depthFade = exp(-depth * 0.03 * WTR_CAUSTIC_DEPTH_FADE);
    vec3 sunPathT = exp(-WtrSigmaA() * (depth / sunY));
    return sunPathT * mix(vec3(1.0), vec3(caustic), clamp(depthFade, 0.0, 1.0));
}

float WtrFresnel(vec3 VtoCamera, vec3 NtowardViewer, bool underwater) {
    float NoV = clamp(dot(NtowardViewer, VtoCamera), 0.0, 1.0);
    const float F0 = 0.02;
    if (!underwater) {
        return F0 + (1.0 - F0) * pow(max(1.0 - NoV, 0.0), 5.0);
    }

    float edge = clamp(1.0 - NoV, 0.0, 1.0);
    float s = min(max(0.54 - edge, 0.0) / 0.1, 1.0);
    s = 1.0 - s * s;
    s *= s * s;
    return clamp(F0 + (1.0 - F0) * s, 0.0, 1.0);
}

float WtrSunGlint(vec3 N, vec3 VtoCamera, vec3 L, float roughness) {
    vec3 V = normalize(VtoCamera);
    vec3 Ln = normalize(L);
    float NoV = max(dot(N, V), 1.0e-4);
    float NoL = max(dot(N, Ln), 0.0);
    if (NoL <= 0.0) return 0.0;

    vec3 H = normalize(V + Ln);
    float NoH = max(dot(N, H), 0.0);
    float VoH = max(dot(V, H), 0.0);

#if WTR_GLINT_MODEL == 1
    return (pow(NoH, 400.0) + 0.12 * pow(NoH, 48.0)) * NoL;
#else
    float a = max(roughness, 0.02);
    float a2 = a * a;
    float d = NoH * NoH * (a2 - 1.0) + 1.0;
    float D = a2 / (3.14159265 * d * d + 1.0e-6);

    float k = a2 * 0.5;
    float G = (NoV / (NoV * (1.0 - k) + k))
            * (NoL / (NoL * (1.0 - k) + k));
    float F = 0.02 + 0.98 * pow(max(1.0 - VoH, 0.0), 5.0);
    return (D * G * F / (4.0 * NoV + 1.0e-5)) * NoL;
#endif
}

#endif
