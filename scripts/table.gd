extends Node3D
const BED := 0.82
var room_environment: Environment
var guide_dots: Array=[]
var guide_phase=0.0
var placement_ring: MeshInstance3D
var geometry: Node3D
var actors: Node3D
var camera: Camera3D
var cue: Node3D
var guide: MeshInstance3D
var ball_nodes: Dictionary={}
var ball_materials: Dictionary={}
var sink_materials: Dictionary={}
var ball_poses: Dictionary={}
var shadow_nodes: Dictionary={}
var sim
var rules
var cloth: Material
var wood: StandardMaterial3D
var leather: StandardMaterial3D
var metal: StandardMaterial3D
var colours: Array[Color]=[Color("f7f4e4"),Color("e9ac06"),Color("084494"),Color("b71b20"),Color("642384"),Color("e06e06"),Color("06634b"),Color("681c24"),Color("111316"),Color("e9ac06"),Color("084494"),Color("b71b20"),Color("642384"),Color("e06e06"),Color("06634b"),Color("681c24"),Color("e7ba17")]
var elevated_view = true
var upgrade=0
var baked_table=false
var warm_ball: MeshInstance3D
var shared_glint: ShaderMaterial
var edge_filter: ColorRect
var guide_cached=false
var guide_origin=Vector2.ZERO
var guide_direction=Vector2.ZERO
var cloth_colour = Color(0.12,0.68,0.46)

func _ready() -> void:
 _room()
 _make_edge_filter()
 camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=38;camera.near=0.02;camera.far=45
 camera.set_cull_mask_value(2,false)
 guide=MeshInstance3D.new();add_child(guide);guide.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var line_mat=ShaderMaterial.new();line_mat.shader=load("res://shaders/aim_guide.gdshader");guide.material_override=line_mat
 wood=_material(Color(0.62,0.53,0.43),0.48,0.0,"walnut.png")
 wood.uv1_triplanar=true;wood.uv1_world_triplanar=true;wood.uv1_scale=Vector3.ONE*1.3
 leather=_material(Color(0.14,0.15,0.16),0.7,0.0,"leather.png")
 metal=_material(Color("a59d8e"),0.3,0.8,"metal.png")

func _material(color: Color,rough: float,metallic: float=0.0,texture_name: String="") -> StandardMaterial3D:
 var m =StandardMaterial3D.new();m.albedo_color=color;m.roughness=rough;m.metallic=metallic
 m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 var path ="res://assets/materials/"+texture_name
 if texture_name!="" and ResourceLoader.exists(path): m.albedo_texture=load(path)
 return m

