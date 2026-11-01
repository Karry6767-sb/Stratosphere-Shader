#ifndef LIB_LIGHTING_SPECULAR_GLSL
#define LIB_LIGHTING_SPECULAR_GLSL

#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/material.glsl"

bool IsSpecularMaterial(float matCode) {
    return matCode > 0.5 && matCode < 3.5;
}

float SpecularRoughness(float matCode) {
    if (matCode > 0.5 && matCode < 1.5) return 0.25;
    if (matCode > 1.5 && matCode < 2.5) return 0.30;
    if (matCode > 2.5 && matCode < 3.5) return 0.10;
    return 1.0;
}

vec3 SpecularF0(vec3 albedo, float matCode) {
    bool isMetal = (matCode > 0.5 && matCode < 1.5);
    return isMetal ? albedo : vec3(0.04);
}

vec3 simpleSpecular(vec3 albedo, float matCode, vec3 N, vec3 V, vec3 L,
                    vec3 lightRadiance, float strength) {
    float NoL = max(dot(N, L), 0.0);
    if (NoL <= 1.0e-5) return vec3(0.0);

    float NoV = max(dot(N, V), 1.0e-5);
    vec3  H   = normalize(V + L);
    float NoH = max(dot(N, H), 0.0);
    float VoH = max(dot(V, H), 0.0);

    float alpha = max(SpecularRoughness(matCode) * SpecularRoughness(matCode), 1.0e-3);
    vec3  f0    = SpecularF0(albedo, matCode);

    vec3  F   = BRDFFresnelSchlick(VoH, f0);
    float D   = BRDFDistributionGGX(NoH, alpha);
    float vis = BRDFVisibilitySmithGGXCorrelated(NoV, NoL, alpha);

    vec3 spec = F * D * vis * NoL * lightRadiance * max(strength, 0.0);
    return min(spec, vec3(8.0));
}

#endif
