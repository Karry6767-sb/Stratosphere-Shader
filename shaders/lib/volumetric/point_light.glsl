#ifndef LIB_VOLUMETRIC_POINT_LIGHT_GLSL
#define LIB_VOLUMETRIC_POINT_LIGHT_GLSL

#include "/lib/options_defaults.glsl"

#ifndef INV_FOUR_PI
#define INV_FOUR_PI 0.07957747154594767
#endif

vec3 PointLightAnalyticScatter(vec3 originWorld, vec3 rayDirWorld,
                               float rayEndDist, vec3 lightPosWorld,
                               vec3 lightColor, float sigmaS) {
    vec3 d = normalize(rayDirWorld);
    vec3 L = lightPosWorld - originWorld;
    float lightDist = length(L);
    if (lightDist > VL_MAX_DIST || lightDist < 1.0e-5) return vec3(0.0);
    if (rayEndDist <= 0.0 || sigmaS <= 0.0) return vec3(0.0);

    float c = dot(L, L);
    float b = -dot(d, L);
    float tClosest = -b;

    if (tClosest > rayEndDist) return vec3(0.0);

    float minR2 = VL_POINT_MIN_RADIUS * VL_POINT_MIN_RADIUS;
    float h2 = max(c - b * b, minR2);
    float invH = inversesqrt(h2);

    float t0 = 0.0;
    float t1 = rayEndDist;
    if (t1 <= t0) return vec3(0.0);

    float integral = invH * (atan((t1 + b) * invH) - atan((t0 + b) * invH));
    integral = max(integral, 0.0);

    float sigmaT = max(sigmaS, 1.0e-4);
    float transmittance = exp(-sigmaT * 0.5 * (t0 + t1));

    return lightColor * sigmaS * transmittance * integral * INV_FOUR_PI;
}

#endif