func _room() -> void:
 var world =WorldEnvironment.new();add_child(world)
 var env =Environment.new();world.environment=env;room_environment=env
 env.background_mode=Environment.BG_SKY;env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY;env.ambient_light_energy=0.38
 env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.tonemap_exposure=1.0
 var panorama =Image.create(1024,512,false,Image.FORMAT_RGBAF);panorama.fill(Color(0.11,0.095,0.075))
 panorama.fill_rect(Rect2i(0,280,1024,232),Color(0.04,0.09,0.07))
 for x in [120,480,840]:
  panorama.fill_rect(Rect2i(x-65,114,130,34),Color(1.1,1.05,0.94))
  panorama.fill_rect(Rect2i(x-56,120,112,22),Color(2.8,2.7,2.5))
 var sky_mat =PanoramaSkyMaterial.new();sky_mat.panorama=ImageTexture.create_from_image(panorama)
 var sky =Sky.new();sky.sky_material=sky_mat;env.sky=sky
 var key =DirectionalLight3D.new();add_child(key);key.rotation_degrees=Vector3(-75,-25,0);key.light_color=Color("fff3dc");key.light_energy=0.75;key.shadow_enabled=true;key.directional_shadow_max_distance=7;key.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;key.shadow_blur=1.8
 var fill =OmniLight3D.new();add_child(fill);fill.position=Vector3(0,3.8,-0.7);fill.omni_range=9;fill.light_energy=0.6;fill.light_color=Color("ecf4ff")
 var floor_mat =StandardMaterial3D.new();floor_mat.albedo_color=Color("30241c");floor_mat.roughness=0.5
 var floor_mesh =PlaneMesh.new();floor_mesh.size=Vector2(18,18)
 var floor_node =MeshInstance3D.new();floor_node.mesh=floor_mesh;floor_node.material_override=floor_mat;floor_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(floor_node)
 # One shared floor surface avoids one draw call per distant board.
 var boards=_material(Color(0.15,0.10,0.07),0.6,0.0,"walnut.png")
 boards.uv1_scale=Vector3(3,6,1)
 _box(self,Vector3(10,0.014,7.5),Vector3(0,0.008,0),boards).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var carpet =_material(Color("010605"),0.95,0.0,"felt.png")
 _box(self,Vector3(5.4,0.018,3.5),Vector3(0,0.023,0),carpet).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func configure(physics,game_rules) -> void:
 guide_cached=false
 sim=physics;rules=game_rules
 if is_instance_valid(geometry): geometry.free()
 if is_instance_valid(actors): actors.free()
 baked_table=sim.pocketed_table
 room_environment.background_mode=Environment.BG_COLOR if baked_table else Environment.BG_SKY
 room_environment.background_color=Color.BLACK
 room_environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
 for child in get_children():
  if child is MeshInstance3D:child.visible=not baked_table
 geometry=Node3D.new();add_child(geometry)
 actors=Node3D.new();add_child(actors);ball_nodes.clear();ball_poses.clear();shadow_nodes.clear();ball_materials.clear();sink_materials.clear()
 var h: Vector2=sim.half_size
 if baked_table:
  _baked_background(h)
  if rules.is_snooker():_markings(h)
  for b in sim.balls:_add_ball(b)
  _make_cue();_position_camera();sync(0)
  return
 var apron =_material(Color("0b1012"),0.76)
 _box(geometry,Vector3(h.x*2+0.37,0.24,h.y*2+0.37),Vector3(0,BED-0.18,0),apron)
 _box(geometry,Vector3(h.x*2+0.39,0.018,h.y*2+0.39),Vector3(0,BED-0.30,0),metal)
 for x in [-1,1]:
  for z in [-1,1]:
   var leg =_cylinder(geometry,0.07,0.12,0.53,Vector3(x*(h.x-0.13),0.30,z*(h.y-0.14)),apron)
   leg.rotation.z=x*0.04
   _cylinder(geometry,0.12,0.12,0.025,Vector3(x*(h.x-0.11),0.055,z*(h.y-0.14)),metal)
 _make_cloth(h)
 var cushion: ShaderMaterial=cloth.duplicate()
 cushion.set_shader_parameter("has_pockets",false)
 var rail_y =BED+0.025
 for z in [-1,1]:
  if sim.pocketed_table:
   for side in [-1,1]:
    var len_x =h.x-sim.pocket_radius*2.24
    _box(geometry,Vector3(len_x,0.038,0.060),Vector3(side*h.x*0.5,BED+0.020,z*(h.y+0.055)),cushion)
  else:
   _box(geometry,Vector3(h.x*2+0.02,0.038,0.060),Vector3(0,BED+0.020,z*(h.y+0.055)),cushion)
  for i in [-3,-2,-1,1,2,3]:
   _cylinder(geometry,0.006,0.006,0.0015,Vector3(i*h.x/4.0,BED+0.0503,z*(h.y+0.095)),_material(Color("d2c29b"),0.3,0.25),4).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for x in [-1,1]:
  var len_z =h.y*2-(sim.pocket_radius*2.24 if sim.pocketed_table else -0.02)
  _box(geometry,Vector3(0.060,0.038,len_z),Vector3(x*(h.x+0.055),BED+0.020,0),cushion)
  for z in [-1,0,1]: _cylinder(geometry,0.006,0.006,0.0015,Vector3(x*(h.x+0.10),BED+0.0503,z*h.y*0.5),_material(Color("d2c29b"),0.3,0.25),4).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if sim.pocketed_table:
  for p in sim.pockets():
   var pit_material=_material(Color("010202"),1.0)
   pit_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
   _cylinder(geometry,sim.pocket_radius*1.13,sim.pocket_radius*0.8,0.12,Vector3(p.x,BED-0.072,p.y),pit_material).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   var rim =TorusMesh.new();rim.inner_radius=sim.pocket_radius*1.02;rim.outer_radius=sim.pocket_radius*1.18;rim.rings=32;rim.ring_segments=10
   var rn =MeshInstance3D.new();rn.mesh=rim;rn.material_override=leather;rn.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;rn.position=Vector3(p.x,BED+0.007,p.y);geometry.add_child(rn)
 _cushion_noses(h,cushion)
 _carved_frame(h)
 _markings(h)
 for b in sim.balls: _add_ball(b)
 _make_cue()
 _position_camera()
 sync(0.0)

