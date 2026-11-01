#ifndef LIB_FOG_LOCAL_FOG_GLSL
#define LIB_FOG_LOCAL_FOG_GLSL

#ifndef PI
#define PI 3.14159265358979323846
#endif
#ifndef PERF_SCALE
#define PERF_SCALE 1.0
#endif

#include "/lib/options_defaults.glsl"
#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"
#include "/lib/shadow/entry.glsl"
#include "/lib/shadow/scene.glsl"

#include "/lib/volumetric/light_sun.glsl"
#include "/lib/fog/heightmap.glsl"

#if FOG_HEIGHTMAP == 1
layout(r32ui) uniform readonly uimage2D uimg_fogHeight;
#endif
const int LOCAL_FOG_LOOP_MAX = 32;

float LocalFogPhaseHG(float cosTheta, float g) {
    return VolumetricSunPhaseHG(cosTheta, g);
}

float LocalFogPhaseDual(float cosTheta, float aniso) {
    return VolumetricSunPhaseDual(cosTheta, aniso);
}

float LocalFogSunElevationDeg() {
    return degrees(asin(clamp(SceneSunDirW().y, -1.0, 1.0)));
}

float LocalFogTimeOfDay() {
#if FOG_MORNING == 1
    float elevDeg = LocalFogSunElevationDeg();
    float width = max(FOG_PEAK_WIDTH, 0.1);
    float morning = exp(-pow((elevDeg - FOG_PEAK_ELEV) / width, 2.0));
    float dayFog = mix(FOG_DAY_AMT, 1.0, morning);
    float nightGate = 1.0 - smoothstep(-width, 1.0, elevDeg);
    return mix(dayFog, FOG_NIGHT_AMT, nightGate);
#else
    return 1.0;
#endif
}

float LocalFogSeaLevel() {
    if (cameraPosition.y < FOG_SEA_LEVEL - 24.0) {
        return cameraPosition.y - 1.0;
    }
    return FOG_SEA_LEVEL;
}

float LocalFogAnchorY(vec3 originRel) {
    float eyeWorldY = cameraPosition.y + originRel.y;
    return max(eyeWorldY, LocalFogSeaLevel());
}

float LocalFogRainAmount(float rainStrength) {
    return clamp(rainStrength, 0.0, 1.0);
}

float LocalFogRainEase(float rainStrength) {
    float r = LocalFogRainAmount(rainStrength);
    return r * r * (3.0 - 2.0 * r);
}

float LocalFogRainTopLift(float rainStrength) {
    return FOG_RAIN_TOP_LIFT * LocalFogRainEase(rainStrength);
}

float LocalFogWeatherScale(float rainStrength) {
    return mix(1.0, FOG_RAIN_BOOST, LocalFogRainEase(rainStrength));
}

float LocalFogWindSpeedScale(float rainStrength) {
    return mix(1.0, 1.8, LocalFogRainEase(rainStrength));
}

float LocalFogNoiseContrastScale(float rainStrength) {
    return mix(1.0, 0.65, LocalFogRainEase(rainStrength));
}

float LocalFogDensityScale(float rainStrength, float timeOfDay) {
    return LocalFogWeatherScale(rainStrength) * clamp(timeOfDay, 0.0, 1.0);
}

float LocalFogHash12(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

const vec2 FOG_PERLIN_GRAD[8] = vec2[8](
    vec2( 1.0000,  0.0000), vec2( 0.7071,  0.7071),
    vec2( 0.0000,  1.0000), vec2(-0.7071,  0.7071),
    vec2(-1.0000,  0.0000), vec2(-0.7071, -0.7071),
    vec2( 0.0000, -1.0000), vec2( 0.7071, -0.7071));

int LocalFogGradientIndex(vec2 cell) {
    return int(floor(LocalFogHash12(cell) * 8.0)) & 7;
}

float LocalFogPerlin2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float n00 = dot(FOG_PERLIN_GRAD[LocalFogGradientIndex(i)], f);
    float n10 = dot(FOG_PERLIN_GRAD[LocalFogGradientIndex(i + vec2(1.0, 0.0))], f - vec2(1.0, 0.0));
    float n01 = dot(FOG_PERLIN_GRAD[LocalFogGradientIndex(i + vec2(0.0, 1.0))], f - vec2(0.0, 1.0));
    float n11 = dot(FOG_PERLIN_GRAD[LocalFogGradientIndex(i + vec2(1.0, 1.0))], f - vec2(1.0, 1.0));

    float n = mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
    return clamp(0.5 + 0.70710678 * n, 0.0, 1.0);
}

