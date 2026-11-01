#ifndef LIB_SKY_AURORA_GLSL
#define LIB_SKY_AURORA_GLSL

#include "/lib/options_defaults.glsl"
#include "/lib/atmosphere/atmosphere_geometry.glsl"
#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/atmosphere/sky_lut.glsl"

#ifndef AURORA_AZIMUTH
#define AURORA_AZIMUTH 0.0
#endif
#ifndef AURORA_ARC_FREQ
#define AURORA_ARC_FREQ 0.0038461538
#endif
#ifndef AURORA_ARC_DRIFT
#define AURORA_ARC_DRIFT 0.0015
#endif
#ifndef AURORA_FOLD_OFFSET
#define AURORA_FOLD_OFFSET 32.0
#endif
#ifndef AURORA_RAY_FREQ
#define AURORA_RAY_FREQ 0.3125
#endif
#ifndef AURORA_RAY_WIDTH
#define AURORA_RAY_WIDTH 1.5
#endif
#ifndef AURORA_RAY_DRIFT
#define AURORA_RAY_DRIFT 0.004
#endif
#ifndef AURORA_SUBSTORM_RATE
#define AURORA_SUBSTORM_RATE 0.0011111111
#endif
#ifndef AURORA_ARC2_OFFSET
#define AURORA_ARC2_OFFSET 55.0
#endif
#ifndef AURORA_ARC3_OFFSET
#define AURORA_ARC3_OFFSET -65.0
#endif
#ifndef AURORA_ARC_GAIN
#define AURORA_ARC_GAIN 1.80
#endif
#ifndef AURORA_RIBON_SCALE
#define AURORA_RIBON_SCALE 0.62
#endif
#ifndef AURORA_VISUAL_TOP
#define AURORA_VISUAL_TOP 280.0
#endif
#ifndef AURORA_SKY_SCALE
#define AURORA_SKY_SCALE 0.012
#endif
#ifndef AURORA_MAX_DIST
#define AURORA_MAX_DIST 900.0
#endif
#ifndef AURORA_RADIANCE_SCALE
#define AURORA_RADIANCE_SCALE 0.0090
#endif
#ifndef AURORA_LINE_WEIGHT
#define AURORA_LINE_WEIGHT vec3(1.0, 0.35, 0.10)
#endif
#ifndef AURORA_STAR_WASH
#define AURORA_STAR_WASH 2.0
#endif

const float AURORA_R_INNER = ATM_PLANET_R + AURORA_H_BOTTOM;
const float AURORA_R_OUTER = ATM_PLANET_R + AURORA_H_TOP;

vec3 AuroraNorthAxis() {
    float az = radians(AURORA_AZIMUTH);
    return normalize(vec3(sin(az), 0.0, -cos(az)));
}

vec3 AuroraFieldDir(vec3 north) {
    float dip = radians(clamp(AURORA_DIP, 0.0, 89.0));
    return normalize(cos(dip) * north - vec3(0.0, sin(dip), 0.0));
}

vec3 AuroraEastAxis(vec3 north) {
    return normalize(cross(north, vec3(0.0, 1.0, 0.0)));
}

vec3 AuroraPlanetCameraPosition() {
    vec3 p = AtmosphereCameraPosition();
    p.x = cameraPosition.x * ATM_M_TO_KM;
    p.z = cameraPosition.z * ATM_M_TO_KM;
    return p;
}

float AuroraHash11(float x) {
    return fract(sin(x * 127.1 + 0.37) * 43758.5453123);
}

float AuroraValueNoise1(float x) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(AuroraHash11(i), AuroraHash11(i + 1.0), f);
}

float AuroraHash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float AuroraValueNoise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = AuroraHash21(i);
    float b = AuroraHash21(i + vec2(1.0, 0.0));
    float c = AuroraHash21(i + vec2(0.0, 1.0));
    float d = AuroraHash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float AuroraFullSkyField(vec2 worldXZ, float t) {
    float tt = t * max(AURORA_ARC_SPEED, 0.05);
    vec2 p = worldXZ;
    float wx = AuroraValueNoise2(p * AURORA_SKY_SCALE + vec2(3.1, tt * 0.003));
    float wy = AuroraValueNoise2(p * AURORA_SKY_SCALE + vec2(-4.7, -tt * 0.002));
    vec2 q = p + (vec2(wx, wy) - 0.5) * 150.0;

    float s = q.x * 0.035 + q.y * 0.018 + tt * 0.012;
    float stripeA = 0.5 + 0.5 * sin(s);
    float stripeB = 0.5 + 0.5 * sin(s * 1.73 + 1.7 + wx * 5.0);
    float lowCut = 0.52;
    float density = smoothstep(lowCut, 0.92, stripeA * 0.72 + stripeB * 0.28);

    float rayCoord = q.x * 0.080 + q.y * 0.050;
    float rays = mix(0.62, 1.0, AuroraValueNoise1(rayCoord + tt * 0.010));
    return density * rays;
}

