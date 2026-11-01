#ifndef LIB_MEDIUM_GLSL
#define LIB_MEDIUM_GLSL

#include "/lib/blackbody.glsl"
#include "/lib/celestial/light_state.glsl"
#include "/lib/shadow/scene.glsl"

vec3 medSigmaT(vec3 sigmaA, vec3 sigmaS) {
return max(sigmaA + sigmaS, vec3(1.0e-5));
}

vec3 medSigmaT(vec3 sigmaA) {
return max(sigmaA, vec3(1.0e-5));
}

vec3 medTransmittance(vec3 sigmaT, float dist) {
return exp(-sigmaT * max(dist, 0.0));
}

vec3 medInScatter(vec3 sigmaT, vec3 sigmaS, float dist) {
return (sigmaS / sigmaT) * (1.0 - exp(-sigmaT * max(dist, 0.0)));
}

vec3 medAmbient(float daylight) {
return mix(vec3(0.010, 0.018, 0.026),
           vec3(0.10, 0.24, 0.30),
           clamp(daylight, 0.0, 1.0));
}

float medFresnelDielectricN(float cosTheta, float n) {
float c = clamp(cosTheta, 0.0, 1.0);
float gSq = n * n + c * c - 1.0;
if (gSq < 0.0) return 1.0;
float g = sqrt(gSq);
float a = g - c;
float b = g + c;
return 0.5 * (a * a) / (b * b)
     * (1.0 + pow((b * c - 1.0) / (a * c + 1.0), 2.0));
}

vec3 medSunTintAt(vec3 lightDirWorld) {
float sunHigh = clamp(lightDirWorld.y, 0.0, 1.0);
return mix(vec3(1.05, 0.62, 0.34),
           vec3(1.0, 0.98, 0.92),
           smoothstep(0.0, 0.45, sunHigh));
}

const float MED_DISC_SUN_RADIUS  = 0.005;
const float MED_DISC_SUN_GLOW    = 0.03;
const float MED_DISC_MOON_RADIUS = 0.00436;
const float MED_DISC_MOON_GLOW   = 0.025;

float medDiscAngularMask(float cosView, float discRadius, float glowRadius) {
return smoothstep(cos(glowRadius), cos(discRadius), cosView);
}

vec3 medCelestialDiscs(vec3 dir, vec3 sunDirWorld, float daylight) {
vec3 d = normalize(dir);
vec3 sunDir = normalize(sunDirWorld);

float upGate = step(0.0, d.y);

float cosS = clamp(dot(d, sunDir), -1.0, 1.0);
float sunFade = CelestialSunUp(sunDir);
vec3 acc = sunLightColor() * medSunTintAt(sunDir) * daylight * sunFade * 2.0
         * medDiscAngularMask(cosS, MED_DISC_SUN_RADIUS, MED_DISC_SUN_GLOW);

vec3 moonDir = SceneMoonDirW();
float cosM = clamp(dot(d, moonDir), -1.0, 1.0);
#if DAYLIGHT_LEGACY == 1
float moonUp = smoothstep(-0.05, 0.06, moonDir.y);
float moonDayDim = 1.0;
#else
float moonUp = CelestialMoonUp(moonDir);
float moonDayDim = CelestialMoonDiscDayDim(daylight);
#endif
float moonK = MoonIllumination(moonPhase);
acc += moonLightColor() * (1.5 * mix(0.15, 1.0, moonK)) * moonUp * moonDayDim
     * medDiscAngularMask(cosM, MED_DISC_MOON_RADIUS, MED_DISC_MOON_GLOW);

return acc * upGate;
}

#endif
