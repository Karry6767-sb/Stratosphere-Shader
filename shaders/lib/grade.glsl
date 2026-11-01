#ifndef LIB_GRADE_GLSL
#define LIB_GRADE_GLSL

#include "/lib/drt.glsl"

const mat3 SRGB_2_XYZ = mat3(
    0.4124564, 0.2126729, 0.0193339,
    0.3575761, 0.7151522, 0.1191920,
    0.1804375, 0.0721750, 0.9503041);

const mat3 XYZ_2_SRGB = mat3(
     3.2404542, -0.9692660,  0.0556434,
    -1.5371385,  1.8760108, -0.2040259,
    -0.4985314,  0.0415560,  1.0572252);

const mat3 XYZ_2_LMS_B = mat3(
     0.8951, -0.7502,  0.0389,
     0.2664,  1.7135, -0.0685,
    -0.1614,  0.0367,  1.0296);

const mat3 LMS_2_XYZ_B = mat3(
     0.9869929,  0.4323053, -0.0085287,
    -0.1470543,  0.5183603,  0.0400428,
     0.1599627,  0.0492912,  0.9684867);

vec3 purkinjeShift(vec3 color, float exposure) {
    const vec3 rodResponse = vec3(0.05, 0.55, 0.60);
    const vec3 tint = vec3(PURKINJE_SHIFT_R, PURKINJE_SHIFT_G, PURKINJE_SHIFT_B);

    vec3 xyz = SRGB_2_XYZ * max(color, 0.0);
    vec3 scotopic = xyz * max(vec3(0.0),
        1.33 * (1.0 + (xyz.y + xyz.z) / max(xyz.x, 1.0e-6)) - 1.68);
    float rodLuminance = dot(XYZ_2_SRGB * scotopic, rodResponse);

    float mesopic = clamp(log2(1.0 + max(exposure, 0.0))
                          / (2.0 + 4.0 * rodLuminance), 0.0, 1.0);
    return mix(color, rodLuminance * tint, PURKINJE_SHIFT_STRENGTH * mesopic);
}

const vec3 GRADE_LUMA_709 = vec3(0.2126, 0.7152, 0.0722);

vec3 purkinjeShift(vec3 color, float exposure, float sceneNight) {
    if (PURKINJE_SHIFT_STRENGTH <= 1.0e-4) return color;

    const vec3 rodResponse = vec3(0.05, 0.55, 0.60);
    const vec3 tint = vec3(PURKINJE_SHIFT_R, PURKINJE_SHIFT_G, PURKINJE_SHIFT_B);

    vec3 xyz = SRGB_2_XYZ * max(color, 0.0);
    vec3 scotopic = xyz * max(vec3(0.0),
        1.33 * (1.0 + (xyz.y + xyz.z) / max(xyz.x, 1.0e-6)) - 1.68);
    float rodLuminance = dot(XYZ_2_SRGB * scotopic, rodResponse);

    float luminance = dot(max(color, 0.0), GRADE_LUMA_709);
    float mesopic = clamp(log2(1.0 + max(exposure, 0.0))
                          / (2.0 + 4.0 * rodLuminance), 0.0, 1.0);
    mesopic *= clamp(sceneNight, 0.0, 1.0);
    mesopic *= 1.0 - smoothstep(0.05, 0.8, luminance);

    return mix(color, rodLuminance * tint, PURKINJE_SHIFT_STRENGTH * mesopic);
}

float gradeContrastCurve(float L, float amount) {
    float x = clamp(L, 0.0, 1.0);
    if (x <= 1.0e-5) return 0.0;
    if (x >= 1.0 - 1.0e-5) return 1.0;

    const float pivot = 0.18;
    float p = clamp(1.0 + amount, 0.20, 3.0);
    if (x <= pivot) return pivot * pow(x / pivot, p);
    return 1.0 - (1.0 - pivot) * pow((1.0 - x) / (1.0 - pivot), p);
}

