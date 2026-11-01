#version 430 compatibility

/*
const int colortex0Format = RGBA16F;
const int colortex3Format = RGBA16F;
const bool colortex3Clear = true;
const int colortex4Format = RGBA16F;
const int colortex6Format = RGBA16F;
const bool colortex6Clear = false;
const int colortex7Format = RGBA16F;
const int colortex8Format = RGBA16F;
const int colortex15Format = RGBA16F;
const bool colortex15Clear = false;
const int colortex12Format = RGBA16F;
const bool colortex12Clear = true;
const int colortex13Format = RGBA16F;
const bool colortex13Clear = true;
const int colortex14Format = RGBA16F;
const bool colortex14Clear = true;
const int colortex9Format = RGBA16F;
const bool colortex9Clear = true;
const int colortex10Format = RGBA16F;
const bool colortex10Clear = true;
const int colortex11Format = RGBA16F;
const bool colortex11Clear = true;
*/

/* RENDERTARGETS: 0 */

#include "/lib/options_defaults.glsl"

#if PERF_TIER == 0
	#define PCF_RANGE 2
	#define PERF_SCALE 0.5
#endif
#if PERF_TIER == 2
	#define PCF_RANGE 8
	#define PERF_SCALE 1.0
#endif
#if PERF_TIER != 0 && PERF_TIER != 2
	#define PCF_RANGE 4
	#define PERF_SCALE 1.0
#endif

const float sunPathRotation = SUN_PATH_ROTATION;

#if SOFT_SHADOWS == 1
#define SHADOW_RANGE PCF_RANGE
#endif

#ifndef AO_TYPE
#endif

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex0;

uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D noisetex;
uniform int isEyeInWater;
uniform float waterEnteredAltitude;
uniform vec3 waterEnteredPosition;
uniform float rainStrength;
uniform vec2 eyeBrightnessSmooth;
uniform float frameTimeCounter;
uniform float frameTime;
uniform int frameCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform vec4 lightningBoltPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;
uniform vec2 u_taa_offset;
uniform float sunAngle;
uniform vec3 sunPosition;
uniform float near;
uniform float far;
uniform int worldTime;
#define CELESTIAL_HAS_WORLD_TIME 1
uniform int worldDay;
uniform float biome_may_snow;
uniform int moonPhase;

in vec2 texcoord;

#include "/lib/distort.glsl"
#include "/lib/shadow/entry.glsl"
#include "/lib/blackbody.glsl"

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"
#include "/lib/atmosphere/adaptive_sky_gain.glsl"
#include "/lib/sky/cirrus.glsl"
#include "/lib/water/settings.glsl"
#include "/lib/atmosphere/sky_sh.glsl"
#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/sky/aurora.glsl"
#include "/lib/lighting/aurora_gi.glsl"
#include "/lib/lighting/ambient.glsl"
#include "/lib/lighting/transport.glsl"
#include "/lib/lighting/physical.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/material.glsl"
#include "/lib/lighting/specular.glsl"
uniform sampler2D starmap;

#include "/lib/post.glsl"
#include "/lib/celestial/sun_flare.glsl"
#include "/lib/ao.glsl"
#include "/lib/shadow_matrix.glsl"
#include "/lib/celestial.glsl"
#include "/lib/celestial/daylight.glsl"
#include "/lib/celestial/eclipse.glsl"
#include "/lib/celestial/light_state.glsl"
#include "/lib/medium.glsl"
#include "/lib/stars.glsl"
#include "/lib/galaxy.glsl"
#include "/lib/meteors.glsl"
#include "/lib/comets.glsl"

#include "/lib/shadow/pcss.glsl"
#include "/lib/lighting/sky_gi.glsl"
#include "/lib/fog/local_fog.glsl"
#include "/lib/volumetric/point_light.glsl"
#include "/lib/volumetric/flash.glsl"

layout(location = 0) out vec4 color;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 nightSkylightColor = vec3(0.03, 0.05, 0.10);
const vec3 sunlightColor = vec3(1.0);
const vec3 ambientColor = vec3(0.05);
#ifndef LEGACY_MOONLIGHT_FALLBACK
#define LEGACY_MOONLIGHT_FALLBACK 0.25
#endif
#if MOON_LIGHT_PHYSICAL == 1
const float moonlightIntensity = MOON_IRRADIANCE_PHYSICAL;
#else
const float moonlightIntensity = LEGACY_MOONLIGHT_FALLBACK;
#endif

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homPos = projectionMatrix * vec4(position, 1.0);
	return homPos.xyz / homPos.w;
}

vec3 viewToScreenSpace(vec3 viewPos) {
	vec3 ndc = projectAndDivide(gbufferProjection, viewPos);
	return ndc * 0.5 + 0.5;
}

vec2 clampRefractionUV(vec2 uv, vec2 base) {
    float vignette = max(uv.x * base.x, 0.0);
    vignette = max(uv.y * base.y, vignette);
    vignette = max((uv.x - 1.0) * (base.x - 1.0), vignette);
    vignette = max((uv.y - 1.0) * (base.y - 1.0), vignette);
    vignette *= vignette * vignette * vignette * vignette;
    return clamp(mix(uv, base, vignette), 0.0, 0.9999999);
}

vec3 perturbIceNormal(vec3 N, vec3 worldPos) {
    vec3 p = worldPos;
    vec2 uv;
    if (abs(N.y) > 0.7) {
        uv = p.xz;
    } else if (abs(N.x) > 0.7) {
        uv = p.zy;
    } else {
        uv = p.xy;
    }
    uv *= 0.03;
    const float e = 0.012;
    float h0 = texture(noisetex, uv).r;
    float hx = texture(noisetex, uv + vec2(e, 0.0)).r;
    float hy = texture(noisetex, uv + vec2(0.0, e)).r;
    vec2 grad = vec2(h0 - hx, h0 - hy);
    vec3 up = (abs(N.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 T = normalize(cross(up, N));
    vec3 B = cross(N, T);
    vec3 bump = (T * grad.x + B * grad.y) * (GLASS_ICE_BUMP * 1.5);
    float bl = length(bump);
    if (bl > 0.35) bump *= 0.35 / bl;
    return normalize(N + bump);
}

float ssrDither(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float computeDaylight() {
    return CelestialDaylight(SceneSunDirW());
}

vec3 WtrSkyRadiance(vec3 dirW, vec3 sunDirW) {
    vec3 d = normalize(dirW);
    vec3 sky = atmSampleSkyView(d, sunDirW, ATM_PLANET_R,
                                AtmosphereCameraAltitude());
#if CIRRUS_REFLECT == 1
    float skyGain = ATM_SKY_RADIANCE_SCALE * atmAdaptiveSkyRadianceGain(worldTime);
    vec3 moonDirW = SceneMoonDirW();
    float moonIllum = MoonIllumination(moonPhase);
    CirrusOut cr = CirrusComposite(AtmosphereCameraPosition(), d, sky,
                                   sunDirW, moonDirW, skyGain, moonIllum);
    sky = cr.sky;
#endif
    return sky;
}

vec3 WtrUnderwaterShafts(vec2 uv, vec3 sunDirW, float viewDist) {
#if WTR_SHAFTS == 0
    return vec3(0.0);
#else
    if (isEyeInWater != 1 || sunDirW.y <= 0.0) return vec3(0.0);
    vec3 sunView = mat3(gbufferModelView) * normalize(sunDirW);
    float vis;
    vec2 sunUV = SunScreenUV(gbufferProjection, sunView, vis);
    if (vis <= 1.0e-4) return vec3(0.0);
    float aspect = viewWidth / max(viewHeight, 1.0);
    vec2 d = (uv - sunUV) * vec2(aspect, 1.0);
    float r = length(d);
    float ang = atan(d.y, d.x);
    float ts = frameTimeCounter;
    float n1 = 0.5 + 0.5 * sin(ang * 13.0 + 1.7 * sin(ang * 4.0 + ts * 0.05) + ts * 0.08);
    float n2 = 0.5 + 0.5 * sin(ang * 29.0 - 2.3 * sin(ang * 9.0 - ts * 0.03) - ts * 0.05);
    float beams = pow(clamp(n1 * n2, 0.0, 1.0), 6.0);
    float falloff = exp(-r * 4.0) * smoothstep(0.0, 0.08, r)
                  * (1.0 - smoothstep(0.60, 1.10, r));
    float distFade = exp(-max(viewDist, 0.0) * 0.018);
    vec3 tint = min(SUN_IRRADIANCE * sunLightColor() * medSunTintAt(sunDirW)
                  * CelestialSunUp(sunDirW), vec3(16.0));
    return tint * (beams * falloff * distFade * WTR_SHAFT_STRENGTH * 0.06);
#endif
}

vec3 CelestialDirectBRDF(vec3 albedo, float roughness, float metalness, float NoV,
                         vec3 N, vec3 V, vec3 L, float angularRadius,
                         float specStrength, vec3 radiance) {
    float NoL = clamp(dot(N, L), 0.0, 1.0);
    if (NoL <= 1.0e-5) return vec3(0.0);
    vec3 H = normalize(V + L);
    float NoH = max(dot(N, H), 0.0);
    float VoH = max(dot(V, H), 0.0);
    float LoH = max(dot(L, H), 0.0);
    float LoV = max(dot(L, V), 0.0);
#if SPECULAR_AREA_LIGHT == 1
    vec3 brdf = EvaluateDirectBRDFAreaLight(albedo, roughness, metalness,
                                            NoV, NoL, LoV, VoH, LoH,
                                            angularRadius, specStrength);
#else
    vec3 brdf = EvaluateDirectBRDF(albedo, roughness, metalness,
                                   NoV, NoL, NoH, VoH, LoH,
                                   specStrength);
#endif
    return brdf * radiance;
}

float sceneAuroraAmount(vec3 sunDirW) {
    float auroraNight = max(AuroraNightFade(sunDirW), smoothstep(15000.0, 60000.0, cameraPosition.y));
    float chance = AuroraChanceFactor(float(worldDay), biome_may_snow);
    return auroraNight * chance;
}

vec3 shadeSurface(vec3 albedo, vec2 lightmap, vec3 normal, vec3 viewPos,
                  vec3 lightDirWorld, vec3 rawShadow, float shadowFadeMul,
                  float ao, vec3 causticMul, float matCode, out vec3 shadowOut) {
   vec3 sunDirW  = SceneSunDirW();
   vec3 moonDirW = SceneMoonDirW();
   float daylight = CelestialDaylight(sunDirW);

	vec3 shadow = rawShadow * shadowFadeMul;
	shadowOut = shadow;

	vec2 lightCurve = pow(max(lightmap, vec2(0.0)), vec2(LIGHTMAP_GAMMA));

	vec3 worldRel = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 atmPos = AtmosphereCameraPosition() + worldRel * ATM_M_TO_KM;

	float sunEarthShadow = 1.0;
	float moonAtmShadowUnused = 1.0;
	vec3 sunTint  = vec3(1.0);
	vec3 moonTint = vec3(1.0);
#if SUN_TRANSPORT == 1
	sunTint  = transportSunTint(atmPos, sunDirW,  sunEarthShadow);
	moonTint = transportSunTint(atmPos, moonDirW, moonAtmShadowUnused);
#else
	sunTint = medSunTintAt(sunDirW);
	#if SUN_TRANSMITTANCE == 1
	sunTint = sunTransmittanceTint(atmPos, sunDirW);
	#endif
	#if SUN_EARTH_SHADOW == 1
	sunEarthShadow = sunVisibility(atmPos, sunDirW);
	#endif
#endif

	float sunUp  = CelestialSunUp(sunDirW);
	float moonUp = CelestialMoonUp(moonDirW);
#if DAYLIGHT_LEGACY == 1
	sunUp  = clamp(lightDirWorld.y * 50.0, 0.0, 1.0) * CelestialLegacyDaylight(sunDirW);
	moonUp = clamp(lightDirWorld.y * 50.0, 0.0, 1.0)
	       * (1.0 - CelestialLegacyDaylight(sunDirW));
#endif

	vec3 sunRadiance = SUN_IRRADIANCE * sunLightColor() * sunTint
	                 * sunUp * sunEarthShadow;

	float moonSkyVisibility = 1.0;
#if MOON_LIGHT_PHYSICAL == 0
	moonSkyVisibility = MOON_ART_GAIN;
#endif
	vec3 moonEclipse = MoonEclipseTint(sunDirW, moonDirW, moonPhase, worldDay);

	vec3 moonRadiance = moonLightColor() * moonlightIntensity * SceneMoonExposure()
	                  * moonTint * moonEclipse * moonUp * moonSkyVisibility;

	bool activeIsSun = SceneActiveIsSun();
	vec3 sunShadowF  = activeIsSun ? shadow : vec3(1.0);
	vec3 moonShadowF = activeIsSun ? vec3(1.0) : shadow;
vec3 sunBounceRadiance = sunRadiance;
vec3 moonBounceRadiance = moonRadiance;
sunRadiance *= sunShadowF;
	moonRadiance *= moonShadowF;

	CelestialLight Ls = CelestialSunLight(sunDirW, sunRadiance * causticMul);
		CelestialLight Lm = CelestialMoonLight(moonDirW, moonRadiance * causticMul);
	Lm.upGate *= moonSkyVisibility;
	Ls.shadowGate = activeIsSun ? 1.0 : 0.0;
	Lm.shadowGate = activeIsSun ? 0.0 : 1.0;

#if CELESTIAL_DUAL_LIGHT == 1
	vec3 sunlight = Ls.radiance * clamp(dot(normal, Ls.dirW), 0.0, 1.0)
	              + Lm.radiance * clamp(dot(normal, Lm.dirW), 0.0, 1.0);
#else
	float NoL = clamp(dot(normal, lightDirWorld), 0.0, 1.0);
	vec3 sunlight = (sunRadiance + moonRadiance) * NoL;
#endif

float sunSkyGate = smoothstep(0.02, 0.30, lightCurve.g);
if (isEyeInWater != 1) sunlight *= sunSkyGate;

vec3 blocklight = lightCurve.r * fireLightColor();
	vec3 skylight = vec3(0.0);
	vec3 ambient  = vec3(0.0);
#if SKY_AMBIENT_LEGACY == 1
	vec3 constantSky = mix(nightSkylightColor, skylightColor, daylight);
	float constantSkyLuma = dot(constantSky, vec3(0.2126, 0.7152, 0.0722));
	constantSky = mix(vec3(constantSkyLuma), constantSky, clamp(SKY_AMBIENT_SATURATION, 0.0, 1.0));
	vec3 constantAmbient = ambientColor * (0.22 + 0.78 * daylight);
	skylight = lightCurve.g * constantSky;
	ambient  = constantAmbient;
#endif
float skyGIOcclusion = 1.0;
#if SKY_AMBIENT == 1
#if SKY_GI_REALTIME == 1
	skyGIOcclusion = mix(1.0,
	                      skyGIHemisphereVisibility(worldRel, normal, shadowDither()),
	                      clamp(SKY_GI_STRENGTH, 0.0, 1.0));
#endif
	vec3 skySH = ambientSkyIrradiance(normal, sunDirW) * skyGIOcclusion;
#if SKY_AMBIENT_LEGACY == 1
	vec3 upSH  = ambientUpIrradiance();
	skylight = lightCurve.g * max(skySH * SKY_AMBIENT_SCALE, constantSky * SKY_AMBIENT_FALLBACK);
	ambient  = max(upSH * AMBIENT_SCALE, constantAmbient * SKY_AMBIENT_FALLBACK);
#else
	vec3 skyLight = lightCurve.g * skySH * SKY_AMBIENT_SCALE;
	vec3 moonAmbient = moonRadiance * (1.0 - sunUp)
	                 * (0.5 + 0.5 * clamp(normal.y, 0.0, 1.0)) * MOON_AMBIENT_SCALE;
	skylight = skyLight + moonAmbient;
	ambient  = vec3(0.0);

	float moonDirWeight = smoothstep(-0.05, 0.15, moonDirW.y);
	float nightAmount = 1.0 - sunUp;
	float lunarDir = clamp(dot(normal, moonDirW), 0.0, 1.0);
	float moonShape = mix(1.0, (0.55 + 1.10 * lunarDir) / 1.10,
	                      nightAmount * moonDirWeight * MOON_NIGHT_SHAPE);
	skylight *= moonShape * mix(1.0, MOON_NIGHT_GAIN, nightAmount * moonDirWeight);

	float shadowLuma = dot(shadow, vec3(0.2126, 0.7152, 0.0722));
	float lunarShadowAmt = (activeIsSun ? 0.0 : 1.0) * nightAmount;
	float ambShadow = mix(1.0, clamp(shadowLuma, 0.0, 1.0),
	                      clamp(MOON_SHADOW_ON_AMBIENT, 0.0, 1.0) * lunarShadowAmt);
	skylight *= ambShadow;
#endif
#else
	{
		vec3 constantSky = mix(nightSkylightColor, skylightColor, daylight);
		skylight = lightCurve.g * constantSky;
		ambient  = ambientColor * (0.22 + 0.78 * daylight);
	}
#endif

	float downFace   = clamp(dot(normal, vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
#if CELESTIAL_DUAL_LIGHT == 1
	float wS = CelestialLuminance(sunBounceRadiance);
	float wM = CelestialLuminance(moonBounceRadiance);
	float wSum = max(wS + wM, 1.0e-8);
	float bounceElev = (wS * clamp(sunDirW.y, 0.0, 1.0)
	                  + wM * clamp(moonDirW.y, 0.0, 1.0)) / wSum;
	vec3  bounceRad  = sunBounceRadiance + moonBounceRadiance;
#else
	float bounceElev = mix(clamp(moonDirW.y, 0.0, 1.0), clamp(sunDirW.y, 0.0, 1.0), daylight);
	vec3  bounceRad  = mix(moonBounceRadiance, sunBounceRadiance, daylight);
#endif
float verticalBounce = 1.0 - smoothstep(0.05, 0.45, normal.y);
float bounceWeight = verticalBounce * mix(0.40, 1.0, downFace);
vec3 bounceTint = mix(vec3(1.0), ATM_GROUND_ALBEDO_RGB * 1.5, 0.35);
float wallBounceGate = mix(1.0, dot(shadow, vec3(0.2126, 0.7152, 0.0722)), verticalBounce * (1.0 - downFace) * 0.85);
vec3  groundBounce = bounceWeight * GROUND_BOUNCE * bounceElev * bounceRad * bounceTint * wallBounceGate;
   vec3 aoBounce = clamp(aoMultiBounce(ao, albedo), 0.0, 1.0);
   aoBounce = max(aoBounce, vec3(clamp(AO_INDIRECT_FLOOR, 0.0, 1.0)));
   vec3 downSkyFill = downFace * ambientUpIrradiance() * AMBIENT_SCALE * 0.5
                    * lightCurve.g * skyGIOcclusion;
   vec3 indirectLight = blocklight + skylight + ambient + downSkyFill;

   vec3 auroraGround = vec3(0.0);
#if AURORA_GROUND_LIGHT == 1
   {
       float groundAuroraAmount = sceneAuroraAmount(sunDirW);
       float moonReference = dot(moonLightColor() * moonlightIntensity
                               * SceneMoonExposure(), vec3(0.2126, 0.7152, 0.0722));
       auroraGround = AuroraGroundIrradiance(normal, albedo,
                                             groundAuroraAmount, moonReference);
       auroraGround *= lightCurve.g;
   }
#endif
   vec3 indirect = (indirectLight + auroraGround) * aoBounce;

   vec3 skyIrradianceAtN = ambientSkyIrradiance(normal, sunDirW);
   vec3 lit;
#if LIGHTING_PBR == 1
    vec3 V = normalize(-viewPos);
    vec3 mat = DecodePBRMaterial(matCode, albedo);
    float roughness = mat.x;
    float metalness = mat.y;
    float sss = mat.z;
    float NoV = max(dot(normal, V), 1.0e-5);
    float specStrength = PBR_SPECULAR_STRENGTH * (1.0 - sss);
#if CELESTIAL_DUAL_LIGHT == 1
    vec3 pbrDirect = CelestialDirectBRDF(albedo, roughness, metalness, NoV,
                                         normal, V, Ls.dirW,
                                         ATM_SUN_ANGULAR_RADIUS, specStrength,
                                         Ls.radiance)
                   + CelestialDirectBRDF(albedo, roughness, metalness, NoV,
                                         normal, V, Lm.dirW,
                                         ATM_MOON_ANGULAR_RADIUS, specStrength,
                                         Lm.radiance);
#else
    float lightAngRadius = SceneActiveIsSun() ? ATM_SUN_ANGULAR_RADIUS : ATM_MOON_ANGULAR_RADIUS;
    vec3 pbrDirect = CelestialDirectBRDF(albedo, roughness, metalness, NoV,
                                         normal, V, lightDirWorld,
                                         lightAngRadius, specStrength,
                                         sunRadiance + moonRadiance);
#endif
    pbrDirect = min(pbrDirect, vec3(16.0));

    vec3 diffuseColor = albedo * (1.0 - metalness);
    vec3 sssTerm = albedo * sss * indirect * (0.35 / PI);
    vec3 ambientSpecF0 = BrdfF0(albedo, metalness);
    vec2 envBRDF = EnvBRDFApprox(roughness, NoV);
    vec3 energyKeep = (vec3(1.0) - metalness) * (vec3(1.0) - ambientSpecF0);
    vec3 ambientSpec = (skyIrradianceAtN * skyGIOcclusion / PI)
                     * (ambientSpecF0 * envBRDF.x + envBRDF.y)
                     * PBR_AMBIENT_SPECULAR
                     * max(energyKeep, vec3(0.0));
#if SSR_ENABLE == 1 && INDIRECT_SPECULAR == 1
    if (IsSpecularMaterial(DecodeMaterialCode(matCode))) {
        ambientSpec = vec3(0.0);
    }
#endif
#if INDIRECT_SPECULAR == 0
    ambientSpec = vec3(0.0);
#endif
    lit = pbrDirect + diffuseColor * (indirect / PI) + sssTerm + ambientSpec
        + diffuseColor * (groundBounce / PI);

    if (sss > 0.5) {
        vec3 leafFill = ambientUpIrradiance() * AMBIENT_SCALE * 0.45
                      + sunBounceRadiance * 0.025 * shadow;
        lit += albedo * sss * leafFill;
    }
#else
    lit = albedo * (indirect + sunlight + groundBounce);
#endif

#if LIGHTING_PI == 1
#if LIGHTING_PBR == 0
	lit = lit / PI;
#endif
#endif

#if LIGHTING_SPECULAR == 1
#if LIGHTING_PBR == 0
	float specMatCode = DecodeMaterialCode(matCode);
	if (IsSpecularMaterial(specMatCode)) {
		vec3 specV = normalize(-viewPos);
#if CELESTIAL_DUAL_LIGHT == 1
		lit += simpleSpecular(albedo, specMatCode, normal, specV, Ls.dirW,
		                      Ls.radiance, SPECULAR_STRENGTH);
		lit += simpleSpecular(albedo, specMatCode, normal, specV, Lm.dirW,
		                      Lm.radiance, SPECULAR_STRENGTH);
#else
		lit += simpleSpecular(albedo, specMatCode, normal, specV, lightDirWorld,
		                      sunRadiance + moonRadiance, SPECULAR_STRENGTH);
#endif
	}
#endif
#endif

float emissiveCode = DecodeMaterialCode(matCode);
if (emissiveCode > 4.5 && emissiveCode < 5.5) {
    float emissiveMask = smoothstep(0.65, 0.95,
                          max(albedo.r, max(albedo.g, albedo.b)));
    lit += albedo * EMISSIVE_STRENGTH * emissiveMask;
}

return lit;
}

vec3 glassInternalBounce(vec2 uv, vec3 refrDirView, float amount, float thicknessScale,
                        vec3 lightDirWorld) {
    vec2 baseUV = uv;
    vec2 offset = refrDirView.xy * amount * thicknessScale;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= GLASS_INTERNAL_BOUNCE) break;
        float s = (i % 2 == 0) ? 1.0 : -0.65;
        float k = pow(0.75, float(i));
        vec2 sUV = clampRefractionUV(baseUV + offset * s * k, uv);
        float d = texture(depthtex1, sUV).r;
        if (d >= 0.9999) continue;
        vec3 albedo = texture(colortex0, sUV).rgb;
        vec2 lm = texture(colortex1, sUV).rg;
        vec3 nraw = texture(colortex2, sUV).rgb * 2.0 - 1.0;
        vec3 n = (length(nraw) > 0.01) ? normalize(nraw) : vec3(0.0, 1.0, 0.0);
        vec3 view = projectAndDivide(gbufferProjectionInverse, vec3(sUV, d) * 2.0 - 1.0);
        vec3 feet = (gbufferModelViewInverse * vec4(view, 1.0)).xyz;
        vec3 rawShadow = getSoftShadow(feet, n, lightDirWorld);
        vec3 sh;
        acc += shadeSurface(albedo, lm, n, view, lightDirWorld, rawShadow,
                            1.0, 1.0, vec3(1.0),
                            texture(colortex11, sUV).a, sh) * k;
        wsum += k;
    }
    return (wsum > 0.0) ? acc / wsum : vec3(0.0);
}

vec4 traceScreenSpaceReflectionScaled(vec3 startPos, vec3 rayDir, vec3 lightDirWorld, float stepScale) {
	vec3 rayView = mat3(gbufferModelView) * rayDir;
	if (rayView.z > -1.0e-4) return vec4(0.0);

	vec3 viewPos0 = (gbufferModelView * vec4(startPos, 1.0)).xyz;
	vec3 viewDir0 = mat3(gbufferModelView) * rayDir;

	vec3 sPos = viewToScreenSpace(viewPos0);
	vec3 sEnd = viewToScreenSpace(viewPos0 + viewDir0);
	vec3 screenDir = normalize(sEnd - sPos);

	vec3 denom = max(abs(screenDir), vec3(1.0e-6));
	float rayLen = min(min(abs(sign(screenDir) - sPos).x / denom.x,
	                       abs(sign(screenDir) - sPos).y / denom.y),
	                   abs(sign(screenDir) - sPos).z / denom.z);

	int steps = max(1, int(float(SSR_MAX_STEPS) * PERF_SCALE * clamp(stepScale, 0.25, 2.0) + 0.5));
	float stepLen = rayLen / float(steps);
	vec3 rayStep = screenDir * stepLen;

	float dither = ssrDither(gl_FragCoord.xy + vec2(float(frameCounter) * 3.7));
	vec3 sRay = sPos + rayStep * dither;

	float depthTol = max(abs(rayStep.z) * 3.0, 0.02 / max(viewPos0.z * viewPos0.z, 1.0e-4));

	bool hit = false;
	for (int i = 0; i < steps; i++, sRay += rayStep) {
		if (clamp(sRay, 0.0, 1.0) != sRay) break;
		vec2 huv = sRay.xy;
		float sceneDepth = texture(depthtex1, huv).r;
		if (sceneDepth < sRay.z && abs(depthTol - (sRay.z - sceneDepth)) < depthTol) {
			hit = true;
			break;
		}
	}
	if (!hit) return vec4(0.0);

	for (int i = 0; i < 5; i++) {
		rayStep *= 0.5;
		float sceneDepth = texture(depthtex1, sRay.xy).r;
		if (sceneDepth < sRay.z && abs(depthTol - (sRay.z - sceneDepth)) < depthTol) {
			sRay -= rayStep;
		} else {
			sRay += rayStep;
		}
	}

	vec2 uv = sRay.xy;
	float finalDepth = texture(depthtex1, uv).r;
	if (finalDepth >= 0.9999) return vec4(0.0);

	float edge = 1.0;
	vec2 e = abs(uv * 2.0 - 1.0);
	edge = (1.0 - smoothstep(0.92, 1.0, e.x)) * (1.0 - smoothstep(0.92, 1.0, e.y));
	float hitW = edge;

		vec3 hitAlbedo = texture(colortex11, uv).rgb;
		vec2 hitLm = texture(colortex1, uv).rg;
		vec3 hitN = normalize(texture(colortex2, uv).rgb * 2.0 - 1.0);

		float hitDepthTex = texture(depthtex1, uv).r;
		vec3 hitView = projectAndDivide(gbufferProjectionInverse,
		                                vec3(uv, hitDepthTex) * 2.0 - 1.0);
		vec3 hitFeet = (gbufferModelViewInverse * vec4(hitView, 1.0)).xyz;

		vec3 hitShadow;
		vec3 hitRawShadow = getSoftShadow(hitFeet, hitN, lightDirWorld);
            vec3 hitLit = shadeSurface(hitAlbedo, hitLm, hitN, hitView,
                                       lightDirWorld, hitRawShadow, 1.0,
                                       1.0,
                                       vec3(1.0),
                                       texture(colortex11, uv).a,
                                       hitShadow);
            return vec4(hitLit, hitW);
}

vec4 traceScreenSpaceReflection(vec3 startPos, vec3 rayDir, vec3 lightDirWorld) {
    return traceScreenSpaceReflectionScaled(startPos, rayDir, lightDirWorld, 1.0);
}

vec3 shadeTranslucentBlock(vec2 uv, vec3 glassNormal, vec3 viewPos, vec3 feetPlayerPos,
                           vec3 lightDirWorld, vec3 sunDirWorld,
                           vec2 glassLightmap, vec3 glassTint, float matClass) {
    vec3 viewDirW = normalize(mat3(gbufferModelViewInverse) * viewPos);
    vec3 V = -viewDirW;

    if (dot(glassNormal, V) < 0.0) glassNormal = -glassNormal;

    bool isIce    = (matClass > 0.22 && matClass < 0.38);
    bool isSlime  = (matClass > 0.38 && matClass < 0.52);
    bool isHoney  = (matClass > 0.52 && matClass < 0.70);
    float ior = isIce ? 1.31 : ((isSlime || isHoney) ? 1.48 : 1.52);

    vec3 iceReflNormal = glassNormal;
    if (isIce) {
        iceReflNormal = perturbIceNormal(glassNormal, feetPlayerPos + cameraPosition);
    }

    float NoV = clamp(dot(glassNormal, V), 0.0, 1.0);
    float viewDist = max(length(viewPos), 1.0);
    float daylight = computeDaylight();
    float glassDepthAtUv = texture(depthtex1, uv).r;

    vec3 nView = mat3(gbufferModelView) * glassNormal;
    nView.y = -nView.y;
    float distFade = 1.0 / (1.0 + pow(viewDist * 0.15, 0.8));
    float refractAmount = GLASS_REFRACT * distFade;
    vec2 uvG = clampRefractionUV(uv - nView.xy * refractAmount, uv);

    float refrDepth = texture(depthtex1, uvG).r;
    float glassDepth0 = texture(depthtex0, uv).r;
    if (refrDepth < glassDepth0) {
        uvG = clampRefractionUV(uv, uv);
        refrDepth = texture(depthtex1, uvG).r;
    }

    vec3 refrAlbedo = texture(colortex0, uvG).rgb;
    if (GLASS_DISPERSION > 0.0) {
        vec2 disp = clamp(nView.xy, -0.2, 0.2) / 0.2 * GLASS_DISPERSION * 0.035;
        vec2 uvR = clampRefractionUV(uv - (nView.xy + disp) * refractAmount, uv);
        vec2 uvB = clampRefractionUV(uv - (nView.xy - disp) * refractAmount, uv);
        refrAlbedo.r = texture(colortex0, uvR).r;
        refrAlbedo.b = texture(colortex0, uvB).b;
    }

    vec3 refrLit;
    if (refrDepth >= 0.9999) {
        refrLit = refrAlbedo;
    } else {
        vec2 refrLm = texture(colortex1, uvG).rg;
        vec3 refrNraw = texture(colortex2, uvG).rgb * 2.0 - 1.0;
        vec3 refrN = (length(refrNraw) > 0.01) ? normalize(refrNraw) : vec3(0.0, 1.0, 0.0);
        vec3 refrView = projectAndDivide(gbufferProjectionInverse,
                                         vec3(uvG, refrDepth) * 2.0 - 1.0);
        vec3 refrFeet = (gbufferModelViewInverse * vec4(refrView, 1.0)).xyz;
        vec3 refrRawShadow = getSoftShadow(refrFeet, refrN, lightDirWorld);
        vec3 refrShadow;
        refrLit = shadeSurface(refrAlbedo, refrLm, refrN, refrView,
                               lightDirWorld, refrRawShadow,
                               1.0,
                               1.0,
                               vec3(1.0),
                               texture(colortex11, uvG).a,
                               refrShadow);
    }

    vec3 sigmaA;
    vec3 sigmaS = vec3(0.0);
    float thickness;
    if (isIce) {
        const vec3 ICE_SIGMA_A = vec3(0.35, 0.10, 0.035);
        const float ICE_SIGMA_GAIN = 6.0;
        sigmaA = ICE_SIGMA_A * ICE_SIGMA_GAIN * GLASS_ABSORPTION;
        sigmaS = vec3(0.35, 0.55, 0.75) * GLASS_SCATTER;
        thickness = max(GLASS_THICKNESS * 32.0, 1.5);
    } else {
        vec3 tint = clamp(glassTint, vec3(0.03), vec3(1.0));
        const float GLASS_TINT_DEPTH = 0.0625;
        sigmaA = (-log(tint) / GLASS_TINT_DEPTH + vec3(0.02)) * GLASS_ABSORPTION;
        thickness = max(GLASS_THICKNESS, 0.01);
    }
    vec3 sigmaT = medSigmaT(sigmaA, sigmaS);
    vec3 transmit = medTransmittance(sigmaT, thickness);
    vec3 glassBody = refrLit * transmit;

    if (GLASS_INTERNAL_BOUNCE > 0) {
        float bounceScale = isIce ? 2.0 : 1.0;
        vec3 inner = glassInternalBounce(uv, nView, refractAmount, bounceScale, lightDirWorld);
        float transmitLum = dot(transmit, vec3(0.2126, 0.7152, 0.0722));
        float innerAmt = clamp((1.0 - transmitLum) * 0.6, 0.0, 0.75);
        glassBody = mix(glassBody, inner, innerAmt);
    }

    if (isIce) {
        float lmSky = clamp(glassLightmap.g, 0.0, 1.0);
        float lmBlock = clamp(glassLightmap.r, 0.0, 1.0);
        float localLight = clamp(max(lmSky, lmBlock), 0.0, 1.0);
        if (glassDepthAtUv >= 0.9999) {
            localLight = 1.0;
        }
        float iceShadow = 0.0;
        if (daylight > 0.001) {
            vec3 iceRawShadow = getSoftShadow(feetPlayerPos, glassNormal, lightDirWorld);
            iceShadow = clamp(iceRawShadow.x, 0.0, 1.0);
        }
        vec3 iceAmbient = medAmbient(daylight) * vec3(1.25, 1.0, 1.0);
        float ambientScale = 0.25 + 0.75 * clamp(daylight, 0.0, 1.0);
        vec3 iceLight = iceAmbient * (0.25 + 1.75 * localLight) * 2.0 * ambientScale
                      + sunLightColor() * medSunTintAt(lightDirWorld)
                        * max(lightDirWorld.y, 0.0) * daylight * 0.35 * iceShadow;
        vec3 inScatter = medInScatter(sigmaT, sigmaS, thickness) * iceLight;
        glassBody += inScatter * 0.7 * (0.85 + 0.15 * (1.0 - NoV));
    }

    vec3 reflDir = reflect(viewDirW, iceReflNormal);
    float skyGate = smoothstep(-0.08, 0.02, reflDir.y);
    vec3 skyRefl = vec3(0.0);
    if (skyGate > 0.001) {
        vec3 skyDir = normalize(vec3(reflDir.x, max(reflDir.y, 0.002), reflDir.z));
        vec2 skyUV = SkyLUTUV(skyDir, sunDirWorld, ATM_PLANET_R, AtmosphereCameraAltitude());
        skyRefl = texture(usam_skylut, skyUV).rgb;
#if GLASS_SUN_DISC == 1
        vec3 disc = medCelestialDiscs(skyDir, sunDirWorld, daylight);
        skyRefl += min(disc, vec3(4.0));
#endif
        skyRefl *= skyGate;
    }

    float glassSky = 1.0;
    if (glassDepthAtUv < 0.9999) {
        glassSky = clamp(texture(colortex1, uv).g, 0.0, 1.0);
    }
    skyRefl *= mix(0.05, 1.0, glassSky);

    float F = clamp(medFresnelDielectricN(NoV, ior) * GLASS_REFLECT, 0.0, 1.0);

    vec3 reflection = skyRefl;
#if GLASS_SSR == 1
    {
        vec3 ssrStart = feetPlayerPos - viewDirW * 0.05;
        vec4 ssr = traceScreenSpaceReflectionScaled(ssrStart, normalize(reflDir), lightDirWorld,
                                                    0.5 + 0.5 * F);
        if (ssr.a > 0.0) reflection = mix(skyRefl, ssr.rgb, clamp(ssr.a, 0.0, 1.0));
    }
#endif

    return mix(glassBody, reflection, F);
}

#include "/lib/water/surface.glsl"

vec3 WtrScreenWaterTint() {
    if (WTR_BIOME_TINT <= 0.0) return vec3(1.0);
    vec3 sum = vec3(0.0);
    float count = 0.0;
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            vec2 uv = (vec2(float(x), float(y)) + 0.5) * 0.25;
            vec4 s = texture(colortex10, uv);
            float valid = step(0.4, s.a);
            sum += s.rgb * valid;
            count += valid;
        }
    }
    vec3 tint = (count > 0.5) ? sum / count : vec3(1.0);
    return mix(vec3(1.0), clamp(tint, 0.0, 1.0),
               clamp(WTR_BIOME_TINT, 0.0, 1.0));
}

vec3 localFogKeyLightRadiance() {
    vec3 activeDir = SceneActiveLightDirW();
    float earthShadow = 1.0;
    vec3 atmTint = transportSunTint(AtmosphereCameraPosition(), activeDir, earthShadow);

    if (SceneActiveIsSun()) {
        vec3 sunDirW = SceneSunDirW();
        return SUN_IRRADIANCE * sunLightColor() * atmTint
             * CelestialSunUp(sunDirW) * earthShadow;
    }

    vec3 moonDirW = SceneMoonDirW();
    float moonArt = 1.0;
#if MOON_LIGHT_PHYSICAL == 0
    moonArt = MOON_ART_GAIN;
#endif
    vec3 moonEclipse = MoonEclipseTint(SceneSunDirW(), moonDirW, moonPhase, worldDay);
    return moonLightColor() * moonlightIntensity * SceneMoonExposure()
         * moonEclipse * CelestialMoonUp(moonDirW) * moonArt
         * atmTint * earthShadow;
}

vec3 localFogAmbientRadiance() {
    float eyeSky = clamp(eyeBrightnessSmooth.y / 240.0, 0.0, 1.0);
    vec3 skyAmbient = max(ambientUpIrradiance(), vec3(0.0)) / PI
                    * mix(0.25, 1.0, eyeSky);
    vec3 floorAmbient = ambientColor * mix(0.15, 1.0, eyeSky);
    vec3 ambient = max(skyAmbient, floorAmbient);

#if VL_BLOCK_FOG == 1
    float eyeBlock = clamp(eyeBrightnessSmooth.x / 240.0, 0.0, 1.0);
    vec3 blockLightCol = fireLightColor() * (eyeBlock * eyeBlock);
    ambient += blockLightCol * VL_BLOCK_FOG_GAIN;
#endif

    return ambient;
}

vec3 localFogApplyAtPixel(vec3 col, vec3 rayDirWorld, float rayEndDist) {
    if (isEyeInWater == 1) return col;
    if (FOG_DENSITY <= 0.0) return col;

    float dirLen = length(rayDirWorld);
    if (dirLen < 1.0e-6) return col;
    vec3 fogDir = rayDirWorld / dirLen;

    float slabT0, slabT1;
    if (!LocalFogVolumeInterval(vec3(0.0), fogDir, rainStrength, slabT0, slabT1)) return col;
    float slabEnd = min(slabT1, min(max(rayEndDist, 0.0), slabT0 + FOG_MAX_RAY));
    if (slabEnd - slabT0 < 1.0e-3) return col;

    return LocalFogApply(col, vec3(0.0), fogDir, rayEndDist,
                         SceneActiveLightDirW(), localFogKeyLightRadiance(),
                         localFogAmbientRadiance(), frameTimeCounter,
                         rainStrength, LocalFogTimeOfDay(),
                         gl_FragCoord.xy, frameCounter);
}

#if VL_POINT_LIGHT == 1
vec3 localFogPointLightScatter(vec3 rayDirWorld, float rayEndDist) {
    if (isEyeInWater == 1) return vec3(0.0);
    if (FOG_DENSITY <= 0.0) return vec3(0.0);

    vec3 d = normalize(rayDirWorld);
    float fogT0, fogT1;
    if (!LocalFogVolumeInterval(vec3(0.0), d, rainStrength, fogT0, fogT1)) {
        return vec3(0.0);
    }
    if (fogT0 > 0.25) return vec3(0.0);
    rayEndDist = min(rayEndDist, fogT1);
    if (rayEndDist <= 0.0) return vec3(0.0);

    vec3 camRight   = normalize(mat3(gbufferModelViewInverse) * vec3(1.0, 0.0, 0.0));
    vec3 camUp      = normalize(mat3(gbufferModelViewInverse) * vec3(0.0, 1.0, 0.0));
    vec3 camForward = normalize(mat3(gbufferModelViewInverse) * vec3(0.0, 0.0, -1.0));

    vec3 mainHand = cameraPosition + camRight * 0.30
                  - camUp * 0.24 + camForward * 0.55;
    vec3 offHand  = cameraPosition - camRight * 0.30
                  - camUp * 0.24 + camForward * 0.55;

    float sigmaS = VL_POINT_SIGMA * clamp(FOG_DENSITY, 0.0, 3.0);
    vec3 heldColor = fireLightColor() * VL_POINT_GAIN;
    vec3 acc = vec3(0.0);

    float mainLevel = clamp(float(heldBlockLightValue) / 15.0, 0.0, 1.0);
    if (mainLevel > 0.0) {
        acc += PointLightAnalyticScatter(cameraPosition, d, rayEndDist,
                                         mainHand,
                                         heldColor * (mainLevel * mainLevel),
                                         sigmaS);
    }
    float offLevel = clamp(float(heldBlockLightValue2) / 15.0, 0.0, 1.0);
    if (offLevel > 0.0) {
        acc += PointLightAnalyticScatter(cameraPosition, d, rayEndDist,
                                         offHand,
                                         heldColor * (offLevel * offLevel),
                                         sigmaS);
    }
    return acc;
}
#endif

#if VL_FLASH == 1
vec3 localFogFlashScatter(vec3 rayDirWorld, float rayEndDist) {
    if (isEyeInWater == 1) return vec3(0.0);
    if (FOG_DENSITY <= 0.0) return vec3(0.0);

    vec3 d = normalize(rayDirWorld);
    float fogT0, fogT1;
    if (!LocalFogVolumeInterval(vec3(0.0), d, rainStrength, fogT0, fogT1)) {
        return vec3(0.0);
    }
    if (fogT0 > 0.25) return vec3(0.0);
    rayEndDist = min(rayEndDist, fogT1);
    if (rayEndDist <= 0.0) return vec3(0.0);

    float sigmaS = VL_POINT_SIGMA * clamp(FOG_DENSITY, 0.0, 3.0);
    vec3 acc = VolumetricFlashEventsScatter(cameraPosition, d, rayEndDist,
                                            frameTimeCounter, sigmaS);
    acc += VolumetricFlashEventsGlow(cameraPosition, frameTimeCounter);
    acc += VolumetricLightningPointScatter(cameraPosition, d, rayEndDist,
                                           lightningBoltPosition, sigmaS);
    return acc;
}
#endif

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;

	if (depth == 1.0) {
		vec3 skView = normalize(projectAndDivide(gbufferProjectionInverse,
			vec3(texcoord.xy, 1.0) * 2.0 - 1.0));
		vec3 skViewDir = normalize(mat3(gbufferModelViewInverse) * skView);
		vec3 skSunDir = normalize(mat3(gbufferModelViewInverse) *
			normalize(shadowLightPosition));

#if ENABLE_LOCAL_FOG == 1
		color.rgb = localFogApplyAtPixel(color.rgb, skViewDir, far);
#if VL_POINT_LIGHT == 1
		color.rgb += localFogPointLightScatter(skViewDir, far);
#endif
#if VL_FLASH == 1
		color.rgb += localFogFlashScatter(skViewDir, far);
#endif
#endif
		if (WTR_ENABLED == 1 && isEyeInWater == 1) {
			color.rgb = WtrUnderwaterScreen(color.rgb, far, true, far, vec3(1.0));
			color.rgb += WtrUnderwaterShafts(texcoord, SceneSunDirW(), 16.0);
		}
		return;
	}

	vec3 sceneAlbedo = texture(colortex0, texcoord).rgb;
	vec2 lightmap = texture(colortex1, texcoord).rg;
	vec4 encoded = texture(colortex2, texcoord);
	vec3 normal = normalize((encoded.rgb - 0.5) * 2.0);
float isThinGeo = step(0.5, encoded.a);

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	vec3 lightDirWorld = SceneActiveLightDirW();
	vec3 sunDirWorld = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));

	vec4 translucentData = texture(colortex9, texcoord);
	vec4 surfaceTintData = texture(colortex10, texcoord);
	bool isWaterPixel = (WTR_ENABLED == 1) && (translucentData.a > 0.5);
	bool isGlassPixel = (GLASS_ENABLED == 1)
	                 && (translucentData.a <= 0.5)
	                 && (surfaceTintData.a > 0.05) && (surfaceTintData.a < 0.75);

		if (isWaterPixel) {
			vec3 waterNormalRaw = translucentData.rgb * 2.0 - 1.0;
			vec3 waterNormal = (length(waterNormalRaw) > 0.01)
			                 ? normalize(waterNormalRaw) : vec3(0.0, 1.0, 0.0);
			vec3 viewDirW = normalize(mat3(gbufferModelViewInverse) * viewPos);
			vec3 VtoCamera = -viewDirW;
			bool underwater = (isEyeInWater == 1);

			vec3 bottomLit;
			float pathLen;
			vec3 skyRefl;

			if (underwater) {
				vec3 incidentToSurfaceW = -VtoCamera;
				vec3 transmittedW = refract(incidentToSurfaceW, waterNormal, 1.33);
				vec3 skyThrough = vec3(0.0);
				if (dot(transmittedW, transmittedW) > 1.0e-6) {
					vec3 transmittedDirW = normalize(transmittedW);
					vec3 skyDirW = normalize(vec3(transmittedDirW.x,
					                              max(transmittedDirW.y, 0.003),
					                              transmittedDirW.z));
					skyThrough = WtrSkyRadiance(skyDirW, sunDirWorld);

					vec3 traceStart = feetPlayerPos + transmittedDirW * 0.08;
					vec4 transmittedScene = traceScreenSpaceReflectionScaled(
						traceStart, transmittedDirW, lightDirWorld, 0.85);
					if (transmittedScene.a > 0.0) {
skyThrough = mix(skyThrough, transmittedScene.rgb,
                 clamp(transmittedScene.a, 0.0, 1.0));
}

#if WTR_UNDERWATER_SUN == 1
vec3 sunDirN = normalize(sunDirWorld);
float cosSun = clamp(dot(transmittedDirW, sunDirN), -1.0, 1.0);
float sunDiscRadius = 0.00465116 * CELESTIAL_ANGULAR_SCALE * 2.0;
float sunDisc = smoothstep(cos(sunDiscRadius),
                           cos(sunDiscRadius * 0.82), cosSun);
float sunAng = acos(cosSun);
float halo = exp(-sunAng * 30.0) * 0.65
           + exp(-sunAng * 7.0) * 0.10;
vec3 sunTint = min(SUN_IRRADIANCE * sunLightColor()
                 * medSunTintAt(sunDirWorld)
                 * CelestialSunUp(sunDirWorld), vec3(20.0));
skyThrough += sunTint * (sunDisc * 0.90 + halo * 0.20)
            * smoothstep(-0.02, 0.06, sunDirWorld.y);
#endif
}
bottomLit = skyThrough;
				pathLen = 0.0;

				vec3 bgAtten = exp(-WtrSigmaA() * 15.0) * 2.0;
				skyRefl = medAmbient(computeDaylight()) * bgAtten;

				if (WTR_SSR == 1) {
					vec3 reflectedDirW = reflect(viewDirW, waterNormal);
					vec3 ssrStart = feetPlayerPos + reflectedDirW * 0.08;
					vec4 ssr = traceScreenSpaceReflectionScaled(ssrStart,
					                                            normalize(reflectedDirW),
					                                            lightDirWorld, 1.0);
					if (ssr.a > 0.0) {
						vec3 reflectedScene = ssr.rgb * bgAtten;
						skyRefl = mix(skyRefl, reflectedScene, clamp(ssr.a, 0.0, 1.0));
					}
				}
			} else {
				float viewDist = max(length(viewPos), 1.0);
				float surfaceDepth = texture(depthtex0, texcoord).r;
				float opaqueDepth = texture(depthtex1, texcoord).r;
				float surfaceLinear = WtrLinearDepth(surfaceDepth, near, far);
				float opaqueLinear = WtrLinearDepth(opaqueDepth, near, far);
				vec2 refrUV = WtrRefractionUV(texcoord, waterNormal, VtoCamera, viewDist,
				                              false, depthtex1, depthtex0);
				float refrDepth = texture(depthtex1, refrUV).r;

				if (refrDepth >= 0.9999) {
					bottomLit = texture(colortex0, refrUV).rgb;
					pathLen = 1.0;
				} else {
					vec3 bottomAlbedo = texture(colortex0, refrUV).rgb;
					if (WTR_DISPERSION > 0.0) {
						vec3 nView = mat3(gbufferModelView) * waterNormal;
						vec2 dispDir = clamp(nView.xy, -0.2, 0.2) / 0.2;
						float dispAmt = WTR_DISPERSION * 0.0015;
						vec2 uvR = clamp(refrUV + dispDir * dispAmt, vec2(0.001), vec2(0.999));
						vec2 uvB = clamp(refrUV - dispDir * dispAmt, vec2(0.001), vec2(0.999));
						bottomAlbedo.r = texture(colortex0, uvR).r;
						bottomAlbedo.b = texture(colortex0, uvB).b;
					}
					vec2 bottomLm = texture(colortex1, refrUV).rg;
					vec3 bottomNraw = texture(colortex2, refrUV).rgb * 2.0 - 1.0;
					vec3 bottomN = (length(bottomNraw) > 0.01)
					             ? normalize(bottomNraw) : vec3(0.0, 1.0, 0.0);
					vec3 bottomView = projectAndDivide(gbufferProjectionInverse,
					                                   vec3(refrUV, refrDepth) * 2.0 - 1.0);
					vec3 bottomFeet = (gbufferModelViewInverse * vec4(bottomView, 1.0)).xyz;
					vec3 rawShadow = getSoftShadow(bottomFeet, bottomN, lightDirWorld);

					float depthBelow = max((cameraPosition.y + feetPlayerPos.y)
					                     - (cameraPosition.y + bottomFeet.y), 0.0);
					vec3 causticMul = WtrCausticFactor(bottomFeet + cameraPosition,
					                                   sunDirWorld, depthBelow,
					                                   frameTimeCounter, viewDist);

					vec3 unusedShadow;
					bottomLit = shadeSurface(bottomAlbedo, bottomLm, bottomN, bottomView,
					                         lightDirWorld, rawShadow, 1.0, 1.0,
					                         causticMul,
					                         texture(colortex11, refrUV).a, unusedShadow);

					float rayScale = viewDist / max(-viewPos.z, 0.05);
					pathLen = max(opaqueLinear - surfaceLinear, 0.0) * rayScale;
				}

				vec3 R = reflect(viewDirW, waterNormal);
				vec3 Rfallback = normalize(vec3(R.x, max(R.y, 0.003), R.z));
				vec3 skyAtHorizon = WtrSkyRadiance(Rfallback, sunDirWorld);
				float skyGate = smoothstep(-0.16, 0.035, R.y);
				skyRefl = mix(skyAtHorizon * 0.42, skyAtHorizon, skyGate);

				if (WTR_SSR == 1) {
					vec3 ssrStart = feetPlayerPos + normalize(R) * 0.06;
					vec4 ssr = traceScreenSpaceReflectionScaled(ssrStart,
					                                            normalize(R),
					                                            lightDirWorld, 1.0);
					if (ssr.a > 0.0) {
						skyRefl = mix(skyRefl, ssr.rgb, clamp(ssr.a, 0.0, 1.0));
					}
				}

				float waterShadow = 1.0;
				if (WTR_GLINT_STRENGTH > 0.0) {
					waterShadow = clamp(getSoftShadow(feetPlayerPos,
					                                  vec3(0.0, 1.0, 0.0),
					                                  lightDirWorld).x, 0.0, 1.0);
				}

				if (WTR_GLINT_STRENGTH > 0.0) {
					float glint = WtrSunGlint(waterNormal, VtoCamera, sunDirWorld,
					                          WTR_GLINT_ROUGHNESS);
					vec3 sunGlint = SUN_IRRADIANCE * sunLightColor()
					              * medSunTintAt(sunDirWorld)
					              * CelestialSunUp(sunDirWorld)
					              * glint * WTR_GLINT_STRENGTH * waterShadow;
					skyRefl += min(sunGlint, vec3(8.0));
				}

			}

			color.rgb = WtrShadeSurface(waterNormal, VtoCamera, bottomLit,
			                            skyRefl, pathLen, surfaceTintData,
			                            underwater);
		} else if (isGlassPixel) {
		vec3 glassNormalRaw = translucentData.rgb * 2.0 - 1.0;
		vec3 glassNormal = (length(glassNormalRaw) > 0.01)
		                 ? normalize(glassNormalRaw) : vec3(0.0, 1.0, 0.0);
		color.rgb = shadeTranslucentBlock(texcoord, glassNormal, viewPos, feetPlayerPos,
		                                  lightDirWorld, sunDirWorld,
		                                  lightmap, surfaceTintData.rgb, surfaceTintData.a);
	} else {
		vec3 rawShadow = getSoftShadowSSS(feetPlayerPos, normal, lightDirWorld,
		                                  isThinGeo * float(SHADOW_SSS));

          float aoVis = 1.0;
          #if AO_TYPE != 0
            vec3 aoWorldNormal = texture(colortex2, texcoord).rgb * 2.0 - 1.0;
            float aoDepth = texture(depthtex0, texcoord).r;
            vec3 aoBentView;
            aoVis = aoApply(texcoord, aoDepth, aoWorldNormal,
                            AO_STRENGTH, AO_RADIUS, AO_TYPE,
                            isThinGeo, aoBentView);
          #endif

          vec3 effShadow = rawShadow;
          #if CONTACT_SHADOW == 1
            vec3 lightDirView = normalize(mat3(gbufferModelView) * lightDirWorld);
            float cs = aoContactShadow(vec3(texcoord, depth), viewPos,
                                       lightDirView, isThinGeo, length(viewPos));
            effShadow *= mix(1.0, cs, 0.5);
          #endif

          vec3 causticMul = vec3(1.0);
          if (WTR_ENABLED == 1 && WTR_CAUSTICS == 1 && isEyeInWater == 1) {
              float worldAbsY = cameraPosition.y + feetPlayerPos.y;
              float waterSurfaceY = waterEnteredAltitude;
              if (abs(waterSurfaceY - cameraPosition.y) > 64.0) {
                  waterSurfaceY = waterEnteredPosition.y;
              }
              if (abs(waterSurfaceY - cameraPosition.y) > 64.0) {
                  waterSurfaceY = cameraPosition.y + 1.0;
              }
              float depthBelow = max(waterSurfaceY - worldAbsY, 0.0);
              causticMul = WtrCausticFactor(feetPlayerPos + cameraPosition,
                                            sunDirWorld, depthBelow,
                                            frameTimeCounter,
                                            max(length(viewPos), 1.0));
          }

          vec3 surfaceShadow;
          color.rgb = shadeSurface(sceneAlbedo, lightmap, normal, viewPos,
                                   lightDirWorld, effShadow,
                                   1.0,
                                   aoVis,
                                   causticMul,
                                    texture(colortex11, texcoord).a,
                                   surfaceShadow);
	}

