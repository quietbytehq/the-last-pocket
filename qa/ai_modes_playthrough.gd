extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1;print("PASS · " if ok else "FAIL · ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func frames(n: int):
 for i in range(n):await process_frame;await RenderingServer.frame_post_draw
func click(button: Button):
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.position=button.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e,true)
func button(parent: Node,text: String):
 for b in parent.find_children("*","Button",true,false):
  if b.text.strip_edges()==text:return b
 return null
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game);game.set_physics_process(false)
 game.ui.show_ai();await frames(8)
 check(game.ui.ai_mode_buttons.size()==10,"AI selection matches the local game grid")
 check(game.ui.ai_mode_buttons[9].disabled,"Practice correctly has no AI opponent")
 root.get_texture().get_image().save_png("res://qa/ai-mode-selection.png")
 for mode in [1,5,8]:
  click(game.ui.ai_mode_buttons[mode]);await frames(3)
  check(game.ui.selected_ai_mode==mode,"Mouse selects requested AI game")
  click(button(game.ui.ai_page,"START AMATEUR TOUR"));await frames(4)
  check(game.state=="intro" and game.rules.mode==mode,"Start launches selected AI game")
  check(game.ui.intro_rank.text.contains(game.rules.MODES[mode]),"Rival card names selected game")
  game.ui.show_ai();await frames(4)
 print("AI MODE INPUT: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
