let name = "default_shader"

let source =
  {|
#include <metal_stdlib>
using namespace metal;

kernel void default_shader(
  device   uchar4 *output [[buffer(0)]],
  constant uint2 &dims    [[buffer(1)]],
  constant uint2 &mouse   [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= dims.x || gid.y >= dims.y) return;

    uint index = gid.y * dims.x + gid.x;

    float2 gid_f = float2(gid);
    float2 dims_f = float2(dims);
    float2 mouse_f = float2(mouse);

    float2 uv = gid_f / dims_f;
    float2 pq = (mouse_f / dims_f) + float2(0.5); 

    
    float rval = dot(uv * uv * uv, pq * pq * pq);
    uchar r = rval < 0.4 ? uchar(rval * 150) : 0;
    uchar b = uchar(dot(uv * pq , pq) * 150);

    output[index] = uchar4(r, 0, b, 255);
}
|}
