extends SceneTree
var checks=0
var failures=0
func check(condition: bool,label: String):
 checks+=1
 if not condition: failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame
 game.set_process(false);game.set_physics_process(false)
 check(game.state=="menu","Launch opens game selection")
 check(game.ui.mode_buttons.size()==10,"Ten mode choices")
 for i in range(10):
  game.start_match(i);game.set_process(false);game.set_physics_process(false)
  check(game.state=="aim" and game.rules.mode==i,"Menu launches mode %d" % i)
  check(game.table.ball_nodes.size()==game.sim.balls.size(),"Every ball has a rendered actor")
  var point=Vector2(-game.sim.half_size.x*0.75,0.1)
  var projected=game.table.camera.unproject_position(Vector3(point.x,game.table.BED+game.sim.radius,point.y))
  check(game.table.screen_to_table(projected).distance_to(point)<0.0001,"Mouse projection matches physical table")
 # Successful placement, shot, pause/resume, settlement and turn transfer.
 game.start_match(0);game.set_process(false);game.set_physics_process(false)
 check(game.rules.ball_in_hand,"New pool frame requires cue placement")
 check(not game.rules.is_placement_legal(Vector2.ZERO,game.sim),"Break must be behind head string")
 game.sim.place(0,Vector2(-0.85,0.25));game.rules.ball_in_hand=false
 game.aim=Vector2.LEFT;game.power=0.1;game.strike()
 check(game.state=="rolling" and game.sim.ball(0).v.length()>0,"Strike launches cue ball")
 var p=game.sim.ball(0).p
 game.toggle_pause();game._physics_process(1.0)
 check(game.state=="paused" and game.sim.ball(0).p==p,"Pause freezes physics")
 game.toggle_pause();check(game.state=="rolling","Resume restores rolling state")
 for tick in range(3600):
  game._physics_process(1.0/120.0)
  if game.state=="aim":break
 check(game.state=="aim" and game.rules.player==1,"Miss ends shot and passes to second player")
 # Scene has a valid ball-in-hand preview and a legal saved match after foul.
 check(not game.save_slot(0).ok,"Local matches cannot be saved as tournaments")
 game.launch_tournament("ALPHA");game.begin_frame()
 game.rules.scores=[7,4];game.rules.player=1;game.rules.names=["ALPHA","BRAVO"];check(game.save_slot(0).ok,"Explicit tournament save succeeds")
 game.rules.scores=[0,0];game.rules.player=0
 check(game.load_slot(0),"Chosen saved slot loads");game.resume_play()
 check(game.rules.scores==[7,4] and game.rules.player==1 and game.rules.names==["ALPHA","BRAVO"],"Resume restores scores, players and turn")
 check(game.sim.balls.size()==16,"Resume restores all pool balls")
 # A release over the interface still ends a charged shot rather than sticking.
 game.rules.ball_in_hand=false;game.sim.respot(0,Vector2(-0.7,0.3));game.rules.player=0;game.power_drag=true;game.power=0.2;game.state="aim"
 var release=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;game._input(release)
 check(not game.power_drag and game.state=="aim","Power release over UI preserves deliberate shot")
 game.open_menu();check(game.state=="menu" and not game.charging,"New match cancels shot charging")
 game.start_match(5);game.set_process(false);game.set_physics_process(false);game.rules.phase="colour";game.rules.nominated=2;game.ui.refresh_calls()
 check(game.ui.call_choice.get_selected_id()==2,"Snooker selector retains nominated colour")
 game.start_match(2);game.set_process(false);game.set_physics_process(false);game.rules.ball_in_hand=false;game.rules.break_shot=false;game.rules.called_ball=1;game.ui.refresh_calls()
 check(game.rules.called_ball==-1,"Called ball cannot silently carry across shots")
 game.strike();check(game.state=="aim" and "Select" in game.rules.message,"Uncalled ten-ball shot is blocked")
 var old_quality=game.high_quality;game.toggle_quality();check(game.high_quality!=old_quality,"Performance graphics preset works");game.toggle_quality()
 var old_sound=game.sound_enabled;game.toggle_sound();check(game.sound_enabled!=old_sound,"Effects toggle works");game.toggle_sound()
 var old_music=game.music_enabled;game.toggle_music();check(game.music_enabled!=old_music,"Music toggle works without supplied audio");game.toggle_music()
 game.launch_tournament("ACE");game.set_process(false);game.set_physics_process(false);game.save_slot(1)
 var valid=game._read_slot(1)
 check(game._valid_save(valid),"Fresh match save validates")
 var bad=valid.duplicate(true);bad.rules.player=99;check(not game._valid_save(bad),"Invalid saved player is rejected")
 bad=valid.duplicate(true);bad.balls[1].id=0;check(not game._valid_save(bad),"Duplicate saved ball is rejected")
 bad=valid.duplicate(true);bad.balls[0].p=Vector2(NAN,0);check(not game._valid_save(bad),"Non-finite saved position is rejected")
 bad=valid.duplicate(true);bad.rules.names=["Only one"];check(not game._valid_save(bad),"Malformed saved names are rejected")
 bad=valid.duplicate(true);bad.balls[0].erase("fall");check(not game._valid_save(bad),"Missing ball state is rejected")
 bad=valid.duplicate(true);bad.power=2.0;check(not game._valid_save(bad),"Invalid saved power is rejected")
 bad=valid.duplicate(true);bad.balls[0].v=Vector2(3,0);check(not game._valid_save(bad),"Unsettled saved shot is rejected")
 print("PASS" if failures==0 else "FAIL",": ",checks," integration checks, ",failures," failures")
 await game.prepare_to_close()
 game.queue_free();await process_frame
 quit(0 if failures==0 else 1)
