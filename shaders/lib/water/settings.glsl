#ifndef LIB_WTR_SETTINGS_GLSL
#define LIB_WTR_SETTINGS_GLSL

#ifndef WTR_ENABLED
#define WTR_ENABLED 1 // [0 1]
#endif

#ifndef WTR_PATCHY
#define WTR_PATCHY 1.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
const float WTR_DISP_AMP = 0.12;
#ifndef WTR_AMP
#define WTR_AMP 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#endif
#ifndef WTR_SPEED
#define WTR_SPEED 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0]
#endif
#ifndef WTR_GEO_SPEED
#define WTR_GEO_SPEED 6.0 // [0.0 1.0 2.0 3.0 4.0 6.0 8.0 10.0 12.0 16.0]
#endif
#ifndef WTR_DELTA_NEAR
#define WTR_DELTA_NEAR 0.15 // [0.02 0.05 0.08 0.1 0.15 0.2 0.3 0.4 0.5]
#endif
#ifndef WTR_DELTA_FAR
#define WTR_DELTA_FAR 1.0 // [0.3 0.5 0.7 1.0 1.25 1.5 1.75 2.0]
#endif
#ifndef WTR_FADE_DIST
#define WTR_FADE_DIST 384.0 // [128.0 192.0 256.0 384.0 512.0 768.0 1024.0 2048.0]
#endif
#ifndef WTR_FADE_MAX
#define WTR_FADE_MAX 3.0 // [0.0 0.5 1.0 1.5 2.0 2.5 3.0 4.0 6.0 8.0]
#endif

#ifndef WTR_ABSORB_SCALE
#define WTR_ABSORB_SCALE 0.25 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#endif
#ifndef WTR_REFRACT
#define WTR_REFRACT 4.0 // [0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0]
#endif
#ifndef WTR_REFRACT_DEPTH
#define WTR_REFRACT_DEPTH 0.5 // [0.1 0.2 0.3 0.5 0.75 1.0]
#endif
#ifndef WTR_UNDERWATER_REFRACT
#define WTR_UNDERWATER_REFRACT 0.1 // [0.05 0.1 0.2 0.3 0.5 1.0]
#endif
#ifndef WTR_SSR
#define WTR_SSR 1 // [0 1]
#endif
#ifndef WTR_BIOME_TINT
#define WTR_BIOME_TINT 1.0 // [0.0 0.25 0.5 0.75 1.0]
#endif
#ifndef WTR_SCATTER_DIST
#define WTR_SCATTER_DIST 50.0 // [10.0 20.0 30.0 40.0 50.0 75.0 100.0]
#endif
#ifndef WTR_FOG_FAR
#define WTR_FOG_FAR 112.0 // [32.0 48.0 64.0 80.0 112.0 160.0 256.0]
#endif

#ifndef WTR_CAUSTICS
#define WTR_CAUSTICS 1 // [0 1]
#endif
#ifndef WTR_UNDERWATER_SUN
#define WTR_UNDERWATER_SUN 1 // [0 1]
#endif
#ifndef WTR_SHAFTS
#define WTR_SHAFTS 1 // [0 1]
#endif
#ifndef WTR_SHAFT_STRENGTH
#define WTR_SHAFT_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0]
#endif
#ifndef WTR_CAUSTIC_SCALE
#define WTR_CAUSTIC_SCALE 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0 4.0]
#endif
#ifndef WTR_CAUSTIC_BRIGHT
#define WTR_CAUSTIC_BRIGHT 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5]
#endif
#ifndef WTR_CAUSTIC_POWER
#define WTR_CAUSTIC_POWER 1.6 // [1.0 1.25 1.5 1.6 2.0 2.5 3.0]
#endif
#ifndef WTR_CAUSTIC_DEPTH_FADE
#define WTR_CAUSTIC_DEPTH_FADE 1.0 // [0.0 0.5 1.0 1.5 2.0]
#endif

#ifndef WTR_GLINT_STRENGTH
#define WTR_GLINT_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]
#endif
#ifndef WTR_GLINT_ROUGHNESS
#define WTR_GLINT_ROUGHNESS 0.12 // [0.03 0.05 0.08 0.10 0.12 0.15 0.20 0.28]
#endif
#ifndef WTR_GLINT_MODEL
#define WTR_GLINT_MODEL 0 // [0 1]
#endif
#ifndef WTR_DISPERSION
#define WTR_DISPERSION 1.0 // [0.0 1.0 2.0 3.0 4.0]
#endif

const float WTR_GOLDEN = 2.39996;
const mat2 WTR_ROT = mat2(cos(WTR_GOLDEN), -sin(WTR_GOLDEN),
                          sin(WTR_GOLDEN),  cos(WTR_GOLDEN));

const vec3 WTR_SIGMA_A = vec3(0.392389, 0.108329, 0.0660636);
const float WTR_MIN_ABSORB = 0.0;
const vec3 WTR_DIRT = vec3(0.6, 0.39, 0.39) * 0.1 / 3.14159265;

#endif
