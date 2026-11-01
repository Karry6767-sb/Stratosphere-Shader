#ifndef LIB_VOLUMETRIC_LIGHT_SUN_GLSL
#define LIB_VOLUMETRIC_LIGHT_SUN_GLSL

#include "/lib/options_defaults.glsl"
#include "/lib/shadow/entry.glsl"
#include "/lib/shadow/scene.glsl"

#ifndef PI
#define PI 3.14159265358979323846
#endif

float VolumetricSunPhaseHG(float cosTheta, float g) {
    float g2 = g * g;
    float denom = max(1.0 + g2 - 2.0 * g * cosTheta, 1.0e-4);
    return (1.0 - g2) / (4.0 * PI * pow(denom, 1.5));
}

float VolumetricSunPhaseDual(float cosTheta, float aniso) {
    float gForward = VL_PHASE_G * aniso;
    float gBack    = VL_PHASE_BACK_G * aniso;
    return (1.0 - VL_PHASE_BACK) * VolumetricSunPhaseHG(cosTheta, gForward)
         + VL_PHASE_BACK * VolumetricSunPhaseHG(cosTheta, gBack);
}

vec3 VolumetricSunMultiScatterPhase(float cosTheta, vec3 shadow, int orderCap) {
    vec3 msShadow = clamp(shadow, vec3(0.0), vec3(1.0));
    vec3 phaseLight = vec3(0.0);
    float msAmount = 1.0;
    float aniso = 1.0;

    for (int k = 0; k < FOG_MS_ORDER; ++k) {
        if (k >= orderCap) break;
        phaseLight += msShadow * VolumetricSunPhaseDual(cosTheta, aniso) * msAmount;
        msShadow = sqrt(max(msShadow, vec3(0.0)));
        msAmount *= FOG_MS_DECAY;
        aniso *= FOG_MS_ANISO_DECAY;
    }
    return phaseLight;
}

vec3 VolumetricDirectionalShadowAt(vec3 pRel, vec3 lightDirWorld, float distNorm) {
    vec3 biasedRel = pRel + lightDirWorld * FOG_SHADOW_BIAS;
    vec3 shadowScreen = shadowWorldToScreenWithMatrix(SceneShadowModelView(), biasedRel);

    if (shadowScreen.x < 0.0 || shadowScreen.x > 1.0 ||
        shadowScreen.y < 0.0 || shadowScreen.y > 1.0 ||
        shadowScreen.z < 0.0 || shadowScreen.z > 1.0) {
        return vec3(mix(1.0, FOG_SHADOW_OUTSIDE, clamp(distNorm, 0.0, 1.0)));
    }

#if VL_COLORED_SHAFT == 1
    vec3 coloredShadow = clamp(getShadow(shadowScreen), vec3(0.0), vec3(1.0));
    return clamp(coloredShadow * VL_COLORED_GAIN, vec3(0.0), vec3(1.0));
#else
    return vec3(clamp(getShadowOpaque(shadowScreen), 0.0, 1.0));
#endif
}

vec3 VolumetricDirectionalGain(bool activeIsSun) {
    if (activeIsSun) {
        return VL_SUN_TINT * clamp(VL_SUN_STRENGTH, 0.0, 2.0);
    }
#if VL_MOON_SHAFT == 1
    return vec3(VL_MOON_GAIN);
#else
    return vec3(0.0);
#endif
}

vec3 VolumetricSunLight(float cosTheta,
                        vec3 sunShadow,
                        vec3 lightRadiance,
                        vec3 sunTransmittance,
                        int msOrder,
                        bool activeIsSun) {
    vec3 phase = VolumetricSunMultiScatterPhase(cosTheta, sunShadow, msOrder);
    vec3 direct = phase * max(lightRadiance, vec3(0.0)) * max(sunTransmittance, vec3(0.0));
    return direct * VolumetricDirectionalGain(activeIsSun);
}

#endif
