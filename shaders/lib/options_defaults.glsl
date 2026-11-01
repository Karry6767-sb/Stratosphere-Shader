#ifndef LIB_OPTIONS_DEFAULTS_GLSL
#define LIB_OPTIONS_DEFAULTS_GLSL

#ifndef AA_MODE
#define AA_MODE 2 // [0 1 2 3 4]
#endif
#ifndef AGX_LOOK
#define AGX_LOOK 0 // [0 1 2]
#endif
#ifndef AMBIENT_SCALE
#define AMBIENT_SCALE 0.20 // [0.0 0.02 0.05 0.08 0.1 0.2 0.5 1.0]
#endif
#ifndef AO_INDIRECT_FLOOR
#define AO_INDIRECT_FLOOR 0.35 // [0.0 0.15 0.25 0.35 0.5 0.75 1.0]
#endif
#ifndef AO_RADIUS
#define AO_RADIUS 0.20 // [0.15 0.35 0.6 1.0 1.5]
#endif
#ifndef AO_SAMPLES
#define AO_SAMPLES 12 // [4 8 12 16]
#endif
#ifndef AO_STRENGTH
#define AO_STRENGTH 0.5 // [0.0 0.5 1.0 1.5 2.0 3.0]
#endif
#ifndef AO_TYPE
#define AO_TYPE 1 // [0 1 2]
#endif
#ifndef ATM_AIRGLOW
#define ATM_AIRGLOW 1 // [0 1]
#endif
#ifndef ATM_AIRGLOW_STRENGTH
#define ATM_AIRGLOW_STRENGTH 2.0 // [0.0 0.5 1.0 1.5 2.0 3.0]
#endif
#ifndef ATM_ANGSTROM
#define ATM_ANGSTROM 1.3 // [0.0 0.5 1.0 1.3 1.6 2.0]
#endif
#ifndef ATM_AP_LUT
#define ATM_AP_LUT 1 // [0 1]
#endif
#ifndef ATM_AP_STRENGTH
#define ATM_AP_STRENGTH 0.5 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5]
#endif
#ifndef ATM_AQI
#define ATM_AQI 25 // [0 25 50 100 150 200 300 400 500]
#endif
#ifndef ATM_CINE
#define ATM_CINE 1 // [0 1]
#endif
#ifndef ATM_CINE_BLUE
#define ATM_CINE_BLUE 1.0 // [0.3 0.6 0.8 1.0 1.3 1.6 2.0]
#endif
#ifndef ATM_CINE_HORIZON
#define ATM_CINE_HORIZON 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef ATM_CINE_SAT
#define ATM_CINE_SAT 1.15 // [0.9 1.0 1.15 1.25 1.4 1.6 1.8]
#endif
#ifndef ATM_CINE_SHADOW
#define ATM_CINE_SHADOW 0.6 // [0.0 0.3 0.6 0.8 1.0]
#endif
#ifndef ATM_CINE_SUNSET
#define ATM_CINE_SUNSET 1.3 // [0.0 0.5 0.8 1.0 1.3 1.6 2.0]
#endif
#ifndef ATM_DEBUG_MSLUT
#define ATM_DEBUG_MSLUT 0 // [0 1]
#endif
#ifndef ATM_ENABLE_PHYSICAL
#define ATM_ENABLE_PHYSICAL 1 // [0 1]
#endif
#ifndef ATM_EXP_FOG
#define ATM_EXP_FOG 1 // [0 1]
#endif
#ifndef ATM_EXP_FOG_STRENGTH
#define ATM_EXP_FOG_STRENGTH 1.5 // [0.25 0.5 1.0 1.5 2.0 3.0]
#endif
#ifndef ATM_LIGHT_POLLUTION
#define ATM_LIGHT_POLLUTION 1 // [0 1]
#endif
#ifndef ATM_LP_SCALE_HEIGHT
#define ATM_LP_SCALE_HEIGHT 0.10 // [0.04 0.07 0.10 0.16 0.25]
#endif
#ifndef ATM_LP_STRENGTH
#define ATM_LP_STRENGTH 1.0 // [0.0 0.25 0.5 1.0 1.5 2.0]
#endif
#ifndef ATM_MOON_BRIGHTNESS
#define ATM_MOON_BRIGHTNESS 1.0 // [0.4 0.6 0.8 1.0 1.3 1.6 2.0]
#endif
#ifndef ATM_REFRACTION
#define ATM_REFRACTION 1 // [0 1]
#endif
#ifndef ATM_REFRACTION_MAX
#define ATM_REFRACTION_MAX 0.020 // [0.005 0.008 0.010 0.014 0.020]
#endif
#ifndef ATM_SKY_PEAK
#define ATM_SKY_PEAK 12.0 // [2 3 4 6 8 12 20]
#endif
#ifndef ATM_SKY_RADIANCE_SCALE
#define ATM_SKY_RADIANCE_SCALE 0.8 // [0.25 0.35 0.5 0.65 0.8 1.0]
#endif
#ifndef ATM_SUN_BRIGHTNESS
#define ATM_SUN_BRIGHTNESS 2.0 // [0.5 0.75 1.0 1.5 2.0 2.5 3.0]
#endif
#ifndef ATM_SUN_GRANULATION
#define ATM_SUN_GRANULATION 1 // [0 1]
#endif
#ifndef ATM_SUN_GRANULE_CONTRAST
#define ATM_SUN_GRANULE_CONTRAST 0.14 // [0.0 0.07 0.14 0.25 0.4]
#endif
#ifndef ATM_SUN_GRANULE_SCALE
#define ATM_SUN_GRANULE_SCALE 26.0 // [10.0 16.0 26.0 40.0 64.0]
#endif
#ifndef ATM_SUN_SPOTS
#define ATM_SUN_SPOTS 1 // [0 1]
#endif
#ifndef ATM_SUN_SPOT_AMOUNT
#define ATM_SUN_SPOT_AMOUNT 0.45 // [0.0 0.2 0.35 0.45 0.6 0.8]
#endif
#ifndef AURORA_ENABLE
#define AURORA_ENABLE 1 // [0 1]
#endif
#ifndef AURORA_CHANCE
#define AURORA_CHANCE 2 // [1 2 3]
#endif
#ifndef AURORA_INTENSITY
#define AURORA_INTENSITY 1.5 // [0.1 0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#endif
#ifndef AURORA_SATURATION
#define AURORA_SATURATION 1.05 // [0.6 0.8 1.0 1.05 1.2 1.5]
#endif
#ifndef AURORA_PURPLE_TOP
#define AURORA_PURPLE_TOP 0.85 // [0.0 0.25 0.5 0.75 0.85 1.0]
#endif
#ifndef AURORA_STEPS_MAX
#define AURORA_STEPS_MAX 32 // [12 16 24 32 48]
#endif
#ifndef AURORA_STEPS_MIN
#define AURORA_STEPS_MIN 12 // [8 12 16 24]
#endif
#ifndef AURORA_MULTI_ARC
#define AURORA_MULTI_ARC 1 // [0 1]
#endif
#ifndef AURORA_MULTI_ARC_WEIGHT
#define AURORA_MULTI_ARC_WEIGHT 0.25 // [0.15 0.25 0.35 0.5 0.7]
#endif
#ifndef AURORA_COVERAGE
#define AURORA_COVERAGE 0.15
#endif
#ifndef AURORA_FULL_SKY
#define AURORA_FULL_SKY 0 // [0 1]
#endif
#ifndef AURORA_PULSATION
#define AURORA_PULSATION 1 // [0 1]
#endif
#ifndef AURORA_GROUND_LIGHT
#define AURORA_GROUND_LIGHT 1 // [0 1]
#endif
#ifndef AURORA_GROUND_STRENGTH
#define AURORA_GROUND_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef AURORA_DIST
#define AURORA_DIST 200.0 // [20.0 50.0 80.0 120.0 200.0 300.0 400.0 600.0]
#endif
#ifndef AURORA_BAND_W
#define AURORA_BAND_W 16.0 // [10.0 16.0 22.0 28.0 40.0 60.0 90.0]
#endif
#ifndef AURORA_ARC_AMP
#define AURORA_ARC_AMP 40.0 // [0.0 10.0 25.0 40.0 60.0 80.0]
#endif
#ifndef AURORA_ARC_DYNAMICS
#define AURORA_ARC_DYNAMICS 1 // [0 1]
#endif
#ifndef AURORA_ARC_SPEED
#define AURORA_ARC_SPEED 1.0 // [0.25 0.5 0.6 1.0 1.5]
#endif
#ifndef AURORA_RAY_CONTRAST
#define AURORA_RAY_CONTRAST 2.0 // [1.0 1.5 2.0 3.0 4.0]
#endif
#ifndef AURORA_FOLD_WEIGHT
#define AURORA_FOLD_WEIGHT 0.6 // [0.0 0.3 0.6 0.85 1.0]
#endif
#ifndef AURORA_DIP
#define AURORA_DIP 78.0 // [60.0 70.0 78.0 85.0]
#endif
#ifndef AURORA_H_BOTTOM
#define AURORA_H_BOTTOM 90.0 // [80.0 90.0 100.0 110.0]
#endif
#ifndef AURORA_H_TOP
#define AURORA_H_TOP 400.0 // [300.0 350.0 400.0 500.0]
#endif
#ifndef AUTO_EV_BIAS
#define AUTO_EV_BIAS 0.0 // [-2.0 -1.0 -0.5 0.0 0.25 0.5 1.0 2.0]
#endif
#ifndef AUTO_EV_MAX
#define AUTO_EV_MAX 14.0 // [12.0 14.0 16.0]
#endif
#ifndef AUTO_EV_MIN
#define AUTO_EV_MIN -7.0 // [-24.0 -16.0 -12.0 -9.0 -7.0 -5.0 -4.0]
#endif
#ifndef BB_FIRE_TEMP
#define BB_FIRE_TEMP 2500 // [1500 1800 2000 2500 3000 3500]
#endif
#ifndef BB_MOON_TEMP
#define BB_MOON_TEMP 4500.0 // [3000 3500 4100 4500 5000 6500]
#endif
#ifndef BB_SUN_TEMP
#define BB_SUN_TEMP 5778.0 // [4500 5200 5778 6500]
#endif
#ifndef CELESTIAL_DUAL_LIGHT
#define CELESTIAL_DUAL_LIGHT 1 // [0 1]
#endif
#ifndef CELESTIAL_ANGULAR_SCALE
#define CELESTIAL_ANGULAR_SCALE 3.225 // [1.0 2.0 2.5 3.0 3.225 3.5 4.0]
#endif
#ifndef CELESTIAL_HORIZON_SOFTNESS
#define CELESTIAL_HORIZON_SOFTNESS 1.0 // [0.5 1.0 1.5 2.0 3.0]
#endif
#ifndef CELESTIAL_REFRACTION_DEG
#define CELESTIAL_REFRACTION_DEG 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef DAYLIGHT_LEGACY
#define DAYLIGHT_LEGACY 0 // [0 1]
#endif
#ifndef DAYLIGHT_TWILIGHT_HIGH
#define DAYLIGHT_TWILIGHT_HIGH -0.5 // [-1.5 -0.5 0.0 2.0]
#endif
#ifndef DAYLIGHT_TWILIGHT_LOW
#define DAYLIGHT_TWILIGHT_LOW -12.0 // [-18.0 -15.0 -12.0 -9.0 -6.0]
#endif
#ifndef BLOOM_ANAMORPHIC_X
#define BLOOM_ANAMORPHIC_X 3.0 // [1.0 1.5 2.0 3.0 4.0]
#endif
#ifndef BLOOM_CHROMA
#define BLOOM_CHROMA 1 // [0 1]
#endif
#ifndef BLOOM_CHROMA_AMOUNT
#define BLOOM_CHROMA_AMOUNT 1.0 // [0.0 0.15 0.25 0.35 0.5 0.75 1.0]
#endif
#ifndef BLOOM_FIREFLY
#define BLOOM_FIREFLY 0.25 // [0.0 0.05 0.15 0.25 0.4 0.7]
#endif
#ifndef BLOOM_INTENSITY
#define BLOOM_INTENSITY 1.0 // [0.0 0.1 0.2 0.35 0.5 0.7 1.0]
#endif
#ifndef BLOOM_MIP_CHAIN
#define BLOOM_MIP_CHAIN 1 // [0 1]
#endif
#ifndef BLOOM_MIP_LEVELS
#define BLOOM_MIP_LEVELS 6 // [2 3 4 5 6]
#endif
#ifndef BLOOM_SOFT
#define BLOOM_SOFT 0.75 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef BLOOM_STREAK
#define BLOOM_STREAK 0.7 // [0.0 0.15 0.35 0.5 0.7 1.0]
#endif
#ifndef BLOOM_STREAK_REACH
#define BLOOM_STREAK_REACH 24.0 // [8.0 16.0 24.0 32.0 48.0]
#endif
#ifndef BLOOM_THRESHOLD
#define BLOOM_THRESHOLD 0.3 // [0.3 0.5 0.8 1.0 1.5 2.0]
#endif
#ifndef BRIGHTNESS
#define BRIGHTNESS 1.0 // [0.6 0.7 0.85 1.0 1.15 1.3]
#endif
#ifndef CINE_BARREL
#define CINE_BARREL 0.0 // [0.0 0.02 0.04 0.06 0.10]
#endif
#ifndef CINE_CHROMA
#define CINE_CHROMA 0.35 // [0.0 0.15 0.25 0.35 0.5 0.8]
#endif
#ifndef CINE_CHROMA_MODE
#define CINE_CHROMA_MODE 0 // [0 1]
#endif
#ifndef CINE_CYLINDRICAL
#define CINE_CYLINDRICAL 0.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef CINE_FISHEYE
#define CINE_FISHEYE 0.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef CINE_GRAIN
#define CINE_GRAIN 0.0 // [0.0 0.1 0.2 0.35 0.5 0.7 1.0]
#endif
#ifndef CINE_GRAIN_LUMA_DEP
#define CINE_GRAIN_LUMA_DEP 0.7 // [0.0 0.35 0.7 1.0]
#endif
#ifndef CINE_GRAIN_SIZE
#define CINE_GRAIN_SIZE 1.6 // [1.0 1.6 2.4 3.5]
#endif
#ifndef CINE_HALATION
#define CINE_HALATION 0.25 // [0.0 0.1 0.18 0.25 0.4 0.6]
#endif
#ifndef CINE_HALATION_THRESHOLD
#define CINE_HALATION_THRESHOLD 0.7 // [0.5 0.6 0.7 0.8 0.9]
#endif
#ifndef CINE_INTRO
#define CINE_INTRO 1 // [0 1]
#endif
#ifndef CINE_INTRO_DURATION
#define CINE_INTRO_DURATION 5.0 // [3.0 4.0 5.0 6.0 8.0]
#endif
#ifndef CINE_LENS_K1
#define CINE_LENS_K1 0.0 // [-0.10 -0.05 0.0 0.02 0.05 0.10]
#endif
#ifndef CINE_LENS_K2
#define CINE_LENS_K2 0.0 // [-0.02 -0.01 0.0 0.01 0.02]
#endif
#ifndef CINE_LETTERBOX
#define CINE_LETTERBOX 0 // [0 1]
#endif
#ifndef CINE_LETTERBOX_SIZE
#define CINE_LETTERBOX_SIZE 0.10 // [0.04 0.06 0.08 0.10 0.12 0.16]
#endif
#ifndef CINE_VIGNETTE
#define CINE_VIGNETTE 0.35 // [0.0 0.15 0.25 0.35 0.5 0.7 1.0]
#endif
#ifndef CINE_VIGNETTE_ANAMORPHIC
#define CINE_VIGNETTE_ANAMORPHIC 1 // [0 1]
#endif
#ifndef COLOR_OFFSET
#define COLOR_OFFSET 0.4 // [0.0 0.15 0.25 0.4 0.7 1.0]
#endif
#ifndef COMET_BRIGHTNESS
#define COMET_BRIGHTNESS 0.6 // [0.0 0.3 0.6 1.0 1.5 2.5]
#endif
#ifndef COMET_CHANCE
#define COMET_CHANCE 0.35 // [0.05 0.15 0.35 0.6 1.0]
#endif
#ifndef COMET_DEBUG_FORCE
#define COMET_DEBUG_FORCE 1 // [0 1]
#endif
#ifndef COMET_DUST_BEND
#define COMET_DUST_BEND 0.2 // [0.0 0.2 0.35 0.55 0.8 1.1]
#endif
#ifndef COMET_DUST_CURVE
#define COMET_DUST_CURVE 0.18 // [0.0 0.01 0.03 0.06 0.10 0.18]
#endif
#ifndef COMET_DUST_INTENSITY
#define COMET_DUST_INTENSITY 10.0 // [0.0 2.0 5.0 8.0 10.0 14.0 22.0]
#endif
#ifndef COMET_DUST_LEN
#define COMET_DUST_LEN 0.6 // [0.2 0.4 0.6 0.85 1.1 1.5]
#endif
#ifndef COMET_DUST_WIDEST
#define COMET_DUST_WIDEST 0.028 // [0.008 0.011 0.015 0.020 0.028]
#endif
#ifndef COMET_DUST_WIDTH
#define COMET_DUST_WIDTH 0.024 // [0.004 0.007 0.010 0.016 0.024]
#endif
#ifndef COMET_ELEV_BASE
#define COMET_ELEV_BASE 0.9 // [0.4 0.65 0.9 1.15]
#endif
#ifndef COMET_HEAD_GAIN
#define COMET_HEAD_GAIN 1.6 // [0.0 0.6 1.0 1.6 2.5 4.0]
#endif
#ifndef COMET_HEAD_SIZE
#define COMET_HEAD_SIZE 0.005 // [0.003 0.005 0.007 0.009 0.013 0.020]
#endif
#ifndef COMET_ION_CURVE
#define COMET_ION_CURVE 0.0 // [0.0 0.01 0.03 0.06 0.10]
#endif
#ifndef COMET_ION_INTENSITY
#define COMET_ION_INTENSITY 6.0 // [0.0 1.5 3.0 6.0 10.0 16.0]
#endif
#ifndef COMET_ION_LEN
#define COMET_ION_LEN 0.3 // [0.3 0.5 0.7 0.9 1.3 1.8]
#endif
#ifndef COMET_ION_WIDEST
#define COMET_ION_WIDEST 0.012 // [0.005 0.008 0.012 0.018 0.028]
#endif
#ifndef COMET_ION_WIDTH
#define COMET_ION_WIDTH 0.006 // [0.002 0.004 0.006 0.010 0.016]
#endif
#ifndef COMET_PERIOD
#define COMET_PERIOD 300.0 // [120.0 180.0 300.0 600.0 1200.0]
#endif
#ifndef COMET_TAIL_ANALYTIC
#define COMET_TAIL_ANALYTIC 0 // [0 1]
#endif
#ifndef COMET_TAIL_BEND_POW
#define COMET_TAIL_BEND_POW 1.2 // [0.8 1.0 1.2 1.5 2.0]
#endif
#ifndef COMET_TAIL_DENSITY
#define COMET_TAIL_DENSITY 1.00 // [0.4 0.7 1.0 1.4 2.0 3.0]
#endif
#ifndef COMET_TAIL_SHARP
#define COMET_TAIL_SHARP 1.0 // [0.6 0.8 1.0 1.4 2.0]
#endif
#ifndef COMET_TAIL_STEPS
#define COMET_TAIL_STEPS 64 // [32 48 64 96 128]
#endif
#ifndef COMET_TAIL_TAPER
#define COMET_TAIL_TAPER 0.80 // [0.42 0.55 0.65 0.80 1.0]
#endif
#ifndef COMET_WINDOW
#define COMET_WINDOW 0.6 // [0.3 0.45 0.6 0.8]
#endif
#ifndef CONTACT_SHADOW
#define CONTACT_SHADOW 1 // [0 1]
#endif
#ifndef CONTACT_SHADOW_LENGTH
#define CONTACT_SHADOW_LENGTH 0.75 // [0.75 1.0 1.5 2.0 3.0]
#endif
#ifndef CONTACT_SHADOW_SAMPLES
#define CONTACT_SHADOW_SAMPLES 8 // [6 8 10 12 16]
#endif
#ifndef CONTRAST
#define CONTRAST 0.22 // [-0.5 -0.25 0.0 0.1 0.15 0.22 0.3 0.35 0.5]
#endif
#ifndef DEBAND_EDGE_HI
#define DEBAND_EDGE_HI 0.12 // [0.06 0.08 0.12 0.18 0.25]
#endif
#ifndef DEBAND_EDGE_LO
#define DEBAND_EDGE_LO 0.02 // [0.005 0.01 0.02 0.04 0.08]
#endif
#ifndef DEBAND_MODE
#define DEBAND_MODE 1 // [0 1]
#endif
#ifndef DEBAND_STRENGTH
#define DEBAND_STRENGTH 0.35 // [0.0 0.1 0.2 0.35 0.45]
#endif
#ifndef DITHER_STRENGTH
#define DITHER_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef DRT_EXPOSURE
#define DRT_EXPOSURE 0.75 // [0.5 0.75 1.0 1.25 1.5]
#endif
#ifndef DRT_OPERATOR
#define DRT_OPERATOR 1 // [1 2]
#endif
#ifndef EDGE_FOG_STRENGTH
#define EDGE_FOG_STRENGTH 0.5 // [0.2 0.4 0.5 0.7 1.0 1.5]
#endif
#ifndef EMISSIVE_STRENGTH
#define EMISSIVE_STRENGTH 3.0 // [0.0 0.5 1.0 1.5 2.0 3.0 4.0]
#endif
#ifndef ENABLE_COMETS
#define ENABLE_COMETS 1 // [0 1]
#endif
#ifndef ENABLE_EDGE_FOG
#define ENABLE_EDGE_FOG 0 // [0 1]
#endif
#ifndef ENABLE_GALAXY
#define ENABLE_GALAXY 1 // [0 1]
#endif
#ifndef ENABLE_METEORS
#define ENABLE_METEORS 1 // [0 1]
#endif
#ifndef ENABLE_MOON_ORBIT
#define ENABLE_MOON_ORBIT 1 // [0 1]
#endif
#ifndef ENABLE_MOON_PHASE
#define ENABLE_MOON_PHASE 1 // [0 1]
#endif
#ifndef ENABLE_MOON_SHADOW
#define ENABLE_MOON_SHADOW 1 // [0 1]
#endif
#ifndef ENABLE_STARS
#define ENABLE_STARS 0 // [0 1]
#endif
#ifndef EXPOSURE_AMBIENT_FLOOR
#define EXPOSURE_AMBIENT_FLOOR 0.20 // [0.0 0.02 0.05 0.1 0.2 0.5]
#endif
#ifndef EXPOSURE_ENABLED
#define EXPOSURE_ENABLED 0 // [0 1]
#endif
#ifndef EXPOSURE_HIGHLIGHT_EV
#define EXPOSURE_HIGHLIGHT_EV 6.0 // [2.0 3.0 4.0 6.0 10.0 99.0]
#endif
#ifndef EXPOSURE_KEY_STRENGTH
#define EXPOSURE_KEY_STRENGTH 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef EXPOSURE_KEY_VALUE
#define EXPOSURE_KEY_VALUE 1 // [0 1]
#endif
#ifndef EXPOSURE_MODE
#define EXPOSURE_MODE 0 // [0 1 2]
#endif
#ifndef EXPOSURE_NIGHT_AMBIENT
#define EXPOSURE_NIGHT_AMBIENT 0.02 // [0.002 0.005 0.01 0.02 0.05 0.1]
#endif
#ifndef EXPOSURE_NIGHT_KEY
#define EXPOSURE_NIGHT_KEY 0.5 // [0.05 0.1 0.15 0.2 0.3 0.5]
#endif
#ifndef EXPOSURE_SKY_WEIGHT
#define EXPOSURE_SKY_WEIGHT 0.50 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef EXPOSURE_SKY_WEIGHT_NIGHT
#define EXPOSURE_SKY_WEIGHT_NIGHT 0.60 // [0.0 0.25 0.5 0.6 0.75 1.0]
#endif
#ifndef EXPOSURE_SPEED_DOWN
#define EXPOSURE_SPEED_DOWN 1.8 // [0.3 0.5 0.8 1.0 1.5 1.8 2.5 3.0]
#endif
#ifndef EXPOSURE_SPEED_UP
#define EXPOSURE_SPEED_UP 0.6 // [0.3 0.5 0.6 1.0 1.5 2.0 3.0]
#endif
#ifndef VL_SUN_STRENGTH
#define VL_SUN_STRENGTH 2.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#endif
#ifndef VL_PHASE
#define VL_PHASE 0.86 // [0.35 0.5 0.6 0.72 0.8 0.86]
#endif
#ifndef VL_PHASE_G
#define VL_PHASE_G VL_PHASE
#endif
#ifndef VL_PHASE_BACK
#define VL_PHASE_BACK 0.25
#endif
#ifndef VL_PHASE_BACK_G
#define VL_PHASE_BACK_G -0.15
#endif
#ifndef VL_SUN_TINT_R
#define VL_SUN_TINT_R 1.0
#endif
#ifndef VL_SUN_TINT_G
#define VL_SUN_TINT_G 1.0
#endif
#ifndef VL_SUN_TINT_B
#define VL_SUN_TINT_B 1.0
#endif
#ifndef VL_SUN_TINT
#define VL_SUN_TINT vec3(VL_SUN_TINT_R, VL_SUN_TINT_G, VL_SUN_TINT_B)
#endif
#ifndef VL_COLORED_SHAFT
#define VL_COLORED_SHAFT 1 // [0 1]
#endif
#ifndef VL_COLORED_GAIN
#define VL_COLORED_GAIN 1.6
#endif
#ifndef VL_MOON_SHAFT
#define VL_MOON_SHAFT 1 // [0 1]
#endif
#ifndef VL_MOON_GAIN
#define VL_MOON_GAIN 8.0
#endif

