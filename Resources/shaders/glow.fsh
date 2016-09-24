// GLSL defines no random number generator. This
// generator takes a 2 dimensional seed and returns
// a one dimensional random number.
//https://github.com/mattruston/The-Beacon/blob/master/glow.fsh
float rand(vec2 seed) {
    return fract(sin(dot(seed, vec2(12.9898,78.233))) * 43758.5453);
}

void main ()
{
    // Apple provides a bunch of symbols that you would
    // normally have to compute yourself. You can find
    // these symbols in the SKShader reference:
    // https://developer.apple.com/library/ios/documentation/SpriteKit/Reference/SKShader_Ref/
    
    // Among these is v_tex_coord, which gives us a
    // normalized (in the range 0-1 per axis) coordinate
    // for sampling the texture.
    
    // u_texture is the texture of the currently
    // rendering SKSpriteNode.
    
    // texture2D returns the data from a sampler2D at
    // a specified normalized coordinate
    vec4 c = texture2D(u_texture, v_tex_coord);
    
    //if (c.a > 0.0) {
        // Try computing r everywhere it's needed and
        // note how dramatically performance decreases
        // Keep in mind that this code is running for
        // every cloud pixel
        //float r = rand(v_tex_coord);
        //c.rgb -= 0.0;
        //c.b = 0.5;  // More blue in output
        //c.r = 0.5;
        
        //c.a -= 0.1 * u_time;
//        if (mod(floor(u_time*0.2),2.0) == 1.0) {
//            float p = ((5.0 - mod(u_time,5.0))+1.0) * 0.1;
////            c.g = p;
////            c.r = p;
////            c.b = p;
//            c.a = p;
//        }else{
//            float p = (mod(u_time,5.0)+1.0) * 0.1;
////            c.g = p;
////            c.r = p;
////            c.b = p;
//            c.a = p;
//        }
//    }
    c.a = 0.0;
    
    // The sole responsibility of the shader is to write
    // a value to gl_FragColor.
    gl_FragColor = c;
}