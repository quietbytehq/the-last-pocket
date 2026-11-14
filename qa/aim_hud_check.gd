extends SceneTree
var viewport: SubViewport
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func render() -> Image:
 for i in range(3):await process_frame;RenderingServer.force_draw(false)
 return viewport.get_texture().get_image()
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.start_match(0)
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 game.table.update_aim(Vector2.RIGHT,0.45,true,true,Vector2.ZERO)
 var preview=await render();preview.save_png("res://qa/cue-placement-white.png")
 check(game.table.ball_materials[0].albedo_color==Color.WHITE,"Cue preview keeps white material even at invalid starting position")
 game.rules.ball_in_hand=false;game.rules.groups=[0,1];game.rules.names=["ACE","BENNY BANKS"]
 game.sim.place(0,Vector2(-0.85,0.2));game.sim.ball(2).active=false;game.sim.ball(2).fall=1.0;game.sim.ball(11).active=false;game.sim.ball(11).fall=1.0
 game.table.sync(0);game.table.update_aim(Vector2(1,-0.2).normalized(),0.45,true)
 var first=await render();first.save_png("res://qa/hud-side-balls.png")
 var mesh=game.table.guide.mesh
 game.table.advance_guide_animation(PI/4.5)
 var second=await render();second.save_png("res://qa/aim-flow-second.png")
 var changed=0
 for y in range(300,800):
  for x in range(300,1300):
   var a=first.get_pixel(x,y);var b=second.get_pixel(x,y)
   if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.12:changed+=1
 check(changed>200,"Flowing guide changes hundreds of rendered pixels")
 check(game.table.guide.mesh==mesh,"Animated locked aim reuses the geometry")
 var file=FileAccess.open("res://qa/aim-hud-results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"animated_pixels":changed},"\t"));file.close()
 print("RENDERED AIM / HUD: ",checks," checks, ",failures," failures; ",changed," moving pixels")
 await game.prepare_to_close();viewport.queue_free();await process_frame;quit(0 if failures==0 else 1)
