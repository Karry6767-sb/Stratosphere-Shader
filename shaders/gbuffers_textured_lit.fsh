#version 430 compatibility

/* RENDERTARGETS: 0,1,2 */

#include "/lib/options_defaults.glsl"
#include "/lib/volumetric/flash_list.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef = 0.1;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform vec4 entityColor;
uniform vec3 cameraPosition;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 worldAbsPos;
flat in float entityCode;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
vec4 tex = texture(gtexture, texcoord) * glcolor;

#if VL_FLASH == 1
if (entityCode > 1000.5 && entityCode < 1003.5) {
float distToCam = length(worldAbsPos - cameraPosition);
if (distToCam < VL_FLASH_MAX_DIST) {
float pulse = 0.65 + 0.35 * sin(frameTimeCounter * 18.0);
float creeperGate = (entityCode > 1001.5 && entityCode < 1002.5)
                  ? clamp(entityColor.a, 0.0, 1.0) : 1.0;
float intensity = VL_FLASH_GAIN * 8.0 * pulse * creeperGate;
if (intensity > 1.0e-4) {
VolumetricRegisterFlash(worldAbsPos, vec3(1.0, 0.78, 0.45),
                        intensity,
                        frameTimeCounter + VL_FLASH_LIFETIME);
}
}
}
#endif

if (tex.a < alphaTestRef) {
discard;
}

color = vec4(tex.rgb, 1.0);
lightmapData = vec4(lmcoord, 0.0, 1.0);
encodedNormal = vec4(normal * 0.5 + 0.5, 0.0);
}