func _make_cloth(h: Vector2) -> void:
 var shader =Shader.new()
 shader.code="""shader_type spatial;
uniform sampler2D felt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 half_size;
uniform bool has_pockets = true;
uniform float pocket_radius = 0.067;
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 p=world_position.xz;
 if(has_pockets){
  if(distance(p,vec2(-half_size.x,-half_size.y))<pocket_radius || distance(p,vec2(half_size.x,-half_size.y))<pocket_radius || distance(p,vec2(-half_size.x,half_size.y))<pocket_radius || distance(p,vec2(half_size.x,half_size.y))<pocket_radius || distance(p,vec2(0.0,half_size.y))<pocket_radius || distance(p,vec2(0.0,-half_size.y))<pocket_radius) discard;
 }
 vec3 tex=texture(felt,UV*vec2(14.0,7.0)).rgb;
 float weave=dot(tex,vec3(0.2126,0.7152,0.0722));
 ALBEDO=weave*vec3(0.09,0.85,0.32); ROUGHNESS=0.91; SPECULAR=0.16;
}
"""
 var material =ShaderMaterial.new();material.shader=shader
 if ResourceLoader.exists("res://assets/materials/felt.png"): material.set_shader_parameter("felt",load("res://assets/materials/felt.png"))
 material.set_shader_parameter("half_size",h);material.set_shader_parameter("has_pockets",sim.pocketed_table);material.set_shader_parameter("pocket_radius",sim.pocket_radius)
 var plane =PlaneMesh.new();plane.size=h*2
 var node =MeshInstance3D.new();node.mesh=plane;node.material_override=material;node.position.y=BED;geometry.add_child(node);cloth=material

func _markings(h: Vector2) -> void:
 var mat =StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(0.75,0.78,0.62,0.35);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 var mesh =ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat)
 if rules.is_snooker():
  var x: float=-h.x*0.58
  mesh.surface_add_vertex(Vector3(x,BED+0.0005,-h.y));mesh.surface_add_vertex(Vector3(x,BED+0.0005,h.y))
  for i in range(64):
   var a =PI/2+PI*i/64.0;var b =PI/2+PI*(i+1)/64.0
   mesh.surface_add_vertex(Vector3(x+cos(a)*h.y*0.35,BED+0.0006,sin(a)*h.y*0.35))
   mesh.surface_add_vertex(Vector3(x+cos(b)*h.y*0.35,BED+0.0006,sin(b)*h.y*0.35))
 else:
  for x in [-h.x*0.5,h.x*0.5]:
   mesh.surface_add_vertex(Vector3(x-0.005,BED+0.0005,0));mesh.surface_add_vertex(Vector3(x+0.005,BED+0.0005,0))
 mesh.surface_end();var marks =MeshInstance3D.new();marks.mesh=mesh;marks.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;geometry.add_child(marks)

func _glint_material() -> ShaderMaterial:
 if shared_glint!=null:return shared_glint
 var glint=ShaderMaterial.new();var glint_shader=Shader.new()
 glint_shader.code="""shader_type spatial; render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
void fragment(){
 vec3 n=normalize(NORMAL);
 float panel=(1.0-smoothstep(0.11,0.16,abs(n.x+0.27)))*(1.0-smoothstep(0.10,0.15,abs(n.y-0.64)));
 float pane2=(1.0-smoothstep(0.045,0.075,abs(n.x-0.03)))*(1.0-smoothstep(0.08,0.12,abs(n.y-0.70)));
 float glow=pow(max(0.0,dot(n,normalize(vec3(-0.3,0.6,0.8)))),28.0);
 ALBEDO=vec3(panel*0.72+pane2*0.62+glow*0.15);
}
"""
 glint.shader=glint_shader;shared_glint=glint
 return glint

