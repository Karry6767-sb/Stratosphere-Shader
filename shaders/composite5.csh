#version 430 compatibility

#include "/lib/options_defaults.glsl"

#include "/lib/exposure_data.glsl"

uniform float frameTime;

layout(local_size_x = HISTOGRAM_BIN_COUNT) in;
const ivec3 workGroups = ivec3(1, 1, 1);

shared uint prefix[HISTOGRAM_BIN_COUNT];
shared float reduceWeighted[HISTOGRAM_BIN_COUNT];
shared uint reduceCount[HISTOGRAM_BIN_COUNT];
shared uint sharedMedian;
shared uint sharedQ3;
shared uint sharedP95;

void main() {
    uint i = gl_LocalInvocationIndex;

    prefix[i] = histogram[i];
    barrier();

#define PREFIX_STEP(s)                                   \
    {                                                    \
        uint v_##s = (i >= (s)) ? prefix[i - (s)] : 0u;  \
        barrier();                                       \
        prefix[i] += v_##s;                              \
        barrier();                                       \
    }
    PREFIX_STEP(1u)
#if HISTOGRAM_BIN_COUNT > 2
    PREFIX_STEP(2u)
#endif
#if HISTOGRAM_BIN_COUNT > 4
    PREFIX_STEP(4u)
#endif
#if HISTOGRAM_BIN_COUNT > 8
    PREFIX_STEP(8u)
#endif
#if HISTOGRAM_BIN_COUNT > 16
    PREFIX_STEP(16u)
#endif
#if HISTOGRAM_BIN_COUNT > 32
    PREFIX_STEP(32u)
#endif
#if HISTOGRAM_BIN_COUNT > 64
    PREFIX_STEP(64u)
#endif
#if HISTOGRAM_BIN_COUNT > 128
    PREFIX_STEP(128u)
#endif
#if HISTOGRAM_BIN_COUNT > 256
    PREFIX_STEP(256u)
#endif
#undef PREFIX_STEP

    uint total = prefix[HISTOGRAM_BIN_COUNT - 1u];

    uint midCount = total / 2u;
    uint q3Count = (total * 3u) / 4u;
    uint p95Count = uint(float(total) * clamp(NIGHT_SCENE_P95, 0.5, 1.0));

    if (i == 0u) {
        sharedMedian = 0u;
        sharedQ3 = 0u;
        sharedP95 = 0u;
    }
    barrier();
    {
        bool firstMedian = (prefix[i] >= midCount) &&
                           (i == 0u || prefix[i - 1u] < midCount);
        bool firstQ3 = (prefix[i] >= q3Count) &&
                       (i == 0u || prefix[i - 1u] < q3Count);
        bool firstP95 = (prefix[i] >= p95Count) &&
                        (i == 0u || prefix[i - 1u] < p95Count);
        sharedMedian = firstMedian ? i : sharedMedian;
        sharedQ3 = firstQ3 ? i : sharedQ3;
        sharedP95 = firstP95 ? i : sharedP95;
    }
    barrier();

    if (total == 0u) {
        if (i == 0u) {
            if (exposure <= 0.0) exposure = 1.0;
            sceneNightAmt = 0.0;
        }
    }
    bool validHistogram = (total > 0u);

    uint loBin = 0u;
    uint hiBin = uint(HISTOGRAM_BIN_COUNT) - 1u;
    {
        uint med = sharedMedian;
        float amb4 = max(ambientLum, 0.0);
        float nightForMeter = 1.0 - smoothstep(EXPOSURE_NIGHT_AMBIENT * 0.2,
                                               EXPOSURE_NIGHT_AMBIENT * 2.0,
                                               max(amb4, 1.0e-6));
        uint nightQuantileBin = sharedP95;
        uint meterBin = (nightForMeter > 0.5) ? nightQuantileBin : med;
        uint span = uint(clamp(HISTOGRAM_MODE_SPAN, 0, HISTOGRAM_BIN_COUNT - 1));
        loBin = (meterBin > span) ? meterBin - span : 0u;
        hiBin = min(meterBin + span, uint(HISTOGRAM_BIN_COUNT) - 1u);
    }

    uint n = (i >= loBin && i <= hiBin) ? histogram[i] : 0u;

    reduceWeighted[i] = float(n) * float(i);
    reduceCount[i] = n;
    barrier();

#define REDUCE_STEP(s)                                  \
    {                                                   \
        if (i < (s)) {                                  \
            reduceWeighted[i] += reduceWeighted[i + (s)]; \
            reduceCount[i] += reduceCount[i + (s)];     \
        }                                               \
        barrier();                                      \
    }
#if HISTOGRAM_BIN_COUNT > 256
    REDUCE_STEP(256u)
#endif
#if HISTOGRAM_BIN_COUNT > 128
    REDUCE_STEP(128u)
#endif
#if HISTOGRAM_BIN_COUNT > 64
    REDUCE_STEP(64u)
#endif
#if HISTOGRAM_BIN_COUNT > 32
    REDUCE_STEP(32u)
#endif
#if HISTOGRAM_BIN_COUNT > 16
    REDUCE_STEP(16u)
#endif
#if HISTOGRAM_BIN_COUNT > 8
    REDUCE_STEP(8u)
#endif
#if HISTOGRAM_BIN_COUNT > 4
    REDUCE_STEP(4u)
#endif
#if HISTOGRAM_BIN_COUNT > 2
    REDUCE_STEP(2u)
#endif
    REDUCE_STEP(1u)
#undef REDUCE_STEP

    if (i == 0u && validHistogram && reduceCount[0] > 0u) {
        float meanBin = reduceWeighted[0] / max(float(reduceCount[0]), 1.0);
        float meanLog = mix(float(AUTO_EV_MIN), float(AUTO_EV_MAX),
                            meanBin / float(HISTOGRAM_BIN_COUNT - 1u));
        float meanLum = max(exp2(meanLog), 1.0e-6);
        float basicTarget = 0.18 * exp2(float(AUTO_EV_BIAS)) / meanLum;
        float avgBin = reduceWeighted[0] / float(reduceCount[0]);
        float avgLogLum = mix(float(AUTO_EV_MIN), float(AUTO_EV_MAX),
                              avgBin / float(HISTOGRAM_BIN_COUNT - 1u));
        float avgLum = exp2(avgLogLum);

        float amb = max(ambientLum, 0.0);
        float q3Log = mix(float(AUTO_EV_MIN), float(AUTO_EV_MAX),
                          float(sharedQ3) / float(HISTOGRAM_BIN_COUNT - 1u));
        float q3Lum = exp2(q3Log);
        float nightProbe = max(amb, max(avgLum, q3Lum));
        float nightAmt = 1.0 - smoothstep(EXPOSURE_NIGHT_AMBIENT * 0.2,
                                          EXPOSURE_NIGHT_AMBIENT * 2.0,
                                          max(nightProbe, 1.0e-6));

        float ambientFloor = amb * clamp(EXPOSURE_AMBIENT_FLOOR, 0.0, 1.0)
                                * (1.0 - nightAmt);

        float adaptLum = max(avgLum, max(ambientFloor, NIGHT_SCENE_FLOOR));

        float oldExposure = 0.18 * exp2(float(AUTO_EV_BIAS)) / max(adaptLum, 1.0e-6);

        float key = 1.03 - 2.0 / (log(max(avgLum, 1.0e-6) + 1.0) * 0.4342944819 + 2.0);
#if EXPOSURE_KEY_VALUE

        float keyExposure = key / max(adaptLum, 1.0e-4);
        float target = mix(oldExposure, keyExposure, clamp(EXPOSURE_KEY_STRENGTH, 0.0, 1.0));
#else
        float target = oldExposure;
#endif
        target = mix(basicTarget, target,
                     (EXPOSURE_MODE == EXPOSURE_MODE_AUTO_BASIC) ? 0.0 : 1.0);

        target *= mix(1.0, clamp(EXPOSURE_NIGHT_KEY, 0.0, 1.0), nightAmt);

        float nightGain = mix(1.0, clamp(NIGHT_BRIGHTNESS, 0.1, 32.0), nightAmt);

        target = clamp(target, exp2(float(AUTO_EV_MIN)), exp2(float(AUTO_EV_MAX)));
        target = clamp(target * nightGain, 0.0, exp2(float(AUTO_EV_MAX)) * 32.0);

        adaptedLum = adaptLum;
        nightSignal = nightAmt;
        sceneNightAmt = nightAmt;

        float fwd = target > exposure ? float(EXPOSURE_SPEED_UP) : float(EXPOSURE_SPEED_DOWN);
        float w = 1.0 - exp2(-max(frameTime, 0.0) / max(fwd, 1.0e-3));
        if (exposure <= 0.0) {
            exposure = target;
        } else {
            exposure = mix(exposure, target, clamp(w, 0.0, 1.0));
        }
    }

    histogram[i] = 0u;
}
