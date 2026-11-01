#version 330 compatibility

/* RENDERTARGETS: 0 */

#include "/lib/options_defaults.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
vec4 tex = texture(gtexture, texcoord) * glcolor;

vec2 lm = texture(lightmap, lmcoord).rg;
float lightningLight = clamp(max(lm.r, lm.g), 0.0, 1.0);
float emissive = VL_LIGHTNING_EMISSIVE_BASE + lightningLight * VL_LIGHTNING_EMISSIVE;

vec3 boltCore = vec3(0.72, 0.84, 1.0);
vec3 emissiveRGB = tex.rgb * (1.0 + emissive)
                 + boltCore * (emissive * 0.22 * tex.a);

color = vec4(emissiveRGB, tex.a);
if (color.a < alphaTestRef) {
discard;
}
}
