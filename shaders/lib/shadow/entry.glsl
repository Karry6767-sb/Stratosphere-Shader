#ifndef LIB_SHADOW_COMMON_GLSL
#define LIB_SHADOW_COMMON_GLSL
#include "/lib/distort.glsl"

vec2 shadowDiskPoint(int i, int count) {
    float fi = float(i) + 0.5;
    float r = sqrt(fi / max(float(count), 1.0));
    float theta = fi * 2.399963229728653;
    return r * vec2(cos(theta), sin(theta));
}

vec2 shadowRotateDisk(vec2 point, mat2 rot) {
    return rot * point;
}

mat2 shadowRotation(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec3 getShadow(vec3 shadowScreenPos) {
    float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
    if (transparentShadow == 1.0) {
        return vec3(1.0);
    }
    float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);
    if (opaqueShadow == 0.0) {
        return vec3(0.0);
    }
    vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
    return shadowColor.rgb * (1.0 - shadowColor.a);
}

float getShadowOpaque(vec3 shadowScreenPos) {
    return step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);
}

vec4 getNoise(vec2 coord) {
    vec2 p = coord * 4096.0;
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    float r = fract((p3.x + p3.y) * p3.z);
    float g = fract((p3.y + p3.z) * p3.x);
    float b = fract((p3.z + p3.x) * p3.y);
    return vec4(r, g, b, 1.0);
}

float shadowDither() {
    return getNoise(texcoord + vec2(float(frameCounter & 63) * 0.017, 0.0)).r;
}

vec3 shadowWorldToScreenWithMatrix(mat4 shadowMV, vec3 worldPos) {
    vec3 shadowView = (shadowMV * vec4(worldPos, 1.0)).xyz;
    vec4 shadowClip = shadowProjection * vec4(shadowView, 1.0);
    vec3 distorted = distortShadowClipPos(shadowClip.xyz);
    return (distorted / shadowClip.w) * 0.5 + 0.5;
}

#endif
