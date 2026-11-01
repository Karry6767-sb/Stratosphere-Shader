#version 330 compatibility

/* RENDERTARGETS: 4,12,13 */

#include "/lib/options_defaults.glsl"

#include "/lib/intro.glsl"
#include "/lib/lighting/ssil.glsl"
#include "/lib/lighting/ssr.glsl"

uniform sampler2D colortex9;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 ssilRaw;
layout(location = 2) out vec4 ssrRaw;

void main() {
        float blurAmt = introBlurAmount();

        vec3 src = texture(colortex0, texcoord).rgb;
        if (blurAmt > 0.002) {
                vec2 size = vec2(viewWidth, viewHeight);
                vec2 texel = 1.0 / max(size, vec2(1.0));
                float radiusPx = introBlurRadiusPx(size) * blurAmt;
                src = introGaussH(colortex0, texcoord, texel, radiusPx);
        }

        color = vec4(src, blurAmt);

        float sceneDepth = texture(depthtex0, texcoord).r;

        vec3 ssilValue = vec3(0.0);
        float ssilTraced = 0.0;
#if SSIL_ENABLE == 1
        if (sceneDepth < 1.0 && ssilCheckerboard(gl_FragCoord.xy) < 0.5) {
                vec3 worldNormal = normalize(texture(colortex2, texcoord).rgb * 2.0 - 1.0);
                vec3 viewPos = ssilScreenToView(texcoord, sceneDepth);
                vec3 viewNormal = normalize(mat3(gbufferModelView) * worldNormal);
                float dither = ssilFrameDither(gl_FragCoord.xy);

                vec2 depthSize = vec2(textureSize(depthtex0, 0));
                vec2 sceneSize = vec2(textureSize(colortex0, 0));
                float ssilVis, ssilHit;
                vec3 indirect = ssilSample(viewPos, viewNormal, texcoord, dither,
                                           depthSize, sceneSize, ssilVis, ssilHit);

                vec3 hitAlbedo = max(texture(colortex11, texcoord).rgb, vec3(0.0));
                ssilValue = indirect * hitAlbedo * mix(0.35, 1.0, ssilVis);
                ssilTraced = 1.0;
        }
#endif
        ssilRaw = vec4(ssilValue, ssilTraced);

        vec3 ssrValue = vec3(0.0);
        float ssrConfidence = 0.0;
#if SSR_ENABLE == 1
        float opaqueDepth = texture(depthtex1, texcoord).r;
        if (sceneDepth < 1.0
            && sceneDepth <= opaqueDepth + 1.0e-5
            && texture(colortex9, texcoord).a <= 0.5) {
                float packedMaterial = texture(colortex11, texcoord).a;
                float matCode = ssrMaterialCode(packedMaterial);
                if (ssrIsReflectiveMaterial(matCode)) {
                        vec3 worldNormal = normalize(texture(colortex2, texcoord).rgb * 2.0 - 1.0);
                        vec3 viewPos = ssilScreenToView(texcoord, sceneDepth);
                        vec3 viewNormal = normalize(mat3(gbufferModelView) * worldNormal);
                        float roughness = ssrRoughness(matCode);
                        float dither = ssrDither(gl_FragCoord.xy);
                        vec4 refl = ssrTraceReflection(viewPos, viewNormal, roughness, dither);

                        vec3 albedo = max(texture(colortex11, texcoord).rgb, vec3(0.0));
                        vec3 f0 = ssrF0(albedo, matCode);
                        float NoV = clamp(dot(viewNormal, normalize(-viewPos)), 0.0, 1.0);
                        vec2 envBRDF = EnvBRDFApprox(roughness, NoV);
                        vec3 specularWeight = f0 * envBRDF.x + envBRDF.y;
                        ssrValue = refl.rgb * specularWeight * SSR_INTENSITY;
                        ssrConfidence = refl.a;
                }
        }
#endif
        ssrRaw = vec4(ssrValue, ssrConfidence);
}
