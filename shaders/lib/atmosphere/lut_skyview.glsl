// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_LUT_SKYVIEW_GLSL
#define LIB_ATMOSPHERE_LUT_SKYVIEW_GLSL

#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/atmosphere/lut_images.glsl"

#ifndef ATM_SKYVIEW_SAMPLES
#define ATM_SKYVIEW_SAMPLES 32
#endif

mat2x3 atmScatteringIntegralRGB(vec3 rayPos, vec3 rayDir, vec3 sunDir, float tMax, bool groundHit) {
    float cosTheta = dot(rayDir, sunDir);
    vec2 phase = atmPhasePair(cosTheta);

    float stepSize = tMax / float(ATM_SKYVIEW_SAMPLES);
    vec3 rayStep = stepSize * rayDir;
    rayPos += 0.5 * rayStep;

    vec3 lum = vec3(0.0);
    vec3 trans = vec3(1.0);

    for (int i = 0; i < ATM_SKYVIEW_SAMPLES; ++i) {
        float r = length(rayPos);
        float muSun = dot(rayPos, sunDir) / max(r, 1.0e-6);

        vec3 rayleigh = atmRayleighCoeffRGB(r);
        vec3 mie = atmMieCoeffRGB(r);
        vec3 scattering = rayleigh + mie;
        vec3 extinction = max(scattering + atmOzoneCoeffRGB(r), vec3(1.0e-6));

        vec3 sunTransmittance = atmSpectralRatioRGB(atmTransmittanceToSunShadowed(rayPos, sunDir));
        vec3 psiMs = atmReadMultiScatteringImage(r, muSun);

        vec3 inScattering = rayleigh * phase.x + mie * phase.y;
        inScattering = inScattering * sunTransmittance + scattering * psiMs;

        vec3 sampleTransmittance = exp(-stepSize * extinction);
        vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

        lum += scatteringIntegral * trans;
        trans *= sampleTransmittance;
        rayPos += rayStep;
    }

    if (groundHit) {
        float planetHeight = length(rayPos);
        vec3 upVector = rayPos / max(planetHeight, 1.0e-6);
        float sunZenithCos = dot(upVector, sunDir);
        vec3 transmittanceToSun = atmSpectralRatioRGB(
            atmTransmittanceToSunShadowed(rayPos, sunDir));
        lum += ATM_GROUND_ALBEDO_RGB * PI * clamp(sunZenithCos, 0.0, 1.0)
             * trans * transmittanceToSun;
    }

    return mat2x3(lum, trans);
}

vec3 atmRaymarchScatteringRGB(vec3 rayPos, vec3 rayDir, vec3 sunDir) {
    float tMax;
    bool groundHit;
    if (!atmSetupRay(rayPos, rayDir, tMax, groundHit)) return vec3(0.0);
    return atmScatteringIntegralRGB(rayPos, rayDir, sunDir, tMax, groundHit)[0];
}

#endif
