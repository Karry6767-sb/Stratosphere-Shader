// Star map data: NASA SVS #4851 "Deep Star Maps 2020" (public domain).

#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef TAU
#define TAU 6.28318530717958647693
#endif

#ifndef LIB_GALAXY_GLSL
#define LIB_GALAXY_GLSL

vec2 equatorialToSpherical(vec3 equatorial) {
    float dec = asin(clamp(equatorial.z, -1.0, 1.0));
    float ra  = atan(equatorial.y, equatorial.x);
    return vec2(ra, dec);
}

mat3 galaxyRotY(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, 0.0, s,
                0.0, 1.0, 0.0,
                -s, 0.0, c);
}

mat3 galaxyRotZ(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, -s, 0.0,
                s, c, 0.0,
                0.0, 0.0, 1.0);
}

vec3 equatorialObserverRotation(vec3 equatorial, float solarLon, float hourAngle, float lat) {
    mat3 latRotation   = galaxyRotY(lat);
    mat3 solarRotation = galaxyRotZ(PI - solarLon - hourAngle);
    return solarRotation * latRotation * equatorial;
}

vec2 GalaxyUV(vec3 worldDir, float worldTimeTicks) {
    vec3 eq = vec3(worldDir.yx, -worldDir.z);

    float hourAngle = (worldTimeTicks - 18000.0) * (TAU / 24000.0);

    eq = equatorialObserverRotation(eq,
            GALAXY_SOLAR_POS * TAU,
            hourAngle,
            radians(GALAXY_LATITUDE));

    vec2 sph = equatorialToSpherical(normalize(eq));

    vec2 uv;
    uv.x = 0.5 - GALAXY_RA_SIGN * sph.x * (0.5 / PI);
    uv.y = 0.5 - sph.y * (1.0 / PI);
    return uv;
}

vec3 SampleStarMap(sampler2D starmap, vec2 uv) {
    return texture(starmap, vec2(uv.x, clamp(uv.y, 0.0, 1.0))).rgb;
}

vec3 RenderGalaxy(sampler2D starmap, vec3 worldDir, float worldTimeTicks, float nightFade) {
    if (nightFade <= 0.001) return vec3(0.0);

    vec2 uv = GalaxyUV(normalize(worldDir), worldTimeTicks);
    vec3 c = SampleStarMap(starmap, uv);

    return c * GALAXY_INTENSITY * nightFade;
}

#endif
