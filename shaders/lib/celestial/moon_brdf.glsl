// Hapke 2012 lunar photometric model (simplified: no coherent backscatter, no shadow hiding).

#ifndef LIB_CELESTIAL_MOON_BRDF_GLSL
#define LIB_CELESTIAL_MOON_BRDF_GLSL

#ifndef MOON_BRDF
#define MOON_BRDF 1 // [0 1]
#endif
#ifndef MOON_HAPKE_W
#define MOON_HAPKE_W 0.34 // [0.25 0.30 0.34 0.40 0.45]
#endif
#ifndef MOON_HAPKE_B0
#define MOON_HAPKE_B0 1.6 // [0.0 0.8 1.2 1.6 2.0 3.0]
#endif
#ifndef MOON_HAPKE_HS
#define MOON_HAPKE_HS 0.06 // [0.02 0.04 0.06 0.09 0.12]
#endif
#ifndef MOON_HAPKE_B
#define MOON_HAPKE_B -0.25 // [-0.4 -0.3 -0.25 -0.15 0.0 0.15]
#endif

#ifndef MOON_EARTHSHINE
#define MOON_EARTHSHINE 0.02 // [0.0 0.008 0.02 0.035 0.06]
#endif
#ifndef MOON_EARTHSHINE_R
#define MOON_EARTHSHINE_R 0.55 // [0.4 0.5 0.55 0.62 0.7]
#endif
#ifndef MOON_EARTHSHINE_G
#define MOON_EARTHSHINE_G 0.65 // [0.5 0.6 0.65 0.72 0.8]
#endif
#ifndef MOON_EARTHSHINE_B
#define MOON_EARTHSHINE_B 0.85 // [0.7 0.8 0.85 0.9 1.0]
#endif

vec3 MoonEarthshineColor() {
    return vec3(MOON_EARTHSHINE_R, MOON_EARTHSHINE_G, MOON_EARTHSHINE_B)
         * MOON_EARTHSHINE;
}

float MoonPhaseHG(float cg) {
    float b  = MOON_HAPKE_B;
    float b2 = b * b;
    float den = max(1.0 + b2 - 2.0 * b * cg, 1.0e-4);
    return (1.0 - b2) / (den * sqrt(den));
}

float MoonOppositionSurge(float g) {
    return MOON_HAPKE_B0 / (1.0 + tan(0.5 * g) / max(MOON_HAPKE_HS, 1.0e-4));
}

float MoonHfunc(float x) {
    float k = sqrt(max(1.0 - MOON_HAPKE_W, 0.0));
    return (1.0 + 2.0 * x) / (1.0 + 2.0 * x * k);
}

float MoonBRDFRaw(float mu0, float mu, float cg) {
    float g = acos(clamp(cg, -1.0, 1.0));
    float B = MoonOppositionSurge(g);
    float p = MoonPhaseHG(cg);
    float H0 = MoonHfunc(mu0);
    float H1 = MoonHfunc(mu);
    float ls = mu0 / max(mu0 + mu, 1.0e-4);
    float r = 0.25 * MOON_HAPKE_W * ls * ((1.0 + B) * p + H0 * H1 - 1.0);
    return max(r, 0.0);
}

float MoonBRDFNominal() {
    float B = MoonOppositionSurge(0.0);
    float p = MoonPhaseHG(1.0);
    float H = MoonHfunc(1.0);
    return max(0.25 * MOON_HAPKE_W * 0.5 * ((1.0 + B) * p + H * H - 1.0), 1.0e-6);
}

float MoonBRDF(vec3 N, vec3 L, vec3 V) {
    float mu0 = clamp(dot(N, L), 0.0, 1.0);
    float mu  = clamp(dot(N, V), 1.0e-4, 1.0);
    float cg  = clamp(dot(L, V), -1.0, 1.0);
    return MoonBRDFRaw(mu0, mu, cg) / MoonBRDFNominal();
}

#endif
