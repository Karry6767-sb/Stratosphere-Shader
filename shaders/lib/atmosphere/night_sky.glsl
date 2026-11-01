// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_NIGHT_SKY_GLSL
#define LIB_ATMOSPHERE_NIGHT_SKY_GLSL

#include "/lib/atmosphere/geometry.glsl"
#include "/lib/atmosphere/spectrum.glsl"

float atmHash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float atmLightPollutionAmount(vec3 worldDir) {
    if (ATM_LIGHT_POLLUTION == 0) return 0.0;

    vec2 cam = cameraPosition.xz;
    const float CELL = 4000.0;
    vec2 base = floor(cam / CELL);
    vec2 viewXZ = vec2(worldDir.x, worldDir.z);
    float vlen = length(viewXZ);
    if (vlen < 1.0e-5) return 0.0;
    vec2 vdir = viewXZ / vlen;

    float amount = 0.0;
    for (int dz = -1; dz <= 1; ++dz) {
        for (int dx = -1; dx <= 1; ++dx) {
            vec2 cell = base + vec2(float(dx), float(dz));
            vec2 jitter = vec2(atmHash12(cell), atmHash12(cell + vec2(17.3, 31.7)));
            vec2 city = (cell + 0.25 + 0.5 * jitter) * CELL;
            vec2 delta = city - cam;
            float dist = length(delta);
            float distKm = max(dist * 0.001, 2.0);
            vec2 cdir = delta / max(dist, 1.0e-3);
            float aim = pow(max(dot(vdir, cdir), 0.0), 6.0);
            amount += aim / pow(distKm, 2.5);
        }
    }

    float horizon = exp(-max(worldDir.y, 0.0) / ATM_LP_SCALE_HEIGHT);
    return amount * horizon;
}

vec3 atmNormalizedEmission(vec4 emission) {
    vec3 c = max(SpectralToLinearSRGB(emission), vec3(0.0));
    return c / max(max(c.r, max(c.g, c.b)), 1.0e-4);
}

vec3 atmAirglowColor() {
    return atmNormalizedEmission(vec4(0.0, 0.30, 0.70, 0.0));
}

vec3 atmLightPollutionColor() {
    return atmNormalizedEmission(vec4(0.0, 0.0, 0.55, 0.45));
}

vec3 atmNightSkyBackground(vec3 worldDir, float nightFactor) {
    vec3 c = vec3(0.0);

#if ATM_LIGHT_POLLUTION == 1
    float lp = atmLightPollutionAmount(worldDir);
    c += atmLightPollutionColor() * lp * ATM_LP_STRENGTH * 0.025 * nightFactor;
#endif

#if ATM_AIRGLOW == 1
    c += atmAirglowColor() * ATM_AIRGLOW_STRENGTH * 0.0006 * nightFactor;
#endif

    return c;
}

float atmLightPollutionStarOcclusion(float amount) {
    return clamp(1.0 - 0.8 * amount, 0.0, 1.0);
}

#endif
