#version 330 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/distort.glsl"
#include "/lib/wind.glsl"

#ifndef PLANT_NORMAL_THRESHOLD
#define PLANT_NORMAL_THRESHOLD 0.55
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform int moonPhase;
uniform int worldDay;

#include "/lib/shadow/scene.glsl"

in vec2 mc_midTexCoord;
in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;
out vec2 lmcoord;
flat out float isWaterSurface;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	isWaterSurface = (mc_Entity.x - 10000.0 == 1.0) ? 1.0 : 0.0;

	vec3 rel = (shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;

	vec3 absPos = rel + cameraPosition;
	vec3 absN = abs(gl_Normal);
	float maxAbsN = max(absN.x, max(absN.y, absN.z));
	bool isPlant = maxAbsN < PLANT_NORMAL_THRESHOLD;
	bool isTop = gl_MultiTexCoord0.y < mc_midTexCoord.y;
	if (isPlant) {
		absPos += getPlantSway(absPos, isTop, 1.0);
	}
	rel = absPos - cameraPosition;

	rel = SceneShadowRotation() * rel;

	gl_Position = gl_ProjectionMatrix * (shadowModelView * vec4(rel, 1.0));
	gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}