float LocalFogNoise(vec3 worldPos, float timeSeconds, float rainStrength) {
    float rain = LocalFogRainAmount(rainStrength);
    float windSpeed = FOG_WIND_SPEED * LocalFogWindSpeedScale(rain);
    float t = timeSeconds * windSpeed;
    vec2 baseUV = worldPos.xz * FOG_NOISE_SCALE;
    vec2 windA = vec2(0.93, 0.36);
    vec2 windB = vec2(-0.42, 0.91);

    vec2 uv1 = baseUV + windA * t + vec2(0.0, worldPos.y * 0.012);
    vec2 uv2 = baseUV * 2.7 - windB * t * 1.65
             + vec2(19.1, 7.7) + vec2(0.0, worldPos.y * 0.055);
    vec2 uv3 = baseUV * 6.2 + windA * t * 2.40
             + vec2(-13.7, 21.3) + vec2(0.0, worldPos.y * 0.140);
    float a = LocalFogPerlin2D(uv1);
    float b = LocalFogPerlin2D(uv2);
    float n = mix(a, b, 0.35);
    float c = LocalFogPerlin2D(uv3);
    n = n * 0.82 + c * 0.18;

    n = mix(n, 0.5 + (n - 0.5) * 0.65, rain * 0.8);
    return clamp(n, 0.0, 1.0);
}

float LocalFogTopNoise(vec3 worldPos, float timeSeconds, float rainStrength) {
    float rain = LocalFogRainAmount(rainStrength);
    float t = timeSeconds * FOG_WIND_SPEED * LocalFogWindSpeedScale(rain);
    vec2 p = worldPos.xz * FOG_TOP_NOISE_SCALE
           + vec2(0.90, 0.35) * t + vec2(31.7, 11.3);
    float n1 = LocalFogPerlin2D(p);
    float n2 = LocalFogPerlin2D(p * 2.3 + vec2(-7.7, 13.1)
                              - vec2(0.35, 0.90) * t * 0.6);
    float n = mix(n1, n2, 0.35);
    float amp = FOG_TOP_NOISE_AMP * mix(1.0, 1.35, rain);

    float periodMeters = 1.0 / max(FOG_TOP_NOISE_SCALE, 1.0e-4);
    float maxSlope = 0.35;
    float ampLimit = periodMeters * maxSlope * 0.25;
    amp = min(amp, ampLimit);

    return (n - 0.5) * 2.0 * amp;
}

#if FOG_HEIGHTMAP == 1
bool LocalFogHeightmapCell(ivec2 cell, int frameIndex, out float groundY) {
    groundY = 0.0;
    if (cell.x < 0 || cell.y < 0 ||
        cell.x >= FOG_HEIGHTMAP_SIZE || cell.y >= FOG_HEIGHTMAP_SIZE) {
        return false;
    }
    uint packedCell = imageLoad(uimg_fogHeight, cell).r;
    return FogHeightmapDecodeGroundY(packedCell, cameraPosition, frameIndex, groundY);
}
#endif

