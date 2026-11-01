#ifndef CINE_CHROMA_MAX
#define CINE_CHROMA_MAX 1.6
#endif

#ifndef CINE_HALATION_TAPS
#define CINE_HALATION_TAPS 8
#endif

#ifndef CINE_HALATION_TIGHT
#define CINE_HALATION_TIGHT 2.0
#endif

#ifndef CINE_HALATION_WIDE
#define CINE_HALATION_WIDE 5.0
#endif

#ifndef CINE_ENABLED
#define CINE_ENABLED 1
#endif

#ifndef LIB_CINEMATIC_GLSL
#define LIB_CINEMATIC_GLSL

uniform sampler2D noisetex;

vec3 filmGrain(vec3 col, vec2 uv, vec2 viewSize, float strength, float time) {
    if (strength <= 0.0) return col;

    vec2 gp = floor(uv * viewSize / max(CINE_GRAIN_SIZE, 0.5));

    float frame = floor(time * 24.0);
    float n = texture(noisetex,
                      (gp + vec2(frame * 37.0, frame * 17.0)) / 512.0).r;

    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));

    float weight = 4.0 * luma * (1.0 - luma);
    weight = mix(1.0, weight, clamp(CINE_GRAIN_LUMA_DEP, 0.0, 1.0));

    float g = (n - 0.5) * 2.0 * 0.06 * strength * weight;
    return clamp(col + g, 0.0, 1.0);
}

vec3 cineGrain(vec3 col, vec2 uv, vec2 viewSize, float strength, float time) {
    return filmGrain(col, uv, viewSize, strength, time);
}

vec3 lensChroma(sampler2D ldr, vec2 uv, vec2 texel,
                float strength, vec3 center) {
    if (strength <= 0.0) return center;

    vec2 c = uv - 0.5;
    float r2 = dot(c, c);
    float edge = smoothstep(0.08, 0.5, r2);

    vec2 dir;
    if (CINE_CHROMA_MODE == 1) {
        dir = vec2(1.0, 0.0);
    } else {
        dir = (r2 > 1.0e-6) ? normalize(c) : vec2(0.0);
    }

    float amt = strength * edge * CINE_CHROMA_MAX;

    vec3 col = center;
    col.r = texture(ldr, uv + dir * texel * (amt * 1.0)).r;
    col.g = texture(ldr, uv).g;
    col.b = texture(ldr, uv - dir * texel * (amt * 1.15)).b;
    return col;
}

vec3 halationBlur(sampler2D ldr, vec2 uv, vec2 texel, vec3 radiusPx) {
    vec3 sum = vec3(0.0);
    float wsum = 0.0;

    for (int i = 0; i < CINE_HALATION_TAPS; i++) {
        float fi = float(i) + 0.5;
        float r = sqrt(fi / float(CINE_HALATION_TAPS));
        float a = fi * 2.39996323;
        vec2 o = vec2(cos(a), sin(a)) * r;
        float w = exp(-2.5 * r * r);

        sum.r += texture(ldr, uv + o * texel * radiusPx.r).r * w;
        sum.g += texture(ldr, uv + o * texel * radiusPx.g).g * w;
        sum.b += texture(ldr, uv + o * texel * radiusPx.b).b * w;
        wsum += w;
    }
    return sum / max(wsum, 1.0e-6);
}

vec3 halation(sampler2D ldr, vec2 uv, vec2 texel,
              float strength, vec3 center) {
    if (strength <= 0.0) return center;

    vec3 rad = vec3(1.4, 1.0, 0.7);
    vec3 tight = halationBlur(ldr, uv, texel, rad * CINE_HALATION_TIGHT);
    vec3 wide  = halationBlur(ldr, uv, texel, rad * CINE_HALATION_WIDE);

    float t = clamp(CINE_HALATION_THRESHOLD, 0.0, 0.999);
    vec3 bright = clamp((center - vec3(t)) / max(1.0 - t, 1.0e-3),
                        0.0, 1.0);
    vec3 halo = tight * 0.6 + wide * 0.4;
    return center + halo * bright * strength;
}

vec3 cineApply(sampler2D ldr, vec3 col, vec2 uv, vec2 viewSize) {
#if CINE_ENABLED == 0
    return col;
#else
    vec2 texel = 1.0 / max(viewSize, vec2(1.0));
    vec3 base = col;

#if CINE_CHROMA > 0.0
    base = lensChroma(ldr, uv, texel, CINE_CHROMA, base);
#endif
#if CINE_HALATION > 0.0
    base = halation(ldr, uv, texel, CINE_HALATION, base);
#endif

    return base;
#endif
}

vec3 cineLetterbox(vec3 col, vec2 uv, vec2 viewSize,
                   float enabled, float sizeRatio) {
    if (enabled < 0.5 || sizeRatio <= 0.0) return col;

    float feather = 1.5 / max(viewSize.y, 1.0);
    vec2 centered = abs(uv - 0.5);
    float m = smoothstep(0.5 - sizeRatio - feather,
                         0.5 - sizeRatio + feather,
                         centered.y);
    return mix(col, vec3(0.0), m);
}

#endif
