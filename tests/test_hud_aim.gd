extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame
 game.set_process(false);game.set_physics_process(false);game.start_match(0)
 var initial=game.table.ball_materials[0].albedo_color
 game.table.update_aim(Vector2.RIGHT,0.5,true,true,Vector2.ZERO)
 check(game.table.ball_materials[0].albedo_color==initial,"Invalid placement keeps cue ball's original white material")
 check(game.table.placement_ring.visible,"Placement has an independent warning ring")
 var warning=game.table.placement_ring.material_override.albedo_color
 game.table.update_aim(Vector2.RIGHT,0.5,true,true,Vector2(-0.85,0.2))
 check(game.table.ball_materials[0].albedo_color==initial,"Legal placement uses the same white cue ball")
 check(game.table.placement_ring.material_override.albedo_color!=warning,"Only ring changes colour with legality")
 game.rules.ball_in_hand=false;game.sim.place(0,Vector2(-0.85,0.2));game.table.sync(0)
 game.table.update_aim(Vector2.RIGHT,0.5,true)
 check(not game.table.placement_ring.visible,"Placement ring disappears after placement")
 var mesh=game.table.guide.mesh
 game.table.advance_guide_animation(0.25)
 check(game.table.guide_phase>0,"Guide animation advances")
 check(game.table.guide.material_override.get_shader_parameter("phase")==game.table.guide_phase,"Guide animation reaches shader")
 check(game.table.guide.mesh==mesh,"Locked guide animates without rebuilding its mesh")
 var phase=game.table.guide_phase
 game.state="paused";game._process(0.25)
 check(game.table.guide_phase==phase,"Guide animation freezes when paused")
 game.state="aim";game.aim_locked=true;game._process(0.25)
 check(game.table.guide_phase>phase,"Guide animation resumes during aiming")
 check(game.ui.BADGE_RADIUS==21.0,"Scored balls have 42px diameter")
 check(game.ui.profile_panels[0].position.x<100 and game.ui.profile_panels[1].position.x>1000,"Profiles use both sides of the header")
 for width in [155.0,180.0]:
  var fitted=game.ui.fit_player_name("WWWWWWWWWWWWWWWWWW",width)
  check(game.ui.bold.get_string_size(fitted.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted.size).x<=width,"Long names fit beside scored ball sets")
 game.ui._process(0)
 check(game.ui.pause_button.position.x>625 and game.ui.pause_button.position.x<1005,"Pause leaves side collections unobstructed")
 print("HUD / AIM: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();quit(0 if failures==0 else 1)