float AuroraHash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float AuroraDither(vec2 fragCoord) {
    vec2 p = floor(fragCoord);
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

float AuroraArcOffset(float eastKm, float t) {
    float animT = t * max(AURORA_ARC_SPEED, 0.05);
    float dynamics = clamp(float(AURORA_ARC_DYNAMICS), 0.0, 1.0);

    float wobble = sin(animT * 0.047 + 0.60);
    float phaseWarp = dynamics * 0.55 * sin(animT * 0.029 + 1.70);
    float ampMod = mix(1.0, 0.78 + 0.35 * wobble, dynamics);
    float secondAmp = mix(0.38, 0.28 + 0.18 * wobble, dynamics);

    float ph = eastKm * AURORA_ARC_FREQ + t * AURORA_ARC_DRIFT;
    return AURORA_ARC_AMP * AURORA_ARC_GAIN
         * (ampMod * sin(ph + phaseWarp)
         + secondAmp * sin(ph * 1.83 + 1.7 + phaseWarp * 1.30)
         + 0.12 * sin(ph * 3.70 + 3.1));
}

float AuroraRibbonWidth(float eastC, float t) {
    return AURORA_BAND_W * AURORA_RIBON_SCALE
         * (0.80 + 0.22 * sin(eastC * 0.011 + t * 0.025 + 1.3));
}

float AuroraRibbonAt(float northC, float center, float curve, float width) {
    float s = northC - center - curve;
    float d = abs(s) / max(width, 1.0e-3);
    float body = exp(-d * d);
    float edge = 1.0 - smoothstep(1.6, 3.0, d);
    return body * edge;
}

float AuroraBandAt(float northC, float eastC, float t) {
    return AuroraRibbonAt(northC, AURORA_DIST, AuroraArcOffset(eastC, t),
                          AuroraRibbonWidth(eastC, t));
}

float AuroraBandField(float northC, float eastC, float t) {
    float width = AuroraRibbonWidth(eastC, t);
    float curveA = AuroraArcOffset(eastC, t);
    float curveB = AuroraArcOffset(eastC, t * 0.83);

    float bandA = AuroraRibbonAt(northC, AURORA_DIST, curveA, width);
    float bandB = AuroraRibbonAt(northC,
                                 AURORA_DIST + AURORA_FOLD_OFFSET * AURORA_RIBON_SCALE,
                                 curveB, width) * AURORA_FOLD_WEIGHT;
    float band = max(bandA, bandB) + 0.35 * bandA * bandB;

    float coverage = max(clamp(AURORA_COVERAGE, 0.0, 1.0), float(AURORA_MULTI_ARC));
    float extraWeight = coverage * (0.5 + 0.5 * clamp(AURORA_MULTI_ARC_WEIGHT, 0.0, 1.0));
    if (extraWeight > 0.01) {
        float bandC = AuroraRibbonAt(northC, AURORA_DIST - 80.0,
                                     curveA * 1.22, width * 1.15)
                    * extraWeight * 0.85;
        float bandD = AuroraRibbonAt(northC, AURORA_DIST + 105.0,
                                     curveA * 0.82, width * 1.25)
                    * extraWeight * 0.65;
        float bandE = AuroraRibbonAt(northC, AURORA_DIST + 220.0,
                                     curveB * 1.35, width * 1.35)
                    * extraWeight * 0.50;
        band = max(band, bandC);
        band = max(band, bandD);
        band = max(band, bandE);
    }
    return band;
}

float AuroraStriation(float eastC, float t) {
    float freq = min(AURORA_RAY_FREQ, 1.0 / max(AURORA_RAY_WIDTH, 1.5));
    float n0 = AuroraValueNoise1(eastC * freq + t * AURORA_RAY_DRIFT);
    float n1 = AuroraValueNoise1(eastC * freq * 2.7 + 11.3
                               - t * AURORA_RAY_DRIFT * 1.4);
    float n = clamp(0.62 * n0 + 0.38 * n1, 0.0, 1.0);
    float ray = pow(n, max(AURORA_RAY_CONTRAST, 1.0));
    return mix(0.62, 1.0, ray);
}

vec3 AuroraAltitudeProfile(float h) {
    float bottom = smoothstep(AURORA_H_BOTTOM, AURORA_H_BOTTOM + 24.0, h);
    float visualTop = min(AURORA_H_TOP, AURORA_VISUAL_TOP);

    float green = bottom * (1.0 - smoothstep(140.0, 230.0, h));
    float redTop = smoothstep(220.0, max(visualTop, 221.0), h);
    float red = smoothstep(130.0, 210.0, h) * (1.0 - redTop);
    float blue = bottom * exp(-pow(max(h - 96.0, 0.0) / 14.0, 2.0));

    return vec3(green, red, blue);
}

vec3 AuroraLineColor(vec3 prof) {
    const mat3 AURORA_LINE_RGB = mat3(
        vec3(0.10, 1.00, 0.34),
        vec3(1.00, 0.10, 0.05),
        vec3(0.32, 0.16, 1.00)
    );
    return AURORA_LINE_RGB * (prof * AURORA_LINE_WEIGHT);
}

float AuroraPurpleProfile(float h) {
    float visualTop = min(AURORA_H_TOP, AURORA_VISUAL_TOP);
    return smoothstep(170.0, 220.0, h)
         * (1.0 - smoothstep(230.0, max(visualTop, 231.0), h));
}

vec3 AuroraApplySaturation(vec3 c, float sat) {
    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
    return max(mix(vec3(luma), c, sat), vec3(0.0));
}

vec3 AuroraAtmosphericTransmittance(vec3 camPos, vec3 dir) {
    return clamp(atmSpectralRatioRGB(atmTransmittanceToSun(camPos, dir)),
                 vec3(0.0), vec3(1.0));
}

float AuroraSubstorm(float t, float daySeed) {
    float phase = fract(t * AURORA_SUBSTORM_RATE + AuroraHash11(daySeed * 1.7 + 3.1));
    float pulse = smoothstep(0.0, 0.06, phase)
                * (1.0 - smoothstep(0.35, 1.0, phase));
    return mix(0.35, 1.0, pulse);
}

float AuroraPulse(float eastC, float t) {
    float n = AuroraValueNoise1(eastC * 0.035 - t * 0.04);
    float s = 0.5 + 0.5 * sin(t * 1.7 + n * 6.2831853 + eastC * 0.012);
    return mix(0.82, 1.18, smoothstep(0.15, 0.85, s));
}

float AuroraChanceFactor(float daySeed, float biomeMaySnow) {
#if AURORA_CHANCE == 1
    float snow = clamp(biomeMaySnow, 0.0, 1.0);
    return snow * (0.35 + 0.65 * step(0.55, AuroraHash11(daySeed * 0.73 + 19.7)));
#else
    return 1.0;
#endif
}

float AuroraNightFade(vec3 sunDirW) {
    return 1.0 - smoothstep(-0.10, 0.02, sunDirW.y);
}

bool AuroraShellInterval(vec3 origin, vec3 dir, out float tEnter, out float tExit) {
    tEnter = 0.0;
    tExit  = 0.0;

    float r = length(origin);
    float t0i, t1i, t0o, t1o;
    bool hitInner = RayIntersectSphere(origin, dir, AURORA_R_INNER, t0i, t1i);
    bool hitOuter = RayIntersectSphere(origin, dir, AURORA_R_OUTER, t0o, t1o);
    if (!hitOuter) return false;

    if (r < AURORA_R_INNER) {
        if (!hitInner || t1i <= 0.0 || t1o <= 0.0) return false;
        tEnter = t1i;
        tExit  = t1o;
    } else if (r <= AURORA_R_OUTER) {
        tEnter = 0.0;
        tExit  = t1o;
    } else {
        if (t0o <= 0.0) return false;
        tEnter = t0o;
        tExit  = (hitInner && t0i > 0.0) ? t0i : t1o;
    }

    tExit = min(tExit, AURORA_MAX_DIST);
    float tGround;
    if (RayHitPlanet(origin, dir, tGround)) tExit = min(tExit, tGround);
    return tExit > tEnter;
}

float AuroraSampleDistance(float t0, float t1, float tc, float u) {
    if (t1 <= t0) return t0;

    float W = max(90.0, AURORA_BAND_W * 3.0);
    float tcClamped = clamp(tc, t0, t1);
    float b0 = clamp(tcClamped - W, t0, t1);
    float b1 = clamp(tcClamped + W, t0, t1);
    if (b1 <= b0 + 1.0e-3) return mix(t0, t1, clamp(u, 0.0, 1.0));

    float lowerLen = max(b0 - t0, 0.0);
    float upperLen = max(t1 - b1, 0.0);
    float tailLen  = lowerLen + upperLen;
    float lowerShare = (tailLen > 1.0e-5) ? (0.5 * lowerLen / tailLen) : 0.0;
    float bandEnd = lowerShare + 0.5;

    if (lowerShare > 1.0e-4 && u < lowerShare) {
        return mix(t0, b0, clamp(u / lowerShare, 0.0, 1.0));
    }
    if (u < bandEnd) {
        return mix(b0, b1, clamp((u - lowerShare) / 0.5, 0.0, 1.0));
    }
    float upperShare = max(1.0 - bandEnd, 1.0e-4);
    return mix(b1, t1, clamp((u - bandEnd) / upperShare, 0.0, 1.0));
}

int AuroraStepCount(vec3 dir, vec3 B) {
    float along = abs(dot(dir, B));
    float f = mix(float(AURORA_STEPS_MAX), float(AURORA_STEPS_MIN),
                  clamp(along, 0.0, 1.0));
    return max(int(f + 0.5), 4);
}

vec3 AuroraFootPoint(vec3 pRelKm, float h, float hRef, vec3 B) {
    float s = max(-B.y, 0.2);
    return pRelKm + B * ((h - hRef) / s);
}

vec3 AuroraRadianceInternal(vec3 dir, vec3 camPos, float t, float daySeed, float visibility, int stepsOverride) {
#if AURORA_ENABLE == 0
    return vec3(0.0);
#else
    if (visibility <= 0.001) return vec3(0.0);

    dir = normalize(dir);
    vec3 north = AuroraNorthAxis();
    vec3 B     = AuroraFieldDir(north);
    vec3 east  = AuroraEastAxis(north);

    float tEnter, tExit;
    if (!AuroraShellInterval(camPos, dir, tEnter, tExit)) return vec3(0.0);

    float dist = max(AURORA_DIST, 1.0);
    float tCross = dist / max(dot(dir, north), 1.0e-4);
    int steps = (stepsOverride > 0) ? stepsOverride : AuroraStepCount(dir, B);
    float dither = AuroraDither(gl_FragCoord.xy);
    float envelope = AuroraSubstorm(t, daySeed);

    float eastOrigin = dot(camPos, east);
    vec3 emission = vec3(0.0);
    float shapeWeight = 0.0;
    float purpleWeight = 0.0;

    for (int i = 0; i < steps; ++i) {
        float u0 = float(i) / float(steps);
        float u1 = float(i + 1) / float(steps);
        float d0 = AuroraSampleDistance(tEnter, tExit, tCross, u0);
        float d1 = AuroraSampleDistance(tEnter, tExit, tCross, u1);
        float stepLen = d1 - d0;
        if (stepLen <= 0.0) continue;

        float d = mix(d0, d1, dither);
        vec3  p = camPos + dir * d;
        float h = length(p) - ATM_PLANET_R;
        if (h < AURORA_H_BOTTOM - 2.0 || h > AURORA_H_TOP + 2.0) continue;

        vec3 foot = AuroraFootPoint(dir * d, h, 100.0, B);
        float eastC  = dot(foot, east) + eastOrigin;
        float northC = dot(foot, north);

#if AURORA_FULL_SKY == 1
        vec2 skyXZ = vec2(eastC, northC + dot(camPos, north));
        float northShape = AuroraBandField(northC, eastC, t)
                         * AuroraStriation(eastC, t);
        float fullSkyShape = AuroraFullSkyField(skyXZ, t) * AURORA_COVERAGE;
        float shape = max(northShape, fullSkyShape);
#else
        float shape = AuroraBandField(northC, eastC, t)
                    * AuroraStriation(eastC, t);
#endif
        float pulse = mix(1.0, AuroraPulse(eastC, t),
                          clamp(float(AURORA_PULSATION), 0.0, 1.0));
        float sampleWeight = shape * pulse * stepLen;
        shapeWeight += sampleWeight;
        purpleWeight += sampleWeight * AuroraPurpleProfile(h);
        emission += AuroraAltitudeProfile(h) * sampleWeight;
    }

    vec3 col = AuroraLineColor(emission);
    float purpleFrac = clamp((purpleWeight / max(shapeWeight, 1.0e-4))
                           * clamp(AURORA_PURPLE_TOP, 0.0, 1.0), 0.0, 1.0);
    float colLuma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    vec3 purpleTint = vec3(0.55, 0.08, 1.00) * colLuma * 1.15;
    col = mix(col, purpleTint, purpleFrac);
    col *= AuroraAtmosphericTransmittance(camPos, dir);
    col = AuroraApplySaturation(col, AURORA_SATURATION);
    return col * (AURORA_INTENSITY * visibility * envelope * AURORA_RADIANCE_SCALE);
#endif
}

vec3 AuroraRadiance(vec3 dir, vec3 camPos, float t, float daySeed, float visibility) {
    return AuroraRadianceInternal(dir, camPos, t, daySeed, visibility, 0);
}

vec3 AuroraRadianceWater(vec3 dir, vec3 camPos, float t, float daySeed, float visibility) {
    return AuroraRadianceInternal(dir, camPos, t, daySeed, visibility, 8);
}

#endif
