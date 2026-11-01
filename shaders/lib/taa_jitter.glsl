#ifndef TAA_JITTER_GLSL
#define TAA_JITTER_GLSL

#include "/lib/aa_options.glsl"

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

float taaHalton(int index, int base) {
    float r = 0.0;
    float f = 1.0;
    int i = index;
    while (i > 0) {
        f /= float(base);
        r += f * float(i % base);
        i /= base;
    }
    return r;
}
vec2 taaJitterOffsetPixels(int frame) {
    vec2 h = vec2(taaHalton(frame % 16 + 1, 2),
                  taaHalton(frame % 16 + 1, 3));
    return (h - 0.5) * 2.0;
}

vec4 ApplyTaaJitter(vec4 position) {
#if (AA_MODE == 2 || AA_MODE == 4)
 #if TAA_JITTER == 1
    vec2 offset = taaJitterOffsetPixels(frameCounter)
                * (position.w / max(vec2(viewWidth, viewHeight), vec2(1.0)));
    position.xy += offset;
 #endif
#endif
    return position;
}

#endif
