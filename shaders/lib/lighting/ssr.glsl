#ifndef LIB_LIGHTING_SSR_GLSL
#define LIB_LIGHTING_SSR_GLSL

#include "/lib/lighting/ssil.glsl"
#include "/lib/lighting/brdf.glsl"

uniform sampler2D depthtex1;

float ssrMaterialCode(float packedMaterial) {
    return floor(fract(packedMaterial) * 10.0 + 0.5);
}

bool ssrIsReflectiveMaterial(float matCode) {
    return matCode > 0.5 && matCode < 3.5;
}

float ssrRoughness(float matCode) {
    if (matCode > 0.5 && matCode < 1.5) return 0.25;
    if (matCode > 1.5 && matCode < 2.5) return 0.30;
    if (matCode > 2.5 && matCode < 3.5) return 0.10;
    return 1.0;
}

vec3 ssrF0(vec3 albedo, float matCode) {
    bool isMetal = (matCode > 0.5 && matCode < 1.5);
    return isMetal ? albedo : vec3(0.04);
}

float ssrDither(vec2 fragCoord) {
    return fract(52.9829189 * fract(dot(fragCoord, vec2(0.06711056, 0.00583715))));
}

float ssrEdgeFade(vec2 uv) {
    vec2 e = abs(uv * 2.0 - 1.0);
    return (1.0 - smoothstep(0.90, 1.0, e.x)) * (1.0 - smoothstep(0.90, 1.0, e.y));
}

vec4 ssrTraceOneRay(vec3 start, vec3 dir, float rayLength, float dither) {
    dir = normalize(dir);
    vec3 end = start + dir * rayLength;

    vec4 clip0 = gbufferProjection * vec4(start, 1.0);
    vec4 clip1 = gbufferProjection * vec4(end, 1.0);
    if (clip0.w <= 1.0e-6 || clip1.w <= 1.0e-6) return vec4(0.0);

    vec2 uv0 = (clip0.xy / clip0.w) * 0.5 + 0.5;
    vec2 uv1 = (clip1.xy / clip1.w) * 0.5 + 0.5;
    vec2 seg = uv1 - uv0;
    if (dot(seg, seg) < 1.0e-12) return vec4(0.0);

    float tMax = 1.0;
    if (seg.x > 1.0e-6) tMax = min(tMax, (1.0 - uv0.x) / seg.x);
    else if (seg.x < -1.0e-6) tMax = min(tMax, (0.0 - uv0.x) / seg.x);
    if (seg.y > 1.0e-6) tMax = min(tMax, (1.0 - uv0.y) / seg.y);
    else if (seg.y < -1.0e-6) tMax = min(tMax, (0.0 - uv0.y) / seg.y);
    if (tMax <= 0.0) return vec4(0.0);

    vec2 stepUV = seg * (tMax / float(SSR_MAX_STEPS));
    vec2 p = uv0 + stepUV * (0.25 + 0.5 * dither);
    vec2 prevP = uv0;
    vec2 lastSkyUV = vec2(-1.0);

    for (int i = 0; i < SSR_MAX_STEPS; ++i) {
        if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) break;

        float sceneDepth = texture(depthtex1, p).r;
        if (sceneDepth >= 1.0) {
            lastSkyUV = p;
        } else {
            vec3 hitView = ssilScreenToView(p, sceneDepth);
            vec3 delta = hitView - start;
            float along = dot(delta, dir);
            if (along > 0.05 && along < rayLength) {
                float perp = length(delta - dir * along);
                float tol = min(SSR_THICKNESS + along * 0.012, 1.5);
                if (perp < tol) {
                    vec2 bestUV = p;
                    float bestPerp = perp;
                    vec2 lo = prevP;
                    vec2 hi = p;
                    for (int r = 0; r < SSR_REFINE_STEPS; ++r) {
                        vec2 mid = (lo + hi) * 0.5;
                        float midDepth = texture(depthtex1, mid).r;
                        if (midDepth >= 1.0) { lo = mid; continue; }
                        vec3 midView = ssilScreenToView(mid, midDepth);
                        vec3 midDelta = midView - start;
                        float midAlong = dot(midDelta, dir);
                        if (midAlong <= 0.0 || midAlong >= rayLength) { lo = mid; continue; }
                        float midPerp = length(midDelta - dir * midAlong);
                        if (midPerp < bestPerp) {
                            bestPerp = midPerp;
                            bestUV = mid;
                        }
                        if (midAlong < along) lo = mid; else hi = mid;
                    }
                    return vec4(min(texture(colortex0, bestUV).rgb, vec3(64.0)), ssrEdgeFade(bestUV));
                }
            }
        }

        prevP = p;
        p += stepUV;
    }

    if (lastSkyUV.x >= 0.0) {
        return vec4(min(texture(colortex0, lastSkyUV).rgb, vec3(64.0)), ssrEdgeFade(lastSkyUV) * 0.75);
    }
    return vec4(0.0);
}

vec4 ssrTraceReflection(vec3 viewStart, vec3 viewNormal, float roughness, float dither) {
    vec3 N = normalize(viewNormal);
    vec3 V = normalize(-viewStart);
    vec3 R = reflect(-V, N);

    vec3 n = normalize(R);
    vec3 helper = abs(n.z) < 0.99 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(helper, n));
    vec3 b = cross(n, t);

    float cone = clamp(roughness * 0.75, 0.015, 0.9);
    int rayBudget;
    if (roughness < 0.15) {
        rayBudget = 1;
    } else if (roughness < 0.28) {
        rayBudget = SSR_RAY_COUNT;
    } else {
        rayBudget = 1;
    }

    vec3 start = viewStart + N * 0.06;
    vec3 sum = vec3(0.0);
    float weightSum = 0.0;

    for (int r = 0; r < SSR_RAY_COUNT; ++r) {
        if (r >= rayBudget) break;
        float phi;
        float cosTheta;
        if (rayBudget <= 1) {
            phi = 0.0;
            cosTheta = 1.0;
        } else {
            phi = (float(r) + 0.5) / float(rayBudget) * 6.28318530718
                + dither * 6.28318530718;
            cosTheta = sqrt(max(1.0 - cone * cone * 0.25, 0.0));
        }
        float sinTheta = sqrt(max(1.0 - cosTheta * cosTheta, 0.0));
        vec3 dir = normalize(t * (cos(phi) * sinTheta)
                           + b * (sin(phi) * sinTheta)
                           + n * cosTheta);
        vec4 ray = ssrTraceOneRay(start, dir, SSR_DISTANCE, dither);
        sum += ray.rgb * ray.a;
        weightSum += ray.a;
    }

    if (weightSum <= 1.0e-4) return vec4(0.0);
    return vec4(sum / weightSum, clamp(weightSum / float(rayBudget), 0.0, 1.0));
}

#endif
