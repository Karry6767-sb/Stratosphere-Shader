#ifndef ATM_MOON_ANGULAR_RADIUS
#define ATM_MOON_ANGULAR_RADIUS 0.00452017
#endif

#ifndef ATM_SUN_ANGULAR_RADIUS
#define ATM_SUN_ANGULAR_RADIUS 0.00465116
#endif

#ifndef LIB_LIGHTING_TRANSPORT_GLSL
#define LIB_LIGHTING_TRANSPORT_GLSL

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"

const float TRANSPORT_EPS = 1.0e-6;

float capSolidAngle(float halfAngle) {
    return 2.0 * PI * (1.0 - cos(clamp(halfAngle, 0.0, PI)));
}

float capsIntersectSolidAngle(float alpha, float beta, float gamma) {
    alpha = clamp(alpha, 0.0, PI);
    beta  = clamp(beta,  0.0, PI);
    gamma = clamp(gamma, 0.0, PI);

    if (alpha >= PI - TRANSPORT_EPS) return capSolidAngle(beta);
    if (beta >= PI - TRANSPORT_EPS) return capSolidAngle(alpha);
    if (gamma >= PI - TRANSPORT_EPS) return 0.0;
    if (gamma >= alpha + beta - TRANSPORT_EPS) return 0.0;
    if (gamma <= abs(alpha - beta) + TRANSPORT_EPS)
        return capSolidAngle(min(alpha, beta));

    float sa = sin(alpha);
    float sb = sin(beta);
    float sg = sin(gamma);
    if (sa < TRANSPORT_EPS || sb < TRANSPORT_EPS || sg < TRANSPORT_EPS) return 0.0;

    float lambdaA = acos(clamp((cos(beta)  - cos(alpha) * cos(gamma)) / (sa * sg), -1.0, 1.0));
    float lambdaB = acos(clamp((cos(alpha) - cos(beta)  * cos(gamma)) / (sb * sg), -1.0, 1.0));
    float lambdaP = acos(clamp((cos(gamma) - cos(alpha) * cos(beta))  / (sa * sb), -1.0, 1.0));

    float omega = 2.0 * PI
                - 2.0 * (lambdaP
                       + lambdaA * cos(alpha)
                       + lambdaB * cos(beta));

    return clamp(omega, 0.0, capSolidAngle(min(alpha, beta)));
}

float sunVisibility(vec3 atmPosKm, vec3 dirToLight) {
    float r = length(atmPosKm);
    if (r < ATM_PLANET_R) return 0.0;

    float earthHalf = asin(clamp(ATM_PLANET_R / r, 0.0, 1.0));
    float lightHalf = ATM_SUN_ANGULAR_RADIUS;
    float lightOmega = capSolidAngle(lightHalf);
    if (lightOmega <= TRANSPORT_EPS) return 1.0;

    vec3 toCore = -atmPosKm / max(r, TRANSPORT_EPS);
    float gamma = acos(clamp(dot(toCore, dirToLight), -1.0, 1.0));

    float overlap = capsIntersectSolidAngle(lightHalf, earthHalf, gamma);
    return clamp((lightOmega - overlap) / lightOmega, 0.0, 1.0);
}

vec3 transportSunTint(vec3 atmPosKm, vec3 dirToLight, out float earthShadow) {
#if SUN_EARTH_SHADOW == 1
    earthShadow = sunVisibility(atmPosKm, dirToLight);
#else
    earthShadow = 1.0;
#endif

#if SUN_TRANSPORT == 1
    vec4 trans = max(atmTransmittanceToSun(atmPosKm, dirToLight), vec4(0.0));
    vec3 rgb   = max(SpectralToLinearSRGB(trans * ATM_SOLAR), vec3(0.0));
    vec3 ref   = max(SpectralToLinearSRGB(ATM_SOLAR), vec3(1.0e-4));
    return rgb / ref;
#else
    return vec3(1.0);
#endif
}

#endif
