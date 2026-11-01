#version 330 compatibility

/* RENDERTARGETS: 0,9,10 */

#include "/lib/options_defaults.glsl"
#include "/lib/water/waves.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef = 0.1;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform int isEyeInWater;

uniform vec3 waterEnteredPosition;
uniform vec3 waterEnteredVelocity;
uniform float waterEnteredTime;
uniform vec3 waterExitedPosition;
uniform vec3 waterExitedVelocity;
uniform float waterExitedTime;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
in vec3 flatNormal;
in vec2 wavePlane;
flat in float isWater;
flat in float glassMat;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 waterData;
layout(location = 2) out vec4 waterTint;

vec2 WtrEntryExitSlope(vec3 absWorldPos) {
    vec3 eventPos;
    vec3 eventVel;
    float eventTime;

    if (isEyeInWater == 1) {
        eventPos = waterEnteredPosition;
        eventVel = waterEnteredVelocity;
        eventTime = waterEnteredTime;
    } else {
        eventPos = waterExitedPosition;
        eventVel = waterExitedVelocity;
        eventTime = waterExitedTime;
    }

    float age = frameTimeCounter - eventTime;
    if (age < 0.0 || age > 3.0) return vec2(0.0);

    vec2 delta = absWorldPos.xz - eventPos.xz;
    float dist = length(delta);
    float radius = age * 2.15 + 0.08;
    float band = exp(-pow((dist - radius) / 0.28, 2.0));
    float fade = exp(-age * 1.40);
    float strength = 0.3 * smoothstep(2.0, 20.0, length(eventVel)) + 0.5;
    vec2 dir = (dist > 1.0e-4) ? delta / dist : vec2(0.0);
    return dir * band * fade * strength * 0.025;
}

void main() {
    if (isWater < 0.5) {
        vec4 d = texture(gtexture, texcoord) * glcolor;
        if (d.a < alphaTestRef) discard;

        if (GLASS_ENABLED == 1 && glassMat > 0.05) {
            vec3 n = flatNormal;
            float nlen = length(n);
            n = (nlen > 1.0e-5) ? n / nlen : vec3(0.0, 1.0, 0.0);
            color = vec4(0.0);
            waterData = vec4(n * 0.5 + 0.5, 0.0);
            waterTint = vec4(d.rgb, glassMat);
        } else {
            color = vec4(d.rgb, d.a);
            waterData = vec4(0.0);
            waterTint = vec4(0.0);
        }
        return;
    }

    vec3 geoN = normalize(flatNormal);
    vec3 n;

    if (abs(geoN.y) > 0.9) {
        n = WtrWaveNormal(wavePlane, length(worldPos), frameTimeCounter);

        n = normalize(n + (geoN - vec3(0.0, 1.0, 0.0)) * 0.18);

        if (isEyeInWater == 1) n = -n;

        vec2 interaction = WtrEntryExitSlope(worldPos + cameraPosition);
        n = normalize(vec3(n.x + interaction.x, n.y, n.z + interaction.y));
    } else {
        vec3 w = WtrWaveNormal(wavePlane, length(worldPos), frameTimeCounter);
        vec3 tangentU;
        vec3 tangentV;
        if (abs(geoN.x) > 0.5) {
            tangentU = vec3(0.0, 0.0, 1.0);
            tangentV = vec3(0.0, 1.0, 0.0);
        } else {
            tangentU = vec3(1.0, 0.0, 0.0);
            tangentV = vec3(0.0, 1.0, 0.0);
        }
        n = normalize(geoN * w.y + tangentU * w.x + tangentV * w.z);
    }

    vec2 lm = texture(lightmap, lmcoord).rg;
    color = vec4(0.0);
    waterData = vec4(n * 0.5 + 0.5, 1.0);
    waterTint = vec4(clamp(glcolor.rgb, 0.0, 1.0), 0.5 + 0.5 * clamp(lm.g, 0.0, 1.0));
}
