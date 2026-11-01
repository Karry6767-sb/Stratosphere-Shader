#version 430 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/exposure_data.glsl"
#include "/lib/atmosphere/sky_lut.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float viewWidth, viewHeight;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;

layout(local_size_x = 256) in;
const ivec3 workGroups = ivec3(8, 8, 1);

shared uint sharedHist[HISTOGRAM_BIN_COUNT];
shared float sharedAmbient;

void main() {
    uint tid = gl_LocalInvocationIndex;
    uint wid = uint(gl_WorkGroupID.y * 8 + gl_WorkGroupID.x);

    ivec2 size = ivec2(viewWidth, viewHeight);
    uint totalPixels = uint(size.x) * uint(size.y);
    uint pixelsPerGroup = (totalPixels + 63u) / 64u;
    uint start = wid * pixelsPerGroup;
    uint end = min(start + pixelsPerGroup, totalPixels);

    for (uint i = tid; i < uint(HISTOGRAM_BIN_COUNT); i += 256u) {
        sharedHist[i] = 0u;
    }
    barrier();

    float highlightLum = 0.18 * exp2(EXPOSURE_HIGHLIGHT_EV);

    vec3 sunDirW = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));

    if (tid == 0u) {
        float alt = AtmosphereCameraAltitude();
        float amb = 0.0;
        amb += dot(max(atmSampleSkyView(vec3(0.0, 1.0, 0.0), sunDirW, ATM_PLANET_R, alt), vec3(0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
        amb += dot(max(atmSampleSkyView(normalize(vec3( 0.60, 0.60, 0.0)),  sunDirW, ATM_PLANET_R, alt), vec3(0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
        amb += dot(max(atmSampleSkyView(normalize(vec3(-0.60, 0.60, 0.0)),  sunDirW, ATM_PLANET_R, alt), vec3(0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
        amb += dot(max(atmSampleSkyView(normalize(vec3( 0.0, 0.60, 0.60)),  sunDirW, ATM_PLANET_R, alt), vec3(0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
        amb += dot(max(atmSampleSkyView(normalize(vec3( 0.0, 0.60,-0.60)),  sunDirW, ATM_PLANET_R, alt), vec3(0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
        sharedAmbient = amb * 0.2;
    }
    barrier();
    float ambient = sharedAmbient;

    if (gl_GlobalInvocationID.x == 0u && gl_GlobalInvocationID.y == 0u) {
        ambientLum = ambient;
    }

    float nightAmt = 1.0 - smoothstep(EXPOSURE_NIGHT_AMBIENT * 0.2,
                                      EXPOSURE_NIGHT_AMBIENT * 2.0,
                                      max(ambient, 1.0e-6));

    for (uint i = start + tid; i < end; i += 256u) {
        ivec2 pos = ivec2(int(i % uint(size.x)), int(i / uint(size.x)));
        vec2 uv = (vec2(pos) + 0.5) / vec2(size);

        float skyMask = (texture(depthtex0, uv).r >= 1.0) ? 1.0 : 0.0;

        float skyWeight = mix(EXPOSURE_SKY_WEIGHT,
                              max(EXPOSURE_SKY_WEIGHT, EXPOSURE_SKY_WEIGHT_NIGHT),
                              nightAmt);
        float weight = mix(1.0, skyWeight, skyMask);

        vec3 c = max(texture(colortex0, uv).rgb, vec3(0.0));
        float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));

        if (weight <= 0.0) continue;
        if (lum > highlightLum) continue;

        uint w = uint(clamp(weight * 255.0 + 0.5, 0.0, 255.0));
        if (w == 0u) continue;

        uint bin = uint(floor(exposureLumToBin(lum) + 0.5));
        atomicAdd(sharedHist[bin], w);
    }
    barrier();

    for (uint i = tid; i < uint(HISTOGRAM_BIN_COUNT); i += 256u) {
        if (sharedHist[i] > 0u) {
            atomicAdd(histogram[i], sharedHist[i]);
        }
    }
}
