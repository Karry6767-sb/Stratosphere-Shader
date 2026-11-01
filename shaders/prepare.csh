#version 430

#include "/lib/options_defaults.glsl"

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/lut_common.glsl"

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(16, 4, 1);

layout(rgba16f) uniform image2D uimg_atm;

void main() {
    ivec2 id = ivec2(gl_GlobalInvocationID.xy);
    if (id.x >= ATM_TLUT_W || id.y >= ATM_TLUT_H) return;

    ivec2 dst = ivec2(id.x, id.y + (256 - ATM_TLUT_H));
    if (imageLoad(uimg_atm, dst).a > 0.0) return;

    vec2 uv = (vec2(id) + 0.5) / vec2(float(ATM_TLUT_W), float(ATM_TLUT_H));
    float r, mu;
    atmUvToTransmittanceParams(r, mu, uv);
    vec4 T = atmBakeTransmittance(r, mu);
    imageStore(uimg_atm, dst, T);
}
