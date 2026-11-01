#ifndef LIB_BLOOM_IMAGE_GLSL
#define LIB_BLOOM_IMAGE_GLSL

#include "/lib/bloom_new.glsl"

vec3 bloomImageBilinear(vec4 rect, vec2 atlasUV, vec2 fullSize) {
    vec2 size = max(rect.zw, vec2(1.0));
    vec2 minPx = rect.xy + vec2(0.5);
    vec2 maxPx = rect.xy + size - vec2(0.5);
    vec2 px = atlasUV * max(fullSize, vec2(1.0));
    vec2 c = clamp(px, minPx, maxPx) - vec2(0.5);

    ivec2 lo = ivec2(floor(minPx));
    ivec2 hi = ivec2(floor(maxPx));
    ivec2 i0 = clamp(ivec2(floor(c)), lo, hi);
    vec2 f = fract(c);
    ivec2 i1 = clamp(i0 + ivec2(1), lo, hi);

    vec3 a = imageLoad(uimg_bloom, i0).rgb;
    vec3 b = imageLoad(uimg_bloom, ivec2(i1.x, i0.y)).rgb;
    vec3 d = imageLoad(uimg_bloom, ivec2(i0.x, i1.y)).rgb;
    vec3 e = imageLoad(uimg_bloom, i1).rgb;
    return mix(mix(a, b, f.x), mix(d, e, f.x), f.y);
}

float bloomImageBilinearAlpha(vec4 rect, vec2 atlasUV, vec2 fullSize) {
    vec2 size = max(rect.zw, vec2(1.0));
    vec2 minPx = rect.xy + vec2(0.5);
    vec2 maxPx = rect.xy + size - vec2(0.5);
    vec2 px = atlasUV * max(fullSize, vec2(1.0));
    vec2 c = clamp(px, minPx, maxPx) - vec2(0.5);

    ivec2 lo = ivec2(floor(minPx));
    ivec2 hi = ivec2(floor(maxPx));
    ivec2 i0 = clamp(ivec2(floor(c)), lo, hi);
    vec2 f = fract(c);
    ivec2 i1 = clamp(i0 + ivec2(1), lo, hi);

    float a = imageLoad(uimg_bloom, i0).a;
    float b = imageLoad(uimg_bloom, ivec2(i1.x, i0.y)).a;
    float d = imageLoad(uimg_bloom, ivec2(i0.x, i1.y)).a;
    float e = imageLoad(uimg_bloom, i1).a;
    return mix(mix(a, b, f.x), mix(d, e, f.x), f.y);
}

float bloomDownsampleAtlasAlpha(int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 base = (r.xy + uv * r.zw) / max(fullSize, vec2(1.0));
    return bloomImageBilinearAlpha(r, base, fullSize);
}

vec3 bloomDownsampleAtlasImage(int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 texel = vec2(1.0) / max(fullSize, vec2(1.0));
    vec2 o = bloomAnamorphicTexel(texel);
    vec2 base = (r.xy + uv * r.zw) / max(fullSize, vec2(1.0));

    vec3 a = bloomImageBilinear(r, base + o * vec2(-2.0,  2.0), fullSize);
    vec3 b = bloomImageBilinear(r, base + o * vec2( 0.0,  2.0), fullSize);
    vec3 c = bloomImageBilinear(r, base + o * vec2( 2.0,  2.0), fullSize);
    vec3 d = bloomImageBilinear(r, base + o * vec2(-2.0,  0.0), fullSize);
    vec3 e = bloomImageBilinear(r, base,                             fullSize);
    vec3 f = bloomImageBilinear(r, base + o * vec2( 2.0,  0.0), fullSize);
    vec3 g = bloomImageBilinear(r, base + o * vec2(-2.0, -2.0), fullSize);
    vec3 h = bloomImageBilinear(r, base + o * vec2( 0.0, -2.0), fullSize);
    vec3 i = bloomImageBilinear(r, base + o * vec2( 2.0, -2.0), fullSize);
    vec3 j = bloomImageBilinear(r, base + o * vec2(-1.0,  1.0), fullSize);
    vec3 k = bloomImageBilinear(r, base + o * vec2( 1.0,  1.0), fullSize);
    vec3 l = bloomImageBilinear(r, base + o * vec2(-1.0, -1.0), fullSize);
    vec3 m = bloomImageBilinear(r, base + o * vec2( 1.0, -1.0), fullSize);

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

vec3 bloomUpsampleAtlasImage(int level, vec2 uv, vec2 fullSize) {
    vec4 r = bloomMipRect(level, fullSize);
    vec2 texel = vec2(1.0) / max(fullSize, vec2(1.0));
    vec2 base = (r.xy + uv * r.zw) / max(fullSize, vec2(1.0));
    vec2 o = bloomAnamorphicTexel(texel);

    vec3 s = bloomImageBilinear(r, base + vec2(-o.x,  o.y), fullSize) * 1.0
           + bloomImageBilinear(r, base + vec2( 0.0,  o.y), fullSize) * 2.0
           + bloomImageBilinear(r, base + vec2( o.x,  o.y), fullSize) * 1.0
           + bloomImageBilinear(r, base + vec2(-o.x,  0.0), fullSize) * 2.0
           + bloomImageBilinear(r, base,                      fullSize) * 4.0
           + bloomImageBilinear(r, base + vec2( o.x,  0.0), fullSize) * 2.0
           + bloomImageBilinear(r, base + vec2(-o.x, -o.y), fullSize) * 1.0
           + bloomImageBilinear(r, base + vec2( 0.0, -o.y), fullSize) * 2.0
           + bloomImageBilinear(r, base + vec2( o.x, -o.y), fullSize) * 1.0;
    return s * (1.0 / 16.0);
}

#endif
