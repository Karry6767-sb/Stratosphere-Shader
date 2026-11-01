#ifndef LIB_CELESTIAL_DAYLIGHT_GLSL
#define LIB_CELESTIAL_DAYLIGHT_GLSL

#ifndef PI
#define PI 3.14159265358979323846
#endif

const float CELESTIAL_SUN_RADIUS_DEG  = 0.2665;
const float CELESTIAL_MOON_RADIUS_DEG = 0.259;

float CelestialElevDeg(vec3 dirW) {
    return degrees(asin(clamp(dirW.y, -1.0, 1.0)));
}

float CelestialDiscAboveHorizon(float elevDeg, float radiusDeg) {
    float r = max(radiusDeg, 1.0e-4)
            * clamp(CELESTIAL_HORIZON_SOFTNESS, 0.05, 16.0);
    return smoothstep(-r, r, elevDeg + CELESTIAL_REFRACTION_DEG);
}

float CelestialSunUp(vec3 sunDirW) {
#if DAYLIGHT_LEGACY == 1
    return clamp(sunDirW.y * 50.0, 0.0, 1.0);
#else
    return CelestialDiscAboveHorizon(CelestialElevDeg(sunDirW),
                                     CELESTIAL_SUN_RADIUS_DEG);
#endif
}

float CelestialMoonUp(vec3 moonDirW) {
    return CelestialDiscAboveHorizon(CelestialElevDeg(moonDirW),
                                     CELESTIAL_MOON_RADIUS_DEG);
}

float CelestialDaylightBetween(float elevDeg, float lowDeg, float highDeg) {
    return smoothstep(lowDeg, highDeg, elevDeg);
}

float CelestialLegacyDaylight(vec3 sunDirW) {
#if defined(CELESTIAL_HAS_WORLD_TIME) && CELESTIAL_HAS_WORLD_TIME == 1
    float sunElev = clamp(sunDirW.y / 0.2, 0.0, 1.0);
    float worldT  = mod(float(worldTime), 24000.0);
    if (worldT >= 23200.0 && worldT < 23500.0) {
        return smoothstep(23200.0, 23500.0, worldT);
    } else if (worldT >= 23500.0 || worldT < 12000.0) {
        return 1.0;
    } else if (worldT < 18000.0) {
        return sunElev;
    }
    return 0.0;
#else
    return clamp(sunDirW.y / 0.2, 0.0, 1.0);
#endif
}

float CelestialDaylight(vec3 sunDirW) {
#if DAYLIGHT_LEGACY == 1
    return CelestialLegacyDaylight(sunDirW);
#else
    return CelestialDaylightBetween(CelestialElevDeg(sunDirW),
                                    DAYLIGHT_TWILIGHT_LOW,
                                    DAYLIGHT_TWILIGHT_HIGH);
#endif
}

float CelestialMoonDiscDayDim(float daylight) {
    return mix(1.0, clamp(MOON_DAY_DIM, 0.0, 1.0), clamp(daylight, 0.0, 1.0));
}

#endif
