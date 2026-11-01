#ifndef TAA
#define TAA 1
#endif

#ifndef TAA_GLSL
#define TAA_GLSL

#include "/lib/aa_options.glsl"

layout(rgba16f) uniform image2D uimg_taaHistoryA;
layout(rgba16f) uniform image2D uimg_taaHistoryB;

ivec2 TAA_HistorySize() {
    return ivec2(floor(viewWidth + 0.5), floor(viewHeight + 0.5));
}

vec4 TAA_HistoryLoad(ivec2 p) {
    ivec2 maxP = max(TAA_HistorySize() - ivec2(1), ivec2(0));
    ivec2 q = clamp(p, ivec2(0), maxP);
    if ((frameCounter & 1) == 0) return imageLoad(uimg_taaHistoryA, q);
    return imageLoad(uimg_taaHistoryB, q);
}

void TAA_HistoryStore(ivec2 p, vec4 v) {
    if ((frameCounter & 1) == 0) imageStore(uimg_taaHistoryB, p, v);
    else imageStore(uimg_taaHistoryA, p, v);
}

vec4 TAA_HistoryLoadBilinear(vec2 uv) {
    ivec2 size = TAA_HistorySize();
    vec2 st = uv * vec2(size) - 0.5;
    ivec2 i0 = ivec2(floor(st));
    vec2 f = fract(st);
    vec4 a = TAA_HistoryLoad(i0);
    vec4 b = TAA_HistoryLoad(i0 + ivec2(1, 0));
    vec4 c = TAA_HistoryLoad(i0 + ivec2(0, 1));
    vec4 d = TAA_HistoryLoad(i0 + ivec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
#include "/lib/reprojection.glsl"

void TAA_NeighbourhoodStats(vec2 uv, out vec3 m1, out vec3 m2,
                            out vec3 mn, out vec3 mx) {
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    m1 = vec3(0.0);
    m2 = vec3(0.0);
    mn = vec3(1.0e20);
    mx = vec3(-1.0e20);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec3 s = texture(colortex0, uv + vec2(float(x), float(y)) * texel).rgb;
            m1 += s;
            m2 += s * s;
            mn = min(mn, s);
            mx = max(mx, s);
        }
    }
    m1 /= 9.0;
    m2 /= 9.0;
}
vec3 varianceClip(vec3 history, vec3 m1, vec3 m2, float scale) {
    vec3 sigma = sqrt(max(m2 - m1 * m1, vec3(0.0))) * scale;
    vec3 d = history - m1;
    float len = length(d / max(sigma, vec3(1.0e-5)));
    return (len > 1.0) ? (m1 + d / len) : history;
}

vec4 TAA_CatmullRom5(sampler2D tex, vec2 uv, vec2 texel) {
    vec2 samplePos = uv / texel;
    vec2 tc1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - tc1;
    vec2 f2 = f * f;
    vec2 f3 = f2 * f;

    vec2 w0 = -0.5 * f3 + 1.0 * f2 - 0.5 * f;
    vec2 w1 =  1.5 * f3 - 2.5 * f2 + 1.0;
    vec2 w2 = -1.5 * f3 + 2.0 * f2 + 0.5 * f;
    vec2 w3 =  0.5 * f3 - 0.5 * f2;

    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / max(w12, vec2(1.0e-5));
    vec2 tc0 = (tc1 - 1.0) * texel;
    vec2 tc3 = (tc1 + 2.0) * texel;
    vec2 tc12 = (tc1 + offset12) * texel;

    return texture(tex, vec2(tc12.x, tc0.y)) * (w0.y * w12.x)
         + texture(tex, vec2(tc0.x, tc12.y)) * (w12.y * w0.x)
         + texture(tex, vec2(tc12.x, tc12.y)) * (w12.x * w12.y)
         + texture(tex, vec2(tc3.x, tc12.y)) * (w12.y * w3.x)
         + texture(tex, vec2(tc12.x, tc3.y)) * (w3.y * w12.x);
}
vec3 TAA_NeighbourhoodClamping(vec2 uv, vec3 current, vec3 history) {
    vec3 m1, m2, mn, mx;
    TAA_NeighbourhoodStats(uv, m1, m2, mn, mx);
    mn = min(mn, current);
    mx = max(mx, current);
    return clamp(history, mn, mx);
}

vec3 TAA_Resolve(vec2 texcoord, float depth, vec3 current) {
#if AA_MODE != 2 && AA_MODE != 4
    return current;
#else
    vec3 coord = vec3(texcoord, depth);
    vec2 prvCoord = TAA_Reprojection(coord);
    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    vec4 historySample;
#if TAA_HISTORY_FILTER == 1
    historySample = TAA_HistoryLoadBilinear(prvCoord);
#else
    historySample = TAA_HistoryLoad(ivec2(prvCoord * vec2(viewWidth, viewHeight)));
#endif
    vec3 tempColor = historySample.rgb;

    if (tempColor.r == 0.0 && tempColor.g == 0.0 && tempColor.b == 0.0) {
        return current;
    }
    if (tempColor.r != tempColor.r || tempColor.g != tempColor.g
            || tempColor.b != tempColor.b) {
        return current;
    }
    vec3 m1, m2, mn, mx;
    TAA_NeighbourhoodStats(texcoord, m1, m2, mn, mx);

    float linearDepth = (2.0 * near * far)
                      / max(far + near - (depth * 2.0 - 1.0) * (far - near), 1.0e-5);
    float farFactor = smoothstep(32.0, 128.0, linearDepth);
    float antiFlicker = clamp(TAA_ANTIFLICKER, 0.0, 1.0)
                      * (1.0 - 0.75 * farFactor);
#if TAA_CLIP_MODE == 1
    tempColor = varianceClip(tempColor, m1, m2, TAA_VARIANCE_SCALE * (1.0 + 1.5 * farFactor));
#else
    tempColor = TAA_NeighbourhoodClamping(texcoord, current, tempColor);
#endif

    float historyDepth = historySample.a;
    float depthTol = max(0.010, min(depth, historyDepth) * 0.05);
    bool disocclusion = (historyDepth >= 0.0 && historyDepth <= 1.0)
                     && (abs(historyDepth - depth) > depthTol);

    float localContrast = length(m1 - current);
    float blendFactor = TAA_STRENGTH
                      * (1.0 - smoothstep(0.10, 0.50, localContrast)
                         * antiFlicker);

    blendFactor = mix(blendFactor, 1.0 - 1.0e-3, disocclusion ? 1.0 : 0.0);

    bool inside = (prvCoord.x > 0.0 && prvCoord.x < 1.0
                && prvCoord.y > 0.0 && prvCoord.y < 1.0);
    if (!inside) {
        blendFactor = 0.0;
    }

    blendFactor = clamp(blendFactor, 0.0, 0.98);
    return mix(current, tempColor, blendFactor);
#endif
}

#endif
