#ifndef METEOR_SLOT_SEC
#define METEOR_SLOT_SEC 1.5
#endif

#ifndef TAU
#define TAU 6.28318530717958647693
#endif

#ifndef LIB_METEORS_GLSL
#define LIB_METEORS_GLSL

#include "/lib/galaxy.glsl"

#ifndef METEOR_SLOTS
#define METEOR_SLOTS 2
#endif

float meteorHash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec3 meteorHash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

vec3 MeteorWorldDirFromEquatorial(float raDeg, float decDeg, float mtWorldTimeTicks) {
    float ra  = radians(raDeg);
    float dec = radians(decDeg);
    vec3 eq = vec3(cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec));

    float hourAngle = (mtWorldTimeTicks - 18000.0) * (TAU / 24000.0);
    mat3 R = galaxyRotZ(PI - GALAXY_SOLAR_POS * TAU - hourAngle)
           * galaxyRotY(radians(GALAXY_LATITUDE));

    vec3 e = transpose(R) * eq;
    return normalize(vec3(e.y, e.x, -e.z));
}

void MeteorTangentBasis(vec3 r, out vec3 t1, out vec3 t2) {
    vec3 up = (abs(r.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    t1 = normalize(cross(up, r));
    t2 = cross(r, t1);
}

vec3 MeteorSlot(vec3 viewDir, float slot, float nowSec, vec3 radiantDir,
                float prob, float showerAmt) {
    vec3 h = meteorHash31(slot * 1.37 + 7.13);
    if (h.x >= prob) return vec3(0.0);

    float birth = slot * METEOR_SLOT_SEC + h.y * METEOR_SLOT_SEC;
    float life  = METEOR_LIFE * (0.7 + 0.6 * h.z);
    float prog  = (nowSec - birth) / max(life, 1.0e-3);
    if (prog < 0.0 || prog > 1.0) return vec3(0.0);

    vec3 h2 = meteorHash31(slot * 3.71 + 19.31);
    vec3 h3 = meteorHash31(slot * 8.19 + 41.77);

    bool isShower = (h2.x < showerAmt);
    vec3 startDir;
    if (isShower) {
        vec3 t1, t2;
        MeteorTangentBasis(radiantDir, t1, t2);
        float phi = h2.y * TAU;
        float th0 = radians(METEOR_SHOWER_MIN_ANGLE)
                  + h2.z * radians(METEOR_SHOWER_MAX_ANGLE - METEOR_SHOWER_MIN_ANGLE);
        startDir = normalize(radiantDir * cos(th0) + (t1 * cos(phi) + t2 * sin(phi)) * sin(th0));
    } else {
        float z = h2.y * 2.0 - 1.0;
        float phi = h2.z * TAU;
        float r = sqrt(max(1.0 - z * z, 0.0));
        startDir = vec3(r * cos(phi), z, r * sin(phi));
    }

    vec3 travel;
    if (isShower) {
        travel = startDir - radiantDir * dot(startDir, radiantDir);
        if (length(travel) < 1.0e-4) return vec3(0.0);
        travel = normalize(travel);
    } else {
        vec3 raw = vec3(h3.x, h3.y, h3.z) * 2.0 - 1.0;
        travel = raw - startDir * dot(raw, startDir);
        if (length(travel) < 1.0e-4) return vec3(0.0);
        travel = normalize(travel);
    }

    vec3 polar = normalize(cross(startDir, travel));

    float perp = asin(clamp(dot(viewDir, polar), -1.0, 1.0));
    vec3 inPlane = normalize(cross(polar, startDir));
    float along = atan(dot(viewDir, inPlane), dot(viewDir, startDir));

    float head = prog * METEOR_PATH_LEN;
    float dAlong = head - along;

    float flux = 0.0;
    if (dAlong >= 0.0 && dAlong <= METEOR_TAIL_LEN) {
        float u        = dAlong / max(METEOR_TAIL_LEN, 1.0e-4);
        float lenFade  = exp(-u * METEOR_TAIL_FALLOFF);
        lenFade *= 1.0 - smoothstep(METEOR_TAIL_END_FADE, 1.0, u);
        float w        = METEOR_WIDTH;
        float widthFade = exp(-(perp * perp) / (2.0 * w * w));
        flux = lenFade * widthFade;
    }

    float hs = METEOR_HEAD_SIZE;
    float headD2 = perp * perp + (along - head) * (along - head);
    float headGlow = exp(-headD2 / (2.0 * hs * hs));

    float env = smoothstep(0.0, METEOR_FADE_IN, prog)
              * (1.0 - smoothstep(METEOR_FADE_START, 1.0, prog));

    float mag = 0.35 + 0.65 * h3.x;
    vec3 col = isShower ? vec3(0.72, 1.00, 0.82) : vec3(0.88, 0.94, 1.00);
    col = mix(col, vec3(1.0, 0.96, 0.88), h3.y * 0.4);

    float total = flux * METEOR_TRAIL_GAIN + headGlow * METEOR_HEAD_GAIN;
    return col * (total * env * mag * METEOR_BRIGHTNESS);
}

vec3 RenderMeteors(vec3 viewDir, float nowSec, vec3 radiantDir,
                   float ratePerHour, float showerWindow, float nightFade) {
    float prob = clamp(ratePerHour / 3600.0 * METEOR_SLOT_SEC, 0.0, 1.0);

    float baseSlot = floor(nowSec / METEOR_SLOT_SEC);
    vec3 acc = vec3(0.0);
    for (int i = 0; i < METEOR_SLOTS; i++) {
        float slot = baseSlot - float(i);
        acc += MeteorSlot(viewDir, slot, nowSec, radiantDir, prob, showerWindow);
    }
    return acc * nightFade;
}

#ifndef METEOR_SHOWER_COUNT
#define METEOR_SHOWER_COUNT 8
#endif

const vec4 MS_DATA[METEOR_SHOWER_COUNT] = vec4[METEOR_SHOWER_COUNT](
    vec4(0.008, 0.010, 230.0,  49.0),
    vec4(0.345, 0.014, 338.0,  -1.0),
    vec4(0.580, 0.016, 340.0, -16.0),
    vec4(0.613, 0.018,  48.0,  58.0),
    vec4(0.805, 0.012,  95.0,  16.0),
    vec4(0.879, 0.012, 153.0,  22.0),
    vec4(0.953, 0.014, 262.0,  33.0),
    vec4(0.975, 0.008, 217.0,  76.0)
);

const float MS_ZHR[METEOR_SHOWER_COUNT] = float[METEOR_SHOWER_COUNT](
    110.0,
     60.0,
     25.0,
    100.0,
     20.0,
     15.0,
    150.0,
     10.0
);

float MeteorYearPhase(float worldDay) {
#if METEOR_YEAR_AUTO == 1
    return fract(float(worldDay) / METEOR_YEAR_DAYS + METEOR_YEAR_ORIGIN);
#else
    return fract(METEOR_YEAR_PHASE);
#endif
}

bool MeteorShowers(float yearPhase, out float radRA, out float radDec, out float boost) {
    vec3 accDir = vec3(0.0);
    float wsum  = 0.0;
    float zsum  = 0.0;

    for (int i = 0; i < METEOR_SHOWER_COUNT; i++) {
        float c = MS_DATA[i].x;
        float w = MS_DATA[i].y * METEOR_SHOWER_WIDTH;

        float d = abs(yearPhase - c);
        d = min(d, 1.0 - d);

        float k = 1.0 - smoothstep(0.0, w, d);
        if (k <= 1.0e-4) continue;

        float ra  = radians(MS_DATA[i].z);
        float dec = radians(MS_DATA[i].w);
        vec3 u = vec3(cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec));
        accDir += u * k;
        wsum += k;
        zsum += k * MS_ZHR[i];
    }

    if (wsum <= 1.0e-5) {
        radRA = 0.0; radDec = 0.0; boost = 0.0;
        return false;
    }

    vec3 dir = normalize(accDir);
    radRA  = degrees(atan(dir.y, dir.x));
    radDec = degrees(asin(clamp(dir.z, -1.0, 1.0)));
    float zhrNorm = clamp((zsum / wsum) / 100.0, 0.0, 1.0);
    float peakK = 0.0;
    for (int i = 0; i < METEOR_SHOWER_COUNT; i++) {
        float c = MS_DATA[i].x;
        float w = MS_DATA[i].y * METEOR_SHOWER_WIDTH;
        float d = abs(yearPhase - c);
        d = min(d, 1.0 - d);
        peakK = max(peakK, 1.0 - smoothstep(0.0, w, d));
    }
    boost = clamp(peakK * (0.35 + 0.65 * zhrNorm), 0.0, 1.0);
    return true;
}

#endif
