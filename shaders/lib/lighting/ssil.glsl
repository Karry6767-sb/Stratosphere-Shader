// Algorithm structure after Revelation (Apache-2.0); reimplemented.

#ifndef LIB_LIGHTING_SSIL_GLSL
#define LIB_LIGHTING_SSIL_GLSL
#include "/lib/lighting/ssgi_settings.glsl"
uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex11;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int frameCounter;
uniform float near;
uniform float far;
vec3 ssilScreenToView(vec2 uv, float depth) {
	vec4 clip = vec4(uv * 2.0f - 1.0f, depth * 2.0f - 1.0f, 1.0f);
	vec4 view = gbufferProjectionInverse * clip;
	return view.xyz / (abs(view.w) > 1.0E-6f ? view.w : 1.0f);
}
float ssilFrameDither(vec2 fragCoord) {
	float ign = fract(52.9829189f * fract(dot(fragCoord, vec2(0.06711056f, 0.00583715f))));
	return fract(ign + float(frameCounter) * 0.6180339887498949f);
}
vec2 ssilReprojectUV(vec2 uv, float depth) {
	vec3 pos = vec3(uv, depth) * 2.0f - 1.0f;
	vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0f);
	viewPosPrev /= max(viewPosPrev.w, 1.0E-6f);
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;
	vec3 cameraOffset = cameraPosition - previousCameraPosition;
	vec4 previousPosition = gbufferPreviousProjection * gbufferPreviousModelView * (viewPosPrev + vec4(cameraOffset, 0.0f));
	return (previousPosition.xy / max(previousPosition.w, 1.0E-6f)) * 0.5f + 0.5f;
}
vec4 ssilTemporalAccumulate(vec4 hist, vec3 current, vec3 minCurrent, vec3 maxCurrent, float currentWeight) {
	float confidence = clamp(hist.a, 0.0f, 1.0f);
	vec3 box = max(maxCurrent - minCurrent, vec3(1.0E-4f));
	vec3 lo = minCurrent - box * 0.5f - vec3(0.002f);
	vec3 hi = maxCurrent + box * 0.5f + vec3(0.002f);
	vec3 historyClamped = clamp(hist.rgb, lo, hi);
	float w = clamp(max(currentWeight, 1.0f - confidence), 0.0f, 1.0f);
	vec3 result = mix(historyClamped, current, w);
	float outConfidence = clamp(mix(confidence, 1.0f, w), 0.0f, 1.0f);
	return vec4(result, outConfidence);
}
float ssilCheckerboard(vec2 fragCoord) {
	int phase = int(mod(floor(fragCoord.x) + floor(fragCoord.y), 2.0f));
	int framePhase = frameCounter & 1;
	return float(phase ^ framePhase);
}
float ssilLinearizeDepth(float d) {
    float ndc = d * 2.0 - 1.0;
    return 2.0 * near * far / max((far + near) - ndc * (far - near), 1.0e-6);
}
vec2 ssilUvToTexel(vec2 uv, vec2 size) {
	return uv * size;
}
float ssilLoadDepth(vec2 uv, vec2 depthSize) {
	ivec2 t = ivec2(clamp(uv * depthSize, vec2(0.0f), depthSize - 1.0f));
	return texelFetch(depthtex0, t, 0).r;
}
vec3 ssilLoadScene(vec2 uv, vec2 sceneSize) {
	ivec2 t = ivec2(clamp(uv * sceneSize, vec2(0.0f), sceneSize - 1.0f));
	return min(texelFetch(colortex0, t, 0).rgb, vec3(64.0f));
}
vec3 ssilSample(
    vec3 viewPos,
    vec3 viewNormal,
    vec2 uv,
    float dither,
    vec2 depthTexelSize,
    vec2 sceneTexelSize,
    out float visibility,
    out float hitDistance
) {
    vec3 n = normalize(viewNormal);
    vec3 up = abs(n.z) < 0.99f ? vec3(0.0f, 0.0f, 1.0f) : vec3(1.0f, 0.0f, 0.0f);
    vec3 tangent = normalize(cross(up, n));
    vec3 bitangent = cross(n, tangent);
    float viewDist = max(length(viewPos), 1.0E-4f);
    float radius = min(SSIL_RADIUS, max(2.0f, viewDist * 1.5f));
    vec3 start = viewPos + n * (0.12f + viewDist * 0.002f);
    float startLin = max(-start.z, 1.0E-4f);
    float rRadius = 1.0f / max(radius, 1.0E-4f);
    float stepScale = pow(max(radius / 0.5f, 1.0f), 1.0f / float(SSIL_STEPS));
    vec3 accum = vec3(0.0f);
    float weightSum = 0.0f;
    float blockedRays = 0.0f;
    float hitSum = 0.0f;
    for (int i = 0; i < SSIL_SAMPLES; ++i) {
        float fi = (float(i) + 0.5f) / float(SSIL_SAMPLES);
        float phi = 6.28318530718f * fract(float(i) * 0.61803398875f + dither);
        float cosTheta = sqrt(max(1.0f - fi, 0.0f));
        float sinTheta = sqrt(max(fi, 0.0f));
        vec3 dir = normalize(tangent * (cos(phi) * sinTheta)
                           + bitangent * (sin(phi) * sinTheta)
                           + n * cosTheta);
        vec3 end = start + dir * radius;
        vec4 clip0 = gbufferProjection * vec4(start, 1.0f);
        vec4 clip1 = gbufferProjection * vec4(end, 1.0f);
        if (clip0.w <= 0.0f || clip1.w <= 0.0f) continue;
        vec2 uv0 = (clip0.xy / clip0.w) * 0.5f + 0.5f;
        vec2 uv1 = (clip1.xy / clip1.w) * 0.5f + 0.5f;
        vec2 deltaUV = uv1 - uv0;
        float w0 = clip0.w;
        float w1 = clip1.w;
        float endLin = max(-end.z, 1.0E-4f);
        float along = 0.5f;
        bool blocked = false;
        for (int step = 0; step < SSIL_STEPS; ++step) {
            float s = along * rRadius;
            if (s >= 1.0f) break;
            along *= stepScale;
            vec2 sampleUV = uv0 + deltaUV * s;
            if (clamp(sampleUV, vec2(0.0f), vec2(1.0f)) != sampleUV) break;
            float sceneDepth = ssilLoadDepth(sampleUV, depthTexelSize);
            if (sceneDepth >= 1.0f) continue;
            float denom = (1.0f - s) * w1 + s * w0;
            float t = (denom > 1.0E-6f) ? (s * w0 / denom) : s;
            float rayLin = mix(startLin, endLin, t);
            float sceneLin = ssilLinearizeDepth(sceneDepth);
            if (rayLin <= sceneLin) continue;
            blocked = true;
            float thickness = SSIL_THICKNESS + rayLin * 0.03f;
            if (rayLin < sceneLin + thickness) {
                vec3 hit = ssilLoadScene(sampleUV, sceneTexelSize);
                float ndl = max(dot(dir, n), 0.0f);
                float proj = t * radius;
                float falloff = 1.0f - smoothstep(radius * 0.55f, radius, proj);
                accum += hit * ndl * falloff;
                weightSum += ndl * falloff;
                hitSum += proj;
                break;
            }
        }
        if (blocked) blockedRays += 1.0f;
    }
    visibility = clamp(1.0f - blockedRays / float(SSIL_SAMPLES), 0.0f, 1.0f);
    hitDistance = hitSum;
    if (weightSum <= 1.0E-4f) return vec3(0.0f);
    return accum / weightSum;
}
#endif