func _add_ball(b: Dictionary) -> void:
 var node =MeshInstance3D.new();var sphere =SphereMesh.new();sphere.radius=sim.radius;sphere.height=sim.radius*2;sphere.radial_segments=40;sphere.rings=20;node.mesh=sphere
 var col =ball_colour(b.id)
 var mat =_material(col,0.12);mat.metallic_specular=0.65;mat.clearcoat_enabled=true;mat.clearcoat=0.45;mat.clearcoat_roughness=0.10
 var path ="res://assets/balls/pool_%02d.png" % b.id
 if not rules.is_snooker() and not rules.is_carom() and rules.mode!=4 and ResourceLoader.exists(path):
  mat.albedo_color=Color.WHITE;mat.albedo_texture=load(path)
 mat.next_pass=_glint_material()
 node.material_override=mat;actors.add_child(node);ball_nodes[b.id]=node;ball_materials[b.id]=mat
 var sink=ShaderMaterial.new();sink.shader=load("res://shaders/pocket_ball.gdshader")
 sink.set_shader_parameter("skin",mat.albedo_texture if mat.albedo_texture!=null else load("res://assets/balls/pool_00.png"))
 sink.set_shader_parameter("use_skin",mat.albedo_texture!=null)
 sink.set_shader_parameter("tint",mat.albedo_color)
 sink_materials[b.id]=sink
 var base=Quaternion(Vector3.UP,-PI/2)*Quaternion(Vector3.BACK,PI/2)
 if baked_table:
  var angle=acos(clampf((573.0/1344.0)*(sim.half_size.x/sim.half_size.y),0.5,0.99))
  var facing=Quaternion(Vector3.RIGHT,angle)
  var roll=Quaternion(Vector3(0,cos(angle),sin(angle)),float((b.id*7)%9-4)*0.10)
  base=roll*facing*base
 ball_poses[b.id]=base
 # A soft contact patch survives lower shadow settings without hard black blobs.
 var sm =ShaderMaterial.new();var sh =Shader.new();sh.code="""shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never;
void fragment(){float r=length(UV-vec2(0.5))*2.0;ALBEDO=vec3(0.005);ALPHA=exp(-r*r*3.4)*0.68*(1.0-smoothstep(0.8,1.0,r));}""";sm.shader=sh
 var patch =MeshInstance3D.new();var pm =PlaneMesh.new();pm.size=Vector2.ONE*sim.radius*3.4;patch.mesh=pm;patch.material_override=sm;patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;actors.add_child(patch);shadow_nodes[b.id]=patch

func ball_colour(id: int) -> Color:
 if rules.is_snooker():
  if id>=100: return Color("ae1724")
  return {0:Color("f5f1dc"),2:Color("e1be12"),3:Color("0b683f"),4:Color("704121"),5:Color("164b9d"),6:Color("d87298"),7:Color("101214")}.get(id,Color.WHITE)
 if rules.mode==4:
  if id==0: return colours[0]
  if id==8: return colours[8]
  return Color("ba1920") if id<8 else Color("e8bb0e")
 return colours[clampi(id,0,16)]

