#ifndef LIB_CELESTIAL_ECLIPSE_GLSL
#define LIB_CELESTIAL_ECLIPSE_GLSL

#include "/lib/celestial.glsl"

#ifndef MOON_ECLIPSE
#define MOON_ECLIPSE 1 // [0 1]
#endif
#ifndef MOON_UMBRA_DEG
#define MOON_UMBRA_DEG 0.684 // [0.4 0.55 0.684 0.8 1.0]
#endif
#ifndef MOON_PENUMBRA_DEG
#define MOON_PENUMBRA_DEG 1.216 // [0.9 1.1 1.216 1.4 1.8]
#endif
#ifndef BLOOD_MOON_R
#define BLOOD_MOON_R 0.55 // [0.35 0.45 0.55 0.65 0.8]
#endif
#ifndef BLOOD_MOON_G
#define BLOOD_MOON_G 0.13 // [0.06 0.10 0.13 0.18 0.25]
#endif
#ifndef BLOOD_MOON_B
#define BLOOD_MOON_B 0.05 // [0.02 0.04 0.05 0.08 0.12]
#endif
#ifndef BLOOD_MOON_BRIGHTNESS
#define BLOOD_MOON_BRIGHTNESS 0.15 // [0.05 0.1 0.15 0.25 0.4]
#endif

float MoonEclipseAngleDeg(vec3 sunDirW, vec3 moonDirW, int moonPhase, int worldDay) {
#if ENABLE_MOON_ORBIT == 1
    float cosTheta = clamp(dot(normalize(moonDirW), -normalize(sunDirW)), -1.0, 1.0);
    return degrees(acos(cosTheta));
#else
    return abs(degrees(MoonEclipticLatitude(moonPhase, worldDay)));
#endif
}

vec3 MoonEclipseTint(vec3 sunDirW, vec3 moonDirW, int moonPhase, int worldDay) {
#if MOON_ECLIPSE == 0
    return vec3(1.0);
#else
    float thetaDeg = MoonEclipseAngleDeg(sunDirW, moonDirW, moonPhase, worldDay);

    const float UMBRA    = MOON_UMBRA_DEG;
    const float PENUMBRA = MOON_PENUMBRA_DEG;

    float shade = 1.0 - smoothstep(UMBRA, PENUMBRA, thetaDeg);
    if (shade <= 1.0e-4) return vec3(1.0);

    vec3 blood = vec3(BLOOD_MOON_R, BLOOD_MOON_G, BLOOD_MOON_B) * BLOOD_MOON_BRIGHTNESS;
    vec3 penumbral = mix(vec3(1.0), vec3(1.0, 0.72, 0.55), shade * 0.55);

    float umbral = 1.0 - smoothstep(UMBRA * 0.85, UMBRA * 1.10, thetaDeg);
    vec3 tint = mix(penumbral * (1.0 - shade * 0.55), blood, umbral);
    return max(tint, vec3(0.0));
#endif
}

#endif
