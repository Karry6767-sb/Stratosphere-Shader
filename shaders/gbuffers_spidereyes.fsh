#version 330 compatibility

/* RENDERTARGETS: 0 */

#include "/lib/options_defaults.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
        vec4 c = texture(gtexture, texcoord) * glcolor;
        if (c.a < alphaTestRef) {
                discard;
        }
        color = vec4(c.rgb, 1.0);
}
