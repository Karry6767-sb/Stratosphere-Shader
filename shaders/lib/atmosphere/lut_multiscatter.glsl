// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_LUT_MULTISCATTER_GLSL
#define LIB_ATMOSPHERE_LUT_MULTISCATTER_GLSL

#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/atmosphere/lut_images.glsl"

mat2x3 atmRaymarchMultiScatteringRGB(vec3 rayPos, vec3 rayDir, vec3 sunDir) {
    float tMax;
    bool groundHit;
    if (!atmSetupRay(rayPos, rayDir, tMax, groundHit)) return mat2x3(0.0);

    float stepSize = tMax / float(ATM_MSLUT_SAMPLES);
    vec3 rayStep = stepSize * rayDir;
    rayPos += 0.5 * rayStep;

    vec3 lum = vec3(0.0);
    vec3 fms = vec3(0.0);
    vec3 transmittance = vec3(1.0);

    for (int i = 0; i < ATM_MSLUT_SAMPLES; ++i) {
        float r = length(rayPos);
        vec3 scattering = atmScatteringCoeffRGB(r);
        vec3 extinction = max(scattering + atmOzoneCoeffRGB(r), vec3(1.0e-6));

        vec3 sampleTransmittance = exp(-stepSize * extinction);

        float tEarth = atmRaySphereNearest(rayPos, sunDir, ATM_PLANET_R);
        float earthShadow = (tEarth > 0.0) ? 0.0 : 1.0;

        vec3 scatteringIntegral = (scattering - scattering * sampleTransmittance) / extinction;
        fms += scatteringIntegral * transmittance * earthShadow;

        float muSun = dot(rayPos, sunDir) / max(r, 1.0e-6);
        vec3 sunTransmittance = atmSpectralRatioRGB(atmTransmittanceToSunShadowed(rayPos, sunDir));
        scatteringIntegral *= (1.0 / (4.0 * PI)) * sunTransmittance;

        lum += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
        rayPos += rayStep;
    }

    if (groundHit) {
        float planetHeight = length(rayPos);
        vec3 upVector = rayPos / max(planetHeight, 1.0e-6);
        float sunZenithCos = dot(upVector, sunDir);
        vec3 transmittanceToSun = atmSpectralRatioRGB(
            atmTransmittanceToSunShadowed(rayPos, sunDir));
        lum += ATM_GROUND_ALBEDO_RGB * PI * clamp(sunZenithCos, 0.0, 1.0)
             * transmittance * transmittanceToSun;
    }

    return mat2x3(lum, fms);
}

#endif
