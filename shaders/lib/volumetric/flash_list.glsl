#ifndef LIB_VOLUMETRIC_FLASH_LIST_GLSL
#define LIB_VOLUMETRIC_FLASH_LIST_GLSL

#include "/lib/options_defaults.glsl"

layout(std430, binding = VL_FLASH_SSBO_BINDING) buffer VLFlashData {
    vec4 states[VL_FLASH_MAX];
    vec4 colors[VL_FLASH_MAX];
} vlFlashes;

uint VolumetricFlashHash(vec3 worldPos) {
    ivec3 q = ivec3(floor(worldPos / 4.0 + 0.5));
    uvec3 uq = uvec3(q + ivec3(1048576));
    uint h = uq.x * 73856093u ^ uq.y * 19349663u ^ uq.z * 83492791u;
    h ^= h >> 13;
    h *= 1274126177u;
    h ^= h >> 16;
    return h % uint(VL_FLASH_MAX);
}

void VolumetricRegisterFlash(vec3 worldPos, vec3 color,
                             float intensity, float expiry) {
    uint slot = VolumetricFlashHash(worldPos);
    vlFlashes.states[slot] = vec4(worldPos, expiry);
    vlFlashes.colors[slot] = vec4(max(color, vec3(0.0)), max(intensity, 0.0));
}

#endif
