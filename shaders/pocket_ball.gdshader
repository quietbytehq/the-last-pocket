shader_type spatial;
render_mode depth_test_disabled, depth_draw_never;
uniform sampler2D skin : source_color, filter_linear_mipmap;
uniform bool use_skin = true;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 mouth_center;
uniform vec2 mouth_radius;
uniform float bed_height = 0.82;
uniform float progress = 0.0;
varying float world_height;
void vertex(){ world_height=(MODEL_MATRIX*vec4(VERTEX,1.0)).y; }
void fragment(){
 float aperture=length((SCREEN_UV-mouth_center)/mouth_radius);
 float rim_mask=1.0-smoothstep(0.96,1.04,aperture);
 float below=1.0-smoothstep(bed_height-0.004,bed_height+0.004,world_height);
 float mask=mix(1.0,rim_mask,below);
 float darkness=1.0-smoothstep(0.26,0.93,progress);
 vec3 base=use_skin ? texture(skin,UV).rgb*tint.rgb : tint.rgb;
 ALBEDO=base*mix(0.015,1.0,darkness);
 ROUGHNESS=0.12;SPECULAR=0.65*darkness;
 // The base and reflection share one mask and one draw pass during descent.
 vec3 n=normalize(NORMAL);
 float panel=(1.0-smoothstep(0.11,0.16,abs(n.x+0.27)))*(1.0-smoothstep(0.10,0.15,abs(n.y-0.64)));
 float pane2=(1.0-smoothstep(0.045,0.075,abs(n.x-0.03)))*(1.0-smoothstep(0.08,0.12,abs(n.y-0.70)));
 EMISSION=vec3(panel*0.72+pane2*0.62)*darkness;
 ALPHA=mask*(1.0-smoothstep(0.88,1.0,progress));
}
