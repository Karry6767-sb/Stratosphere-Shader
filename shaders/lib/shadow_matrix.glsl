#ifndef LIB_SHADOW_MATRIX_GLSL
#define LIB_SHADOW_MATRIX_GLSL

#include "/lib/celestial/light_state.glsl"

mat3 RotationFromTo(vec3 a, vec3 b) {
    vec3  v  = cross(a, b);
    float c  = dot(a, b);
    float s2 = dot(v, v);

    if (s2 > 1.0e-12) {
        mat3 K = mat3( 0.0,  v.z, -v.y,
                      -v.z,  0.0,  v.x,
                       v.y, -v.x,  0.0);
        return mat3(1.0) + K + K * K * ((1.0 - c) / s2);
    }

    if (c > 0.0) return mat3(1.0);

    vec3 axis = (abs(a.x) < 0.9) ? normalize(cross(a, vec3(1.0, 0.0, 0.0)))
                                 : normalize(cross(a, vec3(0.0, 1.0, 0.0)));
    return 2.0 * outerProduct(axis, axis) - mat3(1.0);
}

vec3 ShadowLightAxisW(vec3 sunDirW) {
    return normalize(sunDirW.y > 0.0 ? sunDirW : -sunDirW);
}

mat3 ShadowRotationFromActiveLight(vec3 sunDirW, vec3 moonDirW, int moonPhase) {
#if ENABLE_MOON_SHADOW == 0
    return mat3(1.0);
#else
    vec3 activeDir  = CelestialActiveDirW(sunDirW, moonDirW, moonPhase);
    vec3 shadowAxis = ShadowLightAxisW(sunDirW);
    return RotationFromTo(activeDir, shadowAxis);
#endif
}

#endif
