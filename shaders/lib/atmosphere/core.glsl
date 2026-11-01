// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_CORE_GLSL
#define LIB_ATMOSPHERE_CORE_GLSL

#include "/lib/atmosphere/options.glsl"
#include "/lib/atmosphere/geometry.glsl"
#include "/lib/atmosphere/spectrum.glsl"
#include "/lib/atmosphere/medium.glsl"
#include "/lib/atmosphere/lut_transmittance.glsl"

const float ATM_H              = sqrt(max(ATM_ATMO_R2 - ATM_PLANET_R2, 0.0));
const float ATM_ATMO_MINUS_P   = ATM_ATMO_R - ATM_PLANET_R;
const float ATM_RCP_ATMO_MINUS = 1.0 / max(ATM_ATMO_MINUS_P, 1.0e-6);

const vec4 ATM_EPS = vec4(1.0e-5);

#endif
