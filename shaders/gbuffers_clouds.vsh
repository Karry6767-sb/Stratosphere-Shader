#version 330 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/taa_jitter.glsl"

out vec2 texcoord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
        gl_Position = ApplyTaaJitter(gl_Position);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}
