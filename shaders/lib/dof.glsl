#ifndef LIB_DOF_GLSL
#define LIB_DOF_GLSL

const vec3 DOF_LUMA_709 = vec3(0.2126, 0.7152, 0.0722);

float dofLinearizeDepth(float windowDepth) {
    vec4 clip = vec4(0.0, 0.0, windowDepth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    float w = max(abs(view.w), 1.0e-6);
    return max(-view.z / w, 0.0);
}

vec2 dofVogelDisc(int i, int n, float theta) {
    float r = sqrt((float(i) + 0.5) / float(max(n, 1)));
    float a = float(i) * 2.39996323 + theta;
    return r * vec2(cos(a), sin(a));
}

float dofCoCRadiusPx(float sceneDepth, float focusDepth, float viewWidthPx) {
    float f = max(DOF_FOCAL_LENGTH * 0.001, 1.0e-4);
    float apertureD = 0.5 * f / max(DOF_F_STOP, 0.7);
    float focus = max(focusDepth, f * 1.02 + 0.02);
    float denom = 0.036 * max(focus - f, 1.0e-4);
    float scale = apertureD * f * max(viewWidthPx, 1.0) / denom;
    float coc = scale * (sceneDepth - focus) / max(sceneDepth, 1.0e-4);

    float distance = abs(sceneDepth - focus) / max(sceneDepth, 1.0e-4);
    float visible = DOF_VISIBILITY * smoothstep(0.0, 0.02, distance);
    coc *= visible;

    return clamp(coc, -DOF_MAX_BLUR, DOF_MAX_BLUR);
}

float dofAutoFocusDepth(sampler2D depthTex, vec2 uv, vec2 texel, float centerDepth) {
    float centerZ = dofLinearizeDepth(centerDepth);

    if (centerDepth >= 0.999999) return 6.0;

    float sum = centerZ * 2.0;
    float wsum = 2.0;
    float nearest = centerZ;

    for (int y = -2; y <= 2; ++y) {
        for (int x = -2; x <= 2; ++x) {
            if (x == 0 && y == 0) continue;
            vec2 suv = clamp(uv + vec2(float(x), float(y)) * texel * 2.0,
                             vec2(0.0), vec2(1.0));
            float d = texture(depthTex, suv).r;
            if (d >= 0.999999) continue;
            float z = dofLinearizeDepth(d);
            if (z <= DOF_HAND_DEPTH) continue;
            float w = exp(-float(x * x + y * y) * 0.12);
            sum += z * w;
            wsum += w;
            nearest = min(nearest, z);
        }
    }

    float average = (wsum > 1.0e-5) ? sum / wsum : centerZ;
    return mix(average, nearest, 0.35);
}

float dofFocusDistance(sampler2D depthTex, vec2 uv, vec2 texel, float centerDepth) {
    if (DOF_FOCUS < 0.0) {
        return dofAutoFocusDepth(depthTex, uv, texel, centerDepth);
    }
    return DOF_FOCUS;
}

#endif
