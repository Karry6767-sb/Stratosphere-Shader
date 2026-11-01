#ifndef LIB_SKY_CIRRUS_GLSL
#define LIB_SKY_CIRRUS_GLSL

#include "/lib/options_defaults.glsl"
#include "/lib/atmosphere/atmosphere_geometry.glsl"
#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/atmosphere/sky_lut.glsl"

const float CIRRUS_R_BOT_KM = ATM_PLANET_R + CIRRUS_BASE_KM;
const float CIRRUS_R_TOP_KM = CIRRUS_R_BOT_KM + CIRRUS_THICK_KM;

const vec2 CIRRUS_FIELD_SEED_KM = vec2(330.0, -1587.0);

const float CIRRUS_CHORD_SOFT_KM = 22.0;

const float CIRRUS_PHASE_ISO = 0.0795775;

vec2 CirrusWorldXZ(vec3 pLocalKm) {
    return pLocalKm.xz + cameraPosition.xz * ATM_M_TO_KM + CIRRUS_FIELD_SEED_KM;
}

float CirrusHash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 CirrusNoiseGrad(vec2 p) {
    vec2 i = floor(p);
    vec2 w = fract(p);
    vec2 u  = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    vec2 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    float a = CirrusHash(i);
    float b = CirrusHash(i + vec2(1.0, 0.0));
    float c = CirrusHash(i + vec2(0.0, 1.0));
    float d = CirrusHash(i + vec2(1.0, 1.0));

    float k1 = b - a;
    float k2 = c - a;
    float k4 = a - b - c + d;
    return vec3(a + k1 * u.x + k2 * u.y + k4 * u.x * u.y,
                du.x * (k1 + k4 * u.y),
                du.y * (k2 + k4 * u.x));
}

vec2 CirrusCurl(vec2 p) {
    vec3 n = CirrusNoiseGrad(p);
    return vec2(n.y, -n.x);
}

vec2 CirrusDirAniso(vec2 pKm, float angleDeg) {
    float A  = radians(angleDeg);
    vec2  W  = vec2(cos(A), sin(A));
    vec2  Wp = vec2(-W.y, W.x);
    float form    = max(CIRRUS_FORM_KM, 1.0e-3);
    float stretch = max(CIRRUS_STRETCH, 1.0e-3);
    return vec2(dot(pKm, W) / stretch, dot(pKm, Wp)) / form;
}

vec2 CirrusAniso(vec2 pKm) {
    return CirrusDirAniso(pKm, CIRRUS_WIND_ANGLE);
}

float CirrusFiberAt(vec2 pKm, float angleDeg, float detailLod) {
    vec2 q = CirrusDirAniso(pKm, angleDeg);

    vec2 c = CirrusCurl(q * 0.65) * 0.65
           + CirrusCurl(q * 1.70) * 0.35;
    vec2 w = c * 2.4;

    float f1 = CirrusNoiseGrad(q * vec2( 2.0,  4.0) + w).x;
    float f2 = CirrusNoiseGrad(q * vec2( 4.0, 10.0) + w * 1.6 + vec2(13.1, 7.7)).x;
    float f3 = CirrusNoiseGrad(q * vec2( 8.0, 24.0) + w * 2.5 + vec2( 3.7, 19.3)).x;

    return 0.45 * f1 + 0.35 * f2
         + 0.20 * mix(0.45, 1.0, detailLod) * f3;
}

float CirrusCellF1(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float best = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 g = vec2(float(x), float(y));
            vec2 j = vec2(CirrusHash(ip + g),
                          CirrusHash(ip + g + vec2(19.7, 7.3)));
            vec2 r = g + j - fp;
            best = min(best, dot(r, r));
        }
    }
    return sqrt(max(best, 0.0));
}

float CirrusCcCoverageMask(vec2 pKm) {
    float coverKm = max(CIRRUS_COVER_KM * 0.65, 1.0e-3);
    float n1 = CirrusNoiseGrad(pKm / coverKm + vec2(13.7, 8.3)).x;
    float n2 = CirrusNoiseGrad(pKm / (coverKm * 0.5) + vec2(21.1, 4.7)).x;
    float cv = 0.65 * n1 + 0.35 * n2;
    return smoothstep(0.30, 0.66, cv);
}

