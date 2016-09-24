




void main() {

    // white maze color
    vec3 replaceColor1 = vec3(0.87, 0.87, 1.0);

    vec3 mazeColor1 = vec3(0.129, 0.129, 1.0);
    vec3 mazeColor2 = vec3(0, 0, 0);

    // Find the pixel at the coordinate of the actual texture
    vec4 pixel = texture2D(u_texture, v_tex_coord);
    vec3 sample = vec3(pixel.r, pixel.g, pixel.b);
    // epsilon 
    vec3 eps = vec3(0.009, 0.009, 0.009);

    // If the alpha value of that pixel is 0.0
    //if (pixel.r == mazeColor1.r && pixel.g == mazeColor1.g && pixel.b == mazeColor1.b) {
    if ( all( greaterThanEqual(pixel, vec4(mazeColor1 - eps, 1.0)) ) && all( lessThanEqual(pixel, vec4(mazeColor1 + eps, 1.0)) ) ) {
        // flash color
        //pixel = vec4(replaceColor1, 1.0);
        gl_FragColor = replaceColor1;
        
    } else {
        // set transparent
        gl_FragColor = vec4(0, 0, 0, 0);
    }
}