#ifndef VL_BLOCK_FOG
#define VL_BLOCK_FOG 1 // [0 1]
#endif
#ifndef VL_BLOCK_FOG_GAIN
#define VL_BLOCK_FOG_GAIN 0.35
#endif

#ifndef VL_POINT_LIGHT
#define VL_POINT_LIGHT 1 // [0 1]
#endif
#ifndef VL_MAX_LIGHTS
#define VL_MAX_LIGHTS 8
#endif
#ifndef VL_MAX_DIST
#define VL_MAX_DIST 32.0
#endif
#ifndef VL_POINT_SIGMA
#define VL_POINT_SIGMA 0.020
#endif
#ifndef VL_POINT_PHASE
#define VL_POINT_PHASE 0.0
#endif
#ifndef VL_POINT_GAIN
#define VL_POINT_GAIN 3.0
#endif
#ifndef VL_POINT_MIN_RADIUS
#define VL_POINT_MIN_RADIUS 0.20
#endif

#ifndef VL_FLASH
#define VL_FLASH 1 // [0 1]
#endif
#ifndef VL_FLASH_GAIN
#define VL_FLASH_GAIN 1.0
#endif
#ifndef VL_FLASH_DECAY
#define VL_FLASH_DECAY 12.0
#endif
#ifndef VL_FLASH_LIFETIME
#define VL_FLASH_LIFETIME 0.20
#endif
#ifndef VL_FLASH_MAX_DIST
#define VL_FLASH_MAX_DIST 64.0
#endif
#ifndef VL_FLASH_MAX
#define VL_FLASH_MAX 8
#endif
#ifndef VL_FLASH_SSBO_BINDING
#define VL_FLASH_SSBO_BINDING 2
#endif
#ifndef VL_LIGHTNING_EMISSIVE
#define VL_LIGHTNING_EMISSIVE 24.0
#endif
#ifndef VL_LIGHTNING_EMISSIVE_BASE
#define VL_LIGHTNING_EMISSIVE_BASE 8.0
#endif

