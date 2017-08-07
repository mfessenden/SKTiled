
/*
void main() {

    // Find the pixel at the coordinate of the actual texture
    vec4 pixel = texture2D(u_texture, v_tex_coord);
    
    // epsilon 
    vec3 eps = vec3(0.009, 0.009, 0.009);

    if ( all( greaterThanEqual(pixel, vec4(transparentColor - eps, 1.0)) ) && all( lessThanEqual(pixel, vec4(transparentColor + eps, 1.0)) ) ) {
        gl_FragColor = vec4(0, 0, 0, 0);
        
    } else {
        gl_FragColor = vec4(pixel.r, pixel.g, pixel.b, pixel.a);
    }
}

*/


void main() {
    
    // Find the pixel at the coordinate of the actual texture
    vec4 val = texture2D(u_texture, v_tex_coord);
    
    // If replace white/black colors
    if (val.r == transparentColor.r && val.g == transparentColor.g && val.b == transparentColor.b) {
        gl_FragColor = vec4(0, 0, 0, 0);
        
    } else {
        // Otherwise, keep the original color
        gl_FragColor = val;
        
    }
}
