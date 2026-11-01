#ifndef LIB_BLOOM_NEW_GLSL
#define LIB_BLOOM_NEW_GLSL

const vec3 BLOOM_LUMA_709 = vec3(0.2126, 0.7152, 0.0722);

float bloomAnamorphicScale() {
    return clamp(BLOOM_ANAMORPHIC_X, 1.0, 8.0);
}

vec2 bloomAnamorphicTexel(vec2 texel) {
    return texel * vec2(bloomAnamorphicScale(), 1.0);
}

float bloomMipWeight(int level) {
    float sum = 0.0;
    for (int k = 0; k < BLOOM_MIP_LEVELS; k++) {
        sum += exp2(-float(k));
    }
    return exp2(-float(level)) / max(sum, 1.0e-6);
}

vec4 bloomMipRect(int level, vec2 fullSize) {
    float w0 = max(floor(fullSize.x * 0.5), 1.0);
    float h0 = max(floor(fullSize.y * 0.5), 1.0);
    if (level <= 0) {
        return vec4(0.0, 0.0, w0, h0);
    }

    float w = max(floor(w0 * 0.5), 1.0);
    float h = max(floor(h0 * 0.5), 1.0);
    float y = 0.0;
    for (int k = 1; k < level; k++) {
        y += h;
        w = max(floor(w * 0.5), 1.0);
        h = max(floor(h * 0.5), 1.0);
    }
    return vec4(w0, y, w, h);
}

vec2 bloomMipUV(int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 safeSize = max(r.zw, vec2(1.0));
    vec2 halfTexel = min(vec2(0.5) / safeSize, vec2(0.499));
    vec2 c = clamp(uv, halfTexel, vec2(1.0) - halfTexel);
    return (r.xy + c * r.zw) / max(fullSize, vec2(1.0));
}

vec3 bloomAtlasSample(sampler2D src, vec4 rect, vec2 atlasUV, vec2 fullSize) {
    vec2 safeSize = max(rect.zw, vec2(1.0));
    vec2 minUV = (rect.xy + vec2(0.5)) / max(fullSize, vec2(1.0));
    vec2 maxUV = (rect.xy + safeSize - vec2(0.5)) / max(fullSize, vec2(1.0));
    return texture(src, clamp(atlasUV, min(minUV, maxUV), max(minUV, maxUV))).rgb;
}

vec3 bloomPrefilter(vec3 c) {
    float lum = dot(max(c, vec3(0.0)), BLOOM_LUMA_709);
    float knee = max(BLOOM_THRESHOLD * BLOOM_SOFT, 1.0e-4);
    float soft = clamp(lum - BLOOM_THRESHOLD + knee, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee + 1.0e-4);
    float contrib = max(soft, lum - BLOOM_THRESHOLD) / max(lum, 1.0e-4);
    float firefly = 1.0 / (1.0 + lum * BLOOM_FIREFLY);
    return c * contrib * firefly;
}

vec3 downsample13(sampler2D src, vec2 uv, vec2 texel) {
    vec2 o = bloomAnamorphicTexel(texel);
    vec3 a = texture(src, uv + o * vec2(-2.0,  2.0)).rgb;
    vec3 b = texture(src, uv + o * vec2( 0.0,  2.0)).rgb;
    vec3 c = texture(src, uv + o * vec2( 2.0,  2.0)).rgb;
    vec3 d = texture(src, uv + o * vec2(-2.0,  0.0)).rgb;
    vec3 e = texture(src, uv).rgb;
    vec3 f = texture(src, uv + o * vec2( 2.0,  0.0)).rgb;
    vec3 g = texture(src, uv + o * vec2(-2.0, -2.0)).rgb;
    vec3 h = texture(src, uv + o * vec2( 0.0, -2.0)).rgb;
    vec3 i = texture(src, uv + o * vec2( 2.0, -2.0)).rgb;
    vec3 j = texture(src, uv + o * vec2(-1.0,  1.0)).rgb;
    vec3 k = texture(src, uv + o * vec2( 1.0,  1.0)).rgb;
    vec3 l = texture(src, uv + o * vec2(-1.0, -1.0)).rgb;
    vec3 m = texture(src, uv + o * vec2( 1.0, -1.0)).rgb;

    vec3 groups[5];
    groups[0] = (a + b + d + e) * 0.25;
    groups[1] = (b + c + e + f) * 0.25;
    groups[2] = (d + e + g + h) * 0.25;
    groups[3] = (e + f + h + i) * 0.25;
    groups[4] = (j + k + l + m) * 0.25;

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int n = 0; n < 5; n++) {
        float w = 1.0 / (1.0 + dot(max(groups[n], vec3(0.0)), BLOOM_LUMA_709));
        sum += groups[n] * w;
        wsum += w;
    }
    return sum / max(wsum, 1.0e-4);
}