func _make_cue() -> void:
 cue=Node3D.new();actors.add_child(cue)
 placement_ring=MeshInstance3D.new();actors.add_child(placement_ring)
 var placement_mesh=TorusMesh.new();placement_mesh.inner_radius=sim.radius*1.12;placement_mesh.outer_radius=sim.radius*1.25;placement_mesh.rings=40;placement_mesh.ring_segments=8
 placement_ring.mesh=placement_mesh;placement_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var ring_material=StandardMaterial3D.new();ring_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 placement_ring.material_override=ring_material;placement_ring.visible=false
 var maple =_material([Color("ac8e59"),Color("d6bc88"),Color("d8b77c"),Color("e5d2a3")][clampi(upgrade,0,3)],0.36)
 var handle=_material([Color("69412b"),Color("152d33"),Color("572333"),Color("10141d")][clampi(upgrade,0,3)],0.26,0.15 if upgrade>0 else 0.0)
 var shaft =_cylinder(cue,0.005,0.010,1.28,Vector3(0,0,0.75),maple);shaft.rotation.x=PI/2
 var butt =_cylinder(cue,0.010,0.014,0.38,Vector3(0,0,1.52),handle);butt.rotation.x=PI/2
 if upgrade>0:
  for index in range(upgrade+1):
   var ring=_cylinder(cue,0.011,0.011,0.007,Vector3(0,0,1.32+index*0.025),_material(Color("c5a768"),0.20,0.8));ring.rotation.x=PI/2
 var ferrule =_cylinder(cue,0.005,0.005,0.022,Vector3(0,0,0.097),_material(Color("eae7d4"),0.28));ferrule.rotation.x=PI/2
 var tip =_cylinder(cue,0.0052,0.0052,0.008,Vector3(0,0,0.081),_material(Color("639eae"),0.85));tip.rotation.x=PI/2

func _baked_background(h: Vector2) -> void:
 # The photographic plate is static; all balls, the cue, guide, scoring and
 # input remain live. Its pocket centres define the physical projection.
 var mesh=PlaneMesh.new()
 var width=h.x*2.0/(1344.0/1672.0)
 var cosine=(573.0/1344.0)*(h.x/h.y)
 mesh.size=Vector2(width,width/(1672.0/941.0)/cosine)
 var material=StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_texture=load("res://assets/table/club-table-v2.png" if upgrade==0 else "res://assets/table/tier_%d.png" % upgrade)
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=material
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 node.position=Vector3(0,BED-0.001,-6.0/573.0*h.y*2.0-sim.radius*tan(acos(cosine)));geometry.add_child(node)

func _position_camera() -> void:
 if sim==null:return
 var aspect=get_viewport().get_visible_rect().size.aspect()
 if baked_table:
  camera.projection=Camera3D.PROJECTION_ORTHOGONAL
  var width=sim.half_size.x*2.0/(1344.0/1672.0)
  var cosine=clampf((573.0/1344.0)*(sim.half_size.x/sim.half_size.y),0.5,0.99)
  var angle=acos(cosine)
  camera.size=width/(1672.0/941.0)*maxf(1.0,(1672.0/941.0)/aspect)
  var target=Vector3(0,BED+sim.radius,-6.0/573.0*sim.half_size.y*2.0)
  camera.position=target+Vector3(0,3.0*cos(angle),3.0*sin(angle))
  camera.look_at(target,Vector3.UP)
  return
 camera.projection=Camera3D.PROJECTION_PERSPECTIVE
 var length: float=sim.half_size.x*2.0
 var dist: float=length*1.06/maxf(1.0,aspect/1.65)
 camera.position=Vector3(0,BED+dist*(1.12 if elevated_view else 0.74),dist*(0.35 if elevated_view else 0.84))
 camera.look_at(Vector3(0,BED-0.04,0),Vector3.UP)

func prewarm_pocket_shader() -> void:
 if not is_instance_valid(warm_ball):
  warm_ball=MeshInstance3D.new();warm_ball.mesh=ball_nodes[rules.cue_id()].mesh
  warm_ball.material_override=sink_materials[rules.cue_id()]
  warm_ball.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  warm_ball.position=Vector3(0,BED+sim.radius,0);actors.add_child(warm_ball)
  warm_ball.material_override.set_shader_parameter("mouth_radius",Vector2(0.04,0.04))
  warm_ball.material_override.set_shader_parameter("mouth_center",Vector2(0.5,0.5))
 warm_ball.visible=true

func hide_prewarm() -> void:
 if is_instance_valid(warm_ball):warm_ball.visible=false

func pocket_target(index: int) -> Vector2:
 if not baked_table:return sim.pockets()[index]
 var pixels=[Vector2(154,174),Vector2(836,164),Vector2(1518,174),Vector2(1518,766),Vector2(836,781),Vector2(154,766)]
 return (pixels[index]-Vector2(836,476.5))/Vector2(672,286.5)*sim.half_size

