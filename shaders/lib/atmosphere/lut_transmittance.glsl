// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_LUT_TRANSMITTANCE_GLSL
#define LIB_ATMOSPHERE_LUT_TRANSMITTANCE_GLSL

#include "/lib/atmosphere/geometry.glsl"
#include "/lib/atmosphere/medium.glsl"

#ifndef ATM_TLUT_SAMPLES
#define ATM_TLUT_SAMPLES 32
#endif

void atmUvToTransmittanceParams(out float r, out float mu, vec2 uv) {
    float H   = sqrt(max(ATM_ATMO_R2 - ATM_PLANET_R2, 0.0));
    float rho = H * clamp(uv.y, 0.0, 1.0);
    r = sqrt(rho * rho + ATM_PLANET_R2);

    float dMin = max(ATM_ATMO_R - r, 0.0);
    float dMax = rho + H;
    float d = dMin + clamp(uv.x, 0.0, 1.0) * max(dMax - dMin, 0.0);

    mu = (d <= 1.0e-6) ? 1.0 : (H * H - rho * rho - d * d) / (2.0 * r * d);
    mu = clamp(mu, -1.0, 1.0);
}

vec2 atmTransmittanceParamsToUv(float r, float mu) {
    float H   = sqrt(max(ATM_ATMO_R2 - ATM_PLANET_R2, 0.0));
    float rho = sqrt(max(r * r - ATM_PLANET_R2, 0.0));

    float disc = r * r * (mu * mu - 1.0) + ATM_ATMO_R2;
    float d = max(-r * mu + sqrt(max(disc, 0.0)), 0.0);
    float dMin = max(ATM_ATMO_R - r, 1.0e-6);
    float dMax = rho + H;
    float u = (d - dMin) / max(dMax - dMin, 1.0e-6);
    float v = rho / max(H, 1.0e-6);
    return vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0));
}

vec4 atmBakeTransmittance(float r, float mu) {
    vec3 rayPos = vec3(0.0, r, 0.0);
    vec3 rayDir = vec3(sqrt(max(1.0 - mu * mu, 0.0)), mu, 0.0);

    float tGround = atmRaySphereNearest(rayPos, rayDir, ATM_PLANET_R);
    if (tGround > 0.0) return vec4(0.0);

    float tMax = atmRaySphereNearest(rayPos, rayDir, ATM_ATMO_R);
    if (tMax <= 0.0) return vec4(1.0);

    float stepSize = tMax / float(ATM_TLUT_SAMPLES);
    vec3 rayStep = stepSize * rayDir;
    rayPos += 0.5 * rayStep;

    vec4 opticalDepth = vec4(0.0);
    for (int i = 0; i < ATM_TLUT_SAMPLES; ++i) {
        opticalDepth += atmExtinctionSpectrum(rayPos) * stepSize;
        rayPos += rayStep;
    }
    return exp(-opticalDepth);
}

#endif
