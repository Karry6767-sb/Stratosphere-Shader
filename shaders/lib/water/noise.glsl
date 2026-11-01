#ifndef LIB_WTR_NOISE_GLSL
#define LIB_WTR_NOISE_GLSL

float WtrHash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float WtrValueNoiseRaw(vec2 p) {
    vec2 i = floor(p);
    vec2 w = fract(p);
    vec2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float a = WtrHash(i);
    float b = WtrHash(i + vec2(1.0, 0.0));
    float c = WtrHash(i + vec2(0.0, 1.0));
    float d = WtrHash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float WtrValueNoise(vec2 p) {
    const mat2 rot = mat2(0.80, -0.60, 0.60, 0.80);
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    for (int i = 0; i < 3; i++) {
        sum += WtrValueNoiseRaw(p) * amp;
        norm += amp;
        p = rot * p * 2.03 + vec2(17.1, 9.7);
        amp *= 0.5;
    }
    return sum / norm;
}

#endif
