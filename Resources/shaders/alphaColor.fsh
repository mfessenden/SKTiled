
void main() {

    // Find the pixel at the coordinate of the actual texture
    vec4 val = texture2D(u_texture, v_tex_coord);
    
    // If the alpha value of that pixel is 0.0
    if (val.a == 0.0) {
    
        // Turn the pixel green
        gl_FragColor = vec4(0.0,1.0,0.0,1.0);
        
    } else {
    
        // Otherwise, keep the original color
        gl_FragColor = val;
        
    }
}