func sync(_delta: float) -> void:
 for b in sim.balls:
  var n: MeshInstance3D=ball_nodes.get(b.id)
  if n==null:continue
  n.visible=b.active or (b.pocket>=0 and b.fall<1.0)
  var p: Vector2=b.p
  var drop=0.0
  var roll_p=p
  var sinking: bool=not b.active and b.pocket>=0 and b.fall<1.0
  if sinking:
   var t: float=b.fall
   var target=pocket_target(b.pocket)
   p=p.lerp(target,1.0-pow(1.0-clampf(t/0.48,0.0,1.0),3.0))
   roll_p=p
   drop=0.24*pow(maxf(0.0,(t-0.20)/0.80),2.0)
   n.material_override=sink_materials[b.id]
   var sink: ShaderMaterial=sink_materials[b.id]
   var viewport_size=get_viewport().get_visible_rect().size
   var projected=camera.unproject_position(Vector3(target.x,BED+sim.radius,target.y))
   var extent_x=camera.unproject_position(Vector3(target.x+sim.half_size.x*25.0/672.0,BED+sim.radius,target.y)).distance_to(projected)
   sink.set_shader_parameter("mouth_center",projected/viewport_size)
   sink.set_shader_parameter("mouth_radius",Vector2(extent_x*0.93,extent_x*0.85)/viewport_size)
   sink.set_shader_parameter("bed_height",BED)
   sink.set_shader_parameter("progress",t)
   # Keep descent behind the lip, with a small visible drop into the mouth.
   if baked_table:
    var cosine=clampf((573.0/1344.0)*(sim.half_size.x/sim.half_size.y),0.5,0.99)
    p.y-=drop*tan(acos(cosine))*0.78
  else:
   n.material_override=ball_materials[b.id]
  n.position=Vector3(p.x,BED+sim.radius-drop,p.y)
  n.quaternion=b.q*ball_poses[b.id]
  if sinking:
   var travel: Vector2=roll_p-b.p
   if travel.length()>0.00001:n.quaternion=Quaternion(Vector3(travel.y,0,-travel.x).normalized(),travel.length()/sim.radius)*n.quaternion
  n.scale=Vector3.ONE
  n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if sinking else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
  var shadow: MeshInstance3D=shadow_nodes[b.id]
  shadow.visible=b.active
  shadow.position=Vector3(p.x+0.014,BED+0.0015,p.y+0.022)
  shadow.scale=Vector3.ONE

func cue_tint() -> Color:
 var material: StandardMaterial3D=ball_materials[rules.cue_id()]
 return Color.WHITE if material.albedo_texture!=null else ball_colour(rules.cue_id())

func advance_guide_animation(delta: float) -> void:
 guide_phase=fposmod(guide_phase+delta*4.5,TAU*100.0)
 guide.material_override.set_shader_parameter("phase",guide_phase)

