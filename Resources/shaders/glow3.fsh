void main (){

    vec4 dst = texture2D(u_texture, v_tex_coord);
    vec4 src = texture2D(u_texture, v_tex_coord);
    //gl_FragColor = min(src + dst, 1.0);                           // strong result, high overexposure
    gl_FragColor = clamp((src + dst) - (src * dst), 0.0, 1.0);      // mild result, medium overexposure
    //gl_FragColor.w = 1.0;
}