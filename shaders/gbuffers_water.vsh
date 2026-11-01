#version 330 compatibility

#include "/lib/options_defaults.glsl"
#include "/lib/taa_jitter.glsl"
#include "/lib/water/waves.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec4 mc_Entity;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldPos;
out vec3 flatNormal;
out vec2 wavePlane;
flat out float isWater;
flat out float glassMat;

void main() {
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    vec4 viewPos = gbufferModelView * gl_Vertex;
    vec3 wp = (gbufferModelViewInverse * viewPos).xyz;

    vec3 viewN = gl_NormalMatrix * gl_Normal;
    float nlen = length(viewN);
    flatNormal = (nlen > 1.0e-5)
               ? normalize(mat3(gbufferModelViewInverse) * viewN)
               : vec3(0.0, 1.0, 0.0);

    float matId = mc_Entity.x;
    isWater = (abs(matId - 10001.0) < 0.5) ? 1.0 : 0.0;
    glassMat = (abs(matId - 10008.0) < 0.5) ? 0.30
             : (abs(matId - 10080.0) < 0.5) ? 0.15
             : 0.0;

    if (WTR_ENABLED == 1 && isWater > 0.5 && abs(flatNormal.y) > 0.9) {
        vec3 absPos = wp + cameraPosition;
        float h0 = WtrGeometryHeight(absPos.xz, frameTimeCounter);
        absPos.y += h0 * WTR_DISP_AMP;
        wp = absPos - cameraPosition;

        const float e = 0.5;
        float hx = WtrGeometryHeight(absPos.xz + vec2(e, 0.0), frameTimeCounter);
        float hz = WtrGeometryHeight(absPos.xz + vec2(0.0, e), frameTimeCounter);
        flatNormal = normalize(vec3(-(hx - h0) / e * WTR_DISP_AMP,
                                    1.0,
                                    -(hz - h0) / e * WTR_DISP_AMP));
    }

    viewPos = gbufferModelView * vec4(wp, 1.0);
    gl_Position = gl_ProjectionMatrix * viewPos;
    gl_Position = ApplyTaaJitter(gl_Position);

    worldPos = wp;
    wavePlane = WtrWavePlane(wp + cameraPosition, flatNormal);
}