float CirrusCcShape(vec2 pKm, float detailLod) {
    float cellKm = max(CIRRUS_FORM_KM * 0.42, 1.0);

    float A  = radians(CIRRUS_WIND_ANGLE + 12.0);
    vec2  W  = vec2(cos(A), sin(A));
    vec2  Wp = vec2(-W.y, W.x);

    vec2 qc = vec2(dot(pKm, W) / 1.80, dot(pKm, Wp)) / cellKm;
    vec2 c  = CirrusCurl(qc * 0.80) * 0.45
            + CirrusCurl(qc * 1.90) * 0.15;
    qc += c * 0.55;

    float f1 = CirrusCellF1(qc);
    float cells = 1.0 - smoothstep(0.08, 0.60, f1);

    float phase = dot(pKm, Wp) / (cellKm * 1.80)
                + CirrusNoiseGrad(pKm / (cellKm * 6.0) + vec2(2.1, 7.3)).x * 0.80;
    float bands = 0.5 + 0.5 * sin(phase * 6.2831853);
    bands = smoothstep(0.30, 0.72, bands);

    float f2 = CirrusCellF1(qc * 2.10 + vec2(7.3, 3.1));
    float grain = 1.0 - smoothstep(0.08, 0.50, f2);
    float fine = mix(0.78, 0.78 + 0.22 * grain, clamp(detailLod, 0.0, 1.0));

    return cells * mix(0.35, 1.00, bands) * fine;
}

float CirrusCoverageMask(vec2 pKm) {
    float coverKm = max(CIRRUS_COVER_KM, 1.0e-3);
    float n1 = CirrusNoiseGrad(pKm / coverKm + vec2(17.3, 9.1)).x;
    float n2 = CirrusNoiseGrad(pKm / (coverKm * 0.5) + vec2(31.7, 4.9)).x;
    float cv = 0.62 * n1 + 0.38 * n2;

    float coverage = clamp(CIRRUS_COVERAGE, 0.0, 1.0);
    float threshold = 0.74 - 0.50 * coverage;
    float soft      = 0.10 + 0.14 * coverage;
    return smoothstep(threshold, threshold + soft, cv);
}

float CirrusDensityFull(vec2 pKm, float altFrac, float detailLod) {
    float spread = 18.0 + 45.0 * clamp(CIRRUS_FIBER_Q, 0.1, 0.8);
    float fiber = 0.40 * CirrusFiberAt(pKm, CIRRUS_WIND_ANGLE, detailLod)
                + 0.30 * CirrusFiberAt(pKm, CIRRUS_WIND_ANGLE + spread, detailLod)
                + 0.30 * CirrusFiberAt(pKm, CIRRUS_WIND_ANGLE - spread, detailLod);

    float cov = CirrusCoverageMask(pKm);
    float aa = max(fwidth(fiber), 0.5 * fwidth(cov));
    float edge = max(CIRRUS_EDGE_SOFT, 1.0e-3);
    float fiberMask = smoothstep(0.46 - 0.5 * edge - aa,
                                 0.72 + 0.5 * edge + aa, fiber);
    float d = fiberMask * cov;

    vec2 qMain = CirrusAniso(pKm);
    vec2 w = (CirrusCurl(qMain * 0.65) * 0.65
            + CirrusCurl(qMain * 1.70) * 0.35) * 2.4;
    vec2 ep = qMain * vec2(0.75, 2.0);
    float amp = max(CIRRUS_ERODE, 0.0) * 0.33;
    for (int i = 0; i < CIRRUS_ERODE_OCT; ++i) {
        vec2 off = vec2(CIRRUS_FIBER_Q * float(i + 1), 0.0);
        d -= CirrusNoiseGrad(ep + off + w * 1.5 + vec2(3.0, 17.0)).x
           * amp * detailLod;
        ep *= 1.8;
        amp *= 0.55;
    }

    float cc = CirrusCcShape(pKm, detailLod) * CirrusCcCoverageMask(pKm)
             * clamp(CIRRUS_CC_AMOUNT, 0.0, 1.0);
    d = clamp(d, 0.0, 1.0);
    d = 1.0 - (1.0 - d) * (1.0 - clamp(cc, 0.0, 1.0));

    d = pow(max(d, 0.0), 1.4);
    float tent = 1.0 - abs(1.0 - 2.0 * altFrac);
    return d * tent * tent * CIRRUS_DENSITY;
}

