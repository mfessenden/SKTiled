void main(void){
    float currTime = u_time;
    
    vec2 uv = v_tex_coord;
    vec2 circleCenter = vec2(0.5, 0.5);
    vec3 circleColor = vec3(0.8, 0.5, 0.7);
    vec3 posColor = vec3(uv, 0.5 + 0.5 * sin(currTime)) * circleColor;
    
    float illu = pow(1. - distance(uv, circleCenter), 4.) * 1.2;
    illu *= (2. + abs(0.4 + cos(currTime * -20. + 50. * distance(uv, circleCenter)) / 1.5));
    gl_FragColor = vec4(posColor * illu * 2., illu * 2.) * v_color_mix.a;
}