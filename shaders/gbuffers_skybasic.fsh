#version 330 compatibility

/* RENDERTARGETS: 0 */
// Star map data: NASA SVS #4851 "Deep Star Maps 2020" (public domain).


#include "/lib/options_defaults.glsl"

#include "/lib/atmosphere/core.glsl"
#include "/lib/atmosphere/sky_lut.glsl"
#include "/lib/atmosphere/medium_rgb.glsl"
#include "/lib/atmosphere/refraction.glsl"
uniform sampler2D lunar_moon;
uniform sampler2D starmap;

uniform int renderStage;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform int worldTime;
#define CELESTIAL_HAS_WORLD_TIME 1
uniform int worldDay;
uniform float biome_may_snow;
uniform int moonPhase;
uniform float frameTimeCounter;

#include "/lib/atmosphere/night_sky.glsl"
#include "/lib/atmosphere/sun_disk.glsl"
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunPosition;
uniform float sunAngle;

#include "/lib/stars.glsl"
#include "/lib/galaxy.glsl"
#include "/lib/blackbody.glsl"
#include "/lib/celestial.glsl"
#include "/lib/celestial/daylight.glsl"
#include "/lib/celestial/eclipse.glsl"
#include "/lib/meteors.glsl"
#include "/lib/comets.glsl"
#include "/lib/sky/aurora.glsl"
#include "/lib/atmosphere/adaptive_sky_gain.glsl"
#include "/lib/sky/cirrus.glsl"

const float ATM_SUN_DISC_RADIUS  = 0.00465116 * CELESTIAL_ANGULAR_SCALE;
const float ATM_SUN_GLOW_RADIUS  = 0.00465116 * CELESTIAL_ANGULAR_SCALE;
const float ATM_MOON_DISC_RADIUS = 0.00452017 * CELESTIAL_ANGULAR_SCALE;
const float ATM_MOON_GLOW_RADIUS = 0.00452017 * CELESTIAL_ANGULAR_SCALE;

in vec4 glcolor;

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz);
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

vec3 softClipSky(vec3 c, vec3 worldDir, vec3 sunDirW, vec3 moonDirW) {
        float nearSun  = smoothstep(0.90, 0.995, dot(worldDir, sunDirW));
        float nearMoon = smoothstep(0.90, 0.995, dot(worldDir, moonDirW));
        float amt = clamp(max(nearSun, nearMoon), 0.0, 1.0);
        vec3 peak = ATM_SKY_PEAK * (1.0 - exp(-c / ATM_SKY_PEAK));
        return mix(c, peak, max(amt, 0.65));
}

vec3 cinematicSkyGrade(vec3 sky, vec3 worldDir, vec3 sunDirW) {
        float sunEl = sunDirW.y;
        float dayish = smoothstep(-0.12, 0.12, sunEl);
        float twilight = 1.0 - smoothstep(0.04, 0.35, abs(sunEl));
        float twilightLow = smoothstep(-0.25, -0.02, sunEl)
                          * (1.0 - smoothstep(0.05, 0.20, sunEl));

        float cosAng = clamp(dot(worldDir, sunDirW), -1.0, 1.0);
        float nearSun = smoothstep(0.80, 0.98, cosAng);
        float farSun  = 1.0 - smoothstep(-0.75, -0.45, cosAng);
        float beltAzimuth = mix(0.80, 1.0, farSun);

        float camAltH = AtmosphereCameraAltitude();
        float camRH = ATM_PLANET_R + max(camAltH, 0.0);
        float vHH = sqrt(max(camRH * camRH - ATM_PLANET_R * ATM_PLANET_R, 0.0));
        float horizonCos = -vHH / max(camRH, 1.0e-3);
        float el = worldDir.y - horizonCos;

        vec3 c = sky;
        float lum = dot(c, vec3(0.299, 0.587, 0.114));

        float cool = ATM_CINE_BLUE * dayish * smoothstep(0.0, 0.5, el)
                   * (1.0 - nearSun * 0.85);
        c = mix(vec3(lum), c, mix(1.0, ATM_CINE_SAT, cool));
        c *= mix(vec3(1.0), vec3(0.94, 1.0, 1.10), cool);

        float warmBand = nearSun * (1.0 - smoothstep(0.0, 0.22, el))
                       * twilightLow * ATM_CINE_SUNSET;
        c = mix(c, c * vec3(1.16, 0.88, 0.66) + vec3(0.018, 0.006, 0.0),
                warmBand * 0.60);

        float softViolet = nearSun * exp(-pow((el - 0.105) / 0.060, 2.0)) * twilightLow;
        c = mix(c, c * vec3(1.05, 0.86, 1.00) + vec3(0.008, 0.002, 0.006), softViolet * 0.35);

        float earthBand = exp(-pow((el - 0.035) / 0.035, 2.0));
        float earthAmt = mix(0.15, 1.0, farSun) * earthBand * twilightLow * ATM_CINE_SHADOW;
        vec3 earthCol = max(lum, 1.0e-4) * vec3(0.30, 0.43, 0.72)
                      + vec3(0.002, 0.003, 0.008);
        c = mix(c, earthCol, earthAmt * 0.70);

        float venusBand = exp(-pow((el - 0.14) / 0.075, 2.0));
        float venusAmt = beltAzimuth * venusBand * twilightLow;
        vec3 venusCol = max(lum, 1.0e-4) * vec3(1.18, 0.62, 0.82)
                      + vec3(0.018, 0.003, 0.010);
        c = mix(c, venusCol, venusAmt * 0.70);

        float violetAlt = smoothstep(0.18, 0.32, el)
                        * (1.0 - smoothstep(0.45, 0.70, el));
        float violetAmt = beltAzimuth * violetAlt * twilightLow;
        c = mix(c, c * vec3(0.88, 0.90, 1.10) + vec3(0.005, 0.003, 0.012),
                violetAmt * 0.35);

        return c;
}

