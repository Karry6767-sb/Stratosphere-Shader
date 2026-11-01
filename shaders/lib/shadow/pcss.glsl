#ifndef SHADOW_BIAS_MAX
#define SHADOW_BIAS_MAX 1.00
#endif

#ifndef SHADOW_BIAS_CONST_TEXELS
#define SHADOW_BIAS_CONST_TEXELS 1.0
#endif

#ifndef SHADOW_SSS_PENUMBRA_BOOST
#define SHADOW_SSS_PENUMBRA_BOOST 7.0
#endif

#ifndef SHADOW_MAX_PENUMBRA_MUL
#define SHADOW_MAX_PENUMBRA_MUL 0.50
#endif

#ifndef SHADOW_BLOCKER_DEPTH_BIAS
#define SHADOW_BLOCKER_DEPTH_BIAS 0.0
#endif

#ifndef SHADOW_BLOCKER_SAMPLES_MAX
#define SHADOW_BLOCKER_SAMPLES_MAX 8
#endif

#ifndef LIB_SHADOW_PCSS_GLSL
#define LIB_SHADOW_PCSS_GLSL

#include "/lib/shadow/entry.glsl"
#include "/lib/shadow/scene.glsl"
#include "/lib/shadow/distort.glsl"

vec3 shadowClipToScreen(vec4 clickPos) {
    vec3 distorted = distortShadowClipPos(clickPos.xyz);
    return (distorted / clickPos.w) * 0.5 + 0.5;
}

vec3 getWorldShadowBias(vec3 scenePos, vec3 normal, float NoL) {
#if SHADOW_BIAS_NEW == 1
    vec3 viewPos = (SceneShadowModelView() * vec4(scenePos, 1.0)).xyz;
    vec4 clipPos = shadowProjection * vec4(viewPos, 1.0);
    float texelWorld = shadowTexelWorldSize(clipPos.xy);
    float n = clamp(NoL, 0.0, 1.0);
    float slopeWorld = texelWorld * sqrt(max(1.0 - n * n, 0.0)) / max(n, 1e-4);
    float constWorld = texelWorld * SHADOW_BIAS_CONST_TEXELS;
#if SHADOW_BIAS_DISTANCE == 1
    float biasDist = length(scenePos);
    constWorld *= mix(1.0, 2.0, biasDist / (biasDist + 30.0));
#endif
    float slopeWeight = mix(0.50, 1.0, smoothstep(0.0, 0.08, n));
    float biasWorld = slopeWorld * slopeWeight + constWorld;
    return normal * clamp(biasWorld, 0.0, SHADOW_BIAS_MAX);
#else
    return 0.25 * normal * clamp(0.12 + 0.01 * length(scenePos), 0.0, 1.0) * (2.0 - clamp(NoL, 0.0, 1.0));
#endif
}

bool shadowFindBlocker(vec4 biasedClip, vec3 shadowScreenPos, mat2 rot,
                       out float blockerDepth, out float sssThickness) {
    blockerDepth = 0.0;
    sssThickness = 0.0;
    if (shadowScreenPos.x < 0.0 || shadowScreenPos.x > 1.0 ||
        shadowScreenPos.y < 0.0 || shadowScreenPos.y > 1.0) {
        return false;
    }
    float depthSum = 0.0;
    float count = 0.0;
    float gapSum = 0.0;
    float blockerBias = shadowDepthGapFromWorld(0.50);
    vec2 texelClip = vec2(2.0 / float(shadowMapResolution));
    for (int i = 0; i < SHADOW_BLOCKER_SAMPLES_MAX; ++i) {
        if (i >= SHADOW_BLOCKER_SAMPLES) break;
        vec2 disk = shadowRotateDisk(shadowDiskPoint(i, SHADOW_BLOCKER_SAMPLES), rot);
        vec2 offset = disk * SHADOW_BLOCKER_SEARCH_TEXELS * texelClip;
        vec4 sampleClip = biasedClip;
        sampleClip.xy += offset;
        vec3 sampleScreen = shadowClipToScreen(sampleClip);
        if (sampleScreen.x < 0.0 || sampleScreen.x > 1.0 ||
            sampleScreen.y < 0.0 || sampleScreen.y > 1.0) continue;
        float sampleDepth = texture(shadowtex0, sampleScreen.xy).r;
        if (sampleDepth <= 0.0 || sampleDepth >= 1.0) continue;
        float gap = sampleScreen.z - sampleDepth;
        if (gap > blockerBias) {
            depthSum += sampleDepth;
            count += 1.0;
            gapSum += gap;
        }
    }
    if (count < 0.5) return false;
    blockerDepth = depthSum / count;
    sssThickness = shadowDepthGapToWorld(gapSum / count);
    return true;
}

