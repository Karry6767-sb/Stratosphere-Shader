#ifndef MOON_GEOMETRIC_ALBEDO
#define MOON_GEOMETRIC_ALBEDO 0.136
#endif

#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef LIB_LIGHTING_PHYSICAL_GLSL
#define LIB_LIGHTING_PHYSICAL_GLSL

#include "/lib/lighting/transport.glsl"

const vec3 SUN_IRRADIANCE = vec3(1.5 * PI);

float physicalSunSolidAngle()  { return 2.0 * PI * (1.0 - cos(ATM_SUN_ANGULAR_RADIUS)); }
float physicalMoonSolidAngle() { return 2.0 * PI * (1.0 - cos(ATM_MOON_ANGULAR_RADIUS)); }

#ifndef MOON_IRRADIANCE_PHYSICAL
#define MOON_IRRADIANCE_PHYSICAL 2.585302e-6
#endif

#endif
