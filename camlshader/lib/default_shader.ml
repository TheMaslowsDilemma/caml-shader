let name = "default_shader"

let source =
  {|
#include <metal_stdlib>
using namespace metal;

kernel void default_shader(device uchar4 *output [[buffer(0)]],
                         constant uint3 &dims [[buffer(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= dims.x || gid.y >= dims.y) return;

    uint index = gid.y * dims.x + gid.x;
    float2 xy = float2(gid);
    float2 uv = xy / float2(dims.x, dims.y);
    
    float red = length(uv - float2(0.5));
    uchar r = (red > sin(float(dims.z) / 1000 )) ? 0 : 200;
    
    output[index] = uchar4(r, 0, 0, 255);
}
|}
