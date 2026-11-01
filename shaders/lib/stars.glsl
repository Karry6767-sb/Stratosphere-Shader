#ifndef STARS_SIZE_MAG
#define STARS_SIZE_MAG 0.060
#endif

#ifndef STARS_SIZE_BASE
#define STARS_SIZE_BASE 0.020
#endif

#ifndef STARS_SCREEN_PX
#define STARS_SCREEN_PX 1080.0
#endif

#ifndef STARS_FOV_RAD
#define STARS_FOV_RAD 1.2217
#endif

#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef TAU
#define TAU 6.28318530717958647693
#endif

#ifndef LIB_STARS_GLSL
#define LIB_STARS_GLSL

vec3 starsHash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

float starsHash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

vec3 starsCell(vec3 cell, vec3 starDir, vec3 fragDir, float twinkleTime) {
    vec3 rnd = starsHash33(cell);

    if (rnd.x > STARS_COVERAGE) return vec3(0.0);

    float mag = pow(starsHash13(cell * 1.7 + 11.3), 3.0);

    float isBright = step(1.0 - STARS_BRIGHT_RATIO, rnd.y);
    mag = mix(mag, mix(0.55, 1.0, starsHash13(cell * 2.3 + 5.1)), isBright);

    if (mag < 1.0e-4) return vec3(0.0);

    float cosA = clamp(dot(starDir, fragDir), -1.0, 1.0);
    float angDist = acos(cosA) * STARS_SCALE;

    float pxInCell = (STARS_FOV_RAD / STARS_SCREEN_PX) * STARS_SCALE;
    float radius = STARS_SIZE_BASE + STARS_SIZE_MAG * mag;
    radius = max(radius, STARS_MIN_PIXEL * pxInCell);

    if (angDist > radius) return vec3(0.0);

    float d = angDist;
    float prof = 1.0 - d / radius;
    prof = prof * prof;
    prof = sqrt(prof);

    float twinklePhase = TAU * starsHash13(cell * 9.1 + 6.7);
    float twinkle = 1.0 - STARS_TWINKLE * mag
                  * (0.5 + 0.5 * cos(twinkleTime * 2.0 + twinklePhase));
    prof *= twinkle;

    float temp = rnd.z;
    vec3 warm = vec3(1.00, 0.78, 0.60);
    vec3 white = vec3(1.00, 0.97, 0.92);
    vec3 cool = vec3(0.72, 0.83, 1.00);
    vec3 tint = (temp < 0.5)
        ? mix(warm, white, temp * 2.0)
        : mix(white, cool, (temp - 0.5) * 2.0);

    tint = mix(tint, cool, isBright * 0.35);

    return tint * (prof * mag);
}

vec3 RenderStars(vec3 worldDir, mat3 celestialM, float twinkleTime) {
    vec3 dir = normalize(celestialM * normalize(worldDir));

    vec3 p = dir * STARS_SCALE;
    vec3 cell = floor(p);

    vec3 rnd = starsHash33(cell);
    vec3 offset = (rnd - 0.5) * (2.0 * STARS_OFFSET);
    vec3 starDir = normalize(cell + 0.5 + offset);

    vec3 c = starsCell(cell, starDir, dir, twinkleTime);

    return c * STARS_INTENSITY;
}

float StarsNightFade(float sunElev) {
    return 1.0 - smoothstep(STARS_FADE_SUNRISE, STARS_FADE_SUNSET, sunElev);
}

float StarsHorizonFade(float worldY) {
    float airmass = 1.0 / max(worldY, 0.015);
    return exp(-STARS_HORIZON_FADE * (airmass - 1.0));
}

#endif
