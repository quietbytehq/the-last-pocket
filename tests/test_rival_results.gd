extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame;game.set_process(false);game.set_physics_process(false);game.sound_enabled=false
 game.launch_tournament("ACE");game.begin_frame()
 var lines={}
 for index in range(48):
  var rival=game.campaign.roster[index]
  for outcome in ["win","loss"]:
   var line=str(rival.get("result_"+outcome+"_quote",""))
   check(line.length()>15 and line.length()<180,"Rival has concise individual result dialogue")
   check(not lines.has(line),"Every result line is unique");lines[line]=true
   check(ResourceLoader.exists(rival.get("portrait_"+outcome,"")),"Expression art is included")
  check(rival.portrait_win!=rival.portrait_loss,"Victory and defeat use different expression atlases")
  for winner in [0,1]:
   game.campaign.rival_index=index;game.campaign.wins=index;game.campaign.phase="playing";game.campaign.last_won=false;game.campaign.finished=false;game.campaign.recorded=false;game.campaign.diamonds=3
   game.rules.names=["ACE",rival.name];game.rules.winner=winner;game.rules.match_over=true
   game._match_finished()
   var outcome="loss" if winner==0 else "win"
   check(game.ui.result_quote.text.contains(rival["result_"+outcome+"_quote"]),"Result displays this rival's matching outcome dialogue")
   check(game.ui.result_art.texture.atlas.resource_path==rival["portrait_"+outcome],"Result displays this rival's matching expression")
   check(game.ui.result_name.text==rival.name,"Result identifies the opponent")
 check(lines.size()==96,"All 48 opponents have both outcome lines")
 for slot in game.list_save_slots():check(slot.empty,"Finishing frames never creates a progress save")
 check(game.save_slot(0).ok,"Result screen can be explicitly saved")
 game.open_menu();check(game.load_slot(0) and game.state=="result","A saved result opens on its result card")
 check(game.ui.result_name.text=="The Final Frame","Saved final-rival identity is restored")
 print("RIVAL RESULTS: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame
 quit(0 if failures==0 else 1)
