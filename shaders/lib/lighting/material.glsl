#ifndef LIB_LIGHTING_MATERIAL_GLSL
#define LIB_LIGHTING_MATERIAL_GLSL

float DecodeMaterialCode(float packedMat) {
    return floor(packedMat * 10.0 + 0.5);
}

vec3 DecodePBRMaterial(float packedMat, vec3 albedo) {
    float c = DecodeMaterialCode(packedMat);
    float roughness = 0.80;
    float metalness = 0.0;
    float sss = 0.0;
    if (c > 0.5 && c < 1.5) {
        roughness = 0.25;
        metalness = 1.0;
    } else if (c > 1.5 && c < 2.5) {
        roughness = 0.30;
    } else if (c > 2.5 && c < 3.5) {
        roughness = 0.10;
    } else if (c > 3.5 && c < 4.5) {
        roughness = 0.95;
        sss = 1.0;
    }
    return vec3(roughness, metalness, sss);
}

#endif