#if ENABLE_LOCAL_FOG == 1
	{
		vec3 localFogDir = (length(feetPlayerPos) > 1.0e-4)
		                  ? normalize(feetPlayerPos) : vec3(0.0, 0.0, -1.0);
		color.rgb = localFogApplyAtPixel(color.rgb, localFogDir, length(feetPlayerPos));
#if VL_POINT_LIGHT == 1
		color.rgb += localFogPointLightScatter(localFogDir, length(feetPlayerPos));
#endif
#if VL_FLASH == 1
		color.rgb += localFogFlashScatter(localFogDir, length(feetPlayerPos));
#endif
	}
#endif
	float daylight = computeDaylight();

#if ATM_AP_LUT == 1
{
        float apDistKm = length(feetPlayerPos) * ATM_M_TO_KM;
        float apNearKm = max(near * ATM_M_TO_KM, 1.0e-4);
        float apFarKm  = max(far  * ATM_M_TO_KM, apNearKm * 1.001);
        vec4 ap = atmSampleAerialPerspective(texcoord, apDistKm, apNearKm, apFarKm);
        float apT = (ap.a > 0.0) ? clamp(ap.a, 0.0, 1.0) : 1.0;
        color.rgb = color.rgb * apT + ap.rgb * ATM_AP_STRENGTH;
}
#else
#if ENABLE_EDGE_FOG == 1
        vec3 fogViewDir = normalize(feetPlayerPos);
        float fogDist = length(viewPos);
        float fogN = fogDist / max(far, 1.0);
        float fogAmt = 1.0 - exp2(-EDGE_FOG_STRENGTH * 8.0 * pow(max(fogN, 0.0), 8.0));
        fogAmt *= 1.0 - 0.75 * clamp(fogViewDir.y * 5.0, 0.0, 1.0);
        if (fogAmt > 0.001) {
                vec3 horizV = vec3(fogViewDir.x, 0.0, fogViewDir.z);
                float hl = length(horizV);
                vec3 horizW = (hl > 1.0e-4) ? horizV / hl : vec3(1.0, 0.0, 0.0);
                vec2 horizonUV = SkyLUTUV(horizW, sunDirWorld, ATM_PLANET_R, AtmosphereCameraAltitude());
                vec3 horizonCol = texture(usam_skylut, horizonUV).rgb;
                color.rgb = mix(color.rgb, horizonCol, fogAmt);
        }
