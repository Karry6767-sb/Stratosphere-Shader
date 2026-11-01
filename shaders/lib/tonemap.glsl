// AgX by Troy Sobotka (Apache-2.0). ACES RRT+ODT fit by Stephen Hill (2016), TheRealMJP/BakingLab.

#ifndef LIB_TONEMAP_GLSL
#define LIB_TONEMAP_GLSL

const float AGX_INPUT_PIVOT = 0.6060606060606061;
const float AGX_OUTPUT_PIVOT = 0.48943708957387834;
const float AGX_PIVOT_SLOPE = 2.0;
const float AGX_TOE_A = 63.74164317180604;
const float AGX_SHOULDER_A = 63.9174843229821;
const vec3 AGX_NEUTRAL_WEIGHTS = vec3(0.2120053547549465, 0.3921825078090138, 0.3958121374360396);
	const float min_log2 = -12.473931188332412333;
	const float dynamic_range = 16.5;

#ifndef TONEMAP_AGX_GAMUT_COMPRESSION
#define TONEMAP_AGX_GAMUT_COMPRESSION 0.2
#endif

#ifndef TONEMAP_AGX_SHOULDER_POWER
#define TONEMAP_AGX_SHOULDER_POWER 3.25
#endif

#ifndef TONEMAP_AGX_TOE_POWER
#define TONEMAP_AGX_TOE_POWER 3.0
#endif

#ifndef TONEMAP_AGX_GAMMA
#define TONEMAP_AGX_GAMMA 0.9
#endif

#ifndef TONEMAP_AGX_SATURATION
#define TONEMAP_AGX_SATURATION 1.0
#endif

#ifndef TONEMAP_AGX_LOOK
#define TONEMAP_AGX_LOOK 1
#endif

#ifndef TONEMAP_AGX_CONTRAST
#define TONEMAP_AGX_CONTRAST 0.95
#endif

vec3 toneReinhard(vec3 x) { return x / (1.0 + x); }

vec3 toneReinhardJodie(vec3 x) {
	vec3 reinhard = x / (x + 1.0);
	float lum = dot(x, vec3(0.2126, 0.7152, 0.0722));
	return mix(x / (lum + 1.0), reinhard, reinhard);
}

vec3 toneOzius(vec3 x) {
	return 1.0 - exp(-x * (1.37 + 1.43 * exp(-x)));
}

vec3 toneFilmic(vec3 x) {
	vec3 a = x * (x * 0.15 + 0.10) + 0.20;
	vec3 b = x * (x * 0.15 + 0.50) + 0.10;
	return clamp(a / b, 0.0, 1.0);
}

const float AGX_MIN_EV = -7.5;
const float AGX_MAX_EV = 5.5;
const float AGX_MIDDLE_GREY = 0.18;
const vec3 AGX_COMPRESSION = vec3(0.1, 0.1, 0.15);

const mat3 AGX_INSET = mat3(
  0.856627153315983, 0.137318972929847, 0.11189821299995,
  0.0951212405381588, 0.761241990602591, 0.0767994186031903,
  0.0482516061458583, 0.101439036467562, 0.811302368396859
);

const mat3 AGX_INVERSE_OUTSET = mat3(
  1.1271005818144366432, -0.14132976349843826565, -0.14132976349843824772,
  -0.1106066430966032116, 1.1578237022162717623, -0.11060664309660291788,
  -0.016493938717834568157, -0.01649393871783425265, 1.2519364065950402828
);

vec3 agxContrastApprox(vec3 x) {
  vec3 x2 = x * x;
  vec3 x4 = x2 * x2;
  return -17.86 * x4 * x2 * x
         + 78.01 * x4 * x2
         -126.7 * x4 * x
         + 92.06 * x4
         - 28.72 * x2 * x
         + 4.361 * x2
         - 0.1718 * x
         + 0.002857;
}

vec3 agxLook(vec3 val) {
  const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
  float luma = dot(val, lw);

  #if AGX_LOOK == 1
    const vec3 slope = vec3(1.0, 0.9, 0.5);
    const vec3 power = vec3(0.8);
    const float sat = 0.8;
  #elif AGX_LOOK == 2
    const vec3 slope = vec3(1.0);
    const vec3 power = vec3(1.35);
    const float sat = 1.4;
  #else
    const vec3 slope = vec3(1.0);
    const vec3 power = vec3(1.0);
    const float sat = 1.0;
  #endif

  val = pow(max(val * slope, 0.0), power);
  return luma + sat * (val - luma);
}

vec3 toneAgX(vec3 value) {
  value = max(value, 0.0);

  value = AGX_INSET * value;
  value = clamp(log2(max(value, vec3(1.0e-10)) / AGX_MIDDLE_GREY),
                AGX_MIN_EV, AGX_MAX_EV);
  value = (value - AGX_MIN_EV) * (1.0 / (AGX_MAX_EV - AGX_MIN_EV));

  value = agxContrastApprox(value);

  value = agxLook(value);

  value = AGX_INVERSE_OUTSET * value;
  value = pow(max(value, 0.0), vec3(2.2));
  return max(value, 0.0);
}

const mat3 ACES_INPUT_MAT = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777);
const mat3 ACES_OUTPUT_MAT = mat3(
     1.60475, -0.10208, -0.00327,
    -0.53108,  1.10813, -0.07276,
    -0.07367, -0.00605,  1.07602);

