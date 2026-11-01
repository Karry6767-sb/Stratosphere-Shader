#ifndef LIB_INTRO_GLSL
#define LIB_INTRO_GLSL

#include "/lib/cinematic.glsl"
uniform sampler2D logo;
uniform sampler2D font;
uniform float frameTimeCounter;
#ifndef INTRO_DURATION
#define INTRO_DURATION CINE_INTRO_DURATION
#endif

float introBlurAmount() {
#if CINE_INTRO == 0
    return 0.0;
#else
    if (frameTimeCounter <= 0.0 || frameTimeCounter >= INTRO_DURATION) {
        return 0.0;
    }
    return 1.0 - smoothstep(1.0, 2.0, frameTimeCounter);
#endif
}

float introBlurRadiusPx(vec2 viewSize) {
    return viewSize.y * 0.013;
}

float introGlyphAlpha(int code, vec2 localUv) {
    ivec2 cell = ivec2(code % 16, code / 16);
    vec2 atlasUv = (vec2(cell) + localUv) / 16.0;
    ivec2 atlasSize = textureSize(font, 0);
    ivec2 texel = clamp(ivec2(floor(atlasUv * vec2(atlasSize))),
                        ivec2(0), atlasSize - ivec2(1));
    float a = texelFetch(font, texel, 0).a;
    return smoothstep(0.02, 0.35, a);
}

float introGlyphAdvance(int code) {
    if (code == 32)  return 4.0;
    if (code == 116) return 4.0;
    return 6.0;
}

float introPhraseWidth(const int chars[12], int count) {
    float pen = 0.0;
    for (int i = 0; i < 12; i++) {
        if (i >= count) break;
        pen += introGlyphAdvance(chars[i]);
    }
    return pen;
}

float introTitleMask(vec2 fragPx, vec2 anchorPx, float scalePx) {
    const int chars[12] = int[12](83, 116, 114, 97, 116, 111, 115, 112, 104, 101, 114, 101);

    vec2 p = (fragPx - anchorPx) / max(scalePx, 0.0001);
    float mask = 0.0;
    float pen = 0.0;

    for (int i = 0; i < 12; i++) {
        int code = chars[i];
        float advance = introGlyphAdvance(code);

        if (p.x >= pen && p.x < pen + advance && p.y >= 0.0 && p.y < 8.0) {
            vec2 localUv = vec2((p.x - pen) / 8.0, 1.0 - p.y / 8.0);
            mask = max(mask, introGlyphAlpha(code, localUv));
        }

        pen += advance;
    }

    return mask;
}

float introAuthorMask(vec2 fragPx, vec2 anchorPx, float scalePx) {
    const int chars[12] = int[12](98, 121, 32, 75, 97, 114, 114, 121, 0, 0, 0, 0);

    vec2 p = (fragPx - anchorPx) / max(scalePx, 0.0001);
    float mask = 0.0;
    float pen = 0.0;

    for (int i = 0; i < 8; i++) {
        int code = chars[i];
        float advance = introGlyphAdvance(code);

        if (p.x >= pen && p.x < pen + advance && p.y >= 0.0 && p.y < 8.0) {
            vec2 localUv = vec2((p.x - pen) / 8.0, 1.0 - p.y / 8.0);
            mask = max(mask, introGlyphAlpha(code, localUv));
        }

        pen += advance;
    }

    return mask;
}

#ifndef INTRO_CENTER_X
#define INTRO_CENTER_X 0.5
#endif

float introTitleWidth() {
    const int chars[12] = int[12](83, 116, 114, 97, 116, 111, 115, 112, 104, 101, 114, 101);
    return introPhraseWidth(chars, 12);
}

float introAuthorWidth() {
    const int chars[12] = int[12](98, 121, 32, 75, 97, 114, 114, 121, 0, 0, 0, 0);
    return introPhraseWidth(chars, 8);
}

float introLogoSizePx(vec2 viewSize) {
    return max(96.0, viewSize.y * 0.125);
}