float CirrusDensityLite(vec2 pKm, float altFrac) {
    float fiber = CirrusFiberAt(pKm, CIRRUS_WIND_ANGLE, 1.0);
    float cov = CirrusCoverageMask(pKm);
    float d = smoothstep(0.38, 0.76, fiber) * cov;

    float cc = CirrusCcShape(pKm, 1.0) * CirrusCcCoverageMask(pKm)
             * clamp(CIRRUS_CC_AMOUNT, 0.0, 1.0);
    d = 1.0 - (1.0 - clamp(d, 0.0, 1.0)) * (1.0 - clamp(cc, 0.0, 1.0));

    d = pow(max(d, 0.0), 1.4);
    float tent = 1.0 - abs(1.0 - 2.0 * altFrac);
    return d * tent * tent * CIRRUS_DENSITY;
}

float CirrusHG(float c, float g) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * c, 1.0e-4), 1.5));
}

float CirrusPhase(float c) {
    float ph = 0.60 * CirrusHG(c,  0.70)
             + 0.20 * CirrusHG(c,  0.88)
             + 0.20 * CirrusHG(c, -0.30);
#if CIRRUS_HALO > 0
    float haloBand = (c - 0.92718) / 0.035;
    ph += CIRRUS_HALO * 0.35 * exp(-haloBand * haloBand);
#endif
    return ph;
}

float CirrusLightTau(vec3 pLocalKm, vec3 lightDir) {
    const float LG = 1.5;
    float a = CIRRUS_LIGHT_MAX_KM * (LG - 1.0)
            / max(pow(LG, float(CIRRUS_LIGHT_STEPS)) - 1.0, 1.0e-6);
    float b = 0.0;
    float sum = 0.0;
    for (int i = 0; i < CIRRUS_LIGHT_STEPS; ++i) {
        float len = a * pow(LG, float(i));
        b += len;
        vec3  q  = pLocalKm + lightDir * b;
        float af = clamp((length(q) - CIRRUS_R_BOT_KM)
                       / max(CIRRUS_R_TOP_KM - CIRRUS_R_BOT_KM, 1.0e-6), 0.0, 1.0);
        vec2  qField = CirrusWorldXZ(q);
        sum += CirrusDensityLite(qField, af) * len * CIRRUS_SIGMA_KM;
        b += len;
    }
    return min(sum, CIRRUS_TAU_L_MAX);
}

float CirrusAirT(vec3 o, vec3 d, float distKm) {
    vec3  pD = o + d * distKm;
    float rO = max(length(o), ATM_PLANET_R);
    float rD = max(length(pD), ATM_PLANET_R);

    vec4 TO = atmReadTransmittanceLUT(rO, clamp(dot(normalize(o), d), -1.0, 1.0));
    vec4 TD = atmReadTransmittanceLUT(rD, clamp(dot(normalize(pD), d), -1.0, 1.0));

    float lO = dot(TO.rgb, vec3(0.2126, 0.7152, 0.0722));
    float lD = dot(TD.rgb, vec3(0.2126, 0.7152, 0.0722));
    return clamp(lD / max(lO, 1.0e-5), 0.0, 1.0);
}

bool CirrusShellSegment(vec3 o, vec3 d, float r0, float r1, float planetR,
                        out float tA, out float tB) {
    float rc = length(o);
    float a1, b1, a0, b0;
    if (!RayIntersectSphere(o, d, r1, a1, b1)) return false;

    bool hitIn = RayIntersectSphere(o, d, r0, a0, b0);

    if (rc >= r1) {
        tA = max(a1, 0.0);
        tB = (hitIn && a0 > 0.0) ? a0 : b1;
    } else if (rc >= r0) {
        tA = 0.0;
        tB = (hitIn && a0 > 0.0) ? a0 : b1;
    } else {
        tA = (hitIn && b0 > 0.0) ? b0 : max(a1, 0.0);
        tB = b1;
    }

    float tGround;
    if (RayHitPlanet(o, d, tGround)) {
        tA = min(tA, tGround);
        tB = min(tB, tGround);
    }

    return (tB > tA);
}

