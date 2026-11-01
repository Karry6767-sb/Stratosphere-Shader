#ifndef CONTACT_SHADOW_STRENGTH_INV
#define CONTACT_SHADOW_STRENGTH_INV 0.88
#endif
#ifndef CONTACT_SHADOW_BIAS
#define CONTACT_SHADOW_BIAS 4e-4
#endif
#ifndef CONTACT_SHADOW_THIN_SCALE
#define CONTACT_SHADOW_THIN_SCALE 0.35
#endif

#ifndef LIB_AO_GLSL
#define LIB_AO_GLSL

const float AO_PI     = 3.14159265358979;
const float AO_HALF_PI = 1.57079632679490;

float aoFastAcos(float x) {
    const float C0 = 1.57018;
    const float C1 = -0.201877;
    const float C2 = 0.0464619;

    float ax = abs(x);
    float res = (C2 * ax + C1) * ax + C0;
    res *= sqrt(1.0 - ax);
    return x >= 0.0 ? res : AO_PI - res;
}

#ifndef AO_SLICES
#define AO_SLICES        3
#endif
#ifndef AO_HORIZON_STEPS
#define AO_HORIZON_STEPS 3
#endif

#ifndef AO_SSAO_SAMPLES
#define AO_SSAO_SAMPLES  10
#endif
#ifndef AO_FALLOFF_START
#define AO_FALLOFF_START 0.75
#endif

#ifndef AO_SAME_DEPTH_EPS
#define AO_SAME_DEPTH_EPS 1.0e-5
#endif

#ifndef AO_THIN_GEO_RADIUS_SCALE
#define AO_THIN_GEO_RADIUS_SCALE 0.35
#endif

#ifndef CONTACT_SHADOW_DITHER
#define CONTACT_SHADOW_DITHER 0.5
#endif
vec3 aoProjectAndDivide(mat4 m, vec3 p) {
    vec4 h = m * vec4(p, 1.0);
    return h.xyz / h.w;
}

vec3 aoScreenToView(vec3 screenPos) {
    vec3 ndc = screenPos * 2.0 - 1.0;
    return aoProjectAndDivide(gbufferProjectionInverse, ndc);
}

vec3 aoViewToScreen(vec3 viewPos) {
    return aoProjectAndDivide(gbufferProjection, viewPos) * 0.5 + 0.5;
}

float aoMaxHorizonCos(vec3 viewSliceDir, vec3 viewerDir, vec3 screenPos,
                      vec3 viewPos, float radius, float dither) {
    float stepSize = radius / float(AO_HORIZON_STEPS);
    float maxCos = -1.0;

    vec2 rayStep = (aoViewToScreen(viewPos + viewSliceDir * stepSize) -
                    screenPos).xy;

    float rcpRayLen = inversesqrt(max(dot(rayStep, rayStep), 1e-12));
    float startOffset = dither + max(1.0 / viewWidth, 1.0 / viewHeight) * rcpRayLen;
    vec2 rayPos = screenPos.xy + rayStep * startOffset;

    for (int i = 0; i < AO_HORIZON_STEPS; i++) {
        if (rayPos.x < 0.0 || rayPos.x > 1.0 ||
            rayPos.y < 0.0 || rayPos.y > 1.0) {
            break;
        }

        float depth = texture(depthtex0, rayPos).r;
        float depthDiff = abs(depth - screenPos.z);
        if (depth >= 1.0 || depthDiff < AO_SAME_DEPTH_EPS) {
            rayPos += rayStep;
            continue;
        }

        vec3 offset = aoScreenToView(vec3(rayPos, depth)) - viewPos;
        float lenSq = dot(offset, offset);
        if (lenSq < 1e-8) { rayPos += rayStep; continue; }

        float rcpLen = inversesqrt(lenSq);
        float cosTheta = dot(viewerDir, offset) * rcpLen;

        float dist = lenSq * rcpLen;
        float falloff = clamp((dist - AO_FALLOFF_START * radius) /
                              (radius * (1.0 - AO_FALLOFF_START)), 0.0, 1.0);
        cosTheta = mix(cosTheta, -1.0, falloff);

        maxCos = max(maxCos, cosTheta);
        rayPos += rayStep;
    }

    return maxCos;
}

