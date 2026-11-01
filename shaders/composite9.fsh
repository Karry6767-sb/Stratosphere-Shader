#version 430 compatibility

/* RENDERTARGETS: 15 */

#include "/lib/options_defaults.glsl"

in vec2 texcoord;

#include "/lib/post.glsl"
#include "/lib/exposure_data.glsl"
#include "/lib/celestial/sun_flare.glsl"

uniform sampler2D usam_bloom;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
#if LUT_ENABLED
uniform sampler2D post_lut;
#endif

layout(location = 0) out vec4 color;

void main() {
    vec3 scene = texture(colortex3, texcoord).rgb;

    vec2 fullSize = max(vec2(viewWidth, viewHeight), vec2(1.0));
    vec2 bloomUV = bloomMipUV(0, texcoord, fullSize);
    vec3 bloomHalo = bloomChroma(usam_bloom, texcoord, bloomUV, fullSize);
    bloomHalo += bloomStreak(usam_bloom, texcoord, bloomUV, fullSize);

    vec3 combined = max(scene, 0.0) + bloomHalo * BLOOM_INTENSITY;

    float usedExposure;
#if EXPOSURE_ENABLED == 0 || EXPOSURE_MODE == 0
    usedExposure = exp2(-clamp(float(MANUAL_EV), -10.0, 10.0));
#else
    float autoExp = exposure;
    usedExposure = (autoExp > 0.0)
        ? autoExp
        : exp2(-clamp(float(MANUAL_EV), -10.0, 10.0));
#endif
    combined *= usedExposure;

    {
        vec3 sunDirView = normalize(sunPosition);
        vec3 sunDirW = normalize(mat3(gbufferModelViewInverse) * sunDirView);
        float sunVis;
        vec2 sunUV = SunScreenUV(gbufferProjection, sunDirView, sunVis);

        float sunElev = sunDirW.y;
        float elevGate = smoothstep(-0.06, 0.16, sunElev);

        float angRad = 0.00465116 * CELESTIAL_ANGULAR_SCALE;
        float sunRadUV = gbufferProjection[1][1] * tan(angRad) * 0.5;
        float occSum = 0.0;
        occSum += smoothstep(0.99990, 1.0,
                  texture(depthtex0, clamp(sunUV, vec2(0.0), vec2(1.0))).r);
        for (int i = 0; i < 4; ++i) {
            float a = float(i) * 1.5707963;
            vec2 o = vec2(cos(a), sin(a)) * sunRadUV * 0.55;
            occSum += smoothstep(0.99990, 1.0,
                      texture(depthtex0, clamp(sunUV + o, vec2(0.0), vec2(1.0))).r);
        }
        for (int i = 0; i < 4; ++i) {
            float a = float(i) * 1.5707963 + 0.7853982;
            vec2 o = vec2(cos(a), sin(a)) * sunRadUV * 0.90;
            occSum += smoothstep(0.99990, 1.0,
                      texture(depthtex0, clamp(sunUV + o, vec2(0.0), vec2(1.0))).r);
        }
        float sunUnblocked = occSum / 9.0;

        float airmass = clamp(1.0 / max(sunElev + 0.06, 0.06), 1.0, 8.0);
        float atmFade = pow(1.8 / airmass, 0.55);

        if (sunVis > 1.0e-4) {
            vec3 sunPix = texture(colortex3, clamp(sunUV, vec2(0.0), vec2(1.0))).rgb;
            float srcLum = dot(max(sunPix, vec3(0.0)), vec3(0.2126, 0.7152, 0.0722));
            srcLum = max(srcLum, 0.02);

            float tHigh = smoothstep(0.06, 0.30, sunElev);
            float tGold = smoothstep(-0.02, 0.06, sunElev);
            float tRed  = smoothstep(-0.09, -0.02, sunElev);

            vec3 cNoon = vec3(1.00, 0.97, 0.92);
            vec3 cGold = vec3(1.00, 0.78, 0.48);
            vec3 cDusk = vec3(1.00, 0.52, 0.20);
            vec3 cEmber= vec3(0.85, 0.28, 0.12);

            vec3 flareTint = mix(cEmber, cDusk, tRed);
            flareTint      = mix(flareTint, cGold, tGold);
            flareTint      = mix(flareTint, cNoon, tHigh);

            float g = elevGate * sunUnblocked * atmFade;
            if (g > 1.0e-4) {
                combined += SunFlare(texcoord, sunUV, sunVis, flareTint, srcLum) * g;
            }
        }
    }

    float sceneNight = (EXPOSURE_ENABLED == 0 || EXPOSURE_MODE == 0)
                     ? 0.0 : clamp(sceneNightAmt, 0.0, 1.0);
    combined = purkinjeShift(combined, usedExposure, sceneNight);

    combined = clamp(combined, vec3(0.0), vec3(1.0e4));

    vec3 graded = finishGradedColor(combined);
#if BLOOM_MIP_CHAIN == 0
    int ltmMip = 0;
#else
    int ltmMip = max(BLOOM_MIP_LEVELS - 2, 0);
#endif
    float lowFreqHDR = texture(usam_bloom,
                               bloomMipUV(ltmMip, texcoord, fullSize)).a;
    float lowFreqLuma = 0.0;
    if (LTM_STRENGTH > 0.0) {
        vec3 lowFreqDisplay = finishGradedColor(
            vec3(max(lowFreqHDR, 0.0) * usedExposure));
        lowFreqLuma = dot(lowFreqDisplay, vec3(0.2126, 0.7152, 0.0722));
    }
    graded = applyLTM(graded, lowFreqLuma);

#if LUT_ENABLED
    graded = applyLUT(post_lut, graded, LUT_STRENGTH);
#endif
    vec3 ldr = finishVignette(graded);
    color = vec4(ldr, 1.0);
}