bool LocalFogHeightmapGround(vec3 pRel, int frameIndex, out float groundY) {
    groundY = 0.0;
#if FOG_HEIGHTMAP == 1
    vec3 worldPos = pRel + cameraPosition;
#if FOG_QUALITY >= 2
    vec2 rel = (worldPos.xz - FogHeightmapGridOrigin(cameraPosition))
             / FOG_HEIGHTMAP_CELL_SIZE;
    ivec2 base = ivec2(floor(rel));
    vec2 f = fract(rel);
    f = f * f * (3.0 - 2.0 * f);

    float g00, g10, g01, g11;
    bool b00 = LocalFogHeightmapCell(base, frameIndex, g00);
    bool b10 = LocalFogHeightmapCell(base + ivec2(1, 0), frameIndex, g10);
    bool b01 = LocalFogHeightmapCell(base + ivec2(0, 1), frameIndex, g01);
    bool b11 = LocalFogHeightmapCell(base + ivec2(1, 1), frameIndex, g11);

    float w00 = (1.0 - f.x) * (1.0 - f.y);
    float w10 = f.x * (1.0 - f.y);
    float w01 = (1.0 - f.x) * f.y;
    float w11 = f.x * f.y;
    float sum = 0.0;
    float weight = 0.0;
    if (b00) { sum += g00 * w00; weight += w00; }
    if (b10) { sum += g10 * w10; weight += w10; }
    if (b01) { sum += g01 * w01; weight += w01; }
    if (b11) { sum += g11 * w11; weight += w11; }
    if (weight <= 1.0e-5) return false;
    groundY = sum / weight;
    return true;
#else
    bool validCell;
    ivec2 cell = FogHeightmapCellFromWorld(worldPos, cameraPosition, validCell);
    if (!validCell) return false;
    return LocalFogHeightmapCell(cell, frameIndex, groundY);
#endif
#else
    return false;
#endif
}

float LocalFogValleyDensity(vec3 pRel, float groundY, float rainStrength, float topNoise) {
#if FOG_VALLEY == 1
    float worldY = cameraPosition.y + pRel.y;

    float bottomY = LocalFogSeaLevel() - FOG_BASE_DEPTH;
    float topY = LocalFogSeaLevel() + FOG_VALLEY_HEIGHT
               + topNoise * 0.65
               + LocalFogRainTopLift(rainStrength) * 0.35;
    float soft = max(FOG_SOFTNESS * 1.5, 4.0) * mix(1.0, 1.6, LocalFogRainAmount(rainStrength));

    float h = max(worldY - bottomY, 0.0);
    float valley = exp(-h / max(FOG_VALLEY_SCALE_H, 1.0e-3));

    valley *= 1.0 - smoothstep(topY - soft, topY, worldY);

    float floorSoft = max(soft * 0.9, 3.0);
    valley *= smoothstep(bottomY, bottomY + floorSoft, worldY);

    float layerH = (worldY - bottomY) / max(topY - bottomY, 1.0);
    float layerPhase = layerH * 6.2831853;
    valley *= 0.82 + 0.18 * sin(layerPhase * 1.7 + topNoise * 0.35);

    valley *= smoothstep(groundY - 0.5, groundY + 0.75, worldY);

    return clamp(valley * FOG_VALLEY_DENSITY, 0.0, 3.0);
#else
    return 0.0;
#endif
}

float LocalFogHighDensity(vec3 pRel, float rainStrength, float topNoise) {
#if FOG_HIGH_LAYER == 1
    float worldY = cameraPosition.y + pRel.y;
    float startY = FOG_HIGH_START + (LocalFogSeaLevel() - 63.0) + topNoise * 0.35;
    float blend = max(FOG_HIGH_BLEND, 0.5);
    float gate = smoothstep(startY - blend, startY, worldY);
    float h = max(worldY - startY, 0.0);
    float high = exp(-h / max(FOG_HIGH_SCALE_H, 1.0e-3));
    high *= 1.0 - smoothstep(startY + FOG_HIGH_SCALE_H * 3.0 - blend,
                             startY + FOG_HIGH_SCALE_H * 3.0, worldY);
    high *= mix(1.0, 1.45, LocalFogRainEase(rainStrength));
    return clamp(high * gate * FOG_HIGH_DENSITY, 0.0, 3.0);
#else
    return 0.0;
#endif
}

