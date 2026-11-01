#version 430

#include "/lib/options_defaults.glsl"

#define ATM_LUT_IMAGE_MSLUT_DECL
layout(rgba16f) uniform image2D uimg_mslut;

#include "/lib/atmosphere/lut_multiscatter.glsl"

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(2, 2, 1);

void main() {
    ivec2 id = ivec2(gl_GlobalInvocationID.xy);
    if (id.x >= ATM_MSLUT_SIZE || id.y >= ATM_MSLUT_SIZE) return;

    if (imageLoad(uimg_mslut, id).a > 0.0) return;

    vec2 uv = (vec2(id) + 0.5) / float(ATM_MSLUT_SIZE);
    float cosTheta = uv.x * 2.0 - 1.0;
    float height = mix(ATM_PLANET_R, ATM_ATMO_R, uv.y);
    vec3 rayPos = vec3(0.0, height, 0.0);
    vec3 sunDir = normalize(vec3(0.0, cosTheta,
                                 sqrt(max(1.0 - cosTheta * cosTheta, 0.0))));

    vec3 lum = vec3(0.0);
    vec3 fms = vec3(0.0);
    for (int i = 0; i < ATM_MSLUT_DIRECTIONS; ++i) {
        float fi = (float(i) + 0.5) / float(ATM_MSLUT_DIRECTIONS);
        float cosT = 1.0 - 2.0 * fi;
        float sinT = sqrt(max(1.0 - cosT * cosT, 0.0));
        float phi = fi * 2.39996322972865332;
        vec3 dir = normalize(vec3(sinT * cos(phi), cosT, sinT * sin(phi)));

        mat2x3 res = atmRaymarchMultiScatteringRGB(rayPos, dir, sunDir);
        lum += res[0];
        fms += res[1];
    }

    float invN = 1.0 / float(ATM_MSLUT_DIRECTIONS);
    lum *= invN;

    fms = clamp(fms * invN, vec3(0.0), vec3(0.9));
    vec3 ms = lum / max(vec3(1.0) - fms, vec3(0.1));

    if (any(isnan(ms)) || any(isinf(ms))) ms = vec3(0.0);
    ms = clamp(ms, vec3(0.0), vec3(1.0e6));
    float valid = (dot(ms, vec3(1.0)) > 1.0e-12) ? 1.0 : 0.0;
    imageStore(uimg_mslut, id, vec4(ms, valid));
}
