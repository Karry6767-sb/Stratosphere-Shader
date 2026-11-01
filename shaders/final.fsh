#version 430 compatibility

#include "/lib/options_defaults.glsl"

in vec2 texcoord;

#include "/lib/post.glsl"
#include "/lib/aa_options.glsl"
#include "/lib/fxaa.glsl"
#include "/lib/sharpen.glsl"
#include "/lib/lens.glsl"
#include "/lib/cinematic.glsl"
#include "/lib/intro.glsl"

uniform sampler2D colortex15;

layout(location = 0) out vec4 color;

void main() {
    vec2 fullSize = max(vec2(viewWidth, viewHeight), vec2(1.0));
    vec2 texel = 1.0 / fullSize;

    vec3 ldr = texture(colortex15, texcoord).rgb;
#if AA_MODE == 1 || AA_MODE == 3 || AA_MODE == 4
    ldr = fxaa311(colortex15, texcoord, texel);
#endif
#if SHARPEN_MODE == 1
    ldr = rcasSharpen(colortex15, texcoord, ldr, texel, -SHARPEN_STRENGTH);
#endif

    vec2 lensUV = lensDistortFull(
        texcoord, CINE_LENS_K1, CINE_LENS_K2, CINE_FISHEYE,
        viewWidth / max(viewHeight, 1.0), CINE_CYLINDRICAL);

#if CINE_LENS_K1 == 0.0 && CINE_LENS_K2 == 0.0 && CINE_FISHEYE == 0.0 && CINE_CYLINDRICAL == 0.0
    vec3 cam = ldr;
#else
    vec3 cam = texture(colortex15, lensUV).rgb;
#endif

    cam = cineApply(colortex15, cam, lensUV, fullSize);

    cam = applyDeband(colortex15, lensUV, cam, texel);

    cam = cineGrain(cam, texcoord, fullSize, CINE_GRAIN, frameTimeCounter);
    cam = cineLetterbox(cam, texcoord, fullSize,
                        CINE_LETTERBOX, CINE_LETTERBOX_SIZE);

    cam = applyOutputGamma(cam);
    cam = applyDither(cam, gl_FragCoord.xy);

    cam = introOverlay(cam, texcoord, fullSize);
    color = vec4(clamp(cam, 0.0, 1.0), 1.0);
}