vec3 aoSpherePoint(int i, int total, float dither) {
    float u = (float(i) + dither) / float(total);
    float cosTheta = u;
    float sinTheta = sqrt(max(1.0 - cosTheta * cosTheta, 0.0));
    float phi = float(i) * 2.39996322972865332 + dither * 6.2831853;
    return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

float aoComputeSSAO(vec3 screenPos, vec3 viewPos, vec3 viewNormal,
                    vec2 dither, float radius) {
    vec3 n = normalize(viewNormal);
    vec3 t = normalize(abs(n.z) < 0.9 ? cross(vec3(0.0, 0.0, 1.0), n)
                                         : cross(vec3(1.0, 0.0, 0.0), n));
    vec3 b = cross(n, t);

    float occ = 0.0;
    float wsum = 0.0;

    for (int i = 0; i < AO_SSAO_SAMPLES; i++) {
        vec3 dirLocal = aoSpherePoint(i, AO_SSAO_SAMPLES, dither.x);
        vec3 dirView = t * dirLocal.x + b * dirLocal.y + n * dirLocal.z;

        float r = radius * (0.35 + 0.65 * fract(dither.y + float(i) * 0.618));
        vec3 sampleView = viewPos + dirView * r;

        vec3 sampleScreen = aoViewToScreen(sampleView);
        if (sampleScreen.x < 0.0 || sampleScreen.x > 1.0 ||
            sampleScreen.y < 0.0 || sampleScreen.y > 1.0) {
            continue;
        }

        float sampleDepth = texture(depthtex0, sampleScreen.xy).r;
        if (sampleDepth >= 1.0 || abs(sampleDepth - screenPos.z) < AO_SAME_DEPTH_EPS) {
            continue;
        }
        vec3 realView = aoScreenToView(vec3(sampleScreen.xy, sampleDepth));
        vec3 diff = realView - viewPos;

        float len = length(diff);
        if (len < 1e-4 || len > radius) {
            continue;
        }
        float cosAng = max(dot(diff / len, n), 0.0);
        float falloff = 1.0 / (1.0 + len / max(radius, 1e-3));
        float w = cosAng * falloff;
        occ += w;
        wsum += 1.0;
    }

    if (wsum < 0.5) {
        return 1.0;
    }

    float vis = 1.0 - (occ / wsum) * 1.6;
    vis = clamp(vis, 0.0, 1.0);
    return vis * vis * (3.0 - 2.0 * vis);
}

float aoComputeGTAO(vec3 screenPos, vec3 viewPos, vec3 viewNormal,
                    vec2 dither, float radius, out vec3 bentNormal) {
    float ao = 0.0;
    bentNormal = vec3(0.0);

    vec3 viewerDir   = normalize(-viewPos);
    vec3 viewerRight = normalize(cross(vec3(0.0, 1.0, 0.0), viewerDir));
    vec3 viewerUp    = cross(viewerDir, viewerRight);
    mat3 localToView = mat3(viewerRight, viewerUp, viewerDir);

    for (int i = 0; i < AO_SLICES; i++) {
        float sliceAngle = (float(i) + dither.x) * (AO_PI / float(AO_SLICES));

        vec3 sliceDir = vec3(cos(sliceAngle), sin(sliceAngle), 0.0);
        vec3 viewSliceDir = localToView * sliceDir;

        vec3 orthoDir = sliceDir - dot(sliceDir, viewerDir) * viewerDir;
        vec3 axis = cross(sliceDir, viewerDir);
        vec3 projNormal = viewNormal - axis * dot(viewNormal, axis);

        float lenSq = dot(projNormal, projNormal);
        float norm = inversesqrt(max(lenSq, 1e-8));

        float sgnGamma = sign(dot(orthoDir, projNormal));
        float cosGamma = clamp(dot(projNormal, viewerDir) * norm, 0.0, 1.0);
        float gamma = sgnGamma * aoFastAcos(cosGamma);

        float maxHorizonX = aoFastAcos(clamp(
            aoMaxHorizonCos(-viewSliceDir, viewerDir, screenPos, viewPos, radius, dither.y),
            -1.0, 1.0));
        float maxHorizonY = aoFastAcos(clamp(
            aoMaxHorizonCos( viewSliceDir, viewerDir, screenPos, viewPos, radius, dither.y),
            -1.0, 1.0));
        vec2 maxHorizon = vec2(maxHorizonX, maxHorizonY);

        maxHorizon = gamma + clamp(vec2(-1.0, 1.0) * maxHorizon - gamma,
                                   -AO_HALF_PI, AO_HALF_PI);

        vec2 tmp = cosGamma + 2.0 * maxHorizon * sin(gamma) -
                   cos(2.0 * maxHorizon - gamma);
        ao += 0.25 * (tmp.x + tmp.y) * lenSq * norm;

        float bentAngle = dot(maxHorizon, vec2(0.5));
        bentNormal += viewerDir * cos(bentAngle) + orthoDir * sin(bentAngle);
    }

    ao /= float(AO_SLICES);

    bentNormal = normalize(bentNormal - 0.5 * viewerDir);

    return clamp(ao, 0.0, 1.0);
}

vec3 aoMultiBounce(float ao, vec3 albedo) {
    vec3 a = 2.0404 * albedo - 0.3324;
    vec3 b = 4.7951 * albedo - 0.6417;
    vec3 c = 2.7552 * albedo + 0.6903;
    return max(vec3(ao), ((ao * a - b) * ao + c) * ao);
}

float aoApply(vec2 uv, float depth, vec3 worldNormal,
              float aoStrength, float aoRadius, int aoType,
              float isThin, out vec3 bentView) {
    bentView = vec3(0.0, 0.0, 1.0);
    if (depth >= 1.0) {
        return 1.0;
    }

    vec3 screenPos = vec3(uv, depth);
    vec3 viewPos = aoScreenToView(screenPos);
    vec3 viewNormal = mat3(gbufferModelView) * normalize(worldNormal);
    bentView = viewNormal;

    ivec2 aoPixel = ivec2(uv * vec2(viewWidth, viewHeight));
    vec2 h2a = fract(vec2(aoPixel) * vec2(0.1031, 0.1030));
    h2a += dot(h2a, h2a.yx + 33.33);
    float n1 = fract((h2a.x + h2a.y) * h2a.x);
    vec2 h2b = fract(vec2(aoPixel) * vec2(0.0973, 0.1099) + 17.13);
    h2b += dot(h2b, h2b.yx + 41.71);
    float n2 = fract((h2b.x + h2b.y) * h2b.y);
    float fr = fract(float(frameCounter) * 0.6180339887);
    vec2 dither = fract(vec2(n1 + fr, n2 + fr * 0.7548776662));

    float viewDist = length(viewPos);
    float radiusScale = 0.45 + 0.55 * smoothstep(1.0, 6.0, viewDist);
    float radius = max(aoRadius * radiusScale, 0.05);

    if (isThin > 0.5) {
        radius *= AO_THIN_GEO_RADIUS_SCALE;
    }

    float ao;
    if (aoType == 1) {
        ao = aoComputeSSAO(screenPos, viewPos, viewNormal, dither, radius);
    } else {
        ao = aoComputeGTAO(screenPos, viewPos, viewNormal, dither, radius, bentView);
    }

    float k = clamp(aoStrength, 0.0, 3.0);
    if (abs(k - 1.0) > 0.001) {
        ao = pow(clamp(ao, 1e-4, 1.0), k);
    }

    return clamp(ao, 0.0, 1.0);
}
float aoContactShadow(vec3 screenPos, vec3 viewPos, vec3 lightDirView,
                      float isThin, float viewDist) {
    float maxDist = CONTACT_SHADOW_LENGTH;

    vec3 endView = viewPos + lightDirView * maxDist;
    vec3 endScreen = aoViewToScreen(endView);

    vec2 rayVec = endScreen.xy - screenPos.xy;
    float rayLen = length(rayVec);
    if (rayLen < 1e-5) {
        return 1.0;
    }

    float lenScale = (isThin > 0.5) ? CONTACT_SHADOW_THIN_SCALE : 1.0;
    vec2 rayStep = rayVec / float(CONTACT_SHADOW_SAMPLES) * lenScale;

    vec2 rayPos = screenPos.xy + rayStep * CONTACT_SHADOW_DITHER;
    float rayZStep = (endScreen.z - screenPos.z) / float(CONTACT_SHADOW_SAMPLES) * lenScale;
    float rayZ = screenPos.z + rayZStep * CONTACT_SHADOW_DITHER;

    float shadow = 1.0;
    for (int i = 0; i < CONTACT_SHADOW_SAMPLES; i++) {
        rayPos += rayStep;
        rayZ += rayZStep;

        if (rayPos.x < 0.0 || rayPos.x > 1.0 ||
            rayPos.y < 0.0 || rayPos.y > 1.0) {
            break;
        }

        float sampleDepth = texture(depthtex0, rayPos).r;
        if (sampleDepth >= 1.0) {
            continue;
        }

        float depthTol = CONTACT_SHADOW_BIAS * (1.0 + rayZ * 200.0);
        if (sampleDepth < rayZ - depthTol) {
            shadow *= CONTACT_SHADOW_STRENGTH_INV;
        }
    }

    float distanceFade = 1.0 - smoothstep(8.0, 24.0, viewDist);
    return clamp(mix(1.0, shadow, distanceFade), 0.0, 1.0);
}
#endif
