#ifndef LIB_MOTIONBLUR_GLSL
#define LIB_MOTIONBLUR_GLSL

#include "/lib/dof.glsl"
#include "/lib/reprojection.glsl"

vec3 cameraSpatialEffects(vec2 uv, vec3 centerColor, float centerDepth,
                          sampler2D sceneTex, sampler2D depthTex,
                          vec2 fullSize, float blueNoise, float frameTime) {
    float centerZ = dofLinearizeDepth(centerDepth);
    bool isSky = (centerDepth >= 0.999999);

    bool nearHand = (!isSky && centerZ <= DOF_HAND_DEPTH);

    bool dofOn = (DOF_ENABLED != 0);
    bool mbOn = (MOTION_BLUR_ENABLED != 0);
    if (!dofOn && !mbOn) return centerColor;

    if (nearHand) return centerColor;

    vec2 texel = 1.0 / max(fullSize, vec2(1.0));
    float focusZ = dofOn
        ? dofFocusDistance(depthTex, uv, texel, centerDepth)
        : centerZ;

    float centerCoc = (dofOn && !isSky)
        ? dofCoCRadiusPx(centerZ, focusZ, fullSize.x)
        : 0.0;

    vec2 prevUV = TAA_Reprojection(vec3(uv, centerDepth));
    vec2 motionPx = (uv - prevUV) * fullSize;
    float motionLen = length(motionPx);
    vec2 motionDir = (motionLen > 1.0e-5)
        ? motionPx / motionLen
        : vec2(0.0);

    float shutter = clamp(float(MOTION_BLUR_SHUTTER) / 360.0, 0.0, 1.0);
    float fpsScale = clamp((1.0 / 60.0) / max(frameTime, 1.0e-4), 0.25, 4.0);
    float mbLen = (mbOn && !isSky)
        ? min(motionLen * shutter * MOTION_BLUR_STRENGTH * fpsScale,
              MOTION_BLUR_MAX_PX)
        : 0.0;

    float cocPx = abs(centerCoc);
    float gatherRadius = isSky
        ? max(DOF_MIN_SKY_RADIUS, cocPx)
        : cocPx;
    if (gatherRadius < 0.25 && mbLen < 0.25) return centerColor;

    float radiusPx = max(gatherRadius, mbLen * 0.5);
    int sampleCount = max(max(DOF_SAMPLES, MOTION_BLUR_SAMPLES), 1);

    vec3 sum = centerColor;
    float wsum = 1.0;
    float coverage = 0.0;

    for (int i = 0; i < sampleCount; ++i) {
        vec2 disc = dofVogelDisc(i, sampleCount, blueNoise * 6.28318531);
        float lineT = clamp((float(i) + 0.5 + (blueNoise - 0.5) * 0.75)
                          / float(sampleCount), 0.0, 1.0) - 0.5;
        vec2 offsetPx = disc * radiusPx + motionDir * (lineT * mbLen);
        vec2 suv = clamp(uv + offsetPx / fullSize, vec2(0.0), vec2(1.0));

        float sd = texture(depthTex, suv).r;
        bool sampleSky = (sd >= 0.999999);
        float sz = dofLinearizeDepth(sd);
        if (!sampleSky && sz <= DOF_HAND_DEPTH) continue;

        vec3 sc = texture(sceneTex, suv).rgb;

        if (sampleSky) {
            if (isSky) continue;
            float skyLuma = dot(max(sc, vec3(0.0)), DOF_LUMA_709);
            float skyWeight = 1.0 / (1.0 + max(skyLuma - 4.0, 0.0) * 0.25);
            sum += sc * skyWeight * 0.35;
            wsum += skyWeight * 0.35;
            continue;
        }

        if (sz < centerZ - max(0.05, centerZ * 0.03)) continue;

        float sampleCoc = dofOn
            ? abs(dofCoCRadiusPx(sz, focusZ, fullSize.x))
            : 0.0;
        float cocWeight = 1.0 / max(sampleCoc * sampleCoc * 0.02, 0.25);

        float luma = dot(max(sc, vec3(0.0)), DOF_LUMA_709);
        float firefly = 1.0 / (1.0 + max(luma - 16.0, 0.0) * 0.05);
        float w = cocWeight * firefly;
        sum += sc * w;
        wsum += w;

        if (sampleCoc > 0.5) coverage += 1.0 / float(sampleCount);
    }

    if (wsum <= 1.0e-5) return centerColor;

    if (isSky) {
        float skyCover = smoothstep(0.0, 0.30, coverage);
        return mix(centerColor, sum / wsum, skyCover * 0.85);
    }

    return sum / wsum;
}

#endif