layout(location = 0) out vec4 color;

void main() {
	if (renderStage == MC_RENDER_STAGE_STARS) {
#if STARS_VANILLA == 1
		color = glcolor;
#else
		discard;
#endif
		return;
	}

	vec3 pos = screenToView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0));
	vec3 vd = normalize(pos);

#if ATM_ENABLE_PHYSICAL == 1
	{
		vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * vd);
		vec3 sunDirW  = normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition));
                vec3 moonDirW = normalize(MoonDirection(sunDirW, moonPhase, worldDay));
                float moonIllum = MoonIllumination(moonPhase);
                vec3 skyDirW = worldDir;
                vec3 skySunW = sunDirW;
                vec3 skyMoonW = moonDirW;

          vec3 skyPhys = atmSampleSkyView(skyDirW, skySunW, ATM_PLANET_R,
                                          AtmosphereCameraAltitude());
          skyPhys = softClipSky(skyPhys, skyDirW, skySunW, skyMoonW);

		float skyDaylight = CelestialDaylight(sunDirW);

		float atmNightF = 1.0 - smoothstep(-0.32, -0.12, sunDirW.y);
		skyPhys *= mix(clamp(NIGHT_SKY_DIM, 0.0, 1.0), 1.0, skyDaylight);
		skyPhys += atmNightSkyBackground(worldDir, atmNightF);
#if DAYLIGHT_LEGACY == 1
		float moonUp = smoothstep(-0.05, 0.06, moonDirW.y);
		float sunUpFade = 1.0 - smoothstep(-0.05, 0.10, sunDirW.y);
		float moonDayDim = 1.0;
#else
		float moonUp = CelestialDiscAboveHorizon(CelestialElevDeg(moonDirW),
		                                         degrees(ATM_MOON_DISC_RADIUS));
		float sunUpFade = 1.0 - skyDaylight;
		float moonDayDim = CelestialMoonDiscDayDim(skyDaylight);
#endif
		float moonVis = moonUp * sunUpFade * moonIllum;
          if (moonVis > 0.001) {
              float cosVM = clamp(dot(worldDir, moonDirW), -1.0, 1.0);
              float moonAirmass = min(1.0 / max(worldDir.y + 0.10, 0.10), 4.0);
              float moonPhaseFn = 0.15 * PhaseMieHG(cosVM, 0.78) + 0.01 * PhaseRayleigh(cosVM);
              vec3 moonT = atmSpectralRatioRGB(atmTransmittanceToSun(AtmosphereCameraPosition(), moonDirW));
              vec3 moonHalo = atmMoonRGB() * ATM_EXPOSURE * moonVis * moonT
                            * atmScatteringCoeffRGB(ATM_PLANET_R) * moonPhaseFn * moonAirmass;
              skyPhys += moonHalo;
          }
          float atmLpOccl = atmLightPollutionStarOcclusion(
              atmLightPollutionAmount(worldDir) * ATM_LP_STRENGTH * atmNightF);

#if ATM_CINE == 1
		skyPhys = cinematicSkyGrade(skyPhys, worldDir, sunDirW);

#endif
        float cloudT = 1.0;
#if CIRRUS_ENABLE == 1
        {
            float skyGain = ATM_SKY_RADIANCE_SCALE * atmAdaptiveSkyRadianceGain(worldTime);
            CirrusOut cr = CirrusComposite(AtmosphereCameraPosition(), worldDir,
                                           skyPhys, sunDirW, moonDirW, skyGain, moonIllum);
            skyPhys = cr.sky;
            cloudT  = cr.T;
        }
