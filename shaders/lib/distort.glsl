#ifndef LIB_DISTORT_GLSL
#define LIB_DISTORT_GLSL

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;
const int shadowMapResolution = 2048; // [512 1024 2048 4096]
const float shadowDistanceRenderMul = 1.0;

#ifndef SHADOW_DISTORT_FACTOR
#define SHADOW_DISTORT_FACTOR 0.9
#endif

vec2 ShadowDistortFactor(vec2 clip_xy) {
	return mix(vec2(1.0), abs(clip_xy), SHADOW_DISTORT_FACTOR);
}

vec3 distortShadowClipPos(vec3 shadowClipPos) {
	shadowClipPos.xy /= ShadowDistortFactor(shadowClipPos.xy);
	shadowClipPos.z *= SHADOW_Z_COMPRESS;
	return shadowClipPos;
}

#endif
