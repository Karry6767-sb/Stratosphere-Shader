#version 330 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/taa_jitter.glsl"

#include "/lib/wind.glsl"
#ifndef PLANT_NORMAL_THRESHOLD
#define PLANT_NORMAL_THRESHOLD 0.55
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

in vec2 mc_midTexCoord;
in vec4 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

flat out float vegFlag;
flat out float materialId;

void main() {
	vec2 rawLight = gl_MultiTexCoord1.xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec3 worldRel = (gbufferModelViewInverse * viewPos).xyz;
	vec3 worldAbs = worldRel + cameraPosition;

	vec3 absN = abs(gl_Normal);
	float maxAbsN = max(absN.x, max(absN.y, absN.z));
	bool isPlant = maxAbsN < PLANT_NORMAL_THRESHOLD;

	bool isTop = gl_MultiTexCoord0.y < mc_midTexCoord.y;

	if (isPlant) {
		worldAbs += getPlantSway(worldAbs, isTop, 1.0);
	}

	vec3 worldRel2 = worldAbs - cameraPosition;
	gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(worldRel2, 1.0));
        gl_Position = ApplyTaaJitter(gl_Position);

	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;

    vegFlag = isPlant ? 1.0 : 0.0;
  materialId = mc_Entity.x;
}
