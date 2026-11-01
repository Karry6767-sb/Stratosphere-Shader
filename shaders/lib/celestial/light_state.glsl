#ifndef LIB_CELESTIAL_LIGHT_STATE_GLSL
#define LIB_CELESTIAL_LIGHT_STATE_GLSL

#include "/lib/celestial.glsl"
#include "/lib/celestial/daylight.glsl"

struct CelestialLight {
    vec3  dirW;
    vec3  radiance;
    float upGate;
    float shadowGate;
};

float CelestialLuminance(vec3 c) {
    return dot(max(c, vec3(0.0)), vec3(0.2126, 0.7152, 0.0722));
}

const float CELESTIAL_ACTIVE_MOON_RATIO = 2.585302e-6;

float CelestialSunActiveMagnitude(vec3 sunDirW) {
    return CelestialSunUp(sunDirW);
}

float CelestialMoonActiveMagnitude(vec3 moonDirW, int moonPhase) {
    return CelestialMoonUp(moonDirW)
         * MoonLightExposure(MoonIllumination(moonPhase))
         * CELESTIAL_ACTIVE_MOON_RATIO;
}

bool CelestialActiveIsSun(vec3 sunDirW, vec3 moonDirW, int moonPhase) {
    return CelestialSunActiveMagnitude(sunDirW)
        >= CelestialMoonActiveMagnitude(moonDirW, moonPhase);
}

vec3 CelestialActiveDirW(vec3 sunDirW, vec3 moonDirW, int moonPhase) {
    return CelestialActiveIsSun(sunDirW, moonDirW, moonPhase) ? sunDirW : moonDirW;
}

CelestialLight CelestialSunLight(vec3 sunDirW, vec3 sunRadiance) {
    CelestialLight L;
    L.dirW       = sunDirW;
    L.radiance   = sunRadiance;
    L.upGate     = CelestialSunUp(sunDirW);
    L.shadowGate = 1.0;
    return L;
}

CelestialLight CelestialMoonLight(vec3 moonDirW, vec3 moonRadiance) {
    CelestialLight L;
    L.dirW       = moonDirW;
    L.radiance   = moonRadiance;
    L.upGate     = CelestialMoonUp(moonDirW);
    L.shadowGate = 1.0;
    return L;
}

CelestialLight CelestialActiveLight(CelestialLight s, CelestialLight m) {
    if (CelestialLuminance(s.radiance) >= CelestialLuminance(m.radiance)) return s;
    return m;
}

#endif