#if FOG_VOLUME == 1
vec3 LocalFogVolumeLo() {
    return vec3(FOG_VOLUME_X - FOG_VOLUME_RX,
                FOG_VOLUME_Y - FOG_VOLUME_RY,
                FOG_VOLUME_Z - FOG_VOLUME_RZ);
}

vec3 LocalFogVolumeHi() {
    return vec3(FOG_VOLUME_X + FOG_VOLUME_RX,
                FOG_VOLUME_Y + FOG_VOLUME_RY,
                FOG_VOLUME_Z + FOG_VOLUME_RZ);
}

float LocalFogAABBVolumeDensity(vec3 worldPos, float timeSeconds, float rainStrength) {
    vec3 lo = LocalFogVolumeLo();
    vec3 hi = LocalFogVolumeHi();
    vec3 edge = min(vec3(FOG_VOLUME_EDGE), max((hi - lo) * 0.45, vec3(0.01)));

    vec3 q = smoothstep(lo, lo + edge, worldPos)
           * (1.0 - smoothstep(hi - edge, hi, worldPos));
    float mask = q.x * q.y * q.z;
    if (mask <= 1.0e-5) return 0.0;

    float n = LocalFogNoise(worldPos, timeSeconds, rainStrength);
    return FOG_VOLUME_DENSITY * mask * (0.65 + 0.7 * n);
}
#endif
float LocalFogDensityBase(vec3 pRel, vec3 anchorRel, float timeSeconds,
                           float rainStrength, int frameIndex,
                           out float valleyPart, out float highPart) {
    vec3 worldPos = pRel + cameraPosition;
    float topNoise = LocalFogTopNoise(worldPos, timeSeconds, rainStrength);
    float groundY = LocalFogSeaLevel() - FOG_BASE_DEPTH;
    float valleyDensity = 0.0;

#if FOG_HEIGHTMAP == 1
    bool hasGround = LocalFogHeightmapGround(pRel, frameIndex, groundY);
    if (!hasGround) {
        groundY = LocalFogSeaLevel() - FOG_BASE_DEPTH;
    }
    valleyDensity = LocalFogValleyDensity(pRel, groundY, rainStrength, topNoise);
#else
    valleyDensity = LocalFogValleyDensity(pRel, groundY, rainStrength, topNoise);
#endif

    highPart = LocalFogHighDensity(pRel, rainStrength, topNoise);
    valleyPart = valleyDensity;
    return clamp(max(valleyDensity, highPart), 0.0, 3.0);
}

float LocalFogDensityHeightOnly(vec3 pRel, vec3 anchorRel, float rainStrength) {
    float worldY = cameraPosition.y + pRel.y;
    float bottomY = LocalFogSeaLevel() - FOG_BASE_DEPTH;
    float topY = LocalFogSeaLevel() + FOG_VALLEY_HEIGHT
               + LocalFogRainTopLift(rainStrength) * 0.35;
    float soft = max(FOG_SOFTNESS * 1.5, 4.0) * mix(1.0, 1.6, LocalFogRainAmount(rainStrength));
    float h = max(worldY - bottomY, 0.0);
    float valley = exp(-h / max(FOG_VALLEY_SCALE_H, 1.0e-3));
    valley *= 1.0 - smoothstep(topY - soft, topY, worldY);
    valley *= FOG_VALLEY_DENSITY;

    float high = 0.0;
#if FOG_HIGH_LAYER == 1
    float blend = max(FOG_HIGH_BLEND, 0.5);
    float highGate = smoothstep(FOG_HIGH_START - blend, FOG_HIGH_START, worldY);
    float highH = max(worldY - FOG_HIGH_START, 0.0);
    high = exp(-highH / max(FOG_HIGH_SCALE_H, 1.0e-3))
         * highGate * FOG_HIGH_DENSITY
         * mix(1.0, 1.45, LocalFogRainEase(rainStrength));
#endif
    return clamp(max(valley, high), 0.0, 3.0);
}

