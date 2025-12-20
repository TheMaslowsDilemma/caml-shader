let name = "default_shader"

let source =
  {|
#include <metal_stdlib>
using namespace metal;

/*** These shapes are taken from Inigo Quilez articles ***/
float sdBoxFrame(float3 p, float3 b, float e )
{
    p = abs(p) - b;
    float3 q = abs(p + e) - e;
    return min(min(
        length(max(float3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
        length(max(float3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(float3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0)
    );
}

float sdSphere(float3 p, float s) {
    return length(p) - s;
}

float sdBox(float3 p, float3 b) {
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k)
{
    k *= log(2.0);
    float x = b-a;
    return a + x / ( 1.0 - exp2(x/k));
}

float map(float3 p) {
    // --- 1. SETTINGS / POSITIONS ---
    // Ground
    float3 groundPos  = float3(0, 2, 8);
    float3 groundSize = float3(10, 0.4, 10);
    
    // Cube Person (Body)
    float3 bodyPos    = float3(0, 1, 4); // Slightly above ground
    float3 bodySize   = float3(0.4, 0.75, 0.3);
    
    // Cube Person (Head)
    float3 headPos    = float3(0, 0, 4);  // Sitting on top of body
    float  headRadius = 0.4;
    
    // Box Frame
    float3 framePos   = float3(2.0, 1.0, 4); // To the side
    float3 frameSize  = float3(0.8, 1.0, 0.8);
    float  frameThick = 0.05;

    // --- 2. CALCULATE DISTANCES ---
    
    // Ground
    float ground = sdBox(p - groundPos, groundSize);
    
    // Person
    float body = sdBox(p - bodyPos, bodySize);
    float head = sdSphere(p - headPos, headRadius);
    float person = smin(body, head, 0.05); // Combine body and head
    
    // Frame
    float frame = sdBoxFrame(p - framePos, frameSize, frameThick);

    // --- 3. COMBINE ALL (UNION) ---
    return min(ground, min(person, frame));
}

/**
    https://iquilezles.org/articles/normalsSDF/

    NOTE: there are a few versions of the "calcNormal"
    all are described in the article by Inigo Quilezles
    1. hq: uses 6 calls to 
    2. mid: uses 4 calls
    3. low: uses 3 calls and assumes fp = 0
    4. Tetrahedron Technique found below
**/
float3 calcNormal(float3 p) {
    float h = 0.001;
    float2 k = float2(1, -1);
    return normalize(
        k.xyy * map(p + k.xyy * h) +
        k.yyx * map(p + k.yyx * h) +
        k.yxy * map(p + k.yxy * h) +
        k.xxx * map(p + k.xxx * h)
    );
}

float softshadow(float3 ro, float3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

float shadow(float3 ro, float3 rd, float mint, float maxt )
{
    float t = mint;
    for (int i = 0; i < 256 && t < maxt; i++)
    {
        float h = map(ro + rd*t);
        if (h < 0.001)
            return 0.0;
        t += h;
    }
    return 1.0;
}


kernel void default_shader(
    device    uchar4 *output [[buffer(0)]],
    constant uint2 &dims    [[buffer(1)]],
    constant uint2 &mouse   [[buffer(2)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= dims.x || gid.y >= dims.y) return;

    float2 mouse_pos = (float2(mouse) / float2(dims)) * 2.0 - 0.5;

    float2 uv = (float2(gid) / float2(dims)) * 2.0 - 1.0;
    uv.x *= float(dims.x) / float(dims.y);

    //*** Camera Direction and Origin ***//
    float3 ro = float3(mouse_pos.x * 3, mouse_pos.y * 3, -3);
    float3 rd = normalize(float3(uv, 1.5));

    float t = 0.0;
    float maxt = 25;
    float mint = 0.001;
    bool hit = false;
    float3 p;

    for (int i = 0; i < 100; i++) {
        p = ro + rd * t;
        float d = map(p);
        if (d < mint) {
            hit = true;
            break;
        }
        t += d;
        if (t > maxt) break;
    }

    float3 color = float3(0.1, 0.2, 0.5);
    if (hit) {
        float3 normal = calcNormal(p);
        float3 light_pos = float3(mouse_pos.x * 10, mouse_pos.y * 10, -2);

        float3 light_dir = normalize(light_pos - p);
        float dist_to_light = length(light_pos - p);

        float diff = max(dot(normal, light_dir), 0.0);

        float shade = softshadow(p + normal * 0.01, light_dir, 0.01, dist_to_light, 32);

        color = float3(0.4) * diff + 0.5 * shade;

    }

    uint index = gid.y * dims.x + gid.x;
    output[index] = uchar4(uchar3(clamp(color, 0.0, 1.0) * 255), 255);
}
|}
