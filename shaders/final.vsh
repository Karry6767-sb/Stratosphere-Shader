#version 430 compatibility

#include "/lib/options_defaults.glsl"

out vec2 texcoord;

void main() {
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
