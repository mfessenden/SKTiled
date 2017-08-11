
// snap to the nearest pixel
vec2 nearest(vec2 pos) {
    vec2 snapped = floor(pos - 0.5) + 0.5;
    return (snapped + step(0.5, pos - snapped));
}


// translates a normalized uv into a normalized uv that has been snapped
vec2 nearest_uv(vec2 uv, vec2 size) {
    return nearest(uv * size) / size;
}


void main() {
    //vec4 transColor;
    
    // Find the pixel at the coordinate of the actual texture
    //vec4 val = texture2D(u_texture, v_tex_coord);
    
    // sample the color from a snapped uv position
    vec4 val = texture2D(u_texture, nearest_uv(v_tex_coord, u_sprite_size));
    
    // if matching the trans color, knock it out
    if (val.r == transColor.r && val.b == transColor.b && val.g == transColor.g) {
        gl_FragColor = vec4(0.0,0.0,0.0,0.0);
    } else {
        // Otherwise, keep the original color
        gl_FragColor = val;
        
    }
}
