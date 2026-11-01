#ifndef SMAA_GLSL
#define SMAA_GLSL

#include "/lib/aa_options.glsl"

float smaaLuma(vec3 c) {
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    return l / (1.0 + max(l, 0.0));
}

float smaaDepthGate(sampler2D depthTex, vec2 uv, vec2 offset, float centerDepth) {
    float d = texture(depthTex, uv + offset).r;
    float tol = max(0.0015, centerDepth * 0.015);
    return 1.0 - smoothstep(tol, tol * 3.0, abs(d - centerDepth));
}
vec3 smaaPass(sampler2D sceneTex, sampler2D depthTex, vec2 uv, vec2 texel) {
    vec3 c = texture(sceneTex, uv).rgb;
    float dc = texture(depthTex, uv).r;

    vec3 cN = texture(sceneTex, uv + vec2( 0.0, -1.0) * texel).rgb;
    vec3 cS = texture(sceneTex, uv + vec2( 0.0,  1.0) * texel).rgb;
    vec3 cW = texture(sceneTex, uv + vec2(-1.0,  0.0) * texel).rgb;
    vec3 cE = texture(sceneTex, uv + vec2( 1.0,  0.0) * texel).rgb;
    vec3 cNW = texture(sceneTex, uv + vec2(-1.0, -1.0) * texel).rgb;
    vec3 cNE = texture(sceneTex, uv + vec2( 1.0, -1.0) * texel).rgb;
    vec3 cSW = texture(sceneTex, uv + vec2(-1.0,  1.0) * texel).rgb;
    vec3 cSE = texture(sceneTex, uv + vec2( 1.0,  1.0) * texel).rgb;

    float lC = smaaLuma(c);
    float lN = smaaLuma(cN);
    float lS = smaaLuma(cS);
    float lW = smaaLuma(cW);
    float lE = smaaLuma(cE);
    float lNW = smaaLuma(cNW);
    float lNE = smaaLuma(cNE);
    float lSW = smaaLuma(cSW);
    float lSE = smaaLuma(cSE);

    float lMin = min(lC, min(min(min(lN, lS), min(lW, lE)),
                             min(min(lNW, lNE), min(lSW, lSE))));
    float lMax = max(lC, max(max(max(lN, lS), max(lW, lE)),
                             max(max(lNW, lNE), max(lSW, lSE))));
    float localRange = lMax - lMin;

    float edge = smoothstep(0.012, 0.10, localRange);
    if (edge <= 0.0) {
        return c;
    }

    float gx = (lNE + 2.0 * lE + lSE) - (lNW + 2.0 * lW + lSW);
    float gy = (lSW + 2.0 * lS + lSE) - (lNW + 2.0 * lN + lNE);
    float gradLen = length(vec2(gx, gy));
    if (gradLen < 1.0e-6) {
        return c;
    }

    vec2 dir = normalize(vec2(gx, gy));

    vec3 sum = c * 2.0;
    float wsum = 2.0;
    for (int i = 1; i <= 6; i++) {
        float fi = float(i);
        float w = exp(-0.35 * fi);
        vec3 a = texture(sceneTex, uv + dir * texel * fi).rgb;
        vec3 b = texture(sceneTex, uv - dir * texel * fi).rgb;
        sum += (a + b) * w;
        wsum += 2.0 * w;
    }

    vec3 blend = sum / max(wsum, 1.0e-4);
    float strength = clamp(edge, 0.0, 1.0);
    return mix(c, blend, strength);
}

#endif
