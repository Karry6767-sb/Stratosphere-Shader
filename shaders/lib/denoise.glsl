#ifndef LIB_DENOISE_GLSL
#define LIB_DENOISE_GLSL

float atrousKernelWeight(float x) {
    float ax = abs(x);
    if (ax < 0.5) return 0.375;
    if (ax < 1.5) return 0.25;
    if (ax < 2.5) return 0.0625;
    return 0.0;
}

vec3 atrousFilter(sampler2D src, sampler2D depthTex, sampler2D normalTex,
                  vec2 uv, vec2 texel, float centerDepth, vec3 centerN,
                  out vec3 minRaw, out vec3 maxRaw, out float tracedHere) {
    vec4 centerSample = texture(src, uv);
    tracedHere = centerSample.a;
    minRaw = vec3(1.0e20);
    maxRaw = vec3(-1.0e20);
    bool anyTraced = false;

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 suv = clamp(uv + vec2(float(x), float(y)) * texel,
                             vec2(0.0), vec2(1.0));
            vec4 s = texture(src, suv);
            if (s.a < 0.5) continue;
            if (!anyTraced) {
                minRaw = s.rgb;
                maxRaw = s.rgb;
                anyTraced = true;
            } else {
                minRaw = min(minRaw, s.rgb);
                maxRaw = max(maxRaw, s.rgb);
            }
        }
    }
    if (!anyTraced) {
        minRaw = vec3(0.0);
        maxRaw = vec3(1.0e4);
    }

    vec3 color = centerSample.rgb;
    bool haveColor = (centerSample.a >= 0.5);

    for (int level = 0; level < DENOISE_LEVELS; ++level) {
        int step = 1 << level;
        vec3 levelSum = vec3(0.0);
        float levelWsum = 0.0;

        for (int y = -2; y <= 2; ++y) {
            for (int x = -2; x <= 2; ++x) {
                vec2 suv = clamp(uv + vec2(float(x), float(y))
                                   * float(step) * texel,
                                 vec2(0.0), vec2(1.0));
                vec4 s = texture(src, suv);
                if (s.a < 0.5) continue;

                float d = texture(depthTex, suv).r;
                if (d >= 0.999999) continue;

                vec3 nRaw = texture(normalTex, suv).rgb * 2.0 - 1.0;
                float nLen = length(nRaw);
                vec3 n = (nLen > 1.0e-4) ? nRaw / nLen : centerN;

                float depthW = exp(-abs(d - centerDepth) * 200.0);
                float normalW = pow(max(dot(centerN, n), 0.0), 16.0);
                float w = atrousKernelWeight(float(x))
                        * atrousKernelWeight(float(y))
                        * depthW * normalW;
                if (w <= 1.0e-7) continue;

                levelSum += s.rgb * w;
                levelWsum += w;
            }
        }

        if (levelWsum > 1.0e-6) {
            vec3 levelColor = levelSum / levelWsum;
            if (!haveColor) {
                color = levelColor;
                haveColor = true;
            } else {
                float blend = 1.0 / float(level + 1);
                color = mix(color, levelColor, blend);
            }
        }
    }

    if (!haveColor) return vec3(0.0);
    return color;
}

#endif
