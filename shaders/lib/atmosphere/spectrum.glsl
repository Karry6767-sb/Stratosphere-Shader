// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef LIB_ATMOSPHERE_SPECTRUM_GLSL
#define LIB_ATMOSPHERE_SPECTRUM_GLSL

const vec4 ATM_LAMBDA = vec4(410.0, 480.0, 560.0, 630.0);

const vec4 ATM_SOLAR = vec4(1.74769998, 2.05660009, 1.85350001, 1.65419996);

const vec4 ATM_MOON_IRR = vec4(0.1522710, 0.2695135, 0.1635034, 0.1553021) * 0.6;

const float ATM_MOON_SCATTER = 0.25;

const float ATM_EXPOSURE = 0.08;

const vec3  ATM_GROUND_ALBEDO_RGB = vec3(0.1, 0.2, 0.5);
const float ATM_GROUND_ALBEDO = 0.1;

vec3 SpectralToLinearSRGB(vec4 L) {
    return vec3(
        dot(L, vec4( 6.321843624, -26.517091751,  30.142539978, 118.707962036)),
        dot(L, vec4(-5.534153461,  17.321765900,  98.470054626,  -8.898775101)),
        dot(L, vec4(39.173206329,  71.765632629, -12.650737762,  -1.295249343)));
}

#endif
