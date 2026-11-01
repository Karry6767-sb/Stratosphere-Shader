#ifndef LIB_LENS_GLSL
#define LIB_LENS_GLSL

vec2 lensDistortFull(vec2 uv, float k1, float k2, float fisheye, float aspect, float cylindrical) {
    aspect = max(aspect, 1.0e-4);
    vec2 c = (uv - 0.5) * 2.0;
    c.x *= aspect;

    float r2 = dot(c, c);

    if (fisheye > 1.0e-6) {
        float r = sqrt(max(r2, 1.0e-12));
        float theta = atan(r * fisheye);
        c *= theta / (r * fisheye);
    } else {
        vec2 kxy = vec2(k1 + cylindrical * 0.5,
                        k1 - cylindrical * 0.5);
        vec2 radial = vec2(1.0) + kxy * r2 + vec2(k2) * (r2 * r2);
        c *= radial;
    }

    c.x /= aspect;

    float zoom = 1.0 / max(1.0 + abs(k1) + abs(k2)
                               + abs(cylindrical) * 0.5
                               + fisheye * 0.15, 1.0e-4);
    return c * (zoom * 0.5) + 0.5;
}

vec2 lensDistort(vec2 uv, float k1, float k2, float fisheye, float aspect) {
    return lensDistortFull(uv, k1, k2, fisheye, aspect, 0.0);
}

#endif
