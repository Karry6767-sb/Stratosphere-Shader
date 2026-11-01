#ifndef SHARPEN_GLSL
#define SHARPEN_GLSL

vec3 rcasSharpen(sampler2D tex, vec2 uv, vec3 center, vec2 texel, float sharpness) {
    vec3 n = texture(tex, uv + vec2(0.0, -texel.y)).rgb;
    vec3 s = texture(tex, uv + vec2(0.0,  texel.y)).rgb;
    vec3 w = texture(tex, uv + vec2(-texel.x, 0.0)).rgb;
    vec3 e = texture(tex, uv + vec2( texel.x, 0.0)).rgb;

    vec3 mn = min(min(min(n, s), min(w, e)), center);
    vec3 mx = max(max(max(n, s), max(w, e)), center);

    vec3 amp = clamp(min(mn, 1.0 - mx) / max(mx, vec3(1.0e-5)), vec3(0.0), vec3(1.0));
    vec3 wgt = sqrt(amp) * (-sharpness);

    vec3 result = (n + s + w + e) * wgt + center * (1.0 - 4.0 * wgt);
    return clamp(result, mn, mx);
}

#endif