#endif

		{
			vec3  camPos = AtmosphereCameraPosition();
			float camR   = length(camPos);

			float hit;
			bool skyVisible = !RayHitPlanet(camPos, worldDir, hit);

			float nightFade = StarsNightFade(sunDirW.y);
                        float spaceVis = smoothstep(15000.0, 60000.0, cameraPosition.y);
                        float celestialFade = max(nightFade, spaceVis);
            vec3 auroraCol = vec3(0.0);
            float auroraWash = 1.0;
#if AURORA_ENABLE == 1
            float auroraChance = AuroraChanceFactor(float(worldDay), biome_may_snow);
            float auroraNight = max(AuroraNightFade(sunDirW), spaceVis);
            float auroraAmount = auroraNight * auroraChance;
            if (skyVisible && auroraAmount > 0.001) {
                auroraCol = AuroraRadiance(worldDir,
                                           AuroraPlanetCameraPosition(),
                                           frameTimeCounter,
                                           float(worldDay),
                                           auroraAmount);
                skyPhys += auroraCol * cloudT;
                float auroraLuma = dot(auroraCol, vec3(0.2126, 0.7152, 0.0722));
                auroraWash = 1.0 / (1.0 + auroraLuma * AURORA_STAR_WASH);
            }
#endif
			float horizonFade = StarsHorizonFade(worldDir.y);
                       float baseStarOccl = MoonStarOcclusion(moonIllum, moonDirW.y) * atmLpOccl;
                       float starOccl = baseStarOccl * auroraWash;
#if MOON_OCCLUDE_GALAXY == 1
			float galaxyOccl = baseStarOccl * auroraWash;
#else
			float galaxyOccl = auroraWash;
#endif
			if (skyVisible && celestialFade > 0.001 && horizonFade > 0.001) {
				float skyFade = celestialFade * horizonFade;
#if ENABLE_STARS == 1
				skyPhys += RenderStars(worldDir, mat3(shadowModelView), frameTimeCounter)
				         * skyFade * starOccl * cloudT;
#endif
#if ENABLE_GALAXY == 1
				skyPhys += RenderGalaxy(starmap, worldDir, float(worldTime), skyFade * galaxyOccl * cloudT);
#endif
			}

			if (skyVisible) {
				vec4 viewTrans = atmTransmittanceToSun(camPos, worldDir);
                          vec4 sunViewTrans  = atmTransmittanceToSun(camPos, sunDirW);
                          vec4 moonViewTrans = atmTransmittanceToSun(camPos, moonDirW);

#if ENABLE_METEORS == 1
				{
					vec3 atmoTrans = SpectralToLinearSRGB(viewTrans * ATM_SOLAR)
					               / max(SpectralToLinearSRGB(ATM_SOLAR), vec3(1.0e-4));
					atmoTrans = clamp(atmoTrans, 0.0, 1.0);

					float mtYearPhase = MeteorYearPhase(float(worldDay));

					float mtRA    = METEOR_RADIANT_RA;
					float mtDec   = METEOR_RADIANT_DEC;
					float mtBoost = 0.0;
#if METEOR_MULTI_SHOWER == 1
					{
						float sRA, sDec, sBoost;
						if (MeteorShowers(mtYearPhase, sRA, sDec, sBoost)) {
							mtRA    = sRA;
							mtDec   = sDec;
							mtBoost = sBoost;
						}
					}
#endif

					float mtRate = METEOR_RATE * (1.0 + (METEOR_SHOWER_BOOST - 1.0) * mtBoost);
					vec3  mtRad  = MeteorWorldDirFromEquatorial(mtRA, mtDec, float(worldTime));

					float mtFade = celestialFade;
					if (mtFade > 0.001) {
						skyPhys += RenderMeteors(worldDir, frameTimeCounter, mtRad,
						                         mtRate, mtBoost, mtFade) * atmoTrans * cloudT;
					}
				}
#endif

#if ENABLE_COMETS == 1
				{
					vec3 atmoTransC = SpectralToLinearSRGB(viewTrans * ATM_SOLAR)
					                / max(SpectralToLinearSRGB(ATM_SOLAR), vec3(1.0e-4));
					atmoTransC = clamp(atmoTransC, 0.0, 1.0);
					if (celestialFade > 0.001) {
						skyPhys += RenderComets(worldDir, frameTimeCounter, sunDirW, celestialFade) * cloudT
						         * atmoTransC;
					}
				}
#endif

                          float cosS = clamp(dot(skyDirW, skySunW), -1.0, 1.0);
#if DAYLIGHT_LEGACY == 1
                          float sunFade = smoothstep(-0.04, 0.06, skySunW.y);
#else
                          float sunFade = CelestialDiscAboveHorizon(CelestialElevDeg(skySunW),
                                                                    degrees(ATM_SUN_DISC_RADIUS));
#endif
                          float cosDisc = cos(ATM_SUN_DISC_RADIUS);
                          if (cosS > cosDisc && sunFade > 0.001) {
                                  vec3 sunIrrad = SpectralToLinearSRGB(sunViewTrans * ATM_SOLAR) * ATM_EXPOSURE;

                                  float centerToEdge = clamp((1.0 - cosS) / max(1.0 - cosDisc, 1.0e-6), 0.0, 1.0);
                                  float mu = sqrt(max(1.0 - centerToEdge * centerToEdge, 0.0));

                                  vec3 sunU = vec3(SUN_LIMB_U_R, SUN_LIMB_U_G, SUN_LIMB_U_B);
                                  vec3 limbLinear = vec3(1.0) - sunU * (1.0 - mu);
                                  vec3 limb = mix(vec3(1.0), limbLinear,
                                                  clamp(SUN_LIMB_DARKENING, 0.0, 1.0));

                                  vec3 sunUpRef = vec3(0.0, 1.0, 0.0);
                                  vec3 tangentRaw = cross(sunDirW, sunUpRef);
                                  float tangentLen = length(tangentRaw);
                                  if (tangentLen < 1.0e-4) {
                                      tangentRaw = vec3(1.0, 0.0, 0.0);
                                      tangentLen = 1.0;
                                  }
                                  vec3 tangentS = tangentRaw / tangentLen;
                                  vec3 bitangentS = cross(sunDirW, tangentS);
                                  vec2 sunLocal = vec2(dot(worldDir, tangentS), dot(worldDir, bitangentS));
                                  vec2 sunUV = sunLocal / ATM_SUN_DISC_RADIUS;
                                  vec3 detail = sunDiskDetail(sunUV, centerToEdge);
                                  if (any(isnan(detail)) || any(isinf(detail))) detail = vec3(1.0);
                                  skyPhys += sunIrrad * ATM_SUN_BRIGHTNESS * sunFade * limb * detail * cloudT;
                          }

				float cosM = clamp(dot(worldDir, moonDirW), -1.0, 1.0);
                          if (cosM > cos(ATM_MOON_DISC_RADIUS) && moonUp > 0.001
                              && !RayHitPlanet(camPos, moonDirW, hit)) {
					vec3 moonN = MoonSurfaceNormalW(worldDir, moonDirW, cosM,
					                                ATM_MOON_DISC_RADIUS);
					vec2 lib = MoonLibration(worldDay);
					vec2 moonUV = MoonPanoramaUV(moonN, moonDirW, lib.x, lib.y);
					vec3 moonAlbedo = textureLod(lunar_moon, moonUV, 0.0).rgb;
					vec3 moonIrrad = SpectralToLinearSRGB(moonViewTrans * ATM_MOON_IRR) * ATM_EXPOSURE;
					vec3 moonCol = moonIrrad * moonDiscTint();

					vec3 moonLight = MoonTerminatorLightDir(sunDirW, moonDirW, moonPhase);
					float diffuse = MoonDiscDiffuse(worldDir, moonDirW, cosM,
                                                                ATM_MOON_DISC_RADIUS, moonLight);

					float moonMu0 = clamp(dot(moonN, normalize(moonLight)), 0.0, 1.0);
					vec3 shade = vec3(diffuse)
					           + MoonEarthshineColor() * (1.0 - smoothstep(0.0, 0.06, moonMu0));

					vec3 moonEclipse = MoonEclipseTint(sunDirW, moonDirW, moonPhase, worldDay);

					skyPhys += moonCol * ATM_MOON_BRIGHTNESS * moonAlbedo
					         * shade * moonEclipse * moonUp * moonDayDim * cloudT;
				}
			}
		}

#if GALAXY_DEBUG == 1
		color = vec4(SampleStarMap(starmap, GalaxyUV(normalize(worldDir), float(worldTime))) * 4.0, 1.0);
		return;
#endif

		color = vec4(skyPhys, 1.0);
	}
#else
	{
		vec3 sky = calcSkyColor(vd);
		color = vec4(sky, 1.0);

		if (sunAngle < 0.5) {
			vec3 sd = normalize(sunPosition);
			float cosAng = clamp(dot(vd, sd), -1.0, 1.0);
			float ang = acos(cosAng);
			float core = smoothstep(0.020, 0.0, ang);
			float halo = exp(-ang * 12.0);
			float outer = exp(-ang * 3.0);
			float glow = core * 0.85 + halo * 0.45 + outer * 0.18;
			color.rgb += vec3(1.0, 0.94, 0.78) * glow;
		}
	}
#endif
}
