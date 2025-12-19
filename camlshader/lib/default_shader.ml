let name = "default_shader"

let source =
  {|
#include <metal_stdlib>
using namespace metal;

struct Ray {
    float3 origin;
    float3 direction;
};

struct Sphere {
    float3 center;
    float radius;
    float3 color;
    float shininess;   // Higher = smaller, sharper highlight
    float reflectivity; // 0.0 to 1.0
};

struct HitRecord {
    bool hit;
    float t;
    float3 normal;
    int sphere_index;
};

HitRecord intersect_sphere(Ray ray, Sphere s, int id) {
    HitRecord rec;
    rec.hit = false;
    float3 oc = ray.origin - s.center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - s.radius * s.radius;
    float discriminant = b * b - 4 * a * c;

    if (discriminant > 0) {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        if (t > 0.001) {
            rec.hit = true;
            rec.t = t;
            rec.normal = normalize((ray.origin + t * ray.direction) - s.center);
            rec.sphere_index = id;
        }
    }
    return rec;
}

// Helper to find the closest hit in the scene
HitRecord get_closest_hit(Ray ray, Sphere scene[3]) {
    HitRecord closest;
    closest.hit = false;
    float closest_t = 1e10;
    for (int i = 0; i < 3; i++) {
        HitRecord rec = intersect_sphere(ray, scene[i], i);
        if (rec.hit && rec.t < closest_t) {
            closest_t = rec.t;
            closest = rec;
        }
    }
    return closest;
}

kernel void default_shader(
    device    uchar4 *output [[buffer(0)]],
    constant uint2 &dims    [[buffer(1)]],
    constant uint2 &mouse   [[buffer(2)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= dims.x || gid.y >= dims.y) return;

    // 1. Scene Setup
    Sphere scene[3];
    scene[0] = {float3(0, 0, 4), 1.5, float3(0.7, 0.05, 0.05), 50.0, 0.4}; // Red
    scene[1] = {float3(2.5, 1, 6), 1.2, float3(0.05, 0.5, 0.05), 100.0, 0.2}; // Green
    scene[2] = {float3(-2.5, -1, 5), 1.0, float3(0.05, 0.05, 0.7), 200.0, 0.8}; // Blue (Shiny)

    float2 mouse_ndc = (float2(mouse) / float2(dims)) * 2.0 - 1.0;
    float3 light_pos = float3(mouse_ndc.x * 10.0, -mouse_ndc.y * 10.0, 0.0);

    float2 uv = (float2(gid) / float2(dims)) * 2.0 - 1.0;
    uv.x *= float(dims.x) / float(dims.y);
    Ray ray = { float3(0, 0, -2), normalize(float3(uv, 1.5)) };

    float3 final_color = float3(0.05, 0.07, 0.1); // Background color
    float reflection_weight = 1.0;

    // 2. Ray Bouncing (2 Iterations for Reflection)
    for (int bounce = 0; bounce < 5; bounce++) {
        HitRecord hit = get_closest_hit(ray, scene);
        if (!hit.hit) break;

        Sphere s = scene[hit.sphere_index];
        float3 hit_point = ray.origin + hit.t * ray.direction;
        float3 L = normalize(light_pos - hit_point);
        float3 V = -ray.direction;
        float3 H = normalize(L + V); // Half-way vector for Blinn-Phong

        // --- Shadow Ray ---
        Ray shadow_ray = { hit_point, L };
        HitRecord shadow_hit = get_closest_hit(shadow_ray, scene);
        bool in_shadow = shadow_hit.hit && (shadow_hit.t < length(light_pos - hit_point));

        // --- Shading Calculation ---
        float3 ambient = s.color * 0.1;
        float3 diffuse = 0.0;
        float3 specular = 0.0;

        if (!in_shadow) {
            diffuse = s.color * max(dot(hit.normal, L), 0.0);
            specular = float3(1.0) * pow(max(dot(hit.normal, H), 0.0), s.shininess);
        }

        float3 local_color = ambient + diffuse + specular;
        
        // Accumulate color based on reflection weight
        final_color += local_color * reflection_weight * (1.0 - s.reflectivity);
        
        // Prepare next ray (reflection)
        reflection_weight *= s.reflectivity;
        if (reflection_weight < 0.05) break; 

        ray.origin = hit_point;
        ray.direction = reflect(ray.direction, hit.normal);
    }

    uint index = gid.y * dims.x + gid.x;
    output[index] = uchar4(uchar3(clamp(final_color, 0.0, 1.0) * 255), 255);
}
|}
