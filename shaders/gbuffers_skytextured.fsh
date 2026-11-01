#version 330 compatibility

/* RENDERTARGETS: 0 */

#include "/lib/options_defaults.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferProjectionInverse;
uniform vec3 sunPosition;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

void main() {
	vec3 vd = normalize(screenToView(
		vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0)));
	vec3 sd = normalize(sunPosition);
	if (dot(vd, sd) > 0.0) {
		discard;
	}
	if (dot(vd, -sd) > 0.0) {
		discard;
	}

	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}
}
