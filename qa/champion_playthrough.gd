extends SceneTree
var viewport: Viewport
var checks=0
var failures=0
func _initialize():call_deferred("run")
func frames(n: int):
 for i in range(n):await process_frame;await RenderingServer.frame_post_draw
func check(ok: bool,text: String):
 checks+=1;print("PASS · " if ok else "FAIL · ",text)
 if not ok:failures+=1
func click(button: Button):
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.position=button.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;viewport.push_input(e,true)
func key(code: Key):
 for pressed in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.pressed=pressed;viewport.push_input(e,true)
func find_button(parent: Node,text: String):
 for b in parent.find_children("*","Button",true,false):
  if b.text.strip_edges()==text:return b
 return null
func capture(name: String):
 await frames(8);viewport.get_texture().get_image().save_png("res://qa/"+name+".png")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_physics_process(false)
 viewport=root;game.table.camera.current=true;game.table._position_camera()
 await capture("new-title")
 check(game.ui.front_bg.texture.resource_path.ends_with("title_group.png"),"Title uses group portrait")
 key(KEY_SPACE);await frames(3)
 check(game.state=="menu" and game.ui.front_bg.texture.resource_path.ends_with("title_hero.png"),"Group art is restricted to title screen")
 game.launch_tournament("CHAMPION");game.begin_frame();game.set_process(false)
 game.campaign.rival_index=47;game.campaign.wins=47;game.campaign.points=100000;game.campaign.phase="playing";game.campaign.finished=false
 game.rules.winner=0;game.rules.match_over=true;game._match_finished()
 await frames(70);await capture("new-champion")
 check(game.ui.champion_page.is_visible_in_tree() and not game.ui.result_panel.visible,"Final win displays trophy presentation")
 check(game.ui.champion_name.text=="CHAMPION","Ending includes player name")
 click(find_button(game.ui.champion_page,"CONTINUE"));await frames(3)
 check(not game.ui.champion_reveal and game.ui.result_panel.is_visible_in_tree(),"Continue opens final-rival result")
 click(game.ui.result_action);await frames(3)
 check(game.ui.share_shade.visible and game.score_offer.champion,"Top-ten action offers champion score submission")
 await capture("new-online-choice")
 key(KEY_F2);await frames(2);check(not game.online_enabled,"F2 switches posting off")
 click(find_button(game.ui.share_panel,"SAVE CHOICE & VIEW TOP TEN"));await frames(3)
 check(not game.ui.share_shade.visible,"Save choice closes share overlay")
 check(game.find_children("*","HTTPRequest",true,false).is_empty(),"Local-only save never posts")
 print("CHAMPION INPUT: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
