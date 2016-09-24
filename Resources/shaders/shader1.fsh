// https://www.shadertoy.com/view/4lB3DG
//https://gist.github.com/veeneck/21d480aae49482975efe

void main() {
    vec4 val = texture2D(u_texture, v_tex_coord);
    vec4 grad = texture2D(u_gradient, v_tex_coord);
     
    if (val.a < 0.1 && grad.r < 0.65 && grad.a > 0.73) {
        vec2 u = gl_FragCoord.xy / u_sprite_size.xy,
        c = vec2(.5) - u;
     
        float t = u_time,
        z = atan(c.y,c.x) * 3.,
        v = cos(z + sin(t * .1)) + .5 + sin(u.x*10.+t*1.3) * .4;
     
        gl_FragColor = vec4(mix(
                                vec3(v, sin(v * 4.) * .5, sin(v * 2.) * .6),
                                vec3(.7 + cos(z - t*.2) + .5 + sin(u.y*10.+t*1.5) * .5),
                                vec3(1,.5,.5)
        ),1);
    } else {
        gl_FragColor = val;
    }
}
