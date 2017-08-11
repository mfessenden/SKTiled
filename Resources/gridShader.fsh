// https://github.com/h6294443/2DFDTD-CUDA-Hexagons-VBO/blob/master/grid.cpp

// tilemap orientation
const uint Orthogonal    = 0x00000001u;
const uint Isometric     = 0x00000002u;
const uint Staggered     = 0x00000004u;
const uint Hexagonal     = 0x00000008u;

// tilemap dimensions
uniform uint size_w;
uniform uint size_h;

uniform uint tilesize_w;
uniform uint tilesize_h;
uniform uint hex_tilesize_l;

// stagger settings
uniform bool stagger_x;
uniform bool stagger_even;


uniform float time;


// 1 on edges, 0 in middle
float hex(vec2 p) {
    p.x *= 0.57735*2.0;
    p.y += mod(floor(p.x), 2.0)*0.5;
    p = abs((mod(p, 1.0) - 0.5));
    return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}

void main(void) {
    vec2 pos = gl_FragCoord.xy;
    vec2 p = pos/20.0;
    float  r = (1.0 -0.7)*0.5;
    gl_FragColor = vec4(smoothstep(0.0, r + 0.05, hex(p)));
}
