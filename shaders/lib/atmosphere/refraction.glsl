// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_REFRACTION_GLSL
#define LIB_ATMOSPHERE_REFRACTION_GLSL

#include "/lib/atmosphere/options.glsl"

vec3 atmApplyRefraction(vec3 dir, float amount) {
#if ATM_REFRACTION == 1
    dir = normalize(dir);
    float h = asin(clamp(dir.y, -1.0, 1.0));
    float r = amount * exp(-max(h, 0.0) / 0.15);
    float s = sin(r), c = cos(r);
    vec2 xz = vec2(dir.x, dir.z);
    float len = length(xz);
    if (len < 1.0e-5) return dir;
    xz /= len;
    return normalize(vec3(xz.x * c, dir.y * c + s, xz.y * c));
#else
    return dir;
#endif
}

#endif