struct CirrusOut {
    vec3  sky;
    float T;
};
CirrusOut CirrusComposite(vec3 camPosKm, vec3 d, vec3 skyIn,
                          vec3 sunDirW, vec3 moonDirW,
                          float skyGain, float moonIllum) {
    CirrusOut r;
    r.sky = skyIn;
    r.T   = 1.0;

#if CIRRUS_ENABLE == 1
    float tA, tB;
    if (!CirrusShellSegment(camPosKm, d, CIRRUS_R_BOT_KM, CIRRUS_R_TOP_KM, ATM_PLANET_R, tA, tB)) {
        return r;
    }
    float chord   = tB - tA;
    vec3  pMid    = camPosKm + d * (0.5 * (tA + tB));
    float rMid    = length(pMid);
    float altFrac = clamp((rMid - CIRRUS_R_BOT_KM) / max(CIRRUS_R_TOP_KM - CIRRUS_R_BOT_KM, 1.0e-6),
                          0.0, 1.0);

    float detailLod = 1.0 - smoothstep(10.0, 45.0, chord);
    vec2  pFieldKm = CirrusWorldXZ(pMid);
    float density = CirrusDensityFull(pFieldKm, altFrac, detailLod);
    density *= min(1.0, CIRRUS_CHORD_SOFT_KM / max(chord, 1.0e-3));

    float rCam = max(length(camPosKm), ATM_PLANET_R);
    float horizonSin = -sqrt(max(1.0 - (ATM_PLANET_R / rCam) * (ATM_PLANET_R / rCam), 0.0));
    float horizonFade = smoothstep(horizonSin, horizonSin + radians(4.0), d.y);
    density *= horizonFade;
    float tauV    = min(CIRRUS_SIGMA_KM * density * chord, CIRRUS_TAU_MAX);
    float Tv      = exp(-tauV);

    float moonMix = smoothstep(-0.06, -0.16, sunDirW.y);
    vec3 sunLightCol = atmSolarRGB() * ATM_EXPOSURE * skyGain
                     * atmSpectralRatioRGB(atmTransmittanceToSunShadowed(pMid, sunDirW));
    vec3 lightCol = sunLightCol;
    if (moonMix > 0.001) {
        vec3 moonLightCol = atmMoonRGB() * moonIllum * ATM_EXPOSURE * skyGain
                          * atmSpectralRatioRGB(atmTransmittanceToSunShadowed(pMid, moonDirW));
        lightCol = mix(sunLightCol, moonLightCol, moonMix);
    }

    float lightChroma = mix(0.90, 1.0, smoothstep(-0.06, 0.16, sunDirW.y));
    vec3  lightLuma = vec3(dot(lightCol, vec3(0.2126, 0.7152, 0.0722)));
    lightCol = mix(lightLuma, lightCol, lightChroma);

    float fire = (1.0 - smoothstep(-0.04, 0.18, sunDirW.y)) * (1.0 - moonMix);
    lightCol *= mix(vec3(1.0), vec3(1.30, 0.55, 0.32), 0.85 * fire);

    float phSun  = CirrusPhase(clamp(dot(d, sunDirW),  -1.0, 1.0));
    float phMoon = CirrusPhase(clamp(dot(d, moonDirW), -1.0, 1.0));
    float ph     = mix(phSun, phMoon, moonMix) + CIRRUS_PHASE_ISO;
    float tauL   = (moonMix > 0.5) ? CirrusLightTau(pMid, moonDirW)
                                   : CirrusLightTau(pMid, sunDirW);
    float Tlight = exp(-tauL);
    float powder = 1.0 - exp(-2.0 * tauV);

    vec3 Sc1 = CIRRUS_ALBEDO * ph * lightCol * (1.0 - Tv) * Tlight
             * mix(1.0, powder, 0.35);

    vec3 envSky = atmSampleSkyView(vec3(0.0, 1.0, 0.0), sunDirW,
                                   ATM_PLANET_R, CIRRUS_BASE_KM);
    vec3 envLuma = vec3(dot(envSky, vec3(0.2126, 0.7152, 0.0722)));
    envSky = mix(envSky, envLuma, 0.55);
    vec3 Sc2 = (0.10 * envSky + 0.18 * lightCol) * CIRRUS_ALBEDO * (1.0 - Tv);

    vec3 Sc = (Sc1 + Sc2) * CIRRUS_GAIN;

    float twilight = 1.0 - smoothstep(-0.10, 0.12, sunDirW.y);
    float twilightDim = mix(0.55, 1.0, smoothstep(-0.10, 0.08, sunDirW.y));
    float cloudPeak = mix(6.0, 3.5, twilight);
    Sc = Sc * twilightDim / (vec3(1.0) + Sc / cloudPeak);

    float apT = CirrusAirT(camPosKm, d, tA);
    r.sky = skyIn * (1.0 - apT * (1.0 - Tv)) + apT * Sc;
    r.T   = Tv;
#endif

    return r;
}

#endif
