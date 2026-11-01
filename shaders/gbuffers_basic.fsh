#version 330 compatibility

/* RENDERTARGETS: 0 */

#include "/lib/options_defaults.glsl"

uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
        vec4 c = glcolor * texture(lightmap, lmcoord);

        if (c.a < alphaTestRef) {
                discard;
        }

        color = vec4(c.rgb, 1.0);
}
