#version 430 compatibility

/* RENDERTARGETS: 8 */

#include "/lib/options_defaults.glsl"

#include "/lib/bloom_new.glsl"

uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;

layout(rgba16f) uniform image2D uimg_bloom;

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
    vec2 fullSize = max(vec2(viewWidth, viewHeight), vec2(1.0));
    vec4 r = bloomMipRect(0, fullSize);

    ivec2 p = ivec2(floor(gl_FragCoord.xy * 0.5));
    if (p.x >= 0 && p.y >= 0 && p.x < int(r.z) && p.y < int(r.w)) {
        vec2 uv = (vec2(p) + 0.5) / r.zw;
        vec3 sceneTap = downsample13(colortex3, uv, vec2(1.0) / fullSize);
        vec3 c = bloomPrefilter(sceneTap) * bloomMipWeight(0);
        float lowFreqLuma = dot(max(sceneTap, vec3(0.0)), BLOOM_LUMA_709);
        ivec2 dst = ivec2(r.xy) + p;
        imageStore(uimg_bloom, dst, vec4(c, lowFreqLuma));
    }

    color = vec4(0.0, 0.0, 0.0, 1.0);
}
