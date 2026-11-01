#ifndef LIB_REPROJECTION_GLSL
#define LIB_REPROJECTION_GLSL

vec2 TAA_Reprojection(vec3 pos) {
    pos = pos * 2.0 - 1.0;
    vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
    viewPosPrev /= max(viewPosPrev.w, 1e-6);
    viewPosPrev = gbufferModelViewInverse * viewPosPrev;

    vec3 cameraOffset = (pos.z > 0.56)
        ? (cameraPosition - previousCameraPosition)
        : vec3(0.0);

    vec4 previousPosition = gbufferPreviousProjection * gbufferPreviousModelView
                            * (viewPosPrev + vec4(cameraOffset, 0.0));
    return (previousPosition.xy / max(previousPosition.w, 1e-6)) * 0.5 + 0.5;
}

#endif
