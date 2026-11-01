// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_MEDIUM_GLSL
#define LIB_ATMOSPHERE_MEDIUM_GLSL

#include "/lib/atmosphere/geometry.glsl"
#include "/lib/atmosphere/aerosol.glsl"

const float ATM_RAY_EXP_A = 0.07771971;
const float ATM_RAY_EXP_B = 1.16364243;
const vec4  ATM_SIGMA_S_RAY = vec4(0.0478, 0.02545, 0.01374, 0.008576);

const float ATM_OZONE_CENTER_LOG = 3.22261;
const float ATM_OZONE_INV_VAR    = 5.55555555;
const float ATM_OZONE_DENS_SCALE = 3.78547397e+20;
const vec4  ATM_OZONE_SIGMA      = 381.0 * vec4(2.91000003e-27, 7.11000026e-26, 3.88000004e-25, 3.43e-25);

const float ATM_AERO_SCALE     = 8.0;
const float ATM_AERO_SMOOTH_LO = 1.0;
const float ATM_AERO_SMOOTH_HI = 2.0;
const float ATM_WASO_BASE = 1.48999998e-05;
const float ATM_WASO_BG   = 4.57099986e-07;
const float ATM_INSO_BASE = 1.00999996e-05;
const float ATM_INSO_BG   = 2.2910001e-06;
const float ATM_SOOT_BASE = 5.31000012e-07;
const float ATM_SOOT_BG   = 1.36200002e-08;
const float ATM_WASO_SCA_0 = 4612.52978516;
const float ATM_WASO_SCA_1 = 3786.26000977;
const float ATM_WASO_SCA_2 = 3034.39990234;
const float ATM_WASO_SCA_3 = 2533.01000977;
const float ATM_INSO_SCA_0 = 160.83000183;
const float ATM_INSO_SCA_1 = 167.19000244;
const float ATM_INSO_SCA_2 = 173.88000488;
const float ATM_INSO_SCA_3 = 179.25999451;
const float ATM_SOOT_SCA_0 = 3680.42993164;
const float ATM_SOOT_SCA_1 = 2652.76000977;
const float ATM_SOOT_SCA_2 = 1860.20996094;
const float ATM_SOOT_SCA_3 = 1397.32995605;

const vec4 ATM_SM_A = vec4(
    ATM_WASO_BASE*ATM_WASO_SCA_0 + ATM_INSO_BASE*ATM_INSO_SCA_0 + ATM_SOOT_BASE*ATM_SOOT_SCA_0,
    ATM_WASO_BASE*ATM_WASO_SCA_1 + ATM_INSO_BASE*ATM_INSO_SCA_1 + ATM_SOOT_BASE*ATM_SOOT_SCA_1,
    ATM_WASO_BASE*ATM_WASO_SCA_2 + ATM_INSO_BASE*ATM_INSO_SCA_2 + ATM_SOOT_BASE*ATM_SOOT_SCA_2,
    ATM_WASO_BASE*ATM_WASO_SCA_3 + ATM_INSO_BASE*ATM_INSO_SCA_3 + ATM_SOOT_BASE*ATM_SOOT_SCA_3);
const vec4 ATM_SM_B = vec4(
    (ATM_WASO_BG-ATM_WASO_BASE)*ATM_WASO_SCA_0 + (ATM_INSO_BG-ATM_INSO_BASE)*ATM_INSO_SCA_0 + (ATM_SOOT_BG-ATM_SOOT_BASE)*ATM_SOOT_SCA_0,
    (ATM_WASO_BG-ATM_WASO_BASE)*ATM_WASO_SCA_1 + (ATM_INSO_BG-ATM_INSO_BASE)*ATM_INSO_SCA_1 + (ATM_SOOT_BG-ATM_SOOT_BASE)*ATM_SOOT_SCA_1,
    (ATM_WASO_BG-ATM_WASO_BASE)*ATM_WASO_SCA_2 + (ATM_INSO_BG-ATM_INSO_BASE)*ATM_INSO_SCA_2 + (ATM_SOOT_BG-ATM_SOOT_BASE)*ATM_SOOT_SCA_2,
    (ATM_WASO_BG-ATM_WASO_BASE)*ATM_WASO_SCA_3 + (ATM_INSO_BG-ATM_INSO_BASE)*ATM_INSO_SCA_3 + (ATM_SOOT_BG-ATM_SOOT_BASE)*ATM_SOOT_SCA_3);

