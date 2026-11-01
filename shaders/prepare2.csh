#version 430

#include "/lib/options_defaults.glsl"

#define ATM_LUT_IMAGE_ATM_DECL
layout(rgba16f) uniform image2D uimg_atm;

#include "/lib/atmosphere/lut_skyview.glsl"
#include "/lib/atmosphere/adaptive_sky_gain.glsl"

uniform vec3 sunPosition;
uniform int worldTime;
uniform mat4 gbufferModelViewInverse;

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(12, 12, 1);

void main() {
    ivec2 id = ivec2(gl_GlobalInvocationID.xy);
    if (id.x >= 192 || id.y >= 192) return;

    vec2 skyUV = (vec2(id) + 0.5) / 192.0;

    float lightViewCos = 1.0 - 2.0 * skyUV.x;
    float height = ATM_PLANET_R + AtmosphereCameraAltitude();
    float vHorizon = sqrt(max(height * height - ATM_PLANET_R * ATM_PLANET_R, 0.0));
    float beta = acos(clamp(vHorizon / height, -1.0, 1.0));
    float zenithHorizon = PI - beta;

    float viewZenithCos;
    if (skyUV.y < 0.5) {
        float c = 1.0 - 2.0 * skyUV.y;
        c *= c;
        viewZenithCos = cos(zenithHorizon * (1.0 - c));
    } else {
        float c = skyUV.y * 2.0 - 1.0;
        c *= c;
        viewZenithCos = cos(zenithHorizon + beta * c);
    }

    float s = sqrt(max(1.0 - viewZenithCos * viewZenithCos, 0.0));
    vec3 rayDir = normalize(vec3(s * lightViewCos, viewZenithCos,
                                 s * sqrt(max(1.0 - lightViewCos * lightViewCos, 0.0))));

    vec3 sunDirW = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
    float sy = clamp(sunDirW.y, -1.0, 1.0);
    vec3 sunDir = normalize(vec3(sqrt(max(1.0 - sy * sy, 0.0)), sy, 0.0));
    vec3 viewPos = vec3(0.0, height, 0.0);

#if ATM_DEBUG_MSLUT == 1
    float rDbg = length(viewPos);
    float muSunDbg = dot(rayDir, sunDir);
    vec3 msDbg = atmReadMultiScatteringImage(rDbg, muSunDbg);
    imageStore(uimg_atm, id, vec4(msDbg, 1.0));
    return;
#else
    vec3 lum = atmSolarRGB() * atmRaymarchScatteringRGB(viewPos, rayDir, sunDir);
    float skyGain = ATM_SKY_RADIANCE_SCALE * atmAdaptiveSkyRadianceGain(worldTime);
    vec3 rgb = max(lum * ATM_EXPOSURE * skyGain, vec3(0.0));

    if (any(isnan(rgb)) || any(isinf(rgb))) rgb = vec3(0.0);
    imageStore(uimg_atm, id, vec4(rgb, 1.0));
#endif
}
