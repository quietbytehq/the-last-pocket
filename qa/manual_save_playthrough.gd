extends SceneTree
var checks=0
var failures=0
var viewport: SubViewport
func check(value: bool,label: String):
 checks+=1;print("PASS · " if value else "FAIL · ",label)
 if not value:failures+=1
func _initialize():call_deferred("run")
func frames(count: int):
 for i in range(count):await process_frame;await RenderingServer.frame_post_draw
func click(button: Button):
 var point=button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;viewport.push_input(event)
func key(code: Key):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;viewport.push_input(event)
func button(parent: Node,text: String) -> Button:
 for item in parent.find_children("*","Button",true,false):
  if item.text.strip_edges()==text:return item
 return null
func capture(name: String):
 await frames(30);viewport.get_texture().get_image().save_png("res://qa/"+name+".png")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 game.launch_tournament("ACE");game.begin_frame()
 await frames(6)
 key(KEY_ESCAPE);await frames(3)
 check(game.state=="paused" and game.ui.settings.is_visible_in_tree(),"Escape opens visible Pause panel")
 click(game.ui.save_game_button);await frames(3)
 check(game.state=="saves" and game.ui.slot_buttons.size()==10,"Pause opens separate ten-slot save menu")
 click(game.ui.slot_buttons[0]);await frames(3)
 check(game.list_save_slots()[0].valid,"Actual save-slot click writes tournament")
 check(game.ui.slot_buttons[0].text.contains("ACE") and game.ui.slot_buttons[0].text.contains("UTC"),"Slot renders player and timestamp")
 await capture("manual-save-slots")
 click(button(game.ui.save_panel,"BACK"));await frames(3)
 check(game.state=="paused" and game.ui.settings.get_node("ResumePlay").is_visible_in_tree(),"Back restores visible Resume control")
 await capture("manual-save-pause")
 click(game.ui.settings.get_node("ResumePlay"));await frames(3)
 check(game.state=="aim","Actual Resume click returns to play")
 key(KEY_ESCAPE);await frames(2);click(game.ui.journey_button);await frames(3)
 check(game.state=="journey","Pause journey opens")
 key(KEY_ESCAPE);await frames(3);check(game.state=="paused","Journey returns to Pause")
 click(game.ui.settings.get_node("ResumePlay"));await frames(2);check(game.state=="aim","Resume still works after journey")
 game.start_local(0);key(KEY_ESCAPE);await frames(2);click(game.ui.journey_button);await frames(2)
 check(game.state=="paused" and game.ui.help_panel.visible,"Local help preserves paused state")
 click(button(game.ui.help_panel,"BACK TO TABLE"));await frames(2)
 check(game.state=="paused" and game.ui.settings.visible,"Help closes back to Pause")
 click(game.ui.settings.get_node("ResumePlay"));await frames(2);check(game.state=="aim","Resume works after help")
 game.open_menu();game.ui.show_saves("load");await frames(3)
 click(game.ui.slot_buttons[0]);await frames(3)
 check(game.state=="paused" and game.campaign.human_name=="ACE","Load opens selected tournament paused")
 key(KEY_ESCAPE);await frames(2);check(game.state=="aim","Escape resumes loaded tournament")
 game.rules.ball_in_hand=false;game.sim.place(0,Vector2(-0.85,0.2));game.aim=Vector2.RIGHT;game.strike();key(KEY_ESCAPE);await frames(2)
 check(game.state=="paused" and game.pause_origin=="rolling","Pause remembers an in-flight shot")
 click(game.ui.save_game_button);await frames(2);click(game.ui.slot_buttons[1]);await frames(2)
 check(game._read_slot(1).ui_state=="rolling","UI saves the in-flight shot")
 click(button(game.ui.save_panel,"BACK"));await frames(2);click(game.ui.settings.get_node("ResumePlay"));await frames(2)
 check(game.state=="rolling","Resume returns to the same rolling state")
 # Both outcome cards bind the first encountered rival and its correct emotion.
 for winner in [0,1]:
  game.campaign.phase="playing";game.campaign.last_won=false;game.campaign.finished=false;game.campaign.wins=0
  game.rules.winner=winner;game.rules.match_over=true;game._match_finished()
  await capture("rival-result-"+("player-win" if winner==0 else "player-loss"))
  check(not game.ui.result_quote.text.is_empty(),"Result has individual on-screen dialogue")
  check(game.ui.result_art.texture.atlas.resource_path.ends_with("_loss.png" if winner==0 else "_win.png"),"Result uses correct opponent expression")
 print("MANUAL SAVE INPUT: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();viewport.queue_free();await process_frame;quit(0 if failures==0 else 1)
