#version 330 compatibility

/* RENDERTARGETS: 0,11 */

#include "/lib/options_defaults.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;

in vec2 texcoord;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ssrSource;

void main() {
	vec4 c = texture(colortex0, texcoord);
	color = c;
	ssrSource = vec4(c.rgb, texture(colortex2, texcoord).a);
}