vec3 getSoftShadowPCSS(vec3 scenePos, vec3 normal, vec3 lightDir, float sssAmount) {
    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    vec3 biasedScene = scenePos + getWorldShadowBias(scenePos, normal, NoL);
    vec3 biasedView = (SceneShadowModelView() * vec4(biasedScene, 1.0)).xyz;
    vec4 biasedClip = shadowProjection * vec4(biasedView, 1.0);
    vec3 shadowScreen = shadowClipToScreen(biasedClip);
    if (shadowScreen.x < 0.0 || shadowScreen.x > 1.0 ||
        shadowScreen.y < 0.0 || shadowScreen.y > 1.0 ||
        shadowScreen.z < 0.0 || shadowScreen.z > 1.0) {
        return vec3(1.0);
    }
    if (NoL < 1.0e-3) return vec3(0.0);

    mat2 rot = shadowRotation(shadowDither() * 6.28318530718);
    float blockerDepth;
    float sssThickness;
    if (!shadowFindBlocker(biasedClip, shadowScreen, rot, blockerDepth, sssThickness)) {
        return getShadow(shadowScreen);
    }

    float depthGap = max(shadowScreen.z - blockerDepth, 0.0);
    float worldGap = shadowDepthGapToWorld(depthGap);
    float texelWorld = shadowTexelWorldSize(biasedClip.xy);
    float lightAngularRadius = SceneActiveIsSun()
                             ? SHADOW_SUN_ANGULAR_RADIUS
                             : SHADOW_SUN_ANGULAR_RADIUS * 0.872;
    float penumbraTexels = worldGap * lightAngularRadius / max(texelWorld, 1e-4);
    penumbraTexels *= 1.0 + SHADOW_SSS_PENUMBRA_BOOST * clamp(sssAmount, 0.0, 1.0);
    penumbraTexels *= mix(1.0, SHADOW_DISTANCE_BOOST, smoothstep(10.0, 120.0, length(scenePos)));

    float maxPenumbraTexels = SHADOW_BLOCKER_SEARCH_TEXELS * SHADOW_MAX_PENUMBRA_MUL;
    float minPenumbraTexels = max(maxPenumbraTexels * 0.06, 1.0e-3);
    float s9SharpenFactor = clamp(penumbraTexels / minPenumbraTexels, 0.0, 1.0);
    penumbraTexels = clamp(penumbraTexels, minPenumbraTexels, maxPenumbraTexels);

    int stepCount = clamp(int(SHADOW_PCF_MIN_SAMPLES + SHADOW_PCF_GAIN * penumbraTexels),
                          SHADOW_PCF_MIN_SAMPLES, SHADOW_PCF_MAX_SAMPLES);
    vec3 shadowAccum = vec3(0.0);
    int done = 0;
    vec2 texelClip = vec2(2.0 / float(shadowMapResolution));
    float pcfBias = shadowDepthGapFromWorld(0.05);
    for (int i = 0; i < SHADOW_PCF_MAX_SAMPLES; ++i) {
        if (i >= stepCount) break;
        vec2 disk = shadowRotateDisk(shadowDiskPoint(i, stepCount), rot);
        vec2 offset = disk * penumbraTexels * texelClip;
        vec4 sampleClip = biasedClip;
        sampleClip.xy += offset;
        vec3 sampleScreen = shadowClipToScreen(sampleClip);
        if (sampleScreen.x < 0.0 || sampleScreen.x > 1.0 ||
            sampleScreen.y < 0.0 || sampleScreen.y > 1.0) continue;
        sampleScreen.z -= pcfBias;
        shadowAccum += getShadow(sampleScreen);
        done++;
    }
    if (done == 0) return vec3(1.0);
    vec3 shadowResult = shadowAccum / float(done);
#if SHADOW_NEAR_SHARPEN == 1
    shadowResult = mix(smoothstep(vec3(0.3), vec3(0.7), shadowResult),
                       shadowResult, s9SharpenFactor);
#endif
    return shadowResult;
}

vec3 getSoftShadowLegacy(vec3 scenePos, vec3 normal, vec3 lightDir) {
    float NoL = clamp(dot(normal, lightDir), 0.0, 1.0);
    vec3 biasOffset = getWorldShadowBias(scenePos, normal, NoL);
    vec3 biasedScene = scenePos + biasOffset;
    vec3 biasedView = (SceneShadowModelView() * vec4(biasedScene, 1.0)).xyz;
    vec4 biasedClip = shadowProjection * vec4(biasedView, 1.0);
#if SOFT_SHADOWS == 1
    float noise = getNoise(texcoord).r;
    float theta = noise * radians(360.0);
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    vec2 jitter = getNoise(texcoord + vec2(0.5, 0.0)).rg - 0.5;
    vec3 shadowAccum = vec3(0.0);
    const int samples = SHADOW_RANGE * SHADOW_RANGE * 4;
    for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; x++) {
        for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; y++) {
            vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE);
            offset = rotation * offset;
            offset += jitter * SHADOW_RADIUS / float(SHADOW_RANGE);
            offset /= shadowMapResolution;
            vec4 offsetShadowClipPos = biasedClip + vec4(offset, 0.0, 0.0);
            offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
            vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
            vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
            shadowAccum += getShadow(shadowScreenPos);
        }
    }
    return shadowAccum / float(samples);
#else
    vec4 offsetShadowClipPos = biasedClip;
    offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
    vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
    return getShadow(shadowScreenPos);
#endif
}

vec3 getSoftShadowSSS(vec3 scenePos, vec3 normal, vec3 lightDir, float sssAmount) {
#if SHADOW_PCSS == 1
    return getSoftShadowPCSS(scenePos, normal, lightDir, sssAmount);
#else
    return getSoftShadowLegacy(scenePos, normal, lightDir);
#endif
}

vec3 getSoftShadow(vec3 scenePos, vec3 normal, vec3 lightDir) {
    return getSoftShadowSSS(scenePos, normal, lightDir, 0.0);
}

#endif
