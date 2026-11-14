extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func settled(game):
 for ball in game.sim.balls:ball.v=Vector2.ZERO;ball.spin=Vector2.ZERO
func result(game,winner: int):
 settled(game);game.rules.winner=winner;game.rules.match_over=true;game._match_finished()
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.sound_enabled=false
 game.launch_tournament("ACE")
 check(game.state=="intro" and game.campaign.diamonds==3,"New tournament opens first rival introduction")
 check(game.ui.intro_name.text==game.campaign.roster[0].name,"Individual rival portrait card is bound to the roster")
 game.begin_frame();check(game.state=="aim" and game.human_turn(),"First frame begins with the human")
 result(game,0);check(game.state=="result" and game.campaign.wins==1,"Win creates tournament result and score")
 var points=game.campaign.points;game._match_finished();check(game.campaign.points==points,"Duplicate result cannot award points twice")
 game.result_primary();check(game.state=="intro" and game.campaign.rival_index==1,"Next rival appears before next frame")
 game.begin_frame();check(not game.human_turn(),"Opening break alternates to AI")
 # The real threaded planner places and shoots; simulated input cannot take its turn.
 var before=game.state;game.strike();check(game.state==before,"Human cannot fire during AI turn")
 var deadline=Time.get_ticks_msec()+15000
 while game.state=="aim" and Time.get_ticks_msec()<deadline:
  game._tick_ai(0.1);await process_frame
 check(game.state=="rolling" and game.sim.is_moving(),"Threaded AI executes a valid placed break")
 result(game,1)
 check(game.campaign.diamonds==3,"Losing a frame does not spend a diamond without choosing continue")
 game.result_primary();check(game.campaign.diamonds==2 and game.campaign.rival_index==1 and game.state=="intro","Continue retries same rival and spends one diamond")
 var saved=FileAccess.open("user://match.save",FileAccess.READ).get_var(false)
 check(game._valid_save(saved),"Tournament introduction and continue state validate for resume")
 game.open_menu();check(game.resume_match() and game.campaign.diamonds==2 and game.state=="intro","Resume restores campaign and rival introduction")
 game.begin_frame();game.toggle_pause();game._tick_ai(2.0);check(game.state=="paused","AI cannot shoot while paused")
 game.toggle_pause();game._invalidate_ai();game._join_ai()
 # Cross the rank boundary with normal result handling.
 game.campaign.rival_index=11;game.campaign.wins=11;game.campaign.phase="playing";game.campaign.last_won=false
 result(game,0);game.result_primary()
 check(game.campaign.tier()==1 and game.table.upgrade==1 and game.campaign.rival_index==12,"Twelfth win upgrades club and equipment")
 game.begin_frame();result(game,1);game.end_tournament()
 check(game.campaign.finished and game.campaign.recorded and game.ui.menu_page=="board","Ending a run records the score and opens top ten")
 var entries=game.leaderboard.entries.duplicate(true);game._record_run();check(game.leaderboard.entries==entries,"Completed run is recorded once")
 # AI selection cannot reveal or skip to future opponents.
 game.launch_tournament("ACE")
 check(game.campaign.rival_index==0 and game.campaign.tier()==0,"New AI entry always starts Amateur")
 game.ui.show_journey();check(game.ui.journey_ids==[0],"Fresh journey shows only the encountered rival")
 check(game.state=="journey","Hierarchy pauses the match state")
 game.ui.close_journey();check(game.state=="intro","Journey returns to the introduction")
 game.start_local(0);check(game.campaign.kind=="local" and game.human_turn(),"Local versus restores both human controls")
 await game.prepare_to_close()
 print("CAMPAIGN FLOW: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
