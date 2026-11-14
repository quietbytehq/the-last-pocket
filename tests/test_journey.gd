extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func result(game,winner: int):
 for b in game.sim.balls:b.v=Vector2.ZERO;b.spin=Vector2.ZERO
 game.rules.winner=winner;game.rules.match_over=true;game._match_finished()
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 check(game.ui.ai_page.find_children("*","OptionButton",true,false).is_empty(),"AI entry contains no difficulty, opponent or game selectors")
 check(not game.has_method("launch_ai"),"No quick-match route bypasses progression")
 game.launch_tournament("ACE")
 check(game.campaign.tier()==0 and game.campaign.rival_index==0,"AI always starts in Amateur")
 game.ui.show_journey();check(game.ui.journey_ids==[0],"Only current rival is revealed at start")
 var labels=game.ui.journey_grid.find_children("*","Label",true,false)
 for rival in game.campaign.roster.slice(1):
  var leaked=false
  for label in labels:
   if rival.name in label.text:leaked=true
  check(not leaked,"Future opponent name not present in journey UI")
 game.ui.close_journey();game.begin_frame();result(game,1)
 check(game.campaign.losses[0]==1,"Loss history is recorded")
 game.result_primary();check(game.campaign.diamonds==2,"Continue consumes one diamond")
 game.begin_frame();result(game,0)
 var seen=game.campaign.revealed_rivals()
 check(seen.size()==1 and seen[0].defeated and seen[0].losses==1,"Win records defeated rival without revealing next rival early")
 game.result_primary();game.ui.show_journey()
 check(game.ui.journey_ids==[0,1],"Advancing reveals exactly one new opponent")
 seen=game.campaign.revealed_rivals();check(seen[0].status=="Defeated" and seen[1].status=="Current rival","Journal distinguishes defeated and current opponents")
 game.ui.close_journey()
 var file=FileAccess.open("user://match.save",FileAccess.READ);var data=file.get_var(false);file.close()
 check(data.version==4 and data.session.losses[0]==1,"Encounter history is persisted")
 game.open_menu();check(game.resume_match() and game.campaign.losses[0]==1,"Encounter history survives resume")
 var old=data.duplicate(true);old.version=3;old.session.erase("losses")
 check(game._valid_save(old),"Earlier tournament saves remain compatible")
 old.session.kind="ai";check(not game._valid_save(old),"Earlier selectable-skill AI saves cannot bypass Amateur")
 check(game.music_player.stream!=null and game.music_player.stream.get_length()>60,"Supplied lobby track loads")
 var music_stream=game.music_player.stream
 game.music_enabled=true;game.music_player.stream_paused=false
 game.sound_enabled=true;game.toggle_sound()
 check(game.music_player.stream==music_stream and game.music_enabled,"SFX mute leaves lobby music independent")
 game.toggle_music();check(game.music_player.stream_paused,"Music can be muted separately")
 music_stream=null
 await game.prepare_to_close();game.queue_free();await process_frame
 print("JOURNEY: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
