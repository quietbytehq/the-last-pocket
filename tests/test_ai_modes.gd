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
 var legacy={}
 for mode in range(9):
  game.launch_tournament("MODE TEST",mode)
  check(game.state=="intro" and game.rules.mode==mode and game.campaign.game_mode==mode,"Selected AI game starts in correct rules")
  check(game.campaign.rival_index==0 and game.campaign.diamonds==3,"Every mode starts Amateur with three diamonds")
  check(game.save_slot(0,true).ok,"Selected mode introduction can be saved")
  if mode==0:
   legacy=game._read_slot(0);legacy.session.erase("game_mode")
   check(game._valid_save(legacy),"Legacy 8-ball save without mode remains valid")
  check(game.load_slot(0) and game.rules.mode==mode and game.campaign.game_mode==mode,"Save restores selected game")
  game.begin_frame();game.rules.player=1
  var plan=game.AIPlanner.plan(game.AIPlanner.snapshot(game.sim,game.rules),0.0,12345)
  check(not plan.has("error") and plan.aim.is_finite(),"AI plans selected game")
  game.ai_result=plan;game.ai_delay=1.0;game._tick_ai(0.0)
  check(game.state=="rolling" and game.sim.shot.cue==game.rules.cue_id(),"AI actually places and shoots correct cue ball")
  game.sim.step(1.0/120.0)
  check(game.save_slot(1,true).ok,"In-flight selected game can be saved")
  check(game.load_slot(1) and game.state=="paused" and game.pause_origin=="rolling","In-flight selected game restores paused")
  game.resume_play();check(game.state=="rolling" and game.rules.mode==mode,"Resume retains selected rules")
  game.rules.winner=0;game.rules.match_over=true;game._match_finished();game.result_primary()
  check(game.campaign.rival_index==1 and game.rules.mode==mode,"Rival progression retains game type")
  game.campaign.points=2000;game._prepare_score_offer()
  check((not game.score_offer.is_empty())==(mode==0),"Only comparable 8-ball championship enters existing global board")
 var career=game.Campaign.new();career.game_mode=8;check(career.restore(legacy.session) and career.game_mode==0,"Old save restores 8-ball from another mode")
 var snapshot=career.snapshot();snapshot.game_mode=9;check(not career.valid(snapshot),"Practice cannot be an AI tournament")
 game.launch_tournament("IGNORE",9);check(game.rules.mode==8,"Invalid AI mode does not alter current game")
 print("AI GAME MODES: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
