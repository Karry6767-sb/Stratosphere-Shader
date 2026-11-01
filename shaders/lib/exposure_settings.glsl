#ifndef HISTOGRAM_BIN_COUNT
#define HISTOGRAM_BIN_COUNT 256
#endif

#ifndef LIB_EXPOSURE_SETTINGS_GLSL
#define LIB_EXPOSURE_SETTINGS_GLSL

#ifndef EXPOSURE_MODE_MANUAL
#define EXPOSURE_MODE_MANUAL         0
#endif
#ifndef EXPOSURE_MODE_AUTO_BASIC
#define EXPOSURE_MODE_AUTO_BASIC     1
#endif
#ifndef EXPOSURE_MODE_AUTO_HISTOGRAM
#define EXPOSURE_MODE_AUTO_HISTOGRAM 2
#endif

float exposureLumToBin(float lum) {
    float logLum = log2(max(lum, 1e-6));
    float range = max(AUTO_EV_MAX - AUTO_EV_MIN, 1e-3);
    float t = (logLum - AUTO_EV_MIN) / range;
    return clamp(t, 0.0, 1.0) * float(HISTOGRAM_BIN_COUNT - 1);
}

float exposureBinToLogLum(float bin) {
    float range = max(AUTO_EV_MAX - AUTO_EV_MIN, 1e-3);
    float t = clamp(bin, 0.0, float(HISTOGRAM_BIN_COUNT - 1)) /
              float(HISTOGRAM_BIN_COUNT - 1);
    return AUTO_EV_MIN + t * range;
}

#endif
