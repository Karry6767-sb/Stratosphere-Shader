#ifndef LIB_LIGHTING_AMBIENT_GLSL
#define LIB_LIGHTING_AMBIENT_GLSL

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"
#include "/lib/atmosphere/sky_sh.glsl"

vec3 skyAmbientColourPreserve(vec3 irradiance) {
    float l = dot(irradiance, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(l), irradiance, clamp(SKY_AMBIENT_SATURATION, 0.0, 1.0));
}
vec3 ambientSkyIrradiance(vec3 worldNormal, vec3 sunDirWorld) {
#if SKY_AMBIENT == 1
    vec3 probeDir = SkySHWorldToProbe(normalize(worldNormal), sunDirWorld);
    vec3 sh = max(SkySHGlobalIrradiance(probeDir), vec3(0.0));
    vec3 hemi = max(skyEnv.upIrradiance, vec3(0.0));
    return skyAmbientColourPreserve(mix(hemi, sh, 0.20));
#else
    return vec3(0.0);
#endif
}

vec3 ambientUpIrradiance() {
#if SKY_AMBIENT == 1
    return skyAmbientColourPreserve(max(skyEnv.upIrradiance, vec3(0.0)));
#else
    return vec3(0.0);
#endif
}

vec3 sunTransmittanceTint(vec3 atmPos, vec3 sunDirWorld) {
#if SUN_TRANSMITTANCE == 1
    vec4 trans = max(atmTransmittanceToSun(atmPos, sunDirWorld), vec4(0.0));
    vec3 sunRGB = max(SpectralToLinearSRGB(trans * ATM_SOLAR), vec3(0.0));
    vec3 refRGB = max(SpectralToLinearSRGB(ATM_SOLAR), vec3(1.0e-4));
    return clamp(sunRGB / refRGB * SUN_TRANSMITTANCE_GAIN, 0.0, 1.0);
#else
    return vec3(1.0);
#endif
}

#endif
