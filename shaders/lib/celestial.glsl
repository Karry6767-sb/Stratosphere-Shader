#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef TAU
#define TAU 6.28318530717958647693
#endif

#ifndef LIB_CELESTIAL_GLSL
#define LIB_CELESTIAL_GLSL

#include "/lib/celestial/moon_brdf.glsl"

const float MOON_ORBIT_INCL_DEG = 5.145;

vec3 celestialRotateAxis(vec3 v, vec3 axis, float a) {
    float s = sin(a);
    float c = cos(a);
    return v * c + cross(axis, v) * s + axis * (dot(axis, v) * (1.0 - c));
}

vec3 CelestialPoleW() {
    float th = radians(SUN_PATH_ROTATION);
    return vec3(0.0, sin(th), cos(th));
}

float MoonElongation(int moonPhase) {
    float mp = mod(float(moonPhase), 8.0);
    return PI + mp * (TAU / 8.0);
}

float MoonIllumination(int moonPhase) {
    return (1.0 - cos(MoonElongation(moonPhase))) * 0.5;
}

vec3 MoonDirectionFromSun(vec3 sunDirW, int moonPhase) {
    return normalize(celestialRotateAxis(normalize(sunDirW), CelestialPoleW(),
                                         -MoonElongation(moonPhase)));
}

float MoonEclipticLatitude(int moonPhase, int worldDay) {
    float nodalPhase = fract(float(worldDay) / MOON_NODAL_PERIOD);
    return radians(MOON_ORBIT_INCL_DEG * MOON_INCLINATION)
         * sin(TAU * (mod(float(moonPhase), 8.0) * 0.125 + nodalPhase));
}

vec3 MoonApplyInclination(vec3 moonDirW, float beta) {
    vec3 eclipticNormal = CelestialPoleW();
    vec3 nodeAxis = cross(eclipticNormal, moonDirW);
    float nl = length(nodeAxis);
    if (nl < 1.0e-5) return moonDirW;
    return normalize(celestialRotateAxis(moonDirW, nodeAxis / nl, beta));
}

vec3 MoonDirection(vec3 sunDirW, int moonPhase, int worldDay) {
#if ENABLE_MOON_ORBIT == 1
    vec3 m = MoonDirectionFromSun(sunDirW, moonPhase);
    m = MoonApplyInclination(m, MoonEclipticLatitude(moonPhase, worldDay));
    return normalize(m);
#else
    return normalize(-sunDirW);
#endif
}

vec3 MoonTerminatorLightDir(vec3 sunDirW, vec3 moonDirW, int moonPhase) {
#if ENABLE_MOON_ORBIT == 1
    return normalize(sunDirW);
#else
    return normalize(celestialRotateAxis(normalize(moonDirW), CelestialPoleW(),
                                         MoonElongation(moonPhase)));
#endif
}

vec3 MoonSurfaceNormalW(vec3 worldDir, vec3 moonDirW, float cosM, float angularRadius) {
    float d = acos(clamp(cosM, -1.0, 1.0));

    vec3 tangent = worldDir - moonDirW * cosM;
    float tl = length(tangent);
    if (tl > 1.0e-6) {
        tangent = tangent / tl;
    } else {
        vec3 raw = cross(moonDirW, vec3(0.0, 1.0, 0.0));
        float rl = length(raw);
        tangent = (rl > 1.0e-4) ? raw / rl : vec3(1.0, 0.0, 0.0);
    }

    float sinAlpha = clamp(sin(d) / max(sin(angularRadius), 1.0e-6), 0.0, 1.0);
    float cosAlpha = sqrt(max(1.0 - sinAlpha * sinAlpha, 0.0));

    return normalize(-moonDirW * cosAlpha + tangent * sinAlpha);
}

void MoonSurfaceBasis(vec3 moonDirW, out vec3 ex, out vec3 ey, out vec3 nb) {
    nb = -normalize(moonDirW);
    vec3 pole = CelestialPoleW();
    vec3 northRaw = pole - nb * dot(pole, nb);
    float nl = length(northRaw);
    ey = (nl > 1.0e-4) ? (northRaw / nl) : vec3(0.0, 1.0, 0.0);
    ex = cross(ey, nb);
}

vec2 MoonPanoramaUV(vec3 n, vec3 moonDirW, float libLon, float libLat) {
    vec3 ex, ey, nb;
    MoonSurfaceBasis(moonDirW, ex, ey, nb);

    float lon = atan(dot(n, ex), dot(n, nb));
    float lat = asin(clamp(dot(n, ey), -1.0, 1.0));

    float u = 0.5 + (lon + libLon) / TAU;
    float v = 0.5 - (lat + libLat) / PI;

    return vec2(u, clamp(v, 1.0e-3, 1.0 - 1.0e-3));
}

vec2 MoonLibration(int worldDay) {
    if (MOON_LIBRATION_PERIOD <= 0.0) return vec2(0.0);
    float t = TAU * float(worldDay) / MOON_LIBRATION_PERIOD;
    float libLon = radians(MOON_LIBRATION_LON_DEG) * sin(t);
    float libLat = radians(MOON_LIBRATION_LAT_DEG) * sin(t / 1.03);
    return vec2(libLon, libLat);
}

float MoonDiscDiffuse(vec3 worldDir, vec3 moonDirW, float cosM, float angularRadius,
                      vec3 sunDirW) {
    float d = acos(clamp(cosM, -1.0, 1.0));
    if (d >= angularRadius) return 0.0;

    vec3 normal = MoonSurfaceNormalW(worldDir, moonDirW, cosM, angularRadius);
    vec3 L = normalize(sunDirW);
    vec3 V = -normalize(moonDirW);

#if MOON_BRDF == 1
    float mu0 = clamp(dot(normal, L), 0.0, 1.0);

    float term = smoothstep(0.0, 0.02, mu0);

    return term * MoonBRDF(normal, L, V);
#else
    float lambert = clamp(dot(normal, L), 0.0, 1.0);
    float term = smoothstep(0.0, MOON_TERMINATOR_SOFT, lambert);
    return term * pow(lambert, MOON_LIMB_SOFTEN);
#endif
}

float MoonStarOcclusion(float illumination, float moonElev) {
    float above = smoothstep(-0.05, 0.15, moonElev);
    return 1.0 - MOON_STAR_OCCLUSION * clamp(illumination * above, 0.0, 1.0);
}

float MoonLightExposure(float illumination) {
    return mix(MOON_LIGHT_MIN, 1.0, clamp(illumination, 0.0, 1.0));
}

int MoonPhaseEffective(int moonPhase) {
#if ENABLE_MOON_PHASE == 1
    return moonPhase;
#else
    return 0;
#endif
}

#endif