func update_aim(direction: Vector2,power: float,visible_aim: bool,placement: bool=false,place_at: Vector2=Vector2.ZERO) -> void:
 if cue==null: return
 var b: Dictionary=sim.ball(rules.cue_id())
 cue.visible=visible_aim and not placement and not b.is_empty() and b.active
 guide.visible=visible_aim and not placement
 placement_ring.visible=visible_aim and placement
 if placement:
  guide_cached=false
  var n: MeshInstance3D=ball_nodes[rules.cue_id()];n.visible=true;n.position=Vector3(place_at.x,BED+sim.radius,place_at.y);n.scale=Vector3.ONE
  n.material_override=ball_materials[rules.cue_id()]
  shadow_nodes[rules.cue_id()].visible=false
  n.material_override.albedo_color=cue_tint()
  placement_ring.position=Vector3(place_at.x,BED+0.004,place_at.y)
  placement_ring.material_override.albedo_color=Color("e2c98b") if rules.is_placement_legal(place_at,sim) else Color("eb795b")
  return
 if not b.is_empty():ball_materials[rules.cue_id()].albedo_color=cue_tint()
 if not cue.visible:
  guide_cached=false
  return
 cue.position=Vector3(b.p.x,BED+sim.radius+0.006,b.p.y)+Vector3(direction.x,0,direction.y)*(0.04-power*0.11)
 cue.rotation.x=-0.055
 cue.rotation.y=atan2(-direction.x,-direction.y)
 var origin: Vector2=b.p
 if guide_cached and origin.is_equal_approx(guide_origin) and direction.is_equal_approx(guide_direction):return
 guide_cached=true;guide_origin=origin;guide_direction=direction
 var distance =minf(3.0,sim.half_size.x*2)
 var hit: Dictionary={}
 for other in sim.balls:
  if not other.active or other.id==b.id: continue
  var rel: Vector2=origin-other.p
  var proj =rel.dot(direction)
  var disc =proj*proj-(rel.length_squared()-pow(sim.radius*2,2))
  if disc<0: continue
  var t: float=-proj-sqrt(disc)
  if t>0 and t<distance: distance=t;hit=other
 # Clip the guide at the table boundary.
 for axis in range(2):
  if absf(direction[axis])>0.0001:
   var edge: float=((sim.half_size[axis]-sim.radius)*signf(direction[axis])-origin[axis])/direction[axis]
   if edge>0 and edge<distance: distance=edge;hit={}
 var endpoint =origin+direction*distance
 var mesh =ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 guide_dots.clear()
 var travelled: float=sim.radius*1.2
 while travelled<distance:
  var fraction=travelled/2.5
  var alpha=lerpf(0.98,0.20,clampf(fraction,0.0,1.0))
  var spacing=lerpf(0.025,0.085,clampf(fraction,0.0,1.0))
  _dot(mesh,origin+direction*travelled,0.0078,alpha,travelled)
  guide_dots.append({"distance":travelled,"alpha":alpha,"spacing":spacing})
  travelled+=spacing
 if guide_dots.is_empty():_dot(mesh,endpoint,0.003,0.45)
 if not hit.is_empty():
  for i in range(16):
   var a=TAU*i/16.0
   _dot(mesh,endpoint+Vector2(cos(a),sin(a))*sim.radius,0.0048,0.68)
  var exit_dir: Vector2=(hit.p-endpoint).normalized()
  for i in range(1,8):_dot(mesh,hit.p+exit_dir*(sim.radius+i*0.028),0.0045,0.7*(1.0-i/8.0))
 mesh.surface_end();guide.mesh=mesh

func _dot(mesh: ImmediateMesh,p: Vector2,r: float,alpha: float,travel: float=-1.0) -> void:
 for i in range(8):
  for point in [p,p+Vector2(cos(TAU*i/8.0),sin(TAU*i/8.0))*r,p+Vector2(cos(TAU*(i+1)/8.0),sin(TAU*(i+1)/8.0))*r]:
   mesh.surface_set_uv(Vector2(travel,0))
   mesh.surface_set_color(Color(0.79,0.91,0.79,alpha))
   mesh.surface_add_vertex(Vector3(point.x,BED+0.004,point.y))
func screen_to_table(point: Vector2) -> Vector2:
 var from =camera.project_ray_origin(point);var ray =camera.project_ray_normal(point)
 var hit=Plane(Vector3.UP,BED+sim.radius).intersects_ray(from,ray)
 return Vector2(hit.x,hit.z) if hit!=null else Vector2.ZERO
func _box(parent: Node3D,size: Vector3,pos: Vector3,mat: Material) -> MeshInstance3D:
 var n =MeshInstance3D.new();var mesh =BoxMesh.new();mesh.size=size;n.mesh=mesh;n.position=pos;n.material_override=mat;parent.add_child(n);return n
func _cylinder(parent: Node3D,top: float,bottom: float,height: float,pos: Vector3,mat: Material,segments: int=40) -> MeshInstance3D:
 var n =MeshInstance3D.new();var mesh =CylinderMesh.new();mesh.top_radius=top;mesh.bottom_radius=bottom;mesh.height=height;mesh.radial_segments=segments;n.mesh=mesh;n.position=pos;n.material_override=mat;parent.add_child(n);return n