vec3 bloomDownsampleAtlas(sampler2D src, int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 texel = vec2(1.0) / max(fullSize, vec2(1.0));
    vec2 o = bloomAnamorphicTexel(texel);
    vec2 base = (r.xy + uv * r.zw) / max(fullSize, vec2(1.0));

    vec3 a = bloomAtlasSample(src, r, base + o * vec2(-2.0,  2.0), fullSize);
    vec3 b = bloomAtlasSample(src, r, base + o * vec2( 0.0,  2.0), fullSize);
    vec3 c = bloomAtlasSample(src, r, base + o * vec2( 2.0,  2.0), fullSize);
    vec3 d = bloomAtlasSample(src, r, base + o * vec2(-2.0,  0.0), fullSize);
    vec3 e = bloomAtlasSample(src, r, base, fullSize);
    vec3 f = bloomAtlasSample(src, r, base + o * vec2( 2.0,  0.0), fullSize);
    vec3 g = bloomAtlasSample(src, r, base + o * vec2(-2.0, -2.0), fullSize);
    vec3 h = bloomAtlasSample(src, r, base + o * vec2( 0.0, -2.0), fullSize);
    vec3 i = bloomAtlasSample(src, r, base + o * vec2( 2.0, -2.0), fullSize);
    vec3 j = bloomAtlasSample(src, r, base + o * vec2(-1.0,  1.0), fullSize);
    vec3 k = bloomAtlasSample(src, r, base + o * vec2( 1.0,  1.0), fullSize);
    vec3 l = bloomAtlasSample(src, r, base + o * vec2(-1.0, -1.0), fullSize);
    vec3 m = bloomAtlasSample(src, r, base + o * vec2( 1.0, -1.0), fullSize);

    vec3 groups[5];
    groups[0] = (a + b + d + e) * 0.25;
    groups[1] = (b + c + e + f) * 0.25;
    groups[2] = (d + e + g + h) * 0.25;
    groups[3] = (e + f + h + i) * 0.25;
    groups[4] = (j + k + l + m) * 0.25;

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int n = 0; n < 5; n++) {
        float w = 1.0 / (1.0 + dot(max(groups[n], vec3(0.0)), BLOOM_LUMA_709));
        sum += groups[n] * w;
        wsum += w;
    }
    return sum / max(wsum, 1.0e-4);
}

vec3 upsample9(sampler2D src, vec2 uv, vec2 texel, float radius) {
    vec2 o = bloomAnamorphicTexel(texel * max(radius, 0.0));
    vec3 s = texture(src, uv + vec2(-o.x,  o.y)).rgb * 1.0
           + texture(src, uv + vec2( 0.0,  o.y)).rgb * 2.0
           + texture(src, uv + vec2( o.x,  o.y)).rgb * 1.0
           + texture(src, uv + vec2(-o.x,  0.0)).rgb * 2.0
           + texture(src, uv).rgb                      * 4.0
           + texture(src, uv + vec2( o.x,  0.0)).rgb * 2.0
           + texture(src, uv + vec2(-o.x, -o.y)).rgb * 1.0
           + texture(src, uv + vec2( 0.0, -o.y)).rgb * 2.0
           + texture(src, uv + vec2( o.x, -o.y)).rgb * 1.0;
    return s * (1.0 / 16.0);
}

