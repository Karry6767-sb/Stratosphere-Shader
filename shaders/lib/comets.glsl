#ifndef LIB_COMETS_GLSL
#define LIB_COMETS_GLSL

#include "/lib/meteors.glsl"

#ifndef COMET_ION_CURVE
#endif

vec3 CometTailVolume(vec3 cViewDir, vec3 head, vec3 dir, float len, float width, float widest, float curve) {
    float ds = len / float(COMET_TAIL_STEPS);
    float jitter = fract(sin(dot(cViewDir, vec3(12.9898, 78.233, 45.164))
                              + frameTimeCounter * 7.31) * 43758.5453);
    vec3 binormal = normalize(cross(head, dir));

    float total = 0.0;
    for (int i = 0; i < COMET_TAIL_STEPS; i++) {
        float sPhase = (float(i) + jitter) * ds;
        float snPhase = clamp(sPhase / len, 0.0, 1.0);
        float tPhase = snPhase / COMET_TAIL_TAPER;
        float rPhys = widest * tPhase * exp(1.0 - tPhase);
        float jitW = clamp(rPhys / max(ds, 1.0e-6), 0.0, 1.0);
        float s = (float(i) + jitter * jitW) * ds;
        if (s <= 0.0 || s >= len) continue;

        float snA = s / len;
        float bendAngle = (curve == 0.0) ? 0.0 : curve * pow(snA, COMET_TAIL_BEND_POW);
        float cb = cos(bendAngle);
        float sb = sin(bendAngle);
        vec3 dirEff = normalize(cb * dir + sb * binormal);
        vec3 axisP = normalize(cos(s) * head + sin(s) * dirEff);

        float r = acos(clamp(dot(cViewDir, axisP), -1.0, 1.0));

        float sn = s / len;
        float taperSn = sn / COMET_TAIL_TAPER;
        float R = widest * taperSn * exp(1.0 - taperSn);
        R = max(R, ds * 0.9);
        R = max(R, width * 0.5);
        float radial = exp(-(r * r) / (2.0 * (R * COMET_TAIL_SHARP) * (R * COMET_TAIL_SHARP)));

        float axial = exp(-snA * snA * COMET_TAIL_DENSITY);
        axial *= 1.0 - smoothstep(0.75, 1.0, snA);

        total += radial * axial * ds;
    }
    return vec3(total);
}

float CometTailShell(vec3 d, vec3 head, vec3 dir, float len, float width) {
    float a = dot(d, dir);
    float along = asin(clamp(a, -1.0, 1.0));
    if (along <= 0.0 || along >= len) return 0.0;
    float b = dot(d, head);
    float lateral = b - cos(along);
    float spread = width * (0.45 + 1.55 * (along / len));
    float cross_ = exp(-(lateral * lateral) / (2.0 * spread * spread));
    float fade = exp(-along / len * 2.0);
    fade *= 1.0 - smoothstep(0.75, 1.0, along / len);
    return cross_ * fade;
}

vec3 CometTail(vec3 cViewDir, vec3 head, vec3 dir, float len, float width, float widest, float curve) {
#if COMET_TAIL_ANALYTIC == 1
    return vec3(CometTailShell(cViewDir, head, dir, len, width));
#else
    return CometTailVolume(cViewDir, head, dir, len, width, widest, curve);
#endif
}

float CometArcCosDist(vec3 d, vec3 head, vec3 dir, float len) {
    float a = dot(d, head);
    float b = dot(d, dir);
    float along = atan(b, a);
    if (along < 0.0) return a;
    if (along > len) return a * cos(len) + b * sin(len);
    return sqrt(max(0.0, a * a + b * b));
}

vec3 CometSlot(vec3 worldDir, float t, vec3 seed, vec3 sunDirW, float visible) {
    if (visible <= 0.001) return vec3(0.0);

    vec3 up = (abs(sunDirW.y) < 0.95) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 e1 = normalize(cross(up, sunDirW));
    vec3 e2 = cross(sunDirW, e1);
    float az = seed.x * TAU;
    float el = radians(COMET_ELEV_BASE * (0.55 + 0.9 * seed.y));
    vec3 head = normalize(sunDirW * sin(el) + (e1 * cos(az) + e2 * sin(az)) * cos(el));

    vec3 d = normalize(worldDir);
    float angToHead = acos(clamp(dot(d, head), -1.0, 1.0));

    vec3 ionDir = normalize(-sunDirW);
    ionDir = ionDir - head * dot(ionDir, head);
    if (length(ionDir) < 1.0e-4) return vec3(0.0);
    ionDir = normalize(ionDir);

    vec3 dustDir = normalize(cos(COMET_DUST_BEND) * ionDir
                           + sin(COMET_DUST_BEND) * normalize(cross(head, ionDir)));

    float headGlow = exp(-(angToHead * angToHead) / (2.0 * COMET_HEAD_SIZE * COMET_HEAD_SIZE));

    float tol = 4.0 * max(COMET_ION_WIDEST, COMET_DUST_WIDEST)
              + max(COMET_ION_CURVE, COMET_DUST_CURVE);
    float cosTol = cos(tol);
    bool nearIon  = CometArcCosDist(d, head, ionDir,  COMET_ION_LEN)  > cosTol;
    bool nearDust = CometArcCosDist(d, head, dustDir, COMET_DUST_LEN) > cosTol;
    if (!nearIon && !nearDust) return vec3(0.0);

    float ion  = nearIon
               ? CometTail(d, head, ionDir,  COMET_ION_LEN,  COMET_ION_WIDTH,
                           COMET_ION_WIDEST,  COMET_ION_CURVE).r  * COMET_ION_INTENSITY
               : 0.0;
    float dust = nearDust
               ? CometTail(d, head, dustDir, COMET_DUST_LEN, COMET_DUST_WIDTH,
                           COMET_DUST_WIDEST, COMET_DUST_CURVE).r * COMET_DUST_INTENSITY
               : 0.0;

    vec3 col = vec3(0.72, 0.86, 1.00) * ion
             + vec3(1.00, 0.92, 0.74) * dust
             + vec3(0.88, 0.93, 1.00) * headGlow * COMET_HEAD_GAIN;

    return col * (visible * COMET_BRIGHTNESS);
}

vec3 RenderComets(vec3 worldDir, float nowSec, vec3 sunDirW, float nightFade) {
#if COMET_DEBUG_FORCE == 1
    float t = 0.5;
    vec3  seed2 = vec3(0.25, 0.55, 0.5);
    return CometSlot(worldDir, t, seed2, sunDirW, 1.0) * nightFade;
#else
    float cycle = floor(nowSec / COMET_PERIOD);
    vec3  seed  = meteorHash31(cycle * 12.9898 + 4.1414);

    if (seed.z >= COMET_CHANCE) return vec3(0.0);

    float t = fract(nowSec / COMET_PERIOD);
    float taperHalf = (1.0 - COMET_WINDOW) * 0.5;
    float visible = smoothstep(0.0, taperHalf, t)
                  * (1.0 - smoothstep(1.0 - taperHalf, 1.0, t));
    if (visible <= 0.001) return vec3(0.0);

    vec3 seed2 = meteorHash31(cycle * 7.331 + 91.7);
    return CometSlot(worldDir, t, seed2, sunDirW, visible) * nightFade;
#endif
}

#endif