float introTitleScalePx(vec2 viewSize) {
    return max(2.0, viewSize.y / 260.0);
}

vec2 introLogoTitleLefts(vec2 viewSize, float titleWidthPx) {
    float gapPx = viewSize.x * 0.012;
    float groupWidthPx = introLogoSizePx(viewSize) + gapPx + titleWidthPx;
    float logoLeftPx = viewSize.x * INTRO_CENTER_X - groupWidthPx * 0.5;
    return vec2(logoLeftPx, logoLeftPx + introLogoSizePx(viewSize) + gapPx);
}

const float INTRO_GAUSS_SIGMA = 2.2;

float introGaussWeight(int i) {
    float x = float(i);
    return exp(-0.5 * x * x / (INTRO_GAUSS_SIGMA * INTRO_GAUSS_SIGMA));
}

vec2 introGaussLinearTap(int i) {
    float wi  = introGaussWeight(i);
    float wi1 = introGaussWeight(i + 1);
    float s = wi + wi1;
    if (s <= 1e-6) return vec2(0.0, 0.0);
    float offset = (float(i) * wi + float(i + 1) * wi1) / s;
    return vec2(offset, s);
}

vec3 introGauss1D(sampler2D tex, vec2 uv, vec2 texel, vec2 dirUV, float radiusPx) {
    float stepPx = radiusPx / 6.0;
    vec2 stepUV = dirUV * texel * stepPx;

    float n0 = introGaussWeight(0);
    vec2 t12 = introGaussLinearTap(1);
    vec2 t34 = introGaussLinearTap(3);
    vec2 t56 = introGaussLinearTap(5);

    float totalW = n0 + 2.0 * (t12.y + t34.y + t56.y);
    float inv = 1.0 / max(totalW, 1e-6);

    vec3 sum = texture(tex, uv).rgb * (n0 * inv);
    sum += texture(tex, uv + stepUV * t12.x).rgb * (t12.y * inv);
    sum += texture(tex, uv - stepUV * t12.x).rgb * (t12.y * inv);
    sum += texture(tex, uv + stepUV * t34.x).rgb * (t34.y * inv);
    sum += texture(tex, uv - stepUV * t34.x).rgb * (t34.y * inv);
    sum += texture(tex, uv + stepUV * t56.x).rgb * (t56.y * inv);
    sum += texture(tex, uv - stepUV * t56.x).rgb * (t56.y * inv);

    return sum;
}

vec3 introGaussH(sampler2D tex, vec2 uv, vec2 texel, float radiusPx) {
    return introGauss1D(tex, uv, texel, vec2(1.0, 0.0), radiusPx);
}

vec3 introGaussV(sampler2D tex, vec2 uv, vec2 texel, float radiusPx) {
    return introGauss1D(tex, uv, texel, vec2(0.0, 1.0), radiusPx);
}

