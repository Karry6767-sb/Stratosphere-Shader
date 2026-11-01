#version 430

#include "/lib/options_defaults.glsl"

#define ATM_LUT_IMAGE_ATM_DECL
layout(rgba16f) uniform image2D uimg_atm;

#include "/lib/atmosphere/lut_aerial.glsl"
#include "/lib/atmosphere/adaptive_sky_gain.glsl"

uniform vec3 sunPosition;
uniform int worldTime;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float near;
uniform float far;

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(4, 12, 1);

void main() {
    ivec2 local = ivec2(gl_GlobalInvocationID.xy);
    if (local.x >= ATM_AP_W || local.y >= ATM_AP_H) return;

    int slice;
    ivec2 bin;
    atmDecodeAerialAtlas(local, slice, bin);

    vec2 screenUV = (vec2(bin) + 0.5) / float(ATM_AP_BINS);

    vec4 clip = gbufferProjectionInverse * vec4(screenUV * 2.0 - 1.0, 1.0, 1.0);
    vec3 viewDir = normalize(clip.xyz / max(clip.w, 1.0e-6));
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewDir);

    vec3 sunDirW = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
    vec3 camPosKm = AtmosphereCameraPosition();

    float nearKm = max(near * ATM_M_TO_KM, 1.0e-4);
    float farKm  = max(far  * ATM_M_TO_KM, nearKm * 1.001);
    float distKm = atmAerialSliceDistance(nearKm, farKm, slice);

    float transmittance;
    vec3 lum = atmRaymarchAerialPerspectiveRGB(camPosKm, worldDir, sunDirW,
                                               distKm, transmittance);

    float skyGain = ATM_SKY_RADIANCE_SCALE * atmAdaptiveSkyRadianceGain(worldTime);
    vec3 inscatter = max(atmSolarRGB() * lum * ATM_EXPOSURE * skyGain, vec3(0.0));
    imageStore(uimg_atm,
               ivec2(ATM_AP_X_OFFSET + local.x, local.y),
               vec4(inscatter, clamp(transmittance, 0.0, 1.0)));
}