#endif

#if ENABLE_LOCAL_FOG == 0 && ATM_EXP_FOG == 1
        vec3 fogDir = (length(feetPlayerPos) > 1.0e-4) ? normalize(feetPlayerPos) : vec3(0.0, 1.0, 0.0);
        float fogRayLenKm = length(feetPlayerPos) * ATM_M_TO_KM;
        float fogCamH = AtmosphereCameraAltitude();
        float fogWorldH = (cameraPosition.y + feetPlayerPos.y - ATM_SEA_LEVEL) * ATM_M_TO_KM;
        float fogLdotV = dot(fogDir, sunDirWorld);
        vec3 fogSun = sunLightColor() * daylight;
        vec3 fogAmb = ambientColor;
        vec3 fogBefore = color.rgb;
        vec3 fogWork = fogBefore;
        atmExponentialHeightFog(fogSun, fogAmb, fogRayLenKm, fogCamH, fogWorldH, fogLdotV, fogWork);
        color.rgb = mix(fogBefore, fogWork, clamp(ATM_EXP_FOG_STRENGTH, 0.0, 1.0));
#endif
#endif

	if (WTR_ENABLED == 1 && isEyeInWater == 1) {
		color.rgb = WtrUnderwaterScreen(color.rgb, length(viewPos), false, far,
								        WtrScreenWaterTint());
		color.rgb += WtrUnderwaterShafts(texcoord, sunDirWorld, length(viewPos));
	}

}