#ifndef ENABLE_LOCAL_FOG
#define ENABLE_LOCAL_FOG 1 // [0 1]
#endif
#ifndef FOG_DENSITY
#define FOG_DENSITY 0.75 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#endif
#ifndef FOG_HEIGHTMAP
#define FOG_HEIGHTMAP 1 // [0 1]
#endif
#ifndef FOG_NOISE
#define FOG_NOISE 0.45 // [0.0 0.15 0.3 0.45 0.65 0.8 1.0]
#endif
#ifndef FOG_NOISE_AMOUNT
#define FOG_NOISE_AMOUNT FOG_NOISE
#endif
#ifndef FOG_NOISE_SCALE
#define FOG_NOISE_SCALE 0.032 // [0.004 0.008 0.012 0.016 0.024 0.032]
#endif
#ifndef FOG_SOFTNESS
#define FOG_SOFTNESS 6.0 // [2.0 4.0 6.0 9.0 12.0]
#endif
#ifndef FOG_PHASE
#define FOG_PHASE VL_PHASE
#endif
#ifndef FOG_MORNING
#define FOG_MORNING 1 // [0 1]
#endif
#ifndef FOG_HIGH_LAYER
#define FOG_HIGH_LAYER 1 // [0 1]
#endif
#ifndef FOG_HIGH_START
#define FOG_HIGH_START 96.0 // [96.0 112.0 120.0 126.0 140.0 160.0 192.0 224.0]
#endif
#ifndef FOG_HIGH_DENSITY
#define FOG_HIGH_DENSITY 0.2 // [0.1 0.2 0.35 0.5 0.75 1.0]
#endif
#ifndef FOG_HIGH_BLEND
#define FOG_HIGH_BLEND 32.0 // [4.0 8.0 12.0 16.0 24.0 32.0]
#endif
#ifndef FOG_HIGH_SCALE_H
#define FOG_HIGH_SCALE_H 64.0
#endif
#ifndef FOG_VALLEY
#define FOG_VALLEY 1 // [0 1]
#endif
#ifndef FOG_VALLEY_HEIGHT
#define FOG_VALLEY_HEIGHT 24.0 // [0.0 8.0 16.0 24.0 32.0 48.0 64.0]
#endif
#ifndef FOG_VALLEY_DENSITY
#define FOG_VALLEY_DENSITY 0.5 // [0.5 1.0 1.5 2.0 3.0]
#endif
#ifndef FOG_VALLEY_SCALE_H
#define FOG_VALLEY_SCALE_H 32.0
#endif
#ifndef FOG_VOLUME
#define FOG_VOLUME 0 // [0 1]
#endif
#ifndef FOG_VOLUME_X
#define FOG_VOLUME_X 0.0 // [-256.0 -128.0 -64.0 0.0 64.0 128.0 256.0]
#endif
#ifndef FOG_VOLUME_Y
#define FOG_VOLUME_Y 63.0 // [0.0 32.0 48.0 63.0 80.0 96.0 128.0 160.0 200.0]
#endif
#ifndef FOG_VOLUME_Z
#define FOG_VOLUME_Z 0.0 // [-256.0 -128.0 -64.0 0.0 64.0 128.0 256.0]
#endif
#ifndef FOG_VOLUME_RX
#define FOG_VOLUME_RX 32.0 // [8.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#endif
#ifndef FOG_VOLUME_RY
#define FOG_VOLUME_RY 12.0 // [4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0]
#endif
#ifndef FOG_VOLUME_RZ
#define FOG_VOLUME_RZ 32.0 // [8.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#endif
#ifndef FOG_VOLUME_DENSITY
#define FOG_VOLUME_DENSITY 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#endif
#ifndef FOG_QUALITY
#define FOG_QUALITY 1 // [0 1 2 3]
#endif
#ifndef FOG_AMBIENT
#define FOG_AMBIENT 0.35
#endif
#ifndef FOG_BASE_DEPTH
#define FOG_BASE_DEPTH 18.0
#endif
#ifndef FOG_BASE
#define FOG_BASE (FOG_SEA_LEVEL - FOG_BASE_DEPTH)
#endif
#ifndef FOG_COLORED_SHADOW
#define FOG_COLORED_SHADOW VL_COLORED_SHAFT
#endif
#ifndef FOG_DAY_AMT
#define FOG_DAY_AMT 0.6 // [0.2 0.35 0.5 0.6 0.75 0.9 1.0]
#endif
#ifndef FOG_NIGHT_AMT
#define FOG_NIGHT_AMT 0.55 // [0.2 0.35 0.5 0.55 0.7 0.85 1.0]
#endif
#ifndef FOG_PEAK_ELEV
#define FOG_PEAK_ELEV 4.0
#endif
#ifndef FOG_PEAK_WIDTH
#define FOG_PEAK_WIDTH 9.0
#endif
#ifndef FOG_RAIN_BOOST
#define FOG_RAIN_BOOST 3.6 // [1.0 1.4 1.8 2.2 2.6 3.0 3.6]
#endif
#ifndef FOG_RAIN_TOP_LIFT
#define FOG_RAIN_TOP_LIFT 24.0 // [0.0 4.0 8.0 12.0 18.0 24.0]
#endif
#ifndef FOG_HEIGHTMAP_BIAS_CM
#define FOG_HEIGHTMAP_BIAS_CM 10000.0
#endif
#ifndef FOG_HEIGHTMAP_CELL_SIZE
#define FOG_HEIGHTMAP_CELL_SIZE 8.0
#endif
#ifndef FOG_HEIGHTMAP_CENTER_QUANTUM
#define FOG_HEIGHTMAP_CENTER_QUANTUM 128.0
#endif
#ifndef FOG_HEIGHTMAP_FORGET_CM
#define FOG_HEIGHTMAP_FORGET_CM 2.0
#endif
#ifndef FOG_HEIGHTMAP_MAX_AGE
#define FOG_HEIGHTMAP_MAX_AGE 96
#endif
#ifndef FOG_VOLUME_EDGE
#define FOG_VOLUME_EDGE 2.0
#endif
#ifndef FOG_EXIT_T
#define FOG_EXIT_T 1.0e-3
#endif
#ifndef FOG_MAX_RAY
#define FOG_MAX_RAY 260.0
#endif
#ifndef FOG_MAX_STEPS
#define FOG_MAX_STEPS 24
#endif
#ifndef FOG_MIN_STEPS
#define FOG_MIN_STEPS 8
#endif
#ifndef FOG_MS_ANISO_DECAY
#define FOG_MS_ANISO_DECAY 0.7
#endif
#ifndef FOG_MS_DECAY
#define FOG_MS_DECAY 0.5
#endif
#ifndef FOG_MS_ORDER
#define FOG_MS_ORDER 3
#endif
#ifndef FOG_PHASE_BACK
#define FOG_PHASE_BACK VL_PHASE_BACK
#endif
#ifndef FOG_PHASE_BACK_G
#define FOG_PHASE_BACK_G VL_PHASE_BACK_G
#endif
#ifndef FOG_PHASE_G
#define FOG_PHASE_G VL_PHASE_G
#endif
#ifndef FOG_SCALE_H
#define FOG_SCALE_H 12.0
#endif
#ifndef FOG_SCATTER_ALBEDO
#define FOG_SCATTER_ALBEDO 0.98
#endif
#ifndef FOG_SEA_LEVEL
#define FOG_SEA_LEVEL 63.0
#endif
#ifndef FOG_SHADOW_BIAS
#define FOG_SHADOW_BIAS 0.05
#endif
#ifndef FOG_SHADOW_OUTSIDE
#define FOG_SHADOW_OUTSIDE 0.35
#endif
#ifndef FOG_SIGMA0
#define FOG_SIGMA0 0.026
#endif
#ifndef FOG_STEP_GROWTH
#define FOG_STEP_GROWTH 0.10
#endif
#ifndef FOG_SUN_OD_GROWTH
#define FOG_SUN_OD_GROWTH 1.5
#endif
#ifndef FOG_SUN_OD_START_STEP
#define FOG_SUN_OD_START_STEP 4.0
#endif
#ifndef FOG_SUN_OD_STEPS
#define FOG_SUN_OD_STEPS 3
#endif
#ifndef FOG_TERRAIN_RANGE
#define FOG_TERRAIN_RANGE 128.0
#endif
#ifndef FOG_TOP_NOISE_AMP
#define FOG_TOP_NOISE_AMP 3.0 // [1.0 2.0 3.0 5.0 8.0 12.0]
#endif
#ifndef FOG_TOP_NOISE_SCALE
#define FOG_TOP_NOISE_SCALE 0.02 // [0.004 0.006 0.008 0.012 0.02]
#endif
#ifndef FOG_WIND_SPEED
#define FOG_WIND_SPEED 0.02 // [0.0 0.002 0.004 0.008 0.012 0.02]
#endif
#ifndef GAIN_B
#define GAIN_B 1.0 // [0.85 0.9 0.95 1.0 1.05 1.1 1.15]
#endif
#ifndef GAIN_G
#define GAIN_G 1.0 // [0.85 0.9 0.95 1.0 1.05 1.1 1.15]
#endif
#ifndef GAIN_R
#define GAIN_R 1.0 // [0.85 0.9 0.95 1.0 1.05 1.1 1.15]
#endif
#ifndef GALAXY_DEBUG
#define GALAXY_DEBUG 0 // [0 1]
#endif
#ifndef GALAXY_INTENSITY
#define GALAXY_INTENSITY 0.6 // [0.0 0.1 0.25 0.4 0.6 0.8 1.0 1.5 2.0]
#endif
#ifndef GALAXY_LATITUDE
#define GALAXY_LATITUDE 43.0 // [0.0 20.0 30.0 40.0 43.0 50.0 60.0 90.0]
#endif
#ifndef GALAXY_RA_SIGN
#define GALAXY_RA_SIGN 1.0 // [-1.0 1.0]
#endif
#ifndef GALAXY_SOLAR_POS
#define GALAXY_SOLAR_POS 0.5 // [0.0 0.25 0.5 0.75]
#endif
#ifndef GAMMA_BLACK_LIFT
#define GAMMA_BLACK_LIFT 0.008 // [0.0 0.004 0.008 0.015 0.03]
#endif
#ifndef GAMMA_OUT
#define GAMMA_OUT 1.0 // [0.8 0.9 1.0 1.1 1.25 1.5 2.2]
#endif
#ifndef GLASS_ABSORPTION
#define GLASS_ABSORPTION 1.0 // [0.0 0.3 0.6 1.0 1.5 2.0 3.0]
#endif
#ifndef GLASS_DISPERSION
#define GLASS_DISPERSION 0.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#endif
#ifndef GLASS_ENABLED
#define GLASS_ENABLED 1 // [0 1]
#endif
#ifndef GLASS_ICE_BUMP
#define GLASS_ICE_BUMP 0.15 // [0.0 0.15 0.25 0.35 0.5 0.75 1.0]
#endif
#ifndef GLASS_INTERNAL_BOUNCE
#define GLASS_INTERNAL_BOUNCE 2 // [0 1 2 3 4]
#endif
#ifndef GLASS_REFLECT
#define GLASS_REFLECT 1.0 // [0.0 0.3 0.6 1.0 1.3 1.6 2.0]
#endif
#ifndef GLASS_REFRACT
#define GLASS_REFRACT 0.018 // [0.0 0.005 0.01 0.018 0.03 0.05]
#endif
#ifndef GLASS_SCATTER
#define GLASS_SCATTER 0.35 // [0.0 0.1 0.2 0.35 0.5 0.75 1.0]
#endif
#ifndef GLASS_SSR
#define GLASS_SSR 1 // [0 1]
#endif
#ifndef GLASS_SUN_DISC
#define GLASS_SUN_DISC 1 // [0 1]
#endif
#ifndef GLASS_THICKNESS
#define GLASS_THICKNESS 0.0625 // [0.02 0.03125 0.0625 0.125 0.25 0.5 1.0]
#endif
#ifndef GRADE_CONTRAST
#define GRADE_CONTRAST 0.35 // [-1.0 -0.5 -0.25 0.0 0.25 0.5 1.0]
#endif
#ifndef GRADE_EXPOSURE
#define GRADE_EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5]
#endif
#ifndef GRADE_GAIN
#define GRADE_GAIN 1.03 // [1.0 1.03 1.05 1.08 1.12]
#endif
#ifndef GRADE_GREEN_SAT
#define GRADE_GREEN_SAT 0.05 // [-0.3 -0.2 -0.15 -0.1 0.0 0.05 0.1 0.2 0.35 0.5]
#endif
#ifndef GRADE_HUE_SHIFT
#define GRADE_HUE_SHIFT 0.0 // [-0.5 -0.25 0.0 0.25 0.5]
#endif
#ifndef GRADE_ORANGE_SAT
#define GRADE_ORANGE_SAT 0.25 // [-0.3 -0.1 0.0 0.05 0.1 0.25 0.45 0.6]
#endif
#ifndef GRADE_SATURATION
#define GRADE_SATURATION 1.25 // [0.0 0.25 0.5 0.75 1.0 1.05 1.1 1.25 1.5]
#endif
#ifndef GRADE_TEAL_SAT
#define GRADE_TEAL_SAT 0.1 // [-0.3 -0.2 -0.1 0.0 0.05 0.1 0.2 0.35 0.5]
#endif
#ifndef GROUND_BOUNCE
#define GROUND_BOUNCE 0.2 // [0.0 0.03 0.06 0.12 0.2]
#endif
#ifndef HIGHLIGHT_B
#define HIGHLIGHT_B -0.05 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef HIGHLIGHT_G
#define HIGHLIGHT_G -0.03 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef HIGHLIGHT_R
#define HIGHLIGHT_R -0.02 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef HISTOGRAM_LOWER
#define HISTOGRAM_LOWER 0.4 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#endif
#ifndef HISTOGRAM_MODE_SPAN
#define HISTOGRAM_MODE_SPAN 24 // [4 8 16 24 40 64]
#endif
#ifndef HISTOGRAM_UPPER
#define HISTOGRAM_UPPER 0.8 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#endif
#ifndef INDIRECT_SPECULAR
#define INDIRECT_SPECULAR 1 // [0 1]
#endif
#ifndef LIGHTING_PBR
#define LIGHTING_PBR 1 // [0 1]
#endif
#ifndef LIGHTING_PI
#define LIGHTING_PI 1 // [0 1]
#endif
#ifndef LIGHTING_SPECULAR
#define LIGHTING_SPECULAR 1 // [0 1]
#endif
#ifndef LIGHTMAP_GAMMA
#define LIGHTMAP_GAMMA 2.0 // [1.0 1.5 2.0 2.5]
#endif
#ifndef LUT_ENABLED
#define LUT_ENABLED 1 // [0 1]
#endif
#ifndef LUT_STRENGTH
#define LUT_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef MANUAL_EV
#define MANUAL_EV 0.0 // [-2.0 -1.0 0.0 1.0 2.0 3.0 4.0]
#endif
#ifndef METEOR_BRIGHTNESS
#define METEOR_BRIGHTNESS 0.65 // [0.0 0.25 0.4 0.65 1.0 1.6 3.0]
#endif
#ifndef METEOR_FADE_IN
#define METEOR_FADE_IN 0.15 // [0.03 0.08 0.12 0.15 0.22 0.35]
#endif
#ifndef METEOR_FADE_START
#define METEOR_FADE_START 0.45 // [0.35 0.4 0.45 0.55 0.7 0.85]
#endif
#ifndef METEOR_HEAD_GAIN
#define METEOR_HEAD_GAIN 0.65 // [0.0 0.2 0.4 0.65 1.0 1.6 3.0]
#endif
#ifndef METEOR_HEAD_SIZE
#define METEOR_HEAD_SIZE 0.0010 // [0.0 0.0005 0.0008 0.0010 0.0016 0.0030 0.006]
#endif
#ifndef METEOR_LIFE
#define METEOR_LIFE 0.45 // [0.25 0.35 0.45 0.6 0.8 1.2 2.0]
#endif
#ifndef METEOR_MULTI_SHOWER
#define METEOR_MULTI_SHOWER 1 // [0 1]
#endif
#ifndef METEOR_PATH_LEN
#define METEOR_PATH_LEN 0.24 // [0.08 0.12 0.17 0.24 0.32 0.45]
#endif
#ifndef METEOR_RADIANT_DEC
#define METEOR_RADIANT_DEC 58.0 // [-60.0 -30.0 -17.0 -16.0 -1.0 0.0 16.0 22.0 33.0 49.0 58.0 76.0]
#endif
#ifndef METEOR_RADIANT_RA
#define METEOR_RADIANT_RA 48.0 // [0.0 48.0 95.0 153.0 210.0 230.0 262.0 271.0 320.0 338.0 340.0]
#endif
#ifndef METEOR_RATE
#define METEOR_RATE 120.0 // [0.0 10.0 30.0 60.0 120.0 240.0 480.0 900.0]
#endif
#ifndef METEOR_SHOWER_BOOST
#define METEOR_SHOWER_BOOST 12.0 // [1.0 3.0 6.0 12.0 20.0 40.0]
#endif
#ifndef METEOR_SHOWER_MAX_ANGLE
#define METEOR_SHOWER_MAX_ANGLE 75.0 // [45.0 60.0 75.0 90.0]
#endif
#ifndef METEOR_SHOWER_MIN_ANGLE
#define METEOR_SHOWER_MIN_ANGLE 15.0 // [5.0 10.0 15.0 25.0 40.0]
#endif
#ifndef METEOR_SHOWER_WIDTH
#define METEOR_SHOWER_WIDTH 1.0 // [0.3 0.5 0.75 1.0 1.5 2.0 3.0]
#endif
#ifndef METEOR_TAIL_END_FADE
#define METEOR_TAIL_END_FADE 0.6 // [0.4 0.5 0.6 0.75 0.9]
#endif
#ifndef METEOR_TAIL_FALLOFF
#define METEOR_TAIL_FALLOFF 1.4 // [0.6 1.0 1.4 2.2 3.5]
#endif
#ifndef METEOR_TAIL_LEN
#define METEOR_TAIL_LEN 0.10 // [0.06 0.08 0.10 0.14 0.20 0.30]
#endif
#ifndef METEOR_TRAIL_GAIN
#define METEOR_TRAIL_GAIN 1.05 // [0.4 0.7 0.9 1.05 1.25 1.8 2.5]
#endif
#ifndef METEOR_WIDTH
#define METEOR_WIDTH 0.0009 // [0.0006 0.00075 0.0009 0.0012 0.0018 0.0030]
#endif
#ifndef METEOR_YEAR_AUTO
#define METEOR_YEAR_AUTO 1 // [0 1]
#endif
#ifndef METEOR_YEAR_DAYS
#define METEOR_YEAR_DAYS 365.0 // [30.0 90.0 180.0 365.0 730.0]
#endif
#ifndef METEOR_YEAR_ORIGIN
#define METEOR_YEAR_ORIGIN 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]
#endif
#ifndef METEOR_YEAR_PHASE
#define METEOR_YEAR_PHASE 0.613 // [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.345 0.40 0.45 0.50 0.55 0.58 0.613 0.65 0.70 0.75 0.80 0.85 0.88 0.90 0.95 0.975]
#endif
#ifndef MOON_DAY_DIM
#define MOON_DAY_DIM 0.15 // [0.0 0.05 0.15 0.3 0.5 1.0]
#endif
#ifndef MOON_INCLINATION
#define MOON_INCLINATION 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#endif
#ifndef MOON_NIGHT_GAIN
#define MOON_NIGHT_GAIN 2.0 // [1.0 1.2 1.6 2.0 2.5 3.0]
#endif
#ifndef MOON_SHADOW_ON_AMBIENT
#define MOON_SHADOW_ON_AMBIENT 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef MOON_NIGHT_SHAPE
#define MOON_NIGHT_SHAPE 1.0 // [0.0 0.35 0.6 0.8 1.0]
#endif
#ifndef MOON_ART_GAIN
#define MOON_ART_GAIN 1.0 // [0.25 0.5 1.0 2.0 4.0]
#endif
#ifndef MOON_AMBIENT_SCALE
#define MOON_AMBIENT_SCALE 1.0 // [0.0 0.5 1.0 2.0 4.0]
#endif
#ifndef MOON_LIGHT_MIN
#define MOON_LIGHT_MIN 0.18 // [0.03 0.06 0.12 0.18 0.3 0.5 1.0]
#endif
#ifndef MOON_LIGHT_PHYSICAL
#define MOON_LIGHT_PHYSICAL 1 // [0 1]
#endif
#ifndef SUN_LIMB_DARKENING
#define SUN_LIMB_DARKENING 1.0 // [0.0 0.5 0.75 1.0]
#endif
#ifndef SUN_LIMB_U_R
#define SUN_LIMB_U_R 0.62 // [0.45 0.54 0.62 0.7 0.8]
#endif
#ifndef SUN_LIMB_U_G
#define SUN_LIMB_U_G 0.60 // [0.45 0.52 0.60 0.68 0.78]
#endif
#ifndef SUN_LIMB_U_B
#define SUN_LIMB_U_B 0.54 // [0.4 0.47 0.54 0.62 0.72]
#endif
#ifndef MOON_LIBRATION_LON_DEG
#define MOON_LIBRATION_LON_DEG 7.9 // [0.0 3.0 6.0 7.9 9.0]
#endif
#ifndef MOON_LIBRATION_LAT_DEG
#define MOON_LIBRATION_LAT_DEG 6.7 // [0.0 3.0 5.0 6.7 8.0]
#endif
#ifndef MOON_LIBRATION_PERIOD
#define MOON_LIBRATION_PERIOD 27.2 // [0.0 7.0 13.6 27.2 54.4]
#endif
#ifndef MOON_LIMB_SOFTEN
#define MOON_LIMB_SOFTEN 0.35 // [0.15 0.25 0.35 0.5 0.7 1.0]
#endif
#ifndef MOON_NODAL_PERIOD
#define MOON_NODAL_PERIOD 40.0 // [8.0 12.0 20.0 40.0 80.0 160.0]
#endif
#ifndef MOON_OCCLUDE_GALAXY
#define MOON_OCCLUDE_GALAXY 1 // [0 1]
#endif
#ifndef MOON_STAR_OCCLUSION
#define MOON_STAR_OCCLUSION 0.85 // [0.0 0.3 0.5 0.7 0.85 0.95]
#endif
#ifndef MOON_TERMINATOR_SOFT
#define MOON_TERMINATOR_SOFT 0.15 // [0.0 0.04 0.08 0.12 0.15 0.2 0.3]
#endif
#ifndef NIGHT_BRIGHTNESS
#define NIGHT_BRIGHTNESS 16.0 // [1.0 2.0 3.0 4.0 6.0 8.0 12.0 16.0]
#endif
#ifndef NIGHT_SCENE_FLOOR
#define NIGHT_SCENE_FLOOR 0.05 // [0.0 0.005 0.01 0.02 0.05 0.1 0.2]
#endif
#ifndef NIGHT_SCENE_P95
#define NIGHT_SCENE_P95 1 // [0.75 0.85 0.9 0.95 0.98 1.0]
#endif
#ifndef NIGHT_SKY_DIM
#define NIGHT_SKY_DIM 0.60 // [0.04 0.08 0.12 0.16 0.22 0.30 0.45 0.60 0.80 1.0]
#endif
#ifndef NIGHT_SKY_DIM_ELEV
#define NIGHT_SKY_DIM_ELEV -0.20 // [-0.35 -0.28 -0.20 -0.14 -0.08]
#endif
#ifndef OUTPUT_OETF
#define OUTPUT_OETF 0 // [0 1]
#endif
#ifndef PBR_AMBIENT_SPECULAR
#define PBR_AMBIENT_SPECULAR 0.80 // [0.0 0.25 0.5 0.8 1.0 1.5]
#endif
#ifndef PBR_SPECULAR_STRENGTH
#define PBR_SPECULAR_STRENGTH 0.5 // [0.0 0.15 0.3 0.5 0.8 1.0]
#endif
#ifndef PERF_TIER
#define PERF_TIER 1 // [0 1 2]
#endif
#ifndef PURKINJE_SHIFT_B
#define PURKINJE_SHIFT_B 1.0 // [0.6 0.7 0.8 0.9 1.0]
#endif
#ifndef PURKINJE_SHIFT_G
#define PURKINJE_SHIFT_G 0.78 // [0.4 0.45 0.5 0.56 0.6 0.65 0.7 0.78 0.85 0.9 1.0]
#endif
#ifndef PURKINJE_SHIFT_R
#define PURKINJE_SHIFT_R 0.56 // [0.4 0.45 0.5 0.56 0.6 0.65 0.7 0.8 0.9 1.0]
#endif
#ifndef PURKINJE_SHIFT_STRENGTH
#define PURKINJE_SHIFT_STRENGTH 0.2 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#endif
#ifndef SATURATION
#define SATURATION 1.05 // [0.0 0.5 0.8 0.9 1.0 1.05 1.1 1.15 1.2 1.3 1.5 2.0]
#endif
#ifndef SHADOW_B
#define SHADOW_B 0.09 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef SHADOW_BIAS_DISTANCE
#define SHADOW_BIAS_DISTANCE 1 // [0 1]
#endif
#ifndef SHADOW_BIAS_NEW
#define SHADOW_BIAS_NEW 1 // [0 1]
#endif
#ifndef SHADOW_BLOCKER_SAMPLES
#define SHADOW_BLOCKER_SAMPLES 8 // [2 3 4 6 8]
#endif
#ifndef SHADOW_BLOCKER_SEARCH_TEXELS
#define SHADOW_BLOCKER_SEARCH_TEXELS 4.0 // [4.0 6.0 8.0 12.0 16.0]
#endif
#ifndef SHADOW_DISTANCE_BOOST
#define SHADOW_DISTANCE_BOOST 1.0 // [1.0 1.25 1.5 2.0]
#endif
#ifndef SHADOW_G
#define SHADOW_G 0.0 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef SHADOW_NEAR_SHARPEN
#define SHADOW_NEAR_SHARPEN 1 // [0 1]
#endif
#ifndef SHADOW_PCF_GAIN
#define SHADOW_PCF_GAIN 0.35 // [0.25 0.5 1.0 1.5 2.0]
#endif
#ifndef SHADOW_PCF_MAX_SAMPLES
#define SHADOW_PCF_MAX_SAMPLES 16 // [8 12 16 24]
#endif
#ifndef SHADOW_PCF_MIN_SAMPLES
#define SHADOW_PCF_MIN_SAMPLES 12 // [2 3 4 6 8 12]
#endif
#ifndef SHADOW_PCSS
#define SHADOW_PCSS 1 // [0 1]
#endif
#ifndef SHADOW_R
#define SHADOW_R -0.05 // [-0.2 -0.1 -0.05 -0.02 0.0 0.02 0.03 0.05 0.06 0.08 0.1 0.2]
#endif
#ifndef SHADOW_RADIUS
#define SHADOW_RADIUS 1 // [1 2 4]
#endif
#ifndef SHADOW_SSS
#define SHADOW_SSS 1 // [0 1]
#endif
#ifndef SHADOW_SUN_ANGULAR_RADIUS
#define SHADOW_SUN_ANGULAR_RADIUS 0.005 // [0.005 0.01 0.02 0.03 0.04 0.05 0.08 0.12]
#endif
#ifndef SHADOW_Z_COMPRESS
#define SHADOW_Z_COMPRESS 0.25 // [0.125 0.25 0.5 1.0]
#endif
#ifndef SHARPEN_MODE
#define SHARPEN_MODE 0 // [0 1]
#endif
#ifndef SHARPEN_STRENGTH
#define SHARPEN_STRENGTH 0.7 // [0.0 0.1 0.2 0.3 0.4 0.5 0.7 1.0]
#endif
#ifndef SKY_AMBIENT
#define SKY_AMBIENT 1 // [0 1]
#endif
#ifndef SKY_AMBIENT_FALLBACK
#define SKY_AMBIENT_FALLBACK 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef SKY_AMBIENT_LEGACY
#define SKY_AMBIENT_LEGACY 0
#endif
#ifndef SKY_AMBIENT_SATURATION
#define SKY_AMBIENT_SATURATION 0.60 // [0.0 0.25 0.5 0.6 0.75 1.0]
#endif
#ifndef SKY_AMBIENT_SCALE
#define SKY_AMBIENT_SCALE 0.75 // [0.0 0.05 0.1 0.15 0.25 0.5 0.75 1.0 2.0]
#endif
#ifndef SKY_GI_REACH
#define SKY_GI_REACH 24.0 // [8.0 16.0 24.0 40.0 64.0]
#endif
#ifndef SKY_GI_REALTIME
#define SKY_GI_REALTIME 1
#endif
#ifndef SKY_GI_SAMPLES
#define SKY_GI_SAMPLES 4 // [2 4 6]
#endif
#ifndef SKY_GI_STEPS
#define SKY_GI_STEPS 4 // [2 4 6]
#endif
#ifndef SKY_GI_STRENGTH
#define SKY_GI_STRENGTH 0.15 // [0.0 0.5 0.75 1.0]
#endif
#ifndef SOFT_SHADOWS
#define SOFT_SHADOWS 1 // [0 1]
#endif
#ifndef SPECULAR_AREA_LIGHT
#define SPECULAR_AREA_LIGHT 1 // [0 1]
#endif
#ifndef SPECULAR_STRENGTH
#define SPECULAR_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#endif
#ifndef SSIL_ENABLE
#define SSIL_ENABLE 0 // [0 1]
#endif
#ifndef SSIL_INTENSITY
#define SSIL_INTENSITY 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#endif
#ifndef SSIL_RADIUS
#define SSIL_RADIUS 64.0 // [32.0 64.0 96.0 128.0]
#endif
#ifndef SSIL_SAMPLES
#define SSIL_SAMPLES 12 // [8 12 16 24 32]
#endif
#ifndef SSIL_STEPS
#define SSIL_STEPS 5 // [4 5 6 8 12]
#endif
#ifndef SSIL_TEMPORAL_ALPHA
#define SSIL_TEMPORAL_ALPHA 0.20 // [0.05 0.10 0.20 0.35]
#endif
#ifndef SSIL_TEMPORAL_ENABLE
#define SSIL_TEMPORAL_ENABLE 1 // [0 1]
#endif
#ifndef SSIL_THICKNESS
#define SSIL_THICKNESS 0.12 // [0.04 0.08 0.12 0.2 0.3]
#endif
#ifndef SSR_DISTANCE
#define SSR_DISTANCE 96.0 // [32.0 64.0 96.0 128.0 192.0 256.0]
#endif
#ifndef SSR_ENABLE
#define SSR_ENABLE 0 // [0 1]
#endif
#ifndef SSR_INTENSITY
#define SSR_INTENSITY 1.0 // [0.0 0.5 1.0 1.5 2.0]
#endif
#ifndef SSR_MAX_STEPS
#define SSR_MAX_STEPS 12 // [8 12 16 24]
#endif
#ifndef SSR_RAY_COUNT
#define SSR_RAY_COUNT 2 // [1 2 4 6]
#endif
#ifndef SSR_REFINE_STEPS
#define SSR_REFINE_STEPS 2 // [0 2 4 6]
#endif
#ifndef SSR_THICKNESS
#define SSR_THICKNESS 0.45 // [0.2 0.3 0.45 0.6 1.0]
#endif
#ifndef STARS_BRIGHT_RATIO
#define STARS_BRIGHT_RATIO 0.06 // [0.01 0.03 0.06 0.10 0.16 0.25]
#endif
#ifndef STARS_COVERAGE
#define STARS_COVERAGE 0.10 // [0.02 0.05 0.08 0.10 0.15 0.22 0.30]
#endif
#ifndef STARS_FADE_SUNRISE
#define STARS_FADE_SUNRISE -0.18 // [-0.25 -0.22 -0.18 -0.14 -0.10]
#endif
#ifndef STARS_FADE_SUNSET
#define STARS_FADE_SUNSET -0.02 // [-0.08 -0.05 -0.02 0.02 0.05]
#endif
#ifndef STARS_HORIZON_FADE
#define STARS_HORIZON_FADE 0.06 // [0.0 0.02 0.04 0.06 0.10 0.15 0.25]
#endif
#ifndef STARS_INTENSITY
#define STARS_INTENSITY 0.35 // [0.0 0.1 0.2 0.35 0.5 0.7 1.0 1.5 2.0]
#endif
#ifndef STARS_MIN_PIXEL
#define STARS_MIN_PIXEL 2.0 // [1.0 1.5 2.0 2.5 3.0]
#endif
#ifndef STARS_OFFSET
#define STARS_OFFSET 0.15 // [0.05 0.10 0.15 0.20 0.30]
#endif
#ifndef STARS_SCALE
#define STARS_SCALE 80.0 // [50.0 65.0 80.0 100.0 120.0 160.0 220.0]
#endif
#ifndef STARS_TWINKLE
#define STARS_TWINKLE 0.35 // [0.0 0.1 0.2 0.35 0.5 0.7]
#endif
#ifndef STARS_VANILLA
#define STARS_VANILLA 0 // [0 1]
#endif
#ifndef SUN_EARTH_SHADOW
#define SUN_EARTH_SHADOW 1 // [0 1]
#endif
#ifndef SUN_PATH_ROTATION
#define SUN_PATH_ROTATION 0.0 // [-45.0 -30.0 -15.0 0.0 15.0 30.0]
#endif
#ifndef SUN_TRANSMITTANCE
#define SUN_TRANSMITTANCE 1 // [0 1]
#endif
#ifndef SUN_TRANSMITTANCE_GAIN
#define SUN_TRANSMITTANCE_GAIN 1.0 // [1.0 1.15 1.25 1.4 1.6]
#endif
#ifndef SUN_TRANSPORT
#define SUN_TRANSPORT 1 // [0 1]
#endif
#ifndef TAA_ANTIFLICKER
#define TAA_ANTIFLICKER 0.5 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef TAA_CLIP_MODE
#define TAA_CLIP_MODE 1 // [0 1]
#endif
#ifndef TAA_HISTORY_FILTER
#define TAA_HISTORY_FILTER 1 // [0 1]
#endif
#ifndef TAA_JITTER
#define TAA_JITTER 1 // [0 1]
#endif
#ifndef TAA_STRENGTH
#define TAA_STRENGTH 0.9 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#endif
#ifndef TAA_VARIANCE_SCALE
#define TAA_VARIANCE_SCALE 1.25 // [0.5 0.75 1.0 1.25 1.5 2.0]
#endif
#ifndef TM_HIGHLIGHT_COMPRESS
#define TM_HIGHLIGHT_COMPRESS 0.8 // [0.0 0.3 0.5 0.7 0.8 0.9 1.0]
#endif
#ifndef TM_HIGHLIGHT_KNEE
#define TM_HIGHLIGHT_KNEE 1.0 // [0.5 0.75 1.0 1.5 2.0 3.0 5.0]
#endif
#ifndef VIGNETTE_FOV
#define VIGNETTE_FOV 70.0 // [50.0 60.0 70.0 80.0 90.0 110.0]
#endif
#ifndef VIGNETTE_STRENGTH
#define VIGNETTE_STRENGTH 0.35 // [0.0 0.2 0.35 0.5 0.7 1.0]
#endif
#ifndef VIGNETTE_TYPE
#define VIGNETTE_TYPE 1 // [0 1]
#endif
#ifndef WB_TEMPERATURE
#define WB_TEMPERATURE -0.25 // [-0.5 -0.25 -0.1 0.0 0.1 0.15 0.25 0.5]
#endif
#ifndef WB_TINT
#define WB_TINT 0.25 // [-1.0 -0.5 -0.25 0.0 0.25 0.5 1.0]
#endif

