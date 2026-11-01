#ifndef WIND_SPEED
#define WIND_SPEED 1.0
#endif
#ifndef WIND_STRENGTH
#define WIND_STRENGTH 0.0
#endif

uniform float frameTimeCounter;

vec3 getPlantSway(vec3 worldAbs, bool isTop, float unused) {
	if (!isTop) return vec3(0.0);

	float t = frameTimeCounter * WIND_SPEED;
	vec2 phase = worldAbs.xz;

	float noise = sin(phase.x * 3.0 + t) * sin(phase.y * 3.0 - t);
	float windOffset = sin(dot(phase, vec2(2.0, 2.5)) + sin(t * 0.5) * 2.0);
	windOffset *= sin(dot(phase + t * 2.0, vec2(1.0, 0.75))) + noise;

	return vec3(0.4, 0.0, 0.3) * windOffset * WIND_STRENGTH;
}

vec3 getLeafSway(vec3 worldAbs) {
	float t = frameTimeCounter * WIND_SPEED;
	vec2 phase = worldAbs.xz;
	float windOffset = sin(dot(phase, vec2(1.5, 1.2)) + sin(t * 0.4) * 1.5);
	windOffset *= sin(dot(phase + t * 1.5, vec2(0.8, 0.9))) + 0.5;
	return vec3(0.4, 0.05, 0.3) * windOffset * WIND_STRENGTH * 0.35;
}