vec3 bloomUpsampleAtlas(sampler2D src, int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 texel = vec2(1.0) / max(fullSize, vec2(1.0));
    vec2 base = (r.xy + uv * r.zw) / max(fullSize, vec2(1.0));
    vec2 o = bloomAnamorphicTexel(texel);

    vec3 s = bloomAtlasSample(src, r, base + vec2(-o.x,  o.y), fullSize) * 1.0
           + bloomAtlasSample(src, r, base + vec2( 0.0,  o.y), fullSize) * 2.0
           + bloomAtlasSample(src, r, base + vec2( o.x,  o.y), fullSize) * 1.0
           + bloomAtlasSample(src, r, base + vec2(-o.x,  0.0), fullSize) * 2.0
           + bloomAtlasSample(src, r, base,                      fullSize) * 4.0
           + bloomAtlasSample(src, r, base + vec2( o.x,  0.0), fullSize) * 2.0
           + bloomAtlasSample(src, r, base + vec2(-o.x, -o.y), fullSize) * 1.0
           + bloomAtlasSample(src, r, base + vec2( 0.0, -o.y), fullSize) * 2.0
           + bloomAtlasSample(src, r, base + vec2( o.x, -o.y), fullSize) * 1.0;
    return s * (1.0 / 16.0);
}

vec3 bloomChroma(sampler2D bloomAtlas, vec2 uv, vec2 haloUV, vec2 fullSize) {
#if BLOOM_CHROMA == 1
    if (BLOOM_CHROMA_AMOUNT <= 0.0) return texture(bloomAtlas, haloUV).rgb;
    vec2 d = uv - vec2(0.5);
    float k = BLOOM_CHROMA_AMOUNT * 0.001;
    vec2 uvR = clamp(vec2(0.5) + d * (1.0 + k), vec2(0.0), vec2(1.0));
    vec2 uvB = clamp(vec2(0.5) + d * (1.0 - k), vec2(0.0), vec2(1.0));
    vec2 hR = bloomMipUV(0, uvR, fullSize);
    vec2 hB = bloomMipUV(0, uvB, fullSize);
    vec3 s;
    s.r = texture(bloomAtlas, hR).r;
    s.g = texture(bloomAtlas, haloUV).g;
    s.b = texture(bloomAtlas, hB).b;
    return s;
#else
    return texture(bloomAtlas, haloUV).rgb;
#endif
}

vec3 bloomStreak(sampler2D bloomAtlas, vec2 uv, vec2 haloUV, vec2 fullSize) {
#if BLOOM_STREAK > 0.0 && BLOOM_STREAK_REACH > 0.0
    vec2 texel = 1.0 / max(fullSize, vec2(1.0));
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; ++i) {
        float t = float(i) / 6.0;
        float w = exp(-4.0 * t * t);
        vec2 suv = clamp(uv + vec2(t * BLOOM_STREAK_REACH * texel.x, 0.0),
                         vec2(0.0), vec2(1.0));
        vec2 hUV = bloomMipUV(0, suv, fullSize);
        vec3 sc = texture(bloomAtlas, hUV).rgb;
        float lum = dot(max(sc, vec3(0.0)), BLOOM_LUMA_709);
        float gate = smoothstep(BLOOM_THRESHOLD * 0.5, BLOOM_THRESHOLD * 1.5, lum);
        acc += sc * (w * gate);
        wsum += w;
    }
    return acc / max(wsum, 1.0e-4) * BLOOM_STREAK;
#else
    return vec3(0.0);
#endif
}

#endif
