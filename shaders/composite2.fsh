#version 430 compatibility

/* RENDERTARGETS: 7,14 */

#include "/lib/options_defaults.glsl"

#include "/lib/intro.glsl"
#include "/lib/lighting/ssil.glsl"
#include "/lib/denoise.glsl"

uniform sampler2D colortex4;
uniform sampler2D colortex6;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform float viewWidth;
uniform float viewHeight;

vec3 ssilSpatial(vec2 uv, vec2 texel, out vec3 minRaw, out vec3 maxRaw, out float tracedHere) {
    float centerDepth = texture(depthtex0, uv).r;
    vec4 centerSample = texture(colortex12, uv);
    tracedHere = centerSample.a;

    minRaw = vec3(0.0);
    maxRaw = vec3(0.0);
    if (centerDepth >= 1.0) return vec3(0.0);

    vec3 normalRaw = texture(colortex2, uv).rgb * 2.0 - 1.0;
    float normalLen = length(normalRaw);
    vec3 centerN = (normalLen > 1.0e-4)
        ? normalRaw / normalLen
        : vec3(0.0, 1.0, 0.0);

#if DENOISE_MODE == 0
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    bool anyTraced = false;

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 suv = clamp(uv + vec2(float(x), float(y)) * texel,
                             vec2(0.0), vec2(1.0));
            float d = texture(depthtex0, suv).r;
            if (d >= 1.0) continue;
            vec4 s = texture(colortex12, suv);
            if (s.a < 0.5) continue;
            vec3 nRaw = texture(colortex2, suv).rgb * 2.0 - 1.0;
            float nLen = length(nRaw);
            vec3 n = (nLen > 1.0e-4) ? nRaw / nLen : centerN;
            float depthW = exp(-abs(d - centerDepth) * 500.0);
            float normalW = pow(max(dot(centerN, n), 0.0), 24.0);
            float w = depthW * normalW;
            if (w <= 1.0e-6) continue;
            if (!anyTraced) { minRaw = s.rgb; maxRaw = s.rgb; anyTraced = true; }
            else { minRaw = min(minRaw, s.rgb); maxRaw = max(maxRaw, s.rgb); }
            sum += s.rgb * w;
            wsum += w;
        }
    }

    if (!anyTraced) {
        minRaw = vec3(0.0);
        maxRaw = vec3(1.0e4);
        if (tracedHere > 0.5) return centerSample.rgb;
        return vec3(0.0);
    }
    return sum / max(wsum, 1.0e-6);
#else
    return atrousFilter(colortex12, depthtex0, colortex2,
                        uv, texel, centerDepth, centerN,
                        minRaw, maxRaw, tracedHere);
#endif
}

in vec2 texcoord;

#include "/lib/TAA.glsl"

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ssilHistoryNew;

void main() {
        vec4 src = texture(colortex4, texcoord);
        vec3 outColor = src.rgb;

        if (src.a > 0.002) {
                vec2 size = vec2(viewWidth, viewHeight);
                vec2 texel = 1.0 / max(size, vec2(1.0));
                float radiusPx = introBlurRadiusPx(size) * src.a;
                outColor = introGaussV(colortex4, texcoord, texel, radiusPx);
        }

        ssilHistoryNew = vec4(0.0);
#if SSIL_ENABLE == 1
        float depth = texture(depthtex0, texcoord).r;
        if (depth < 1.0) {
                vec2 texel = 1.0 / max(vec2(viewWidth, viewHeight), vec2(1.0));
                vec3 minRaw, maxRaw;
                float tracedHere;
                vec3 currentGI = ssilSpatial(texcoord, texel, minRaw, maxRaw, tracedHere);

#if SSIL_TEMPORAL_ENABLE == 1
                vec2 prevUV = ssilReprojectUV(texcoord, depth);
                bool valid = prevUV.x > 0.0 && prevUV.x < 1.0
                          && prevUV.y > 0.0 && prevUV.y < 1.0;
                vec4 hist = valid ? texture(colortex6, prevUV) : vec4(0.0);

                float prevSceneDepth = valid ? texture(depthtex0, prevUV).r : 1.0;
                bool prevIsGeometry = prevSceneDepth < 1.0;

                vec3 normalHereRaw = texture(colortex2, texcoord).rgb * 2.0 - 1.0;
                vec3 normalThereRaw = prevIsGeometry
                    ? texture(colortex2, prevUV).rgb * 2.0 - 1.0
                    : vec3(0.0);
                float hereLen = length(normalHereRaw);
                float thereLen = length(normalThereRaw);
                bool normalOk = prevIsGeometry && hereLen > 0.10 && thereLen > 0.10;
                vec3 normalHere = hereLen > 1.0e-4 ? normalHereRaw / hereLen : vec3(0.0, 1.0, 0.0);
                vec3 normalThere = thereLen > 1.0e-4 ? normalThereRaw / thereLen : vec3(0.0, 1.0, 0.0);
                float normalAgree = max(dot(normalHere, normalThere), 0.0);

                float speed = valid
                    ? length((texcoord - prevUV) * vec2(viewWidth, viewHeight))
                    : 0.0;
                float currentWeight = SSIL_TEMPORAL_ALPHA
                                    + smoothstep(2.0, 64.0, speed) * 0.65;
                if (!valid || !normalOk || normalAgree < 0.80) currentWeight = 1.0;
                if (tracedHere < 0.5) currentWeight = min(currentWeight, 0.05);
                if (frameCounter < 2) currentWeight = 1.0;

                vec4 accum = ssilTemporalAccumulate(hist, currentGI,
                                                    minRaw, maxRaw,
                                                    clamp(currentWeight, 0.0, 1.0));
                currentGI = accum.rgb;
                ssilHistoryNew = accum;
#else
                ssilHistoryNew = vec4(currentGI, 1.0);
#endif

                outColor += currentGI * SSIL_INTENSITY;
        }
#endif

#if SSR_ENABLE == 1
        outColor += texture(colortex13, texcoord).rgb;
#endif

        float taaDepth = texture(depthtex0, texcoord).r;
        vec3 taaResult = TAA_Resolve(texcoord, taaDepth, outColor);
        color = vec4(taaResult, 1.0);
        TAA_HistoryStore(ivec2(gl_FragCoord.xy), vec4(taaResult, taaDepth));
}
