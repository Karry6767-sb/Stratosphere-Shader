#version 430 compatibility

#include "/lib/options_defaults.glsl"
#include "/lib/taa_jitter.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int entityId;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 worldAbsPos;
flat out float entityCode;

void main() {
gl_Position = ftransform();
gl_Position = ApplyTaaJitter(gl_Position);

texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
glcolor = gl_Color;
lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);

normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);

vec4 entityViewPos = gl_ModelViewMatrix * gl_Vertex;
vec3 entityWorldRel = (gbufferModelViewInverse * entityViewPos).xyz;
worldAbsPos = entityWorldRel + cameraPosition;
entityCode = float(entityId);
}