#ifndef MOTION_BLUR_ENABLED
#define MOTION_BLUR_ENABLED 0 // [0 1]
#endif
#ifndef MOTION_BLUR_STRENGTH
#define MOTION_BLUR_STRENGTH 0.5 // [0.0 0.15 0.3 0.5 0.75 1.0 1.5]
#endif
#ifndef MOTION_BLUR_SAMPLES
#define MOTION_BLUR_SAMPLES 16 // [8 12 16 20 32]
#endif
#ifndef MOTION_BLUR_SHUTTER
#define MOTION_BLUR_SHUTTER 180 // [90 144 180 270 360]
#endif
#ifndef MOTION_BLUR_MAX_PX
#define MOTION_BLUR_MAX_PX 48.0 // [16.0 24.0 32.0 48.0 64.0 96.0]
#endif
#ifndef DOF_ENABLED
#define DOF_ENABLED 0 // [0 1]
#endif
#ifndef DOF_MODE
#define DOF_MODE 1 // [1]
#endif
#ifndef DOF_F_STOP
#define DOF_F_STOP 2.8 // [1.4 2.0 2.8 4.0 5.6 8.0 11.0 16.0]
#endif
#ifndef DOF_FOCAL_LENGTH
#define DOF_FOCAL_LENGTH 24 // [24 35 50 85 135]
#endif
#ifndef DOF_FOCUS
#define DOF_FOCUS 0.5 // [-1.0 0.5 1.0 2.0 3.0 5.0 8.0 15.0 30.0]
#endif
#ifndef DOF_SAMPLES
#define DOF_SAMPLES 32 // [8 12 16 24 32]
#endif
#ifndef DOF_MAX_BLUR
#define DOF_MAX_BLUR 10.0 // [4.0 6.0 8.0 10.0 14.0 20.0]
#endif
#ifndef DOF_HAND_DEPTH
#define DOF_HAND_DEPTH 0.35 // [0.15 0.25 0.35 0.5 0.75]
#endif
#ifndef DOF_VISIBILITY
#define DOF_VISIBILITY 3.0 // [1.0 1.5 2.0 3.0 4.0 6.0 8.0]
#endif
#ifndef DOF_MIN_SKY_RADIUS
#define DOF_MIN_SKY_RADIUS 16.0 // [0.0 3.0 6.0 9.0 12.0 16.0]
#endif