vec3 introOverlay(vec3 color, vec2 uv, vec2 viewSize) {
#if CINE_INTRO == 0
    return color;
#else
    float introTime = frameTimeCounter;

    if (introTime <= 0.0 || introTime >= INTRO_DURATION) {
        return color;
    }
    float fadeOut = 1.0 - smoothstep(4.0, 5.0, introTime);

    float reveal = 1.0 - smoothstep(0.0, 1.0, introTime);

    vec3 darkFrame = vec3(0.055, 0.060, 0.075);
    color = mix(color, darkFrame, reveal);

    float barProgress = smoothstep(1.0, 2.0, introTime);
    float barHeight = 0.1 * barProgress;
    float feather = 1.5 / max(viewSize.y, 1.0);
    vec2 centered = abs(uv - 0.5);
    float barMask = smoothstep(0.5 - barHeight - feather,
                               0.5 - barHeight + feather,
                               centered.y);
    barMask *= barProgress;
    color = mix(color, vec3(0.0), barMask * fadeOut);

    float titleScale = introTitleScalePx(viewSize);
    vec2 groupLefts = introLogoTitleLefts(viewSize, introTitleWidth() * titleScale);

    float logoT = smoothstep(2.0, 2.5, introTime);
    float logoPx = introLogoSizePx(viewSize);
    float logoAlpha = logoT * fadeOut;

    float t_move = smoothstep(2.5, 3.0, introTime);

    float logoGroupCenterPx = groupLefts.x + logoPx * 0.5;
    float logoCenterXPx = mix(viewSize.x * INTRO_CENTER_X, logoGroupCenterPx, t_move);

    vec2 logoCenterPx = vec2(logoCenterXPx, viewSize.y * 0.5);
    vec2 logoCenterUv = logoCenterPx / viewSize;

    if (logoAlpha > 0.0015) {
        vec2 halfUv = vec2(logoPx * 0.5) / viewSize;
        vec2 d = (uv - logoCenterUv) / halfUv;

        if (abs(d.x) <= 1.0 && abs(d.y) <= 1.0) {
            vec2 logoUv = vec2(d.x * 0.5 + 0.5, 0.5 - d.y * 0.5);
            vec4 logoTex = texture(logo, clamp(logoUv, 0.0, 1.0));

            float logoMask = logoTex.a;
            float edge = 1.0 - smoothstep(0.94, 1.0, max(abs(d.x), abs(d.y)));
            logoMask *= edge;

            float lum = dot(logoTex.rgb, vec3(0.2126, 0.7152, 0.0722));
            const float LOGO_LOW  = 0.47;
            const float LOGO_HIGH = 0.90;
            float t = clamp((lum - LOGO_LOW) / (LOGO_HIGH - LOGO_LOW), 0.0, 1.0);
            vec3 logoColor = vec3(mix(0.62, 1.0, t));

            color = mix(color, logoColor, clamp(logoMask * logoAlpha, 0.0, 1.0));
        }
    }

    float titleT = smoothstep(3.0, 3.5, introTime);
    float titleAlpha = titleT * fadeOut;

    if (titleAlpha > 0.0015) {
        float titleAnchorYPx = viewSize.y * 0.5 - 4.0 * titleScale;

        vec2 fragPx = uv * viewSize;
        vec2 titleAnchor = vec2(groupLefts.y, titleAnchorYPx);

        float titleShadow = introTitleMask(fragPx - vec2(2.5, -2.5) * titleScale,
                                           titleAnchor, titleScale);
        float titleMask = introTitleMask(fragPx, titleAnchor, titleScale);

        color = mix(color, vec3(0.0), clamp(titleShadow * 0.35 * titleAlpha, 0.0, 1.0));
        color = mix(color, vec3(0.97, 0.98, 1.0),
                    clamp(titleMask * titleAlpha, 0.0, 1.0));
    }

    float authorT = smoothstep(3.5, 4.0, introTime);
    float authorAlpha = authorT * fadeOut;

    if (authorAlpha > 0.0015) {
        float authorScale = max(1.5, viewSize.y / 360.0);
        float authorWidthPx = introAuthorWidth() * authorScale;

        float authorLeftPx = viewSize.x * INTRO_CENTER_X - authorWidthPx * 0.5;
        float logoBottomYPx = viewSize.y * 0.5 - logoPx * 0.5;
        float authorCenterYPx = logoBottomYPx - 4.0 * authorScale - viewSize.y * 0.03;

        vec2 fragPx = uv * viewSize;
        vec2 authorAnchor = vec2(authorLeftPx, authorCenterYPx - 4.0 * authorScale);

        float authorShadow = introAuthorMask(fragPx - vec2(2.0, -2.0) * authorScale,
                                             authorAnchor, authorScale);
        float authorMask = introAuthorMask(fragPx, authorAnchor, authorScale);

        color = mix(color, vec3(0.0), clamp(authorShadow * 0.30 * authorAlpha, 0.0, 1.0));
        color = mix(color, vec3(0.96, 0.96, 0.97),
                    clamp(authorMask * authorAlpha, 0.0, 1.0));
    }

    return color;
}
#endif

#endif
