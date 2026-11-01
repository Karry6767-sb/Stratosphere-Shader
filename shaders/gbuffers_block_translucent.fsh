#version 330 compatibility

/* RENDERTARGETS: 0,9,10 */

#include "/lib/options_defaults.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;
in vec3 normalWorld;
flat in float glassMat;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 waterMask;
layout(location = 2) out vec4 glassData;

void main() {
        vec4 tex = texture(gtexture, texcoord) * glcolor;

        if (tex.a < alphaTestRef) {
                discard;
        }

        if ((GLASS_ENABLED == 1) && (glassMat > 0.05)) {
                color = vec4(0.0, 0.0, 0.0, 0.0);
                vec3 n = normalWorld;
                float nlen = length(n);
                n = (nlen > 1.0e-5) ? (n / nlen) : vec3(0.0, 1.0, 0.0);
                waterMask = vec4(n * 0.5 + 0.5, 0.0);
                glassData = vec4(tex.rgb, glassMat);
        } else {
                color = vec4(tex.rgb, tex.a);
                waterMask = vec4(0.0);
                glassData = vec4(0.0);
        }
}
