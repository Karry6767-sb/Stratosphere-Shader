#version 430 compatibility

/* RENDERTARGETS: 3,6 */

#include "/lib/options_defaults.glsl"

uniform sampler2D colortex7;
uniform sampler2D colortex14;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTime;

#include "/lib/motionblur.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ssilHistory;

void main() {
    vec2 fullSize = max(vec2(viewWidth, viewHeight), vec2(1.0));
    float depth = texture(depthtex0, texcoord).r;
    vec3 scene = texture(colortex7, texcoord).rgb;
    float blueNoise = texture(noisetex, gl_FragCoord.xy / 512.0).r;

    vec3 spatial = cameraSpatialEffects(texcoord, scene, depth,
                                        colortex7, depthtex0, fullSize,
                                        blueNoise, frameTime);

    color = vec4(spatial, 1.0);
    ssilHistory = texture(colortex14, texcoord);
}
