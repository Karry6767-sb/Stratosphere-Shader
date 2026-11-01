#version 330 compatibility

/* DRAWBUFFERS: 0 */

#include "/lib/options_defaults.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;
in vec2 lmcoord;
flat in float isWaterSurface;

layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < 0.1) {
		discard;
	}

	if (isWaterSurface > 0.5) {
		color.a = 0.15;
		color.rgb *= clamp(glcolor.rgb, vec3(0.0), vec3(1.0));
		return;
	}
}
