#ifndef LIB_ATMOSPHERE_ADAPTIVE_SKY_GAIN_GLSL
#define LIB_ATMOSPHERE_ADAPTIVE_SKY_GAIN_GLSL

float atmAdaptiveSkyRadianceGain(int worldTicks) {
    float t = mod(float(worldTicks), 24000.0);
    if (t < 0.0) t += 24000.0;

    if (t < 6000.0) {
        return mix(1.5, 0.5, t / 6000.0);
    }
    if (t < 12000.0) {
        return mix(0.5, 1.5, (t - 6000.0) / 6000.0);
    }
    return 1.5;
}

#endif
