// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_SKY_LUT_GLSL
#define LIB_ATMOSPHERE_SKY_LUT_GLSL

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/lut_common.glsl"

#ifndef ATM_USAM_SKYLUT_DECLARED
uniform sampler2D usam_skylut;
#define ATM_USAM_SKYLUT_DECLARED
#endif

#ifndef ATM_LUT_TEX_W
#define ATM_LUT_TEX_W 256.0
#endif
#ifndef ATM_LUT_TEX_H
#define ATM_LUT_TEX_H 256.0
#endif
#ifndef ATM_SKYVIEW_W
#define ATM_SKYVIEW_W 192.0
#endif
#ifndef ATM_SKYVIEW_H
#define ATM_SKYVIEW_H 192.0
#endif
#ifndef ATM_TLUT_W_F
#define ATM_TLUT_W_F 256.0
#endif
#ifndef ATM_TLUT_H_F
#define ATM_TLUT_H_F 64.0
#endif
#ifndef ATM_TLUT_Y_OFFSET
#define ATM_TLUT_Y_OFFSET 192.0
#endif

vec4 atmReadTransmittanceLUT(float r, float mu) {
    vec2 uv = atmTransmittanceParamsToUv(r, mu);
    vec2 texel = vec2(uv.x * (ATM_TLUT_W_F - 1.0) + 0.5,
                      uv.y * (ATM_TLUT_H_F - 1.0) + 0.5 + ATM_TLUT_Y_OFFSET);
    return texture(usam_skylut, texel / vec2(ATM_LUT_TEX_W, ATM_LUT_TEX_H));
}