vec3 gradeRGB(vec3 c, float exposure, float contrast, float saturation, float hueShift) {
    c = max(c, 0.0) * max(exposure, 0.0);

    float luma = dot(c, GRADE_LUMA_709);
    float mappedLuma = gradeContrastCurve(luma, contrast);
    c *= mappedLuma / max(luma, 1.0e-6);

    float luma2 = dot(c, GRADE_LUMA_709);
    c = mix(vec3(luma2), c, max(saturation, 0.0));

    if (abs(GRADE_ORANGE_SAT) > 1.0e-4 || abs(GRADE_TEAL_SAT) > 1.0e-4
        || abs(GRADE_GREEN_SAT) > 1.0e-4) {
        vec3 hsl = rgbToHsv(clamp(c, 0.0, 1.0));
        float hDeg = hsl.x * 360.0;
        float dO = min(abs(hDeg - 30.0), 360.0 - abs(hDeg - 30.0));
        float dT = min(abs(hDeg - 200.0), 360.0 - abs(hDeg - 200.0));
        float dG = min(abs(hDeg - 100.0), 360.0 - abs(hDeg - 100.0));
        float wO = exp(-pow(dO / 30.0, 2.0));
        float wT = exp(-pow(dT / 35.0, 2.0));
        float wG = exp(-pow(dG / 40.0, 2.0));
        float sMul = 1.0
                   + GRADE_ORANGE_SAT * wO
                   + GRADE_TEAL_SAT   * wT
                   + GRADE_GREEN_SAT  * wG;
        hsl.y = clamp(hsl.y * max(sMul, 0.0), 0.0, 1.0);
        c = hsvToRgb(hsl);
    }

    if (abs(hueShift) > 1.0e-6) {
        vec3 hsv = rgbToHsv(clamp(c, 0.0, 1.0));
        hsv.x = fract(hsv.x + hueShift / 6.28318530718);
        c = hsvToRgb(hsv);
    }
    return clamp(c, 0.0, 1.0);
}

vec3 whiteBalance(vec3 linearRGB, float tempShift, float tintShift) {
    if (abs(tempShift) < 1.0e-6 && abs(tintShift) < 1.0e-6) {
        return max(linearRGB, 0.0);
    }

    vec3 gain = vec3(1.0 + tempShift * 0.5,
                     1.0 + tintShift * 0.25,
                     1.0 - tempShift * 0.5);

    vec3 xyz = SRGB_2_XYZ * max(linearRGB, 0.0);
    vec3 lms = XYZ_2_LMS_B * xyz;
    vec3 rgb = XYZ_2_SRGB * (LMS_2_XYZ_B * (lms * gain));

    vec3 whiteXyz = SRGB_2_XYZ * vec3(1.0);
    vec3 whiteLms = XYZ_2_LMS_B * whiteXyz;
    vec3 whiteRgb = XYZ_2_SRGB * (LMS_2_XYZ_B * (whiteLms * gain));

    return rgb / max(whiteRgb, vec3(1.0e-6));
}

vec3 lutAtlasFetch(sampler2D lutTex, int size, ivec3 p) {
    return texelFetch(lutTex, ivec2(p.z * size + p.x, p.y), 0).rgb;
}

vec3 applyLUT(sampler2D lutTex, vec3 c, float strength) {
    vec3 base = clamp(c, 0.0, 1.0);
    float blend = clamp(strength, 0.0, 1.0);
    if (blend <= 1.0e-6) return base;

    ivec2 atlasSize = textureSize(lutTex, 0);
    int size = atlasSize.y;
    if (size <= 1 || atlasSize.x < size * size) {
        return base;
    }

    vec3 p = base * float(size - 1);
    ivec3 i0 = ivec3(floor(p));
    ivec3 i1 = min(i0 + ivec3(1), ivec3(size - 1));
    vec3 f = fract(p);

    vec3 c000 = lutAtlasFetch(lutTex, size, ivec3(i0.x, i0.y, i0.z));
    vec3 c100 = lutAtlasFetch(lutTex, size, ivec3(i1.x, i0.y, i0.z));
    vec3 c010 = lutAtlasFetch(lutTex, size, ivec3(i0.x, i1.y, i0.z));
    vec3 c110 = lutAtlasFetch(lutTex, size, ivec3(i1.x, i1.y, i0.z));
    vec3 c001 = lutAtlasFetch(lutTex, size, ivec3(i0.x, i0.y, i1.z));
    vec3 c101 = lutAtlasFetch(lutTex, size, ivec3(i1.x, i0.y, i1.z));
    vec3 c011 = lutAtlasFetch(lutTex, size, ivec3(i0.x, i1.y, i1.z));
    vec3 c111 = lutAtlasFetch(lutTex, size, ivec3(i1.x, i1.y, i1.z));

    vec3 c00 = mix(c000, c100, f.x);
    vec3 c10 = mix(c010, c110, f.x);
    vec3 c01 = mix(c001, c101, f.x);
    vec3 c11 = mix(c011, c111, f.x);
    vec3 lut = mix(mix(c00, c10, f.y), mix(c01, c11, f.y), f.z);

    return clamp(mix(base, lut, blend), 0.0, 1.0);
}

#endif
