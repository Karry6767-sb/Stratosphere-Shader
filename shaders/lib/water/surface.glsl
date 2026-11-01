#ifndef LIB_WTR_SURFACE_GLSL
#define LIB_WTR_SURFACE_GLSL

#include "/lib/water/optics.glsl"

float WtrLinearDepth(float depth, float nearPlane, float farPlane) {
    return 2.0 * nearPlane * farPlane
         / max((farPlane + nearPlane) - depth * (farPlane - nearPlane), 1.0e-6);
}

vec2 WtrRefractionUV(vec2 uv, vec3 N, vec3 VtoCamera, float viewDist,
                     bool underwater, sampler2D depthOpaque, sampler2D depthAll) {
    vec3 incidentW = -normalize(VtoCamera);
    vec3 Nw = normalize(N);

    vec3 flatRefrW = refract(incidentW, vec3(0.0, 1.0, 0.0), 1.0 / 1.33);
    vec3 refrW = refract(incidentW, Nw, 1.0 / 1.33);
    if (dot(flatRefrW, flatRefrW) < 1.0e-6 || dot(refrW, refrW) < 1.0e-6) {
        return uv;
    }

    vec3 flatRefrV = mat3(gbufferModelView) * flatRefrW;
    vec3 refrV = mat3(gbufferModelView) * refrW;
    vec2 offset = (refrV.xy / max(-refrV.z, 1.0e-4))
                - (flatRefrV.xy / max(-flatRefrV.z, 1.0e-4));

    float offsetLen = length(offset);
    if (offsetLen > 2.0) offset *= 2.0 / offsetLen;

    float refractDepth = underwater ? WTR_UNDERWATER_REFRACT : 1.0;
    float amount = (WTR_REFRACT * 0.125) * WTR_REFRACT_DEPTH
                 / (1.0 + pow(max(viewDist, 0.0), 0.8) * refractDepth);

    vec2 edgeDist = min(uv, vec2(1.0) - uv);
    float edgeFade = smoothstep(0.0, 0.10, min(edgeDist.x, edgeDist.y));
    vec2 refrUV = uv + offset * amount * edgeFade;

    float distanceFade = 1.0 - smoothstep(48.0, 128.0, viewDist);
    refrUV = mix(uv, refrUV, distanceFade);

    if (refrUV.x < 0.001 || refrUV.x > 0.999 ||
        refrUV.y < 0.001 || refrUV.y > 0.999) {
        return uv;
    }

    float surfaceDepth = texture(depthAll, uv).r;
    if (texture(depthOpaque, refrUV).r < surfaceDepth) return uv;
    return refrUV;
}

vec3 WtrShadeSurface(vec3 waterNormal, vec3 VtoCamera, vec3 bottomLit,
                     vec3 skyRefl, float pathLen, vec4 waterTintData,
                     bool underwater) {
    vec3 T = WtrBodyTransmittance(pathLen);
    vec3 body = bottomLit * T + WtrDirtScatter() * (1.0 - T);

    float waterSky = clamp(waterTintData.a * 2.0 - 1.0, 0.0, 1.0);
    vec3 refl = skyRefl * mix(0.05, 1.0, waterSky);

    float F = WtrFresnel(VtoCamera, waterNormal, underwater);
    return mix(body, refl, F);
}

vec3 WtrUnderwaterScreen(vec3 col, float linearDist, bool isSky, float farDist,
                         vec3 waterTint) {
    vec3 T = WtrBodyTransmittance(linearDist);
    col *= T;

    if (!isSky) {
        float fogFar = max(min(farDist, WTR_FOG_FAR), 1.0e-3);
        float fade = clamp(1.0 - max(1.0 - linearDist / fogFar, 0.0), 0.0, 1.0);
        vec3 tintedScatter = WtrDirtScatter()
                           * mix(vec3(1.0), clamp(waterTint, 0.0, 1.0), 0.35);
        col += tintedScatter * fade;
    }
    return col;
}

#endif
