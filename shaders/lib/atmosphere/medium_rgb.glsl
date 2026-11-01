// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_MEDIUM_RGB_GLSL
#define LIB_ATMOSPHERE_MEDIUM_RGB_GLSL

#include "/lib/atmosphere/core.glsl"

vec3 atmSolarRGB() {
    return max(SpectralToLinearSRGB(ATM_SOLAR), vec3(1.0e-4));
}

vec3 atmMoonRGB() {
    return max(SpectralToLinearSRGB(ATM_MOON_IRR), vec3(1.0e-4));
}

vec3 atmSpectralToRGB(vec4 spectral) {
    return max(SpectralToLinearSRGB(spectral), vec3(0.0));
}

vec3 atmSpectralRatioRGB(vec4 spectral) {
    return max(SpectralToLinearSRGB(spectral * ATM_SOLAR) / atmSolarRGB(), vec3(0.0));
}

vec3 atmRayleighCoeffRGB(float r) {
    return atmSpectralRatioRGB(atmRayleighScattering(r));
}

vec3 atmMieCoeffRGB(float r) {
    return atmSpectralRatioRGB(atmMieScattering(r));
}

vec3 atmOzoneCoeffRGB(float r) {
    return atmSpectralRatioRGB(atmOzoneExtinction(r));
}

vec3 atmScatteringCoeffRGB(float r) {
    return atmRayleighCoeffRGB(r) + atmMieCoeffRGB(r);
}

vec3 atmExtinctionCoeffRGB(float r) {
    return atmScatteringCoeffRGB(r) + atmOzoneCoeffRGB(r);
}

vec2 atmPhasePair(float cosTheta) {
    return vec2(PhaseRayleigh(cosTheta), PhaseMieHG(cosTheta, 0.8));
}

void atmExponentialHeightFog(vec3 sunColor, vec3 ambColor, float rayLength,
                             float cameraHeight, float worldHeight, float LdotV,
                             inout vec3 background) {
    const float scaleHeight = 1.0;
    const float falloff = 1.0 / scaleHeight;

    float h = max(worldHeight, 0.0);
    vec3 betaT = max(atmScatteringCoeffRGB(ATM_PLANET_R), vec3(1.0e-6));

    float t = max(cameraHeight - h, 0.1) * falloff;
    t = (1.0 - exp2(-t)) / t * exp2(-h * falloff);
    vec3 transmittance = exp(-rayLength * t * betaT);

    vec2 phase = atmPhasePair(LdotV);
    vec3 scattering = atmRayleighCoeffRGB(ATM_PLANET_R) * phase.x
                    + atmMieCoeffRGB(ATM_PLANET_R) * phase.y;

    vec3 inscatter = sunColor * scattering;
    inscatter += ambColor * atmScatteringCoeffRGB(ATM_PLANET_R);
    inscatter *= (1.0 - transmittance) / betaT;

    background = background * transmittance + inscatter;
}

#endif
