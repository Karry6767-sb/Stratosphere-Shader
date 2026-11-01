#version 330 compatibility

/* RENDERTARGETS: 0,1,2 */

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
flat in float vegFlag;
flat in float materialId;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
        vec4 tex = texture(gtexture, texcoord) * glcolor;

        if (tex.a < alphaTestRef) {
                discard;
        }

        color = vec4(tex.rgb, 1.0);
        float matCode = 0.0;
        if (vegFlag > 0.5) matCode = 4.0;
        else if (materialId > 11999.5 && materialId < 12000.5) matCode = 1.0;
        else if (materialId > 12000.5 && materialId < 12001.5) matCode = 2.0;
        else if (materialId > 12001.5 && materialId < 12002.5) matCode = 3.0;
        else if (materialId > 12999.5 && materialId < 13000.5) matCode = 5.0;
        lightmapData = vec4(lmcoord, 0.0, 1.0);
        encodedNormal = vec4(normal * 0.5 + 0.5, vegFlag + matCode * 0.1);
}
