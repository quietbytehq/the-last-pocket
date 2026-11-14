extends SceneTree
var checks=0
var failures=0
var viewport: SubViewport
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func render() -> Image:
 await process_frame;RenderingServer.force_draw(false)
 return viewport.get_texture().get_image()
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.start_match(0);game.rules.ball_in_hand=false
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 game.table.update_aim(Vector2.RIGHT,0,false)
 for ball in game.sim.balls:ball.active=false;ball.fall=1.0
 game.table.sync(0)
 for warmup in range(8):await render()
 var baseline=await render()
 baseline.save_png("res://qa/pocket-baseline.png")
 var centers: Array[Vector2]=[];var radii: Array[Vector2]=[]
 for index in range(6):
  var ball=game.sim.ball(index+1);ball.active=false;ball.pocket=index
  ball.p=game.sim.pockets()[index]+(-game.sim.pockets()[index]).normalized()*0.035
  var target=game.table.pocket_target(index)
  var center=game.table.camera.unproject_position(Vector3(target.x,game.table.BED+game.sim.radius,target.y))
  var radius=game.table.camera.unproject_position(Vector3(target.x+game.sim.half_size.x*25.0/672.0,game.table.BED+game.sim.radius,target.y)).distance_to(center)
  centers.append(center);radii.append(Vector2(radius*0.93,radius*0.85))
 var previous_energy=INF
 var late_frames: Array=[]
 for frame in range(41):
  for index in range(6):game.sim.ball(index+1).fall=frame/40.0
  game.table.sync(0)
  var shot=await render()
  if frame in [0,12,24,32,40]:shot.save_png("res://qa/drop-final-%02d.png" % frame)
  if frame>=30:
   var escaped=0;var energy=0.0
   for index in range(6):
    var center=centers[index];var radius=radii[index]
    for y in range(int(center.y-55),int(center.y+55)):
     for x in range(int(center.x-55),int(center.x+55)):
      var c=shot.get_pixel(x,y);var b=baseline.get_pixel(x,y)
      var difference=absf(c.r-b.r)+absf(c.g-b.g)+absf(c.b-b.b)
      energy+=difference
      if difference>0.12 and ((Vector2(x,y)-center)/radius).length()>1.16:escaped+=1
   check(escaped==0,"Late drop pixels remain inside the six pocket openings")
   check(energy<=previous_energy+1.0,"Pocket image fades smoothly without bright flashes")
   previous_energy=energy;late_frames.append({"frame":frame,"outside_pixels":escaped,"image_energy":energy})
 check(previous_energy<1.0,"Completed drop leaves no stray sphere or glint")
 var file=FileAccess.open("res://qa/pocket-motion-results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":late_frames},"\t"));file.close()
 print("RENDERED POCKET MOTION: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();viewport.queue_free();await process_frame;quit(0 if failures==0 else 1)
