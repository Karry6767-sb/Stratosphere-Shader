// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_SKY_SH_GLSL
#define LIB_ATMOSPHERE_SKY_SH_GLSL

#include "/lib/atmosphere/geometry.glsl"

#ifndef SKY_SH_DATA_DECLARED
#define SKY_SH_DATA_DECLARED
layout(std430, binding = 1) buffer SkySHData {
    vec3 coeffs[9];
    vec3 upIrradiance;
    vec3 downIrradiance;
} skyEnv;
#endif

void SkySHBasis(vec3 d, out float b[9]) {
    b[0] = 0.2820947918;
    b[1] = 0.4886025119 * d.y;
    b[2] = 0.4886025119 * d.z;
    b[3] = 0.4886025119 * d.x;
    b[4] = 1.0925484306 * d.x * d.y;
    b[5] = 1.0925484306 * d.y * d.z;
    b[6] = 0.3153915653 * (3.0 * d.z * d.z - 1.0);
    b[7] = 1.0925484306 * d.x * d.z;
    b[8] = 0.5462742153 * (d.x * d.x - d.y * d.y);
}

vec3 SkySHReconstruct(vec3 c[9], vec3 d) {
    float b[9];
    SkySHBasis(d, b);
    return c[0] * b[0]
         + c[1] * b[1] + c[2] * b[2] + c[3] * b[3]
         + c[4] * b[4] + c[5] * b[5] + c[6] * b[6] + c[7] * b[7] + c[8] * b[8];
}

vec3 SkySHConvolved(vec3 c[9], vec3 d) {
    float b[9];
    SkySHBasis(d, b);
    const float A1 = 2.0 / 3.0;
    const float A2 = 0.25;
    return c[0] * b[0]
         + A1 * (c[1] * b[1] + c[2] * b[2] + c[3] * b[3])
         + A2 * (c[4] * b[4] + c[5] * b[5] + c[6] * b[6] + c[7] * b[7] + c[8] * b[8]);
}

vec3 SkySHIrradiance(vec3 c[9], vec3 n) {
    return PI * SkySHConvolved(c, n);
}

vec3 SkySHGlobalIrradiance(vec3 n) {
    return PI * SkySHConvolved(skyEnv.coeffs, n);
}

vec3 SkySHWorldToProbe(vec3 worldDir, vec3 sunDirWorld) {
    vec3 n = normalize(worldDir);
    vec3 s = normalize(sunDirWorld);
    float h = length(s.xz);
    if (h < 1.0e-5) return n;

    float c  = s.x / h;
    float ss = s.z / h;
    mat3 R = mat3(vec3(-ss, 0.0, c),
                  vec3( 0.0, 1.0, 0.0),
                  vec3(  c, 0.0, ss));
    return R * n;
}

#endif
