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
 check(game.ui.title_group.resource_path.ends_with("title_group.png"),"Group portrait is bound only to title")
 game.launch_tournament("CHAMPION");game.begin_frame()
 game.campaign.rival_index=47;game.campaign.wins=47;game.campaign.points=100000;game.campaign.phase="playing";game.campaign.finished=false
 game.rules.winner=0;game.rules.match_over=true;game._match_finished()
 check(game.campaign.wins==48 and game.ui.champion_reveal,"Last rival win opens trophy presentation")
 check(game.ui.champion_name.text=="CHAMPION" and game.ui.champion_score.text.contains("ALL 48"),"Personalized championship display")
 check(game.ui.champion_art.texture.resource_path.ends_with("champion_trophy.png"),"Correct separate trophy illustration")
 var score=game.campaign.points
 game.result_primary();check(not game.ui.champion_reveal and game.state=="result","Ending Continue opens final-rival result")
 check(game.campaign.points==score,"Ending cannot award extra points")
 game.result_primary();check(game.state=="menu" and game.ui.share_shade.visible,"Finished result opens explicit share choice")
 check(game.score_offer.champion and game.score_offer.points==score,"Share offer retains complete-run category")
 game.online_enabled=true;game.ui.finish_share(true)
 check(not game.online_enabled and not game.ui.share_shade.visible,"Local-only button remembers privacy and closes modal")
 check(game.find_children("*","HTTPRequest",true,false).is_empty(),"Local-only choice sends no HTTP request")
 var config=ConfigFile.new();config.load("user://settings.cfg")
 check(not config.get_value("privacy","online_scores",true),"Privacy choice persisted")
 game.start_local(0);game.rules.winner=0;game.rules.match_over=true;game._match_finished()
 check(not game.ui.champion_reveal,"Local victory never opens champion presentation")
 game._prepare_score_offer();check(game.score_offer.is_empty(),"Local match cannot submit championship scores")
 game.launch_tournament("ONE WIN");game.begin_frame();game.rules.winner=0;game.rules.match_over=true;game._match_finished()
 check(not game.ui.champion_reveal,"Ordinary win never opens final ending")
 game.end_tournament();check(game.ui.share_shade.visible and not game.score_offer.champion,"Unfinished run has no champion claim")
 game.online_enabled=false;game.ui.toggle_online_choice();check(game.online_enabled,"Privacy switch can opt back in")
 game.ui.finish_share(true)
 var data=game.OnlineScores.payload("Ab<c>!",2000,true)
 check(data.size()==4 and data.name=="ABC" and data.mode=="champion_all_48","Exactly four safe fields including champion category")
 check(game.OnlineScores.payload("ACE",1000,false).mode=="championship","Ordinary category uses known id")
 check(not game.OnlineScores.qualifying(950) and not game.OnlineScores.qualifying(1001) and not game.OnlineScores.qualifying(1000050),"Threshold, increment and ceiling")
 print("CHAMPION / ONLINE: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