func _carved_frame(h: Vector2) -> void:
 var corner_radius=0.115
 var height=0.075
 var rail=CSGBox3D.new();rail.size=Vector3(h.x*2+0.35-corner_radius*2,height,h.y*2+0.35);rail.position=Vector3(0,BED+0.012,0);rail.material=wood;geometry.add_child(rail)
 var cross=CSGBox3D.new();cross.size=Vector3(h.x*2+0.35,height,h.y*2+0.35-corner_radius*2);cross.material=wood;rail.add_child(cross)
 for x in [-1,1]:
  for z in [-1,1]:
   var corner=CSGCylinder3D.new();corner.radius=corner_radius;corner.height=height;corner.sides=32;corner.material=wood;corner.position=Vector3(x*(h.x+0.175-corner_radius),0,z*(h.y+0.175-corner_radius));rail.add_child(corner)
 var middle=CSGBox3D.new();middle.size=Vector3(h.x*2-0.03,0.45,h.y*2-0.03);middle.operation=CSGShape3D.OPERATION_SUBTRACTION;middle.material=wood;rail.add_child(middle)
 if sim.pocketed_table:
  for p in sim.pockets():
   var hole=CSGCylinder3D.new();hole.radius=sim.pocket_radius*1.10;hole.height=0.45;hole.sides=48;hole.position=Vector3(p.x,0,p.y);hole.operation=CSGShape3D.OPERATION_SUBTRACTION;hole.material=leather;rail.add_child(hole)

func _nose(length: float,position_on_table: Vector3,along_x: bool,material: Material) -> void:
 var node=MeshInstance3D.new();var shape=CapsuleMesh.new()
 shape.radius=0.018;shape.height=maxf(length,0.036);shape.radial_segments=24;shape.rings=8
 node.mesh=shape;node.material_override=material;node.position=position_on_table
 if along_x: node.rotation.z=PI/2
 else: node.rotation.x=PI/2
 geometry.add_child(node)

func _cushion_noses(h: Vector2,material: Material) -> void:
 for z in [-1,1]:
  if sim.pocketed_table:
   for side in [-1,1]:
    _nose(h.x-sim.pocket_radius*2.24,Vector3(side*h.x*0.5,BED+0.026,z*(h.y+0.018)),true,material)
  else: _nose(h.x*2,Vector3(0,BED+0.026,z*(h.y+0.018)),true,material)
 for x in [-1,1]:
  _nose(h.y*2-(sim.pocket_radius*2.24 if sim.pocketed_table else 0),Vector3(x*(h.x+0.018),BED+0.026,0),false,material)

func _make_edge_filter() -> void:
 var layer=CanvasLayer.new();layer.layer=0;add_child(layer)
 edge_filter=ColorRect.new();layer.add_child(edge_filter)
 edge_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 edge_filter.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shader=Shader.new()
 shader.code="""shader_type canvas_item; render_mode unshaded;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
float luma(vec3 c){return dot(c,vec3(0.299,0.587,0.114));}
void fragment(){
 vec2 p=SCREEN_UV;vec2 t=SCREEN_PIXEL_SIZE;
 vec3 c=texture(scene,p).rgb;
 vec3 n=texture(scene,p+vec2(0.0,-t.y)).rgb;
 vec3 s=texture(scene,p+vec2(0.0,t.y)).rgb;
 vec3 e=texture(scene,p+vec2(t.x,0.0)).rgb;
 vec3 w=texture(scene,p+vec2(-t.x,0.0)).rgb;
 float lc=luma(c);float ln=luma(n);float ls=luma(s);float le=luma(e);float lw=luma(w);
 float hi=max(lc,max(max(ln,ls),max(le,lw)));
 float lo=min(lc,min(min(ln,ls),min(le,lw)));
 float edge=smoothstep(max(0.08,hi*0.18),max(0.16,hi*0.40),hi-lo);
 vec3 filtered=abs(ln-ls)<abs(le-lw)?(n+s)*0.5:(e+w)*0.5;
 COLOR=vec4(mix(c,filtered,edge*0.40),1.0);
}
"""
 var material=ShaderMaterial.new();material.shader=shader;edge_filter.material=material
