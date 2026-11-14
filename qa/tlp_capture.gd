extends SceneTree
var viewport: SubViewport
func _initialize():call_deferred("run")
func capture(file: String):
 for i in range(8):await process_frame;RenderingServer.force_draw(false)
 viewport.get_texture().get_image().save_png("res://qa/"+file+".png")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 game.sound_enabled=false;game.music_enabled=false;game.music_player.stream_paused=true;game.set_process(false);game.set_physics_process(false)
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 await capture("tlp-title")
 game.ui.show_ai();await capture("tlp-entry")
 game.launch_tournament("ACE");await capture("tlp-intro")
 game.ui.show_journey();await capture("tlp-journey-start");game.ui.close_journey();game.begin_frame()
 game.rules.ball_in_hand=false;game.rules.baulk_only=false;game.sim.place(0,Vector2(-0.85,0.2));game.table.sync(0);game.table.update_aim(Vector2(1,-0.2).normalized(),0.45,true)
 await capture("tlp-gameplay")
 game.rules.groups=[0,1];game.sim.ball(2).active=false;game.sim.ball(2).fall=1.0;game.sim.ball(11).active=false;game.sim.ball(11).fall=1.0;game.table.sync(0)
 await capture("tlp-collections")
 game.toggle_pause();await capture("tlp-pause")
 game.ui.show_journey();await capture("tlp-journey-pause");game.ui.close_journey()
 game.campaign.rival_index=14;game.campaign.wins=14;game.campaign.points=23850;game.campaign.phase="intro";game._start_ai_frame()
 game.ui.show_journey();await capture("tlp-journey-progress")
 await game.prepare_to_close();quit()
