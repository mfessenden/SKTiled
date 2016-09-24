
void main( void ){
    lowp vec4 color = texture2D(u_texture, v_tex_coord);
    gl_FragColor = vec4(color.r, color.g, color.b, color.a);
}