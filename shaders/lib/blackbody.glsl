#ifndef LIB_BLACKBODY_GLSL
#define LIB_BLACKBODY_GLSL

vec3 blackbodyColor(float K) {
	K = clamp(K, 1000.0, 12000.0) / 100.0;
	vec3 c;
	if (K <= 66.0) c.r = 255.0;
	else c.r = 329.698727446 * pow(K - 60.0, -0.1332047592);
	if (K <= 66.0) c.g = 99.4708025861 * log(K) - 161.1195681661;
	else c.g = 288.1221695283 * pow(K - 60.0, -0.0755148492);
	if (K >= 66.0) c.b = 255.0;
	else if (K <= 19.0) c.b = 0.0;
	else c.b = 138.5177312231 * log(K - 10.0) - 305.0447927307;
	return clamp(c / 255.0, 0.0, 1.0);
}

vec3 fireLightColor() { return blackbodyColor(BB_FIRE_TEMP); }

vec3 sunLightColor() { return blackbodyColor(BB_SUN_TEMP); }

#ifndef MOON_SPECTRAL_MODE
#define MOON_SPECTRAL_MODE 1 // [0 1]
#endif

vec3 moonRegolithAlbedo() { return vec3(0.94, 0.92, 0.88); }

vec3 moonSpectralTint() {
#if MOON_SPECTRAL_MODE == 1
    return blackbodyColor(BB_MOON_TEMP);
#else
    return sunLightColor() * moonRegolithAlbedo();
#endif
}

vec3 moonDiscTint() {
#if MOON_SPECTRAL_MODE == 1
    return vec3(1.25, 1.05, 0.72);
#else
    return sunLightColor() * moonRegolithAlbedo();
#endif
}

vec3 moonLightColor() { return moonSpectralTint(); }

#endif
