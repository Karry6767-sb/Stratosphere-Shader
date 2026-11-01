#ifndef LIB_LIGHTING_AURORA_GI_GLSL
#define LIB_LIGHTING_AURORA_GI_GLSL

#include "/lib/sky/aurora.glsl"

vec3 AuroraGroundIrradiance(vec3 normal, vec3 albedo, float auroraAmount, float moonReference) {
#if AURORA_GROUND_LIGHT == 0
    return vec3(0.0);
#else
    if (auroraAmount <= 0.001) return vec3(0.0);

    vec3 north = AuroraNorthAxis();
    vec3 arcDir = normalize(north * 0.82 + vec3(0.0, 0.57, 0.0));

    vec3 tint = AuroraLineColor(AuroraAltitudeProfile(145.0));

    float hemi = 0.5 + 0.5 * clamp(dot(normal, arcDir), -1.0, 1.0);
    float upFace = smoothstep(0.05, 0.55, normal.y);
    float albedoLuma = dot(albedo, vec3(0.2126, 0.7152, 0.0722));
    float snowMask = smoothstep(0.55, 0.85, albedoLuma);

    float physicalCap = moonReference * 0.03
                      * clamp(AURORA_GROUND_STRENGTH, 0.0, 1.0);
    return tint * physicalCap * auroraAmount * hemi * upFace * snowMask;
#endif
}

#endif
