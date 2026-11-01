#ifndef TM_MODE
#define TM_MODE 2              // [0 1 2 3 4 5 6 7]
#endif

#include "/lib/bloom_new.glsl"

#include "/lib/exposure_settings.glsl"

#include "/lib/tonemap.glsl"
#include "/lib/drt.glsl"
#include "/lib/grade.glsl"

uniform float viewWidth, viewHeight;

vec3 srgbEncode(vec3 c) {
    c = max(c, 0.0);
    vec3 lo = c * 12.92;
    vec3 hi = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
    return mix(lo, hi, step(vec3(0.0031308), c));
}

vec3 applyOutputGamma(vec3 c) {
#if OUTPUT_OETF == 1
    vec3 lin = clamp(c, 0.0, 1.0);
    float inv = 1.0 / max(GAMMA_OUT, 1.0e-3);
    if (GAMMA_BLACK_LIFT > 0.0) {
        float knee = pow(GAMMA_BLACK_LIFT, inv);
        vec3 g = pow(lin, vec3(inv));
        vec3 low = lin * (knee / GAMMA_BLACK_LIFT);
        return mix(g, low, step(lin, vec3(GAMMA_BLACK_LIFT)));
    }
    return pow(lin, vec3(inv));
#else
    vec3 encoded = srgbEncode(c);
    float inv = 1.0 / max(GAMMA_OUT, 1.0e-3);
    if (abs(GAMMA_OUT - 1.0) > 1.0e-6) {
        encoded = pow(encoded, vec3(inv));
    }
    return clamp(encoded, 0.0, 1.0);
#endif
}

float ignDither(vec2 fragCoord) {
    return fract(52.9829189 * fract(0.06711056 * fragCoord.x
                                  + 0.00583715 * fragCoord.y));
}

vec3 applyDither(vec3 c, vec2 fragCoord) {
    return c + (ignDither(fragCoord) - 0.5)
             * (1.0 / 255.0) * DITHER_STRENGTH;
}

vec3 deband(sampler2D ldr, vec2 uv, vec3 color, vec2 texel) {
    vec3 xp = texture(ldr, uv + vec2(texel.x, 0.0)).rgb;
    vec3 xm = texture(ldr, uv - vec2(texel.x, 0.0)).rgb;
    vec3 yp = texture(ldr, uv + vec2(0.0, texel.y)).rgb;
    vec3 ym = texture(ldr, uv - vec2(0.0, texel.y)).rgb;

    float gx = length(xp - xm);
    float gy = length(yp - ym);
    float flatness = 1.0 - smoothstep(DEBAND_EDGE_LO, DEBAND_EDGE_HI,
                                      max(gx, gy));

    vec2 dir = (gx < gy) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec3 smoothed = 0.5 * (texture(ldr, uv + dir * texel).rgb
                         + texture(ldr, uv - dir * texel).rgb);

    return mix(color, smoothed, clamp(DEBAND_STRENGTH, 0.0, 0.5) * flatness);
}

vec3 applyDeband(sampler2D ldr, vec2 uv, vec3 color, vec2 texel) {
#if DEBAND_MODE == 0
    return color;
#else
    return deband(ldr, uv, color, texel);
#endif
}

float vignetteAntiderivative(float x, float y) {
    float sx = sqrt(1.0 + x * x);
    float sy = sqrt(1.0 + y * y);
    return 0.5 * (x / sx * atan(y / sx) + y / sy * atan(x / sy));
}

float vignetteIntegralRect(vec2 lo, vec2 hi) {
    return vignetteAntiderivative(hi.x, hi.y)
         - vignetteAntiderivative(lo.x, hi.y)
         - vignetteAntiderivative(hi.x, lo.y)
         + vignetteAntiderivative(lo.x, lo.y);
}

float vignetteCos4Average(vec2 uv) {
    float tanHalf = tan(radians(clamp(VIGNETTE_FOV, 10.0, 170.0)) * 0.5);
    float aspect  = viewWidth / max(viewHeight, 1.0);
#if CINE_VIGNETTE_ANAMORPHIC == 1
    aspect *= 0.72;
#endif

    vec2 tanPos = vec2(uv.x * tanHalf * aspect, uv.y * tanHalf);
    float texel = 2.0 * tanHalf / max(viewHeight, 1.0);
    vec2 halfTexel = vec2(0.5 * texel);

    float integral = vignetteIntegralRect(tanPos - halfTexel, tanPos + halfTexel);
    float area = max(texel * texel, 1.0e-8);
    return clamp(integral / area, 0.0, 1.0);
}

vec3 finishGradedColor(vec3 c) {
    c = max(c, 0.0);

    c = applyDRT(c);

    c = gradeRGB(c, GRADE_EXPOSURE, GRADE_CONTRAST, GRADE_SATURATION, GRADE_HUE_SHIFT);
    c = whiteBalance(c, WB_TEMPERATURE, WB_TINT);
    c = clamp(c, 0.0, 1.0);

    c = splitTone(c, vec3(HIGHLIGHT_R, HIGHLIGHT_G, HIGHLIGHT_B),
                 vec3(SHADOW_R, SHADOW_G, SHADOW_B), COLOR_OFFSET);
    return clamp(c, 0.0, 1.0);
}

vec3 applyLTM(vec3 color, float lowFreqLuma) {
    if (LTM_STRENGTH <= 0.0) return color;

    float luma = dot(max(color, vec3(0.0)), vec3(0.2126, 0.7152, 0.0722));
    float key = max(LTM_KEY, 1.0e-4);
    float gain = clamp(key / max(lowFreqLuma, 1.0e-4),
                       1.0 - clamp(LTM_RANGE, 0.0, 0.9),
                       1.0 + clamp(LTM_RANGE, 0.0, 2.0));
    float edgeGuard = 1.0 - smoothstep(LTM_EDGE_LO, LTM_EDGE_HI,
                                       abs(luma - lowFreqLuma));
    float amount = clamp(LTM_STRENGTH, 0.0, 1.0) * edgeGuard;
    return color * mix(1.0, gain, amount);
}

vec3 finishVignette(vec3 c) {
    vec2 uv = texcoord * 2.0 - 1.0;
    float vigStrength = clamp(VIGNETTE_STRENGTH, 0.0, 1.0);
#if CINE_VIGNETTE >= 0.0
    vigStrength = clamp(CINE_VIGNETTE, 0.0, 1.0);
#endif
#if VIGNETTE_TYPE == 1
    c *= mix(1.0, vignetteCos4Average(uv), vigStrength);
#else
    c *= 1.0 - vigStrength * clamp(dot(uv, uv), 0.0, 1.0);
#endif
    return clamp(c, 0.0, 1.0);
}

vec3 finishColor(vec3 c) {
    return finishVignette(finishGradedColor(c));
}

#if LUT_ENABLED
vec3 finishColorWithLUT(vec3 c, sampler2D lutTex) {
    c = finishGradedColor(c);
    c = applyLUT(lutTex, c, LUT_STRENGTH);
    return finishVignette(c);
}
#endif
