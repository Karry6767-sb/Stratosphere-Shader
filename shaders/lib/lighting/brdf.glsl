#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef LIB_LIGHTING_BRDF_GLSL
#define LIB_LIGHTING_BRDF_GLSL

float BRDFPow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float BRDFDistributionGGX(float NoH, float alpha) {
    float a2 = alpha * alpha;
    float d = NoH * NoH * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1.0e-7);
}

float BRDFVisibilitySmithGGXCorrelated(float NoV, float NoL, float alpha) {
    float a2 = alpha * alpha;
    float lv = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float ll = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / max(lv + ll, 1.0e-5);
}

vec3 BRDFFresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * BRDFPow5(1.0 - cosTheta);
}

float BRDFDiffuseBurley(float NoV, float NoL, float LoH, float roughness) {
    float fd90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = 1.0 + (fd90 - 1.0) * BRDFPow5(1.0 - NoL);
    float viewScatter  = 1.0 + (fd90 - 1.0) * BRDFPow5(1.0 - NoV);
    return lightScatter * viewScatter / PI;
}

vec3 BrdfF0(vec3 albedo, float metalness) {
    return mix(vec3(0.04), albedo, metalness);
}

vec2 EnvBRDFApprox(float roughness, float NoV) {
    vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
}

vec3 EvaluateDirectBRDF(vec3 albedo, float roughness, float metalness,
                        float NoV, float NoL, float NoH, float VoH, float LoH,
                        float specStrength) {
    if (NoL <= 1.0e-5) return vec3(0.0);
    float alpha = max(roughness * roughness, 0.002);
    vec3 f0 = BrdfF0(albedo, metalness);
    vec3 F = BRDFFresnelSchlick(max(VoH, 0.0), f0);
    float D = BRDFDistributionGGX(max(NoH, 0.0), alpha);
    float vis = BRDFVisibilitySmithGGXCorrelated(max(NoV, 1.0e-5), NoL, alpha);
    vec3 diffuse = albedo * (vec3(1.0) - F) * (1.0 - metalness)
                 * BRDFDiffuseBurley(max(NoV, 1.0e-5), NoL, LoH, roughness);
    vec3 specular = F * D * vis * max(specStrength, 0.0);
    specular = min(specular, vec3(4.0));
    return (diffuse + specular) * NoL;
}

float BRDFAreaLightNoHSquared(float NoL, float NoV, float LoV, float lightRadius) {
    float cosR = cos(lightRadius);
    float RoL = 2.0 * NoL * NoV - LoV;
    if (RoL >= cosR) return 1.0;

    float tanR = tan(lightRadius);
    float rOverLenT = cosR * tanR * inversesqrt(max(1.0 - RoL * RoL, 1.0e-8));
    float notR = rOverLenT * (NoV - RoL * NoL);
    float votR = rOverLenT * (2.0 * NoV * NoV - 1.0 - RoL * LoV);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - LoV * LoV
                              + 2.0 * NoL * NoV * LoV, 0.0, 1.0));

    float NoBr = rOverLenT * triple;
    float VoBr = rOverLenT * (2.0 * triple * NoV);
    float NoLvtR = NoL * cosR + NoV + notR;
    float LoVvtR = LoV * cosR + 1.0 + votR;
    float p = NoBr * LoVvtR;
    float q = NoLvtR * LoVvtR;
    float s = VoBr * NoLvtR;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLvtR);
    float xDenom = p * p + s * (s - 2.0 * p)
                 + NoLvtR * ((NoL * cosR + NoV) * LoVvtR * LoVvtR
                             + q * (-0.5 * (LoVvtR + LoV * cosR) - 0.5));
    float twoX1 = 2.0 * xNum / max(xDenom * xDenom + xNum * xNum, 1.0e-12);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    notR = cosTheta * notR + sinTheta * NoBr;
    votR = cosTheta * votR + sinTheta * VoBr;

    float newNoL = NoL * cosR + notR;
    float newLoV = LoV * cosR + votR;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newLoV + 2.0;
    return clamp(NoH * NoH / max(HoH, 1.0e-8), 0.0, 1.0);
}

vec3 EvaluateDirectBRDFAreaLight(vec3 albedo, float roughness, float metalness,
                                 float NoV, float NoL, float LoV, float VoH, float LoH,
                                 float lightRadius, float specStrength) {
    if (NoL <= 1.0e-5) return vec3(0.0);
    float alpha = max(roughness * roughness, 0.002);
    vec3 f0 = BrdfF0(albedo, metalness);
    vec3 F = BRDFFresnelSchlick(max(VoH, 0.0), f0);
    float D = BRDFDistributionGGX(sqrt(BRDFAreaLightNoHSquared(NoL, max(NoV, 1.0e-5), LoV, lightRadius)), alpha);
    float vis = BRDFVisibilitySmithGGXCorrelated(max(NoV, 1.0e-5), NoL, alpha);
    vec3 diffuse = albedo * (vec3(1.0) - F) * (1.0 - metalness)
                 * BRDFDiffuseBurley(max(NoV, 1.0e-5), NoL, LoH, roughness);
    vec3 specular = F * D * vis * max(specStrength, 0.0);
    specular = min(specular, vec3(4.0));
    return (diffuse + specular) * NoL;
}

#endif