const float ACES_FULL_PRE_EXPOSURE = 1.12;

vec3 acesRRTAndODTFit(vec3 col) {
    vec3 a = col * (col + 0.0245786) - 0.000090537;
    vec3 b = col * (0.983729 * col + 0.4329510) + 0.238081;
    return a / max(b, vec3(1.0e-6));
}

vec3 toneACESFull(vec3 col) {
    col = max(col, 0.0) * ACES_FULL_PRE_EXPOSURE;
    vec3 aces = ACES_INPUT_MAT * col;
    aces = acesRRTAndODTFit(aces);
    aces = ACES_OUTPUT_MAT * aces;
    return clamp(aces, 0.0, 1.0);
}

vec3 sanitizeHDR(vec3 c) {
    bvec3 selfEq  = equal(c, c);
    bvec3 inRange = lessThan(abs(c), vec3(1.0e10));
    if (!all(selfEq) || !all(inRange)) {
        return vec3(0.0);
    }
    return clamp(c, vec3(0.0), vec3(1.0e4));
}

vec3 softClipHighlights(vec3 c) {
    float strength = clamp(TM_HIGHLIGHT_COMPRESS, 0.0, 1.0);
    if (strength <= 0.0) return c;
    float knee = max(TM_HIGHLIGHT_KNEE, 1.0e-3);
    float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
    if (lum <= knee) return c;
    float p = clamp(1.0 - 0.6 * strength, 0.40, 1.0);
    float compressed = knee * pow(max(lum / knee, 1.0e-6), p);
    float ratio = clamp(compressed / max(lum, 1.0e-6), 0.0, 1.0);
    return c * ratio;
}

vec3 toneMap(vec3 c) {
    c = sanitizeHDR(c);
	c = max(c, 0.0);
	c = softClipHighlights(c);
	#if TM_MODE == 1
		return toneReinhard(c);
	#elif TM_MODE == 2
		return toneACESFull(c);
	#elif TM_MODE == 3
		return toneOzius(c);
	#elif TM_MODE == 4
		return toneFilmic(c);
	#elif TM_MODE == 6
		return toneAgX(c);
	#elif TM_MODE == 7
		return toneReinhardJodie(c);
	#elif TM_MODE == 5
		return clamp(c, vec3(0.0), vec3(1.0));
	#else
		return clamp(c, vec3(0.0), vec3(1.0));
	#endif
}

vec3 rgbToHsl(vec3 c) {
	const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1.0e-6)), d / (q.x + 1.0e-6), q.x);
}

vec3 hslToRgb(vec3 c) {
	const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float isolateHue(vec3 hsl, float centerDeg, float widthDeg) {
	if (hsl.y < 1.0e-2 || hsl.z < 1.0e-2) return 0.0;
	float x = (hsl.x * 360.0 - centerDeg + 180.0) / 360.0;
	x = fract(x) * 360.0 - 180.0;
	x = abs(x) / max(widthDeg, 1.0e-4);
	if (x > 1.0) return 0.0;
	return 1.0 - x * x * (3.0 - 2.0 * x);
}

vec3 sqr3(vec3 x) { return x * x; }

vec3 colorGrade(vec3 c, float wbTemp, float wbTint,
                float brightness, float contrast, float saturation,
                vec3 channelGain) {
	c = max(c, 0.0);

	c.r *= 1.0 + wbTemp * 0.35;
	c.b *= 1.0 - wbTemp * 0.35;
	c.g *= 1.0 + wbTint * 0.25;

	c = max(c * channelGain * brightness, 0.0);

	c = pow(clamp(c, vec3(0.0), vec3(1.0)), vec3(1.0 + contrast));

	float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = max(mix(vec3(luma), c, saturation), 0.0);

	{
		vec3 hsl = rgbToHsl(sqrt(clamp(c, vec3(0.0), vec3(1.0))));
		hsl.y *= 1.0 + GRADE_ORANGE_SAT * isolateHue(hsl, 30.0, 20.0);
		hsl.y *= 1.0 + GRADE_TEAL_SAT   * isolateHue(hsl, 210.0, 20.0);
		hsl.y *= 1.0 + GRADE_GREEN_SAT  * isolateHue(hsl, 90.0, 44.0);
		c = sqr3(clamp(hslToRgb(hsl), 0.0, 1.0));
	}

	{
		vec3 x = clamp(c, vec3(0.0), vec3(1.0));
		vec3 a = 0.5 * pow(2.0 * min(x, 1.0 - x), vec3(GRADE_GAIN));
		c = mix(a, 1.0 - a, step(0.5, x));
	}

	return clamp(c, vec3(0.0), vec3(1.0));
}

vec3 splitTone(vec3 c, vec3 highCol, vec3 shadowCol, float offStrength) {
	if (offStrength <= 0.0 || (highCol == vec3(0.0) && shadowCol == vec3(0.0))) return c;
	float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float s = clamp(offStrength, 0.0, 1.0);
	float shadowW = 1.0 - smoothstep(0.12, 0.5, luma);
	float highW   = smoothstep(0.5, 0.9, luma);
	c *= vec3(1.0) + shadowCol * shadowW * s;
	c *= vec3(1.0) + highCol   * highW   * s;
	return clamp(c, vec3(0.0), vec3(1.0));
}

#endif
