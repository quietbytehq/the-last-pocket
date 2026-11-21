extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.sound_enabled=false
 for mode in [0,5,7]:
  game.start_local(mode)
  if game.rules.ball_in_hand:
   game.sim.place(0,game.placements);game.rules.ball_in_hand=false
  game.table.sync(0);game.table.update_aim(Vector2.RIGHT,0.45,true);game.ui._process(0)
  for frame in range(12):await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://qa/consistent-scale-%d.png" % mode)
 print("SCALE CAPTURES COMPLETE")
 await game.prepare_to_close();game.queue_free();await process_frame;quit()
