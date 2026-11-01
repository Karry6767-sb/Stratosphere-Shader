#ifndef LIB_SHADOW_SCENE_GLSL
#define LIB_SHADOW_SCENE_GLSL

#include "/lib/shadow_matrix.glsl"
#include "/lib/celestial/light_state.glsl"

vec3 SceneSunDirW()  { return normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition)); }
vec3 SceneMoonDirW() { return MoonDirection(SceneSunDirW(), moonPhase, worldDay); }

float SceneMoonExposure() {
    return MoonLightExposure(MoonIllumination(moonPhase));
}

bool SceneActiveIsSun() {
    return CelestialActiveIsSun(SceneSunDirW(), SceneMoonDirW(), moonPhase);
}

vec3 SceneActiveLightDirW() {
    return CelestialActiveDirW(SceneSunDirW(), SceneMoonDirW(), moonPhase);
}

mat3 SceneShadowRotation() {
    return ShadowRotationFromActiveLight(SceneSunDirW(), SceneMoonDirW(), moonPhase);
}

mat4 SceneShadowModelView() {
    return shadowModelView * mat4(SceneShadowRotation());
}

#endif
