#ifndef FXAA_GLSL
#define FXAA_GLSL

#ifndef FXAA_REDUCE_MIN
#define FXAA_REDUCE_MIN (1.0 / 128.0)
#endif
#ifndef FXAA_REDUCE_MUL
#define FXAA_REDUCE_MUL (1.0 / 8.0)
#endif
#ifndef FXAA_SPAN_MAX
#define FXAA_SPAN_MAX   8.0
#endif
vec3 fxaa311(sampler2D sceneTex, vec2 uv, vec2 texel) {
    vec3 rgbNW = texture(sceneTex, uv + vec2(-1.0, -1.0) * texel).rgb;
    vec3 rgbNE = texture(sceneTex, uv + vec2( 1.0, -1.0) * texel).rgb;
    vec3 rgbSW = texture(sceneTex, uv + vec2(-1.0,  1.0) * texel).rgb;
    vec3 rgbSE = texture(sceneTex, uv + vec2( 1.0,  1.0) * texel).rgb;
    vec3 rgbM  = texture(sceneTex, uv).rgb;

    vec3 luma = vec3(0.2126, 0.7152, 0.0722);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE)
                          * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin, vec2(-FXAA_SPAN_MAX), vec2(FXAA_SPAN_MAX)) * texel;
    vec3 rgbA = 0.5 * (
        texture(sceneTex, uv + dir * (1.0 / 3.0 - 0.5)).rgb +
        texture(sceneTex, uv + dir * (2.0 / 3.0 - 0.5)).rgb);

    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture(sceneTex, uv + dir * (0.0 / 3.0 - 0.5)).rgb +
        texture(sceneTex, uv + dir * (3.0 / 3.0 - 0.5)).rgb);

    float lumaB = dot(rgbB, luma);
    if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
        return rgbA;
    }
    return rgbB;
}

#endif
