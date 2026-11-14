extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var Physics=load("res://scripts/physics.gd")
 for side in [-1,1]:
  for offset in [-0.085,-0.075,0.075,0.085]:
   var sim=Physics.new();sim.radius=0.0475;sim.add_ball(0,Vector2(offset,side*0.62))
   sim.begin_shot(0,Vector2(0,side),2.5,Vector2.ZERO)
   for tick in range(30):sim.step(1.0/120.0)
   check(not sim.ball(0).active,"Open side-pocket mouth catches formerly escaping ball")
   check(sim.shot.potted.size()==1,"Pocket records exactly one event")
 var sim=Physics.new();sim.radius=0.0475
 sim.add_ball(0,Vector2(0,-0.40));sim.begin_shot(0,Vector2.UP,6,Vector2.ZERO);sim.ball(0).v=Vector2(0,-60);sim.step(1.0/120.0)
 check(not sim.ball(0).active,"Swept pocket catch handles a fast crossing")
 sim._pot(sim.ball(0),1);check(sim.shot.potted.size()==1,"Repeated pocket detection cannot duplicate event")
 # Deterministic pocket/jaw angles, both gentle and strong shots.
 var random=RandomNumberGenerator.new();random.seed=714
 var escaped=0
 for shot in range(240):
  sim=Physics.new();sim.radius=0.0475
  var pocket: Vector2=sim.pockets()[shot%6]
  var inward=(-pocket).normalized()
  var start=pocket+inward*0.18+inward.orthogonal()*random.randf_range(-0.13,0.13)
  start=start.clamp(-sim.half_size+Vector2.ONE*sim.radius,sim.half_size-Vector2.ONE*sim.radius)
  sim.add_ball(0,start)
  sim.begin_shot(0,(pocket-start).normalized().rotated(random.randf_range(-0.38,0.38)),random.randf_range(0.3,5.45),Vector2.ZERO)
  for tick in range(120):
   sim.step(1.0/120.0)
   if sim.ball(0).active and (absf(sim.ball(0).p.x)>sim.half_size.x+0.0001 or absf(sim.ball(0).p.y)>sim.half_size.y+0.0001):escaped+=1
  check(escaped==0,"Pocket/jaw shot %d remains inside table or pots" % shot)
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame
 game.set_process(false);game.set_physics_process(false);game.start_match(0)
 for index in range(6):
  var ball=game.sim.ball(index+1);ball.active=false;ball.pocket=index;ball.p=game.sim.pockets()[index]
  var target: Vector2=game.table.pocket_target(index)
  var expected=game.table.camera.unproject_position(Vector3(target.x,game.table.BED+game.sim.radius,target.y))
  var previous_y=expected.y
  var extent=game.table.camera.unproject_position(Vector3(target.x+game.sim.radius,game.table.BED+game.sim.radius,target.y)).distance_to(expected)
  for frame in range(20,40):
   ball.fall=frame/40.0;game.table.sync(0)
   var node: MeshInstance3D=game.table.ball_nodes[index+1]
   var actual=game.table.camera.unproject_position(node.position)
   check(actual.distance_to(expected)<extent*0.9,"Descending center stays inside pocket aperture")
   check(actual.y>=previous_y-0.001,"Drop moves smoothly downward without reversing")
   previous_y=actual.y
   check(node.scale==Vector3.ONE,"Descent never shrinks or stretches the sphere")
  check(game.table.ball_nodes[index+1].material_override.next_pass==null,"Pocket body and glint use one masked pass")
 check(game.ui.BADGE_RADIUS>=15.0,"Collected balls are larger")
 var icon: Image=game.ui.badge_texture(2).get_image()
 check(icon.get_width()==96,"Ball badge has detailed shaded texture")
 check(icon.get_pixel(32,24).get_luminance()>icon.get_pixel(75,75).get_luminance(),"Badge has highlight and curved shading")
 print("POCKET SAFETY: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();quit(0 if failures==0 else 1)
