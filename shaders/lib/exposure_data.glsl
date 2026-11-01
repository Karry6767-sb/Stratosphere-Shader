#ifndef LIB_EXPOSURE_DATA_GLSL
#define LIB_EXPOSURE_DATA_GLSL

#include "/lib/exposure_settings.glsl"

layout(std430, binding = 0) buffer ExposureData {
    uint histogram[HISTOGRAM_BIN_COUNT];
    float exposure;
    float adaptedLum;
    float nightSignal;
    float ambientLum;
    float sceneNightAmt;
};

#endif