float LocalFogDensityAt(vec3 pRel, vec3 anchorRel, float timeSeconds,
                       float rainStrength, int frameIndex) {
    float globalDensity = 0.0;
    float valleyPart = 0.0;
    float highPart = 0.0;
    float base = LocalFogDensityBase(pRel, anchorRel, timeSeconds, rainStrength,
                                     frameIndex, valleyPart, highPart);

    if (base > 1.0e-5) {
#if FOG_NOISE_AMOUNT <= 0.0
        vec3 worldPos = pRel + cameraPosition;
        float nmin = LocalFogNoise(worldPos, timeSeconds, rainStrength);
        globalDensity = base * mix(1.0, 0.88 + 0.24 * nmin, 0.35);
#else
        {
            vec3 worldPos = pRel + cameraPosition;
            float n = LocalFogNoise(worldPos, timeSeconds, rainStrength);
            float clumpAmount = clamp(FOG_NOISE_AMOUNT * LocalFogNoiseContrastScale(rainStrength), 0.0, 1.0);

            float clumpShape = 0.65 + 0.75 * smoothstep(0.30, 0.80, n);

            float valleyClump = mix(1.0, clumpShape, clumpAmount * 0.45);
            float highClump   = mix(1.0, clumpShape, clumpAmount);

            globalDensity = clamp(max(valleyPart * valleyClump,
                                      highPart * highClump), 0.0, 3.0);
        }
#endif
    }

#if FOG_VOLUME == 1
    vec3 volumeWorldPos = pRel + cameraPosition;
    float volumeDensity = LocalFogAABBVolumeDensity(volumeWorldPos, timeSeconds, rainStrength);
    return max(globalDensity, volumeDensity);
#else
    return globalDensity;
#endif
}

float LocalFogSigmaAt(vec3 pRel, vec3 anchorRel, float timeSeconds, float rainStrength,
                      float sigmaScale, int frameIndex) {
    return FOG_SIGMA0 * FOG_DENSITY
         * LocalFogDensityAt(pRel, anchorRel, timeSeconds, rainStrength, frameIndex)
         * sigmaScale;
}

float LocalFogSigmaHeightOnlyAt(vec3 pRel, vec3 anchorRel, float rainStrength, float sigmaScale) {
    return FOG_SIGMA0 * FOG_DENSITY * LocalFogDensityHeightOnly(pRel, anchorRel, rainStrength) * sigmaScale;
}
bool LocalFogSlabInterval(vec3 originRel, vec3 dirWorld, float rainStrength,
                          out float t0, out float t1) {
    float eyeWorldY = cameraPosition.y + originRel.y;
    t0 = 0.0;
    t1 = 1.0e9;

    float anchorY = LocalFogAnchorY(originRel);
    float floorY = anchorY - FOG_TERRAIN_RANGE - FOG_BASE_DEPTH;
    float topMax = anchorY + FOG_VALLEY_HEIGHT + FOG_TERRAIN_RANGE
                 + FOG_RAIN_TOP_LIFT + FOG_TOP_NOISE_AMP;
#if FOG_HIGH_LAYER == 1
    float highTop = FOG_HIGH_START + (LocalFogSeaLevel() - 63.0) + FOG_HIGH_SCALE_H * 3.0 + FOG_HIGH_BLEND;
    topMax = max(topMax, highTop);
#endif

    if (abs(dirWorld.y) < 1.0e-5) {
        return eyeWorldY > floorY && eyeWorldY < topMax;
    }

    float ta = (floorY - eyeWorldY) / dirWorld.y;
    float tb = (topMax - eyeWorldY) / dirWorld.y;
    t0 = max(t0, min(ta, tb));
    t1 = min(t1, max(ta, tb));
    return t1 > t0;
}

