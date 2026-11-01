#version 430

#include "/lib/options_defaults.glsl"

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"
#include "/lib/atmosphere/sky_sh.glsl"

uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(1, 1, 1);

#ifndef SKY_SH_SAMPLES
#define SKY_SH_SAMPLES 64
#endif
shared vec3 skySHSum[SKY_SH_SAMPLES * 9];

void main() {
    uint tid = gl_LocalInvocationIndex;
    const uint N = uint(SKY_SH_SAMPLES);
    float b[9];
    vec3 sampleRGB = vec3(0.0);

    if (tid < N) {
        float fi   = float(tid) + 0.5;
        float cosT = 1.0 - 2.0 * fi / float(N);
        float sinT = sqrt(max(1.0 - cosT * cosT, 0.0));
        float phiS = fi * 2.39996322972865332;
        vec3 d = vec3(sinT * cos(phiS), cosT, sinT * sin(phiS));

        vec3 sunDirW = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
        if (d.y >= 0.0) {
            vec2 uv = SkyLUTUV(d, sunDirW, ATM_PLANET_R, AtmosphereCameraAltitude());
            sampleRGB = max(texture(usam_skylut, uv).rgb, vec3(0.0));
        }
        vec3 dProbe = SkySHWorldToProbe(d, sunDirW);
        SkySHBasis(dProbe, b);
    } else {
        for (int k = 0; k < 9; k++) b[k] = 0.0;
    }

    float weight = 4.0 * PI / float(N);
    for (int k = 0; k < 9; k++)
        skySHSum[k * SKY_SH_SAMPLES + int(tid)] = sampleRGB * b[k] * weight;
    barrier();

    if (tid < 9u) {
        vec3 s = vec3(0.0);
        for (int j = 0; j < SKY_SH_SAMPLES; j++)
            s += skySHSum[int(tid) * SKY_SH_SAMPLES + j];
        skyEnv.coeffs[int(tid)] = s;
    }
    barrier();

    if (tid < 2u) {
        vec3 n = (tid == 0u) ? vec3(0.0, 1.0, 0.0) : vec3(0.0, -1.0, 0.0);
        vec3 E = SkySHIrradiance(skyEnv.coeffs, n);
        if (tid == 0u) skyEnv.upIrradiance   = E;
        else           skyEnv.downIrradiance = E;
    }
}
