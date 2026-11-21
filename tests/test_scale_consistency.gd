extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame;game.set_process(false);game.set_physics_process(false);game.sound_enabled=false
 var reference_diameter=0.0
 var reference_corner=Vector2.ZERO
 for mode in range(10):
  game.start_local(mode)
  check(game.sim.half_size==Vector2(1.27,0.635) and is_equal_approx(game.sim.radius,0.0475),"Shared arcade dimensions: %d" % mode)
  check(game.table.camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"Shared camera projection: %d" % mode)
  var centre=Vector3(0,game.table.BED+game.sim.radius,0)
  var camera=game.table.camera
  var diameter=camera.unproject_position(centre+Vector3.RIGHT*game.sim.radius).distance_to(camera.unproject_position(centre-Vector3.RIGHT*game.sim.radius))
  var corner=camera.unproject_position(Vector3(game.sim.half_size.x,game.table.BED+game.sim.radius,game.sim.half_size.y))
  if mode==0:reference_diameter=diameter;reference_corner=corner
  check(absf(diameter-reference_diameter)<0.01 and corner.distance_to(reference_corner)<0.01,"Equal screen ball size and cloth bounds: %d" % mode)
  check(is_equal_approx(game.table.ball_nodes[0].mesh.radius,game.sim.radius),"Visible sphere matches collision radius: %d" % mode)
  game.rules.ball_in_hand=false;game.sim.balls.clear()
  game.sim.add_ball(0,Vector2(-0.3,0));game.sim.add_ball(3,Vector2.ZERO)
  game.sim.begin_shot(0,Vector2.RIGHT,2,Vector2.ZERO)
  for tick in range(60):game.sim.step(1.0/240.0)
  check(game.sim.shot.first==3,"Collision at enlarged ball radius: %d" % mode)
 for mode in [4,5,6,7,8]:
  game.launch_tournament("OLD SAVE",mode)
  game.rules.configure(mode,game.sim,0)
  var old_radius=game.sim.radius;var old_bounds=game.sim.half_size
  var data=game.snapshot_match();data.erase("layout_version")
  check(game._valid_save(data),"Pre-scale save validates: %d" % mode)
  var bytes=var_to_bytes(data)
  DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
  var file=FileAccess.open(game.slot_path(0),FileAccess.WRITE)
  file.store_buffer("TLP5".to_ascii_buffer());file.store_buffer(game._save_digest(bytes));file.store_buffer(bytes);file.close()
  check(game.load_slot(0) and game.sim.layout_version==0 and game.sim.radius==old_radius and game.sim.half_size==old_bounds,"Legacy frame restores exact physics: %d" % mode)
  check(game.AIPlanner.snapshot(game.sim,game.rules).layout_version==0,"AI retains legacy geometry: %d" % mode)
  check(game.save_slot(1,true).ok and game._read_slot(1).layout_version==0,"Re-saving old frame retains layout: %d" % mode)
  game.begin_frame();game.start_match(mode)
  check(game.sim.layout_version==1 and game.sim.radius==0.0475,"Next frame uses consistent scale: %d" % mode)
  check(game.save_slot(2,true).ok and game.load_slot(2) and game.sim.layout_version==1,"New layout round-trips: %d" % mode)
  data.layout_version=2;check(not game._valid_save(data),"Unknown layout rejected")
 print("SCALE CONSISTENCY: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