#if FOG_VOLUME == 1
bool LocalFogAABBInterval(vec3 originRel, vec3 dirWorld,
                          out float t0, out float t1) {
    vec3 ro = originRel + cameraPosition;
    vec3 lo = LocalFogVolumeLo();
    vec3 hi = LocalFogVolumeHi();
    t0 = 0.0;
    t1 = 1.0e9;

    if (abs(dirWorld.x) < 1.0e-5) {
        if (ro.x < lo.x || ro.x > hi.x) return false;
    } else {
        float ta = (lo.x - ro.x) / dirWorld.x;
        float tb = (hi.x - ro.x) / dirWorld.x;
        t0 = max(t0, min(ta, tb));
        t1 = min(t1, max(ta, tb));
    }

    if (abs(dirWorld.y) < 1.0e-5) {
        if (ro.y < lo.y || ro.y > hi.y) return false;
    } else {
        float ta = (lo.y - ro.y) / dirWorld.y;
        float tb = (hi.y - ro.y) / dirWorld.y;
        t0 = max(t0, min(ta, tb));
        t1 = min(t1, max(ta, tb));
    }

    if (abs(dirWorld.z) < 1.0e-5) {
        if (ro.z < lo.z || ro.z > hi.z) return false;
    } else {
        float ta = (lo.z - ro.z) / dirWorld.z;
        float tb = (hi.z - ro.z) / dirWorld.z;
        t0 = max(t0, min(ta, tb));
        t1 = min(t1, max(ta, tb));
    }

    return t1 > t0;
}
#endif

bool LocalFogVolumeInterval(vec3 originRel, vec3 dirWorld, float rainStrength,
                            out float t0, out float t1) {
    t0 = 0.0;
    t1 = 0.0;
    bool hit = false;
    float a0, a1;

    if (LocalFogSlabInterval(originRel, dirWorld, rainStrength, a0, a1)) {
        t0 = a0;
        t1 = a1;
        hit = true;
    }

#if FOG_VOLUME == 1
    if (LocalFogAABBInterval(originRel, dirWorld, a0, a1)) {
        if (!hit) {
            t0 = a0;
            t1 = a1;
            hit = true;
        } else {
            t0 = min(t0, a0);
            t1 = max(t1, a1);
        }
    }
#endif

    return hit;
}
vec3 LocalFogShadowAt(vec3 pRel, vec3 lightDirWorld, float distNorm) {
    return VolumetricDirectionalShadowAt(pRel, lightDirWorld, distNorm);
}

float LocalFogSunOpticalDepth(vec3 pRel, vec3 anchorRel, vec3 lightDirWorld, float rainStrength, float sigmaScale) {
    float od = 0.0;
    float stepLen = FOG_SUN_OD_START_STEP;
    vec3 lightPos = pRel;

    for (int i = 0; i < FOG_SUN_OD_STEPS; ++i) {
        stepLen *= FOG_SUN_OD_GROWTH;
        lightPos += lightDirWorld * stepLen;
        od += LocalFogSigmaHeightOnlyAt(lightPos, anchorRel, rainStrength, sigmaScale) * stepLen;
    }
    return od;
}

float LocalFogAnalyticOpticalDepth(vec3 originRel, vec3 rayDir,
                                  float t0, float t1, float sigmaBase, float baseY) {
    float eyeWorldY = cameraPosition.y + originRel.y;
    float y0 = eyeWorldY + rayDir.y * t0;
    float y1 = eyeWorldY + rayDir.y * t1;
    float invH = 1.0 / max(FOG_SCALE_H, 1.0e-3);

    float e0 = exp(-max(y0 - baseY, 0.0) * invH);
    float e1 = exp(-max(y1 - baseY, 0.0) * invH);

    float tau;
    if (abs(rayDir.y) < 1.0e-4) {
        float yMid = 0.5 * (y0 + y1);
        tau = sigmaBase * (t1 - t0) * exp(-max(yMid - baseY, 0.0) * invH);
    } else {
        tau = sigmaBase * FOG_SCALE_H * (e0 - e1) / rayDir.y;
    }
    return max(tau, 0.0);
}

