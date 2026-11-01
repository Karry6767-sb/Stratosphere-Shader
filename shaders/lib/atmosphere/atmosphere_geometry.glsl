// Based on Hillaire 2020, "A Scalable and Production Ready Sky and Atmosphere Rendering Technique".

#ifndef ATM_SUN_ANGULAR_RADIUS
#define ATM_SUN_ANGULAR_RADIUS 0.00465116
#endif

#ifndef PI
#define PI 3.14159265358979323846
#endif

#ifndef LIB_ATMOSPHERE_ATMOSPHERE_GEOMETRY_GLSL
#define LIB_ATMOSPHERE_ATMOSPHERE_GEOMETRY_GLSL

#ifndef CAMERA_POSITION_DECLARED
uniform vec3 cameraPosition;
#define CAMERA_POSITION_DECLARED
#endif

const float ATM_PLANET_R  = 6360.0;
const float ATM_ATMO_R    = 6480.0;
const float ATM_PLANET_R2 = ATM_PLANET_R * ATM_PLANET_R;
const float ATM_ATMO_R2   = ATM_ATMO_R * ATM_ATMO_R;

const float ATM_SEA_LEVEL = -200.0;
const float ATM_M_TO_KM   = 0.001;

float atmLinearstep(float a, float b, float x) {
    float d = b - a;
    d = (abs(d) < 1.0e-6) ? 1.0e-6 : d;
    return clamp((x - a) / d, 0.0, 1.0);
}

float AtmosphereCameraAltitude() {
    return (cameraPosition.y - ATM_SEA_LEVEL) * ATM_M_TO_KM;
}

vec3 AtmosphereCameraPosition() {
    return vec3(0.0, ATM_PLANET_R + AtmosphereCameraAltitude(), 0.0);
}

bool RayIntersectSphere(vec3 origin, vec3 dir, float radius, out float t0, out float t1) {
    float b = dot(origin, dir);
    float c = dot(origin, origin) - radius * radius;
    float disc = b * b - c;
    if (disc <= 0.0) return false;
    float root = sqrt(disc);
    t0 = -b - root;
    t1 = -b + root;
    return true;
}

float atmRaySphereNearest(vec3 origin, vec3 dir, float radius) {
    float b = dot(origin, dir);
    float c = dot(origin, origin) - radius * radius;
    float disc = b * b - c;
    if (disc < 0.0) return -1.0;
    float root = sqrt(max(disc, 0.0));
    float t0 = -b - root;
    float t1 = -b + root;
    if (t1 < 0.0) return -1.0;
    return (t0 >= 0.0) ? t0 : t1;
}

bool RayHitPlanet(vec3 origin, vec3 dir, out float tHit) {
    float t = atmRaySphereNearest(origin, dir, ATM_PLANET_R);
    if (t > 0.0) { tHit = t; return true; }
    return false;
}

bool atmSetupRay(vec3 origin, vec3 dir, out float tMax, out bool groundHit) {
    groundHit = false;
    float tAtmo = atmRaySphereNearest(origin, dir, ATM_ATMO_R);
    float tGround = atmRaySphereNearest(origin, dir, ATM_PLANET_R);
    if (tAtmo <= 0.0) { tMax = 0.0; return false; }
    if (tGround > 0.0 && tGround < tAtmo) {
        groundHit = true;
        tMax = tGround;
    } else {
        tMax = tAtmo;
    }
    return tMax > 0.0;
}

#endif
