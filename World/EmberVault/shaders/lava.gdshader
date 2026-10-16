shader_type spatial;
render_mode cull_disabled;
uniform vec4 crust_color : source_color = vec4(0.28,0.055,0.022,1.0);
uniform vec4 lava_color : source_color = vec4(1.0,0.24,0.025,1.0);
uniform vec4 hot_color : source_color = vec4(1.0,0.78,0.19,1.0);
uniform float flow_speed = 0.18;
varying vec2 local_xz;
void vertex(){local_xz=VERTEX.xz;}
void fragment(){
 vec2 p=local_xz*1.1;
 float t=TIME*flow_speed;
 p += vec2(sin(p.y*1.3+t),cos(p.x*1.1-t))*0.26;
 float ribbons=sin(p.x*2.0+p.y*0.7+t)+sin(p.y*2.4-p.x*0.5-t*1.2)+sin(p.x*1.2-p.y*1.8+t*0.5);
 float heat=smoothstep(-0.55,0.9,ribbons);
 float core=smoothstep(1.5,2.6,ribbons);
 vec3 c=mix(crust_color.rgb,lava_color.rgb,heat);
 c=mix(c,hot_color.rgb,core);
 ALBEDO=c; EMISSION=c*(0.35+heat*0.65); ROUGHNESS=0.85;
}
