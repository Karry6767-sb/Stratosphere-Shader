#include "/lib/options_defaults.glsl"

#ifndef LIB_CELESTIAL_SUN_FLARE_GLSL
#define LIB_CELESTIAL_SUN_FLARE_GLSL

#ifndef SUN_FLARE
#define SUN_FLARE 1 // [0 1]
#endif
#ifndef SUN_FLARE_GLARE
#define SUN_FLARE_GLARE 0.2 // [0.0 0.2 0.35 0.55 0.8 1.2]
#endif
#ifndef SUN_FLARE_GLARE_WIDTH
#define SUN_FLARE_GLARE_WIDTH 0.16 // [0.10 0.16 0.22 0.30 0.40 0.55]
#endif
#ifndef BLOOM_FLARE_STARBURST
#define BLOOM_FLARE_STARBURST 0.2 // [0.0 0.05 0.1 0.2 0.35]
#endif
#ifndef BLOOM_FLARE_STARBURST_POW
#define BLOOM_FLARE_STARBURST_POW 250.0 // [60.0 120.0 250.0 500.0 1200.0]
#endif
#ifndef BLOOM_FLARE_SPIKES
#define BLOOM_FLARE_SPIKES 8.0 // [2.0 4.0 6.0 8.0]
#endif

vec2 SunScreenUV(mat4 projMat, vec3 sunDirView, out float vis) {
    vec3 d = normalize(sunDirView);
    vis = 0.0;

    if (d.z >= -1.0e-4) return vec2(-10.0);

    vec4 clip = projMat * vec4(d, 1.0);
    vec2 ndc = clip.xy / max(clip.w, 1.0e-6);
    vec2 uv = ndc * 0.5 + 0.5;

    vec2 inFrame = smoothstep(vec2(-0.35), vec2(0.0), uv)
                 * (1.0 - smoothstep(vec2(1.0), vec2(1.35), uv));
    vis = inFrame.x * inFrame.y;
    return uv;
}

vec3 SunVeilingGlare(vec2 uv, vec2 sunUV, float vis, vec3 tint, float strength) {
    if (SUN_FLARE_GLARE <= 0.0) return vec3(0.0);
    if (vis <= 1.0e-4) return vec3(0.0);
    vec2 d = uv - sunUV;
    d.x *= viewWidth / max(viewHeight, 1.0);
    float r = length(d);

    float w = max(SUN_FLARE_GLARE_WIDTH, 1.0e-3);
    float q = r / w;
    float halo = 1.0 / pow(1.0 + q * q, 1.35);
    float core = exp(-r / (w * 0.22));
    float shape = halo * 0.9 + core * 0.6;

    float falloff = shape * strength;

    vec2 edge = vec2(viewWidth / max(viewHeight, 1.0) * 0.5, 0.5);
    float rn = length(d / edge);

    falloff *= 1.0 - smoothstep(0.55, 1.0, rn);

    return tint * falloff;
}

vec3 SunStarburst(vec2 uv, vec2 sunUV, float vis, vec3 tint, float strength) {
    if (BLOOM_FLARE_STARBURST <= 0.0) return vec3(0.0);
    if (vis <= 1.0e-4) return vec3(0.0);

    vec2 d = uv - sunUV;
    d.x *= viewWidth / max(viewHeight, 1.0);
    float r = length(d);
    if (r < 1.0e-6) return vec3(0.0);

    float ang = atan(d.y, d.x);
    float spikes = 0.5 + 0.5 * cos(ang * BLOOM_FLARE_SPIKES);
    float rays = pow(clamp(spikes, 0.0, 1.0), BLOOM_FLARE_STARBURST_POW * 0.02);

    float fall = exp(-r * 9.0) * 0.7 + exp(-r * 2.2) * 0.3;
    return tint * rays * fall * strength * vis;
}

vec3 SunFlare(vec2 uv, vec2 sunUV, float vis, vec3 tint, float srcLum) {
#if SUN_FLARE == 0
    return vec3(0.0);
#else
    vec3 c = vec3(0.0);

    float strength = SUN_FLARE_GLARE * 3.6;

    c += SunVeilingGlare(uv, sunUV, vis, tint, strength);
    c += SunStarburst(uv, sunUV, vis, tint, strength * BLOOM_FLARE_STARBURST);
    return max(c, vec3(0.0));
#endif
}

#endif