vec4 atmTransmittanceToSun(float r, float mu) {
    return atmReadTransmittanceLUT(r, clamp(mu, -1.0, 1.0));
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

float atmSkyViewV(float viewZenithCos, float zenithHorizon, float beta) {
    float horizonCos = cos(zenithHorizon);
    float coord = acos(clamp(viewZenithCos, -1.0, 1.0));
    if (viewZenithCos < horizonCos) {
        coord = sqrt(clamp((coord - zenithHorizon) / max(beta, 1.0e-5), 0.0, 1.0));
        return coord * 0.5 + 0.5;
    }
    coord = sqrt(clamp(1.0 - coord / max(zenithHorizon, 1.0e-5), 0.0, 1.0));
    return (1.0 - coord) * 0.5;
}

float atmSkyViewU(vec3 d, vec3 s) {
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 sideRaw = cross(up, d);
    float sideLen = length(sideRaw);
    vec3 sideVector = (sideLen > 1.0e-5) ? (sideRaw / sideLen) : vec3(1.0, 0.0, 0.0);
    vec3 forwardVector = normalize(cross(sideVector, up));
    vec2 lightOnPlane = vec2(dot(s, sideVector), dot(s, forwardVector));
    float lightLen = length(lightOnPlane);
    float lightViewCos = (lightLen > 1.0e-5) ? (lightOnPlane.y / lightLen) : 1.0;
    return clamp(0.5 - 0.5 * lightViewCos, 0.0, 1.0);
}

vec2 SkyLUTUV(vec3 worldDir, vec3 sunDirWorld, float planetR, float altitude) {
    vec3 d = normalize(worldDir);
    vec3 s = normalize(sunDirWorld);

    float r = max(planetR + altitude, planetR + 1.0e-3);
    float viewZenithCos = clamp(d.y, -1.0, 1.0);

    float vHorizon = sqrt(max(r * r - planetR * planetR, 0.0));
    float beta = acos(clamp(vHorizon / r, -1.0, 1.0));
    float zenithHorizon = PI - beta;

    float u = atmSkyViewU(d, s);
    float v = atmSkyViewV(viewZenithCos, zenithHorizon, beta);

    float inset = 0.5 / ATM_SKYVIEW_W;
    vec2 uv = vec2(u, v) * (1.0 - 1.0 / ATM_SKYVIEW_W) + inset;
    return uv * (ATM_SKYVIEW_W / ATM_LUT_TEX_W);
}

vec4 atmSampleAerialPerspective(vec2 screenUV, float distKm,
                                float nearKm, float farKm) {
    float safeNear = max(nearKm, 1.0e-4);
    float safeFar  = max(farKm, safeNear * 1.001);
    float logT = log(max(distKm, safeNear) / safeNear)
               / max(log(safeFar / safeNear), 1.0e-6);
    int slice = clamp(int(floor(clamp(logT, 0.0, 0.9999) * float(ATM_AP_SLICES))),
                      0, ATM_AP_SLICES - 1);

    int tileX = slice % 2;
    int tileY = slice / 2;
    vec2 st = clamp(screenUV, vec2(0.0), vec2(1.0));
    vec2 texel = vec2(float(tileX * ATM_AP_BINS), float(tileY * ATM_AP_BINS))
               + st * float(ATM_AP_BINS) - 0.5;
    texel = clamp(texel,
                  vec2(float(tileX * ATM_AP_BINS) + 0.5, float(tileY * ATM_AP_BINS) + 0.5),
                  vec2(float((tileX + 1) * ATM_AP_BINS) - 0.5,
                       float((tileY + 1) * ATM_AP_BINS) - 0.5));
    vec2 uv = vec2(float(ATM_AP_X_OFFSET) + texel.x, texel.y) / vec2(ATM_LUT_TEX_W, ATM_LUT_TEX_H);
    return texture(usam_skylut, uv);
}
vec3 atmSampleSkyView(vec3 worldDir, vec3 sunDirWorld, float planetR, float altitude) {
    vec3 d = normalize(worldDir);
    vec3 s = normalize(sunDirWorld);

    float r = max(planetR + altitude, planetR + 1.0e-3);
    float viewZenithCos = clamp(d.y, -1.0, 1.0);

    float vHorizon = sqrt(max(r * r - planetR * planetR, 0.0));
    float beta = acos(clamp(vHorizon / r, -1.0, 1.0));
    float zenithHorizon = PI - beta;
    float horizonCos = cos(zenithHorizon);

    float u = atmSkyViewU(d, s);
    float inset = 0.5 / ATM_SKYVIEW_W;
    float uTex = u * (1.0 - 1.0 / ATM_SKYVIEW_W) + inset;

    const float ATM_HORIZON_AA = 0.0200;
    float tAA = smoothstep(horizonCos - ATM_HORIZON_AA,
                           horizonCos + ATM_HORIZON_AA, viewZenithCos);

    float vBase = atmSkyViewV(viewZenithCos, zenithHorizon, beta);
    float vBaseTex = vBase * (1.0 - 1.0 / ATM_SKYVIEW_W) + inset;
    vec3 colBase = texture(usam_skylut,
                           clamp(vec2(uTex, vBaseTex) * (ATM_SKYVIEW_W / ATM_LUT_TEX_W), 0.0, 1.0)).rgb;
    if (tAA <= 0.001 || tAA >= 0.999) return colBase;

    float vUp = atmSkyViewV(horizonCos + ATM_HORIZON_AA, zenithHorizon, beta);
    float vDn = atmSkyViewV(horizonCos - ATM_HORIZON_AA, zenithHorizon, beta);
    float vUpTex = vUp * (1.0 - 1.0 / ATM_SKYVIEW_W) + inset;
    float vDnTex = vDn * (1.0 - 1.0 / ATM_SKYVIEW_W) + inset;
    vec3 colUp = texture(usam_skylut,
                         clamp(vec2(uTex, vUpTex) * (ATM_SKYVIEW_W / ATM_LUT_TEX_W), 0.0, 1.0)).rgb;
    vec3 colDn = texture(usam_skylut,
                         clamp(vec2(uTex, vDnTex) * (ATM_SKYVIEW_W / ATM_LUT_TEX_W), 0.0, 1.0)).rgb;
    return mix(colDn, colUp, tAA);
}

#endif