float atmRayleighDensity(float r) {
    float h = max(r - ATM_PLANET_R, 0.0);
    return exp(-ATM_RAY_EXP_A * pow(max(h, 0.0), ATM_RAY_EXP_B));
}

float atmMieDensity(float r) {
    float h = max(r - ATM_PLANET_R, 0.0);
    return exp(-h / ATM_AERO_SCALE);
}

float atmOzoneDensity(float r) {
    float h = max(r - ATM_PLANET_R, 1.0e-5);
    float t = log(h) - ATM_OZONE_CENTER_LOG;
    return ATM_OZONE_DENS_SCALE * (1.0 / h) * exp(-t * t * ATM_OZONE_INV_VAR);
}

vec3 atmDensity(vec3 pos) {
    float r = length(pos);
    return vec3(atmRayleighDensity(r), atmMieDensity(r), atmOzoneDensity(r));
}

vec4 atmRayleighScattering(float r) {
    return atmRayleighDensity(r) * ATM_SIGMA_S_RAY;
}

vec4 atmMieScattering(float r) {
    float h = max(r - ATM_PLANET_R, 0.0);
    float t = smoothstep(ATM_AERO_SMOOTH_LO, ATM_AERO_SMOOTH_HI, h);
    return exp(-h / ATM_AERO_SCALE) * (ATM_SM_A + t * ATM_SM_B) * atmMieAerosolScale();
}

vec4 atmOzoneExtinction(float r) {
    return atmOzoneDensity(r) * ATM_OZONE_SIGMA;
}

vec4 atmScatteringSpectrum(vec3 pos) {
    float r = length(pos);
    return atmRayleighScattering(r) + atmMieScattering(r);
}

vec4 atmExtinctionSpectrum(vec3 pos) {
    float r = length(pos);
    return atmRayleighScattering(r) + atmMieScattering(r) + atmOzoneExtinction(r);
}

vec4 GetSigmaSRay(float h)   { return atmRayleighScattering(ATM_PLANET_R + h); }
vec4 GetSigmaSMie(float h)   { return atmMieScattering(ATM_PLANET_R + h); }
vec4 GetSigmaAOzone(float h) { return atmOzoneExtinction(ATM_PLANET_R + h); }
vec4 GetScattering(float h)  { return GetSigmaSRay(h) + GetSigmaSMie(h); }
vec4 GetExtinction(float h)  { return GetScattering(h) + GetSigmaAOzone(h); }

const float ATM_PHASE_RAY_SCALE = 0.0596831;

float PhaseRayleigh(float cosTheta) {
    return (cosTheta * cosTheta + 1.0) * ATM_PHASE_RAY_SCALE;
}

float PhaseMieHG(float cosTheta, float eccentricity) {
    float e2 = eccentricity * eccentricity;
    float den = max(1.0 + e2 - 2.0 * eccentricity * cosTheta, 1.0e-4);
    return (1.0 / (4.0 * PI)) * (1.0 - e2) / (den * sqrt(den));
}

float PhaseCornetteShanks(float cosTheta, float eccentricity) {
    float e2 = eccentricity * eccentricity;
    float p = max(1.0 + e2 - 2.0 * eccentricity * cosTheta, 1.0e-4);
    return (3.0 / (8.0 * PI)) * ((1.0 - e2) * (1.0 + cosTheta * cosTheta))
         / ((2.0 + e2) * p * sqrt(p));
}

const float ATM_G = 0.7;

float atmPhaseRayleigh(float cosTheta) { return PhaseRayleigh(cosTheta); }
float atmPhaseMie(float cosTheta)      { return PhaseMieHG(cosTheta, ATM_G); }
float atmPhase(float cosTheta)         { return atmPhaseRayleigh(cosTheta) + atmPhaseMie(cosTheta); }

#endif