vec3 LocalFogMultiScatterPhase(float cosTheta, vec3 shadow, int orderCap) {
    return VolumetricSunMultiScatterPhase(cosTheta, shadow, orderCap);
}

vec3 LocalFogAnalyticApply(vec3 color,
                           vec3 originRel,
                           vec3 rayDir,
                           float t0,
                           float t1,
                           float rayLen,
                           vec3 lightDirWorld,
                           vec3 lightRadiance,
                           vec3 ambientRadiance,
                           float sigmaScale, int frameIndex) {
    float sigmaBase = FOG_SIGMA0 * FOG_DENSITY * sigmaScale;
    float baseY = LocalFogAnchorY(originRel) - FOG_BASE_DEPTH;
    float midT = t0 + 0.5 * (t1 - t0);
    vec3 midRel = originRel + rayDir * midT;
    float coverage = 1.0;
#if FOG_HEIGHTMAP == 1
    float midGroundY;
    if (!LocalFogHeightmapGround(midRel, frameIndex, midGroundY)) return color;
    baseY = midGroundY;
#else
    coverage = 1.0 - smoothstep(160.0, 320.0, length(midRel.xz));
    if (coverage <= 1.0e-4) return color;
#endif
    float tau = LocalFogAnalyticOpticalDepth(originRel, rayDir, t0, t1, sigmaBase, baseY) * coverage;
    float T = exp(-tau);

    float sampleDist = t0 + 0.5 * rayLen;
    vec3 samplePos = originRel + rayDir * sampleDist;
    float distNorm = clamp(sampleDist / max(FOG_MAX_RAY, 1.0e-3), 0.0, 1.0);

    vec3 sunShadow = LocalFogShadowAt(samplePos, lightDirWorld, distNorm);
    sunShadow *= 1.0 - smoothstep(0.25, 1.0, distNorm);

    float cosTheta = dot(rayDir, lightDirWorld);
    vec3 directLight = VolumetricSunLight(cosTheta, sunShadow, lightRadiance,
                                          vec3(1.0), 1, SceneActiveIsSun());
    vec3 ambient = max(ambientRadiance, vec3(0.0)) * FOG_AMBIENT;
    vec3 source = directLight + ambient;

    vec3 inscatter = source * FOG_SCATTER_ALBEDO * (1.0 - T);
    return color * T + inscatter;
}
float LocalFogIgn(vec2 pixel) {
    pixel = floor(pixel);
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

float LocalFogDither(vec2 pixel, int frameIndex) {
    float ign = LocalFogIgn(pixel);
    float golden = fract(float(frameIndex) * 0.61803398875);
    return fract(ign + golden);
}
vec3 LocalFogApply(vec3 color,
                   vec3 originRel,
                   vec3 rayDirWorld,
                   float rayEndDist,
                   vec3 lightDirWorld,
                   vec3 lightRadiance,
                   vec3 ambientRadiance,
                   float timeSeconds,
                   float rainStrength,
                   float timeOfDay,
                   vec2 pixelCoord,
                   int frameIndex) {
    float dirLen = length(rayDirWorld);
    if (dirLen < 1.0e-6) return color;
    vec3 rayDir = rayDirWorld / dirLen;

    float t0, t1;
    if (!LocalFogVolumeInterval(originRel, rayDir, rainStrength, t0, t1)) return color;

    t1 = min(t1, max(rayEndDist, 0.0));
    t1 = min(t1, t0 + FOG_MAX_RAY);
    float rayLen = t1 - t0;
    if (rayLen < 1.0e-3) return color;

    float sigmaScale = LocalFogDensityScale(rainStrength, timeOfDay);

#if FOG_QUALITY == 0
        float g0, g1;
        if (!LocalFogSlabInterval(originRel, rayDir, rainStrength, g0, g1)) return color;
        g1 = min(g1, max(rayEndDist, 0.0));
        g1 = min(g1, g0 + FOG_MAX_RAY);
        float globalLen = g1 - g0;
        if (globalLen < 1.0e-3) return color;
        return LocalFogAnalyticApply(color, originRel, rayDir, g0, g1, globalLen,
                                     lightDirWorld, lightRadiance, ambientRadiance,
                                     sigmaScale, frameIndex);
#else

    int qualityMax = (FOG_QUALITY <= 1) ? 16
                   : (FOG_QUALITY == 2) ? 24
                   : FOG_MAX_STEPS;
    int msOrder = (FOG_QUALITY >= 3) ? FOG_MS_ORDER
                : (FOG_QUALITY == 2) ? 2 : 1;
    int maxSteps = int(float(qualityMax) * clamp(PERF_SCALE, 0.35, 1.5) + 0.5);
    maxSteps = clamp(maxSteps, 4, LOCAL_FOG_LOOP_MAX);
    int steps = int(float(FOG_MIN_STEPS) + FOG_STEP_GROWTH * rayLen + 0.5);
    steps = clamp(steps, FOG_MIN_STEPS, maxSteps);
    steps = min(steps, LOCAL_FOG_LOOP_MAX);

    float dither = LocalFogDither(pixelCoord, frameIndex);
    float invSteps = 1.0 / float(steps);
    float directMag = dot(max(lightRadiance, vec3(0.0)),
                          vec3(0.2126, 0.7152, 0.0722));
    vec3 ambient = max(ambientRadiance, vec3(0.0)) * FOG_AMBIENT;

    vec3 transmittance = vec3(1.0);
    vec3 inscatter = vec3(0.0);

    for (int i = 0; i < LOCAL_FOG_LOOP_MAX; ++i) {
        if (i >= steps) break;

        float u0 = float(i) * invSteps;
        float u1 = float(i + 1) * invSteps;
        u0 *= u0;
        u1 *= u1;

        float dt = (u1 - u0) * rayLen;
        if (dt <= 1.0e-5) continue;

        float stepDither = fract(dither + float(i) * 0.61803398875);
        float u = mix(u0, u1, stepDither);
        float sampleDist = t0 + u * rayLen;
        vec3 samplePos = originRel + rayDir * sampleDist;
        float sigmaT = LocalFogSigmaAt(samplePos, originRel, timeSeconds, rainStrength,
                                     sigmaScale, frameIndex);
        if (sigmaT <= 1.0e-6) continue;

        float distNorm = clamp(sampleDist / max(FOG_MAX_RAY, 1.0e-3), 0.0, 1.0);
        vec3 sunShadow = LocalFogShadowAt(samplePos, lightDirWorld, distNorm);
        sunShadow *= 1.0 - smoothstep(0.25, 1.0, distNorm);
        float sunOD = (directMag > 1.0e-6)
                    ? LocalFogSunOpticalDepth(samplePos, originRel, lightDirWorld, rainStrength, sigmaScale)
                    : 0.0;
        vec3 sunTransmittance = vec3(exp(-sunOD));

        float cosTheta = dot(rayDir, lightDirWorld);
        vec3 directLight = VolumetricSunLight(cosTheta, sunShadow, lightRadiance,
                                              sunTransmittance, msOrder, SceneActiveIsSun());
        vec3 source = directLight + ambient;

        float stepTrans = exp(-sigmaT * dt);
        float integral = (1.0 - stepTrans) / max(sigmaT, 1.0e-6);
        float sigmaS = sigmaT * FOG_SCATTER_ALBEDO;

        inscatter += transmittance * sigmaS * source * integral;
        transmittance *= stepTrans;

        if (dot(transmittance, vec3(1.0 / 3.0)) < FOG_EXIT_T) break;
    }

    return color * transmittance + inscatter;
#endif
}
#endif
