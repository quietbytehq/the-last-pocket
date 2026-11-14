shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float phase = 0.0;
void fragment(){
 float wave=pow(0.5+0.5*cos(UV.x*18.0-phase),4.0);
 if(UV.x<0.0)wave=0.5+0.5*sin(phase*1.3);
 ALBEDO=mix(COLOR.rgb*0.78,vec3(1.0,0.98,0.83),wave);
 ALPHA=COLOR.a*(0.82+0.18*wave);
}
