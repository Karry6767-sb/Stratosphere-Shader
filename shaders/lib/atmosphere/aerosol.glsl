// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_AEROSOL_GLSL
#define LIB_ATMOSPHERE_AEROSOL_GLSL

#include "/lib/atmosphere/spectrum.glsl"

float atmAqiToMieScale() {
    float a = float(ATM_AQI);
    if (a <= 50.0)  return mix(0.5, 1.0, clamp(a / 50.0, 0.0, 1.0));
    if (a <= 100.0) return 1.0;
    if (a <= 150.0) return mix(1.0, 2.0, (a - 100.0) / 50.0);
    if (a <= 200.0) return mix(2.0, 4.0, (a - 150.0) / 50.0);
    if (a <= 300.0) return mix(4.0, 8.0, (a - 200.0) / 100.0);
    return 16.0;
}

vec4 atmAerosolSpectralWeight() {
    return pow(ATM_LAMBDA / 560.0, vec4(-ATM_ANGSTROM));
}

vec4 atmMieAerosolScale() {
    return atmAqiToMieScale() * atmAerosolSpectralWeight();
}

#endif
