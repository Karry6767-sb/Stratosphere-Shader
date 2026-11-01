#ifndef LIB_VOLUMETRIC_FLASH_GLSL
#define LIB_VOLUMETRIC_FLASH_GLSL

#include "/lib/options_defaults.glsl"
#include "/lib/volumetric/point_light.glsl"
#include "/lib/volumetric/flash_list.glsl"

vec3 VolumetricFlashEventsScatter(vec3 originWorld, vec3 rayDirWorld,
                                  float rayEndDist, float now, float sigmaS) {
#if VL_FLASH == 0
    return vec3(0.0);
#else
    vec3 acc = vec3(0.0);
    for (int i = 0; i < VL_FLASH_MAX; ++i) {
        vec4 state = vlFlashes.states[i];
        vec4 style = vlFlashes.colors[i];
        float remaining = state.w - now;
        if (remaining <= 0.0 || style.a <= 0.0) continue;

        float age = max(VL_FLASH_LIFETIME - remaining, 0.0);
        float fade = exp(-age * VL_FLASH_DECAY);
        vec3 flashColor = style.rgb * (style.a * fade);
        if (max(flashColor.r, max(flashColor.g, flashColor.b)) <= 1.0e-5) continue;

        acc += PointLightAnalyticScatter(originWorld, rayDirWorld, rayEndDist,
                                         state.xyz, flashColor, sigmaS);
    }
    return acc;
#endif
}

vec3 VolumetricFlashEventsGlow(vec3 originWorld, float now) {
#if VL_FLASH == 0
    return vec3(0.0);
#else
    vec3 acc = vec3(0.0);
    for (int i = 0; i < VL_FLASH_MAX; ++i) {
        vec4 state = vlFlashes.states[i];
        vec4 style = vlFlashes.colors[i];
        float remaining = state.w - now;
        if (remaining <= 0.0 || style.a <= 0.0) continue;
        float age = max(VL_FLASH_LIFETIME - remaining, 0.0);
        float fade = exp(-age * VL_FLASH_DECAY);
        float dist2 = dot(state.xyz - originWorld, state.xyz - originWorld);
        acc += max(style.rgb, vec3(0.0))
             * (style.a * fade * 0.008 / (1.0 + dist2 * 0.02));
    }
    return acc;
#endif
}

vec3 VolumetricLightningPointScatter(vec3 originWorld, vec3 rayDirWorld,
                                     float rayEndDist, vec4 bolt, float sigmaS) {
#if VL_FLASH == 0
    return vec3(0.0);
#else
    if (bolt.w <= 0.0) return vec3(0.0);
    float dist2 = dot(bolt.xyz - originWorld, bolt.xyz - originWorld);
    float intensity = min(120.0 / (1.0 + dist2 * 0.002), 12.0);
    vec3 color = vec3(0.60, 0.78, 1.0) * (VL_FLASH_GAIN * intensity);
    return PointLightAnalyticScatter(originWorld, rayDirWorld, rayEndDist,
                                     bolt.xyz, color, sigmaS);
#endif
}

#endif
