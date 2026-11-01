#ifndef LIB_LIGHTING_SKY_GI_GLSL
#define LIB_LIGHTING_SKY_GI_GLSL

#include "/lib/shadow/entry.glsl"
#include "/lib/shadow/scene.glsl"

#ifndef SKY_GI_REACH
#define SKY_GI_REACH 24.0 // [8.0 16.0 24.0 40.0 64.0]
#endif
#ifndef SKY_GI_REALTIME
#define SKY_GI_REALTIME 1 // [0 1]
#endif
#ifndef SKY_GI_SAMPLES
#define SKY_GI_SAMPLES 4 // [2 4 6]
#endif
#ifndef SKY_GI_STEPS
#define SKY_GI_STEPS 4 // [2 4 6]
#endif
#ifndef SKY_GI_STRENGTH
#define SKY_GI_STRENGTH 0.15 // [0.0 0.5 0.75 1.0]
#endif

float skyGIHemisphereVisibility(vec3 worldPos, vec3 worldNormal, float dither) {
#if SKY_GI_REALTIME == 1
    vec3 n = normalize(worldNormal);
    vec3 up = (abs(n.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(up, n));
    vec3 b = cross(n, t);

    float visSum = 0.0;
    float stepLen = SKY_GI_REACH / float(SKY_GI_STEPS);
    mat4 shadowMV = SceneShadowModelView();

    for (int i = 0; i < SKY_GI_SAMPLES; ++i) {
        float fi = (float(i) + 0.5) / float(SKY_GI_SAMPLES);
        float phi = fi * 6.28318530718 + dither * 6.28318530718;
        float cosT = sqrt(max(1.0 - fi, 0.0));
        float sinT = sqrt(max(fi, 0.0));
        vec3 dir = normalize(t * (cos(phi) * sinT)
                           + b * (sin(phi) * sinT)
                           + n * cosT);

        float v = 1.0;
        for (int s = 1; s <= SKY_GI_STEPS; ++s) {
            vec3 p = worldPos + dir * (float(s) * stepLen);
            vec3 sh = shadowWorldToScreenWithMatrix(shadowMV, p);
            float outside = (sh.x < 0.0 || sh.x > 1.0 || sh.y < 0.0 || sh.y > 1.0
                             || sh.z < 0.0 || sh.z > 1.0) ? 1.0 : 0.0;
            float vis = mix(getShadowOpaque(sh), 1.0, outside);
            v = min(v, vis);
            if (v <= 0.0) break;
        }
        visSum += v;
    }
    return clamp(visSum / float(SKY_GI_SAMPLES), 0.0, 1.0);
#else
    return 1.0;
#endif
}

#endif