#ifndef DENOISE_MODE
#define DENOISE_MODE 1 // [0 1]
#endif
#ifndef DENOISE_LEVELS
#define DENOISE_LEVELS 5 // [3 4 5]
#endif

#ifndef LTM_STRENGTH
#define LTM_STRENGTH 0.0 // [0.0 0.15 0.3 0.45 0.6 0.8 1.0]
#endif
#ifndef LTM_KEY
#define LTM_KEY 0.18 // [0.08 0.12 0.18 0.22 0.30]
#endif
#ifndef LTM_RANGE
#define LTM_RANGE 0.55 // [0.0 0.20 0.35 0.55 0.75 1.0]
#endif
#ifndef LTM_EDGE_LO
#define LTM_EDGE_LO 0.04 // [0.01 0.02 0.04 0.08 0.12]
#endif
#ifndef LTM_EDGE_HI
#define LTM_EDGE_HI 0.25 // [0.12 0.18 0.25 0.35 0.5]
#endif

#ifndef CIRRUS_ENABLE
#define CIRRUS_ENABLE 1 // [0 1]
#endif
#ifndef CIRRUS_CC_AMOUNT
#define CIRRUS_CC_AMOUNT 0.55 // [0.0 0.10 0.20 0.30 0.40 0.55 0.75 1.0]
#endif
#ifndef CIRRUS_HALO
#define CIRRUS_HALO 1 // [0 1]
#endif
#ifndef CIRRUS_REFLECT
#define CIRRUS_REFLECT 1 // [0 1]
#endif
#ifndef CIRRUS_BASE_KM
#define CIRRUS_BASE_KM 8.0 // [6.0 7.0 8.0 9.0 10.0 11.0 12.0]
#endif
#ifndef CIRRUS_THICK_KM
#define CIRRUS_THICK_KM 2.0 // [0.5 1.0 1.5 2.0 2.5 3.0]
#endif
#ifndef CIRRUS_SIGMA_KM
#define CIRRUS_SIGMA_KM 0.30 // [0.05 0.10 0.20 0.30 0.50 0.75 1.0]
#endif
#ifndef CIRRUS_TAU_MAX
#define CIRRUS_TAU_MAX 1.5 // [1.0 1.5 2.0 3.0 5.0 8.0]
#endif
#ifndef CIRRUS_ALBEDO
#define CIRRUS_ALBEDO 0.99 // [0.90 0.95 0.99 1.0]
#endif
#ifndef CIRRUS_TAU_L_MAX
#define CIRRUS_TAU_L_MAX 6.0 // [2.0 4.0 6.0 8.0 12.0]
#endif
#ifndef CIRRUS_COVERAGE
#define CIRRUS_COVERAGE 0.30 // [0.0 0.10 0.15 0.20 0.25 0.30 0.36 0.40 0.55 0.75 1.0]
#endif
#ifndef CIRRUS_DENSITY
#define CIRRUS_DENSITY 0.60 // [0.2 0.4 0.6 0.8 1.0]
#endif
#ifndef CIRRUS_FORM_KM
#define CIRRUS_FORM_KM 16.0 // [8.0 12.0 14.0 16.0 25.0 40.0 60.0 90.0 120.0]
#endif
#ifndef CIRRUS_COVER_KM
#define CIRRUS_COVER_KM 120.0 // [60.0 90.0 110.0 120.0 160.0 260.0 400.0 800.0]
#endif
#ifndef CIRRUS_STRETCH
#define CIRRUS_STRETCH 1.8 // [1.0 1.5 1.8 2.0 3.0 4.0 6.0 8.0 12.0]
#endif
#ifndef CIRRUS_ERODE
#define CIRRUS_ERODE 0.20 // [0.05 0.10 0.18 0.20 0.24 0.28 0.45]
#endif
#ifndef CIRRUS_ERODE_OCT
#define CIRRUS_ERODE_OCT 5 // [2 3 4 5]
#endif
#ifndef CIRRUS_FIBER_Q
#define CIRRUS_FIBER_Q 0.80 // [0.10 0.20 0.35 0.50 0.80]
#endif
#ifndef CIRRUS_EDGE_SOFT
#define CIRRUS_EDGE_SOFT 0.45 // [0.10 0.15 0.20 0.28 0.30 0.45 0.60]
#endif
#ifndef CIRRUS_WIND_ANGLE
#define CIRRUS_WIND_ANGLE 45.0 // [0.0 15.0 30.0 45.0 60.0 75.0 90.0 120.0 150.0]
#endif
#ifndef CIRRUS_WIND_KMPS
#define CIRRUS_WIND_KMPS 0.15 // [0.05 0.10 0.15 0.20]
#endif
#ifndef CIRRUS_GAIN
#define CIRRUS_GAIN 0.70 // [0.05 0.10 0.20 0.35 0.50 0.70 0.85 1.0]
#endif
#ifndef CIRRUS_LIGHT_STEPS
#define CIRRUS_LIGHT_STEPS 4 // [3 4 5 6]
#endif
#ifndef CIRRUS_LIGHT_MAX_KM
#define CIRRUS_LIGHT_MAX_KM 100.0 // [50.0 75.0 100.0 150.0]
#endif
#endif
