#version 330 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/taa_jitter.glsl"

out vec4 glcolor;

void main() {
	gl_Position = ftransform();
        gl_Position = ApplyTaaJitter(gl_Position);
	glcolor = gl_Color;
}
