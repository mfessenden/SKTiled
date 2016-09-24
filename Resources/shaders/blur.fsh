// http://www.idevgames.com/forums/thread-3010.html
// A simple blur shader, weighted on alpha

//uniform sampler2D texture;

void main() {
    float radius = 0.01;
    vec4 accum = vec4(0.0);
    vec4 normal = vec4(0.0);
    
    
    vec4 texture = texture2D(u_texture, v_tex_coord);
    vec4 val = texture2D(u_texture, v_tex_coord);
    
    normal = texture2D(texture, vec2(gl_TexCoord[0].s, gl_TexCoord[0].t));
    
    accum += texture2D(texture, vec2(gl_TexCoord[0].s-radius, gl_TexCoord[0].t-radius));
    accum += texture2D(texture, vec2(gl_TexCoord[0].s+radius, gl_TexCoord[0].t-radius));
    accum += texture2D(texture, vec2(gl_TexCoord[0].s+radius, gl_TexCoord[0].t+radius));
    accum += texture2D(texture, vec2(gl_TexCoord[0].s-radius, gl_TexCoord[0].t+radius));
    
    accum *= 0.25;
    
    accum.r = 1.0;
    accum.g = 0.0;
    accum.b = 0.0;
    
    normal = (accum * (1.0 - normal.a)) + (normal * normal.a);
    
    gl_FragColor = normal;
}
