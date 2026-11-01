#version 330 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/taa_jitter.glsl"

uniform mat4 gbufferModelViewInverse;

in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;
out vec3 normalWorld;
flat out float glassMat;

void main() {
        gl_Position = ftransform();
        gl_Position = ApplyTaaJitter(gl_Position);
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;

        vec3 viewNormal = gl_NormalMatrix * gl_Normal;
        float nlen = length(viewNormal);
        normalWorld = (nlen > 1.0e-5)
                    ? normalize(mat3(gbufferModelViewInverse) * viewNormal)
                    : vec3(0.0, 1.0, 0.0);

        glassMat = (abs(mc_Entity.x - 10008.0) < 0.5) ? 0.30
                 : (abs(mc_Entity.x - 10080.0) < 0.5) ? 0.15
                 : 0.0;
}
