extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1;print("PASS · " if value else "FAIL · ",label)
 if not value:failures+=1
func _initialize():call_deferred("run")
func frames(count: int):
 for i in range(count):await process_frame
func key(code: Key):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;root.push_input(event)
func click(button: Button):
 var point=button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event)
func button(parent: Node,text: String) -> Button:
 for node in parent.find_children("*","Button",true,false):
  if node.text.strip_edges()==text:return node
 return null
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await frames(8);check(game.state=="title","The Last Pocket opens on the illustrated title")
 key(KEY_SPACE);await frames(3);click(button(game.ui.hub_page,"VERSUS AI"));await frames(3)
 check(game.ui.menu_page=="ai" and game.ui.ai_page.find_children("*","OptionButton",true,false).is_empty(),"Tournament entry has no rank or rival selection")
 game.ui.ai_name.text="ACE";click(button(game.ui.ai_page,"START AMATEUR TOUR"));await frames(3)
 check(game.state=="intro" and game.campaign.rival_index==0,"Entering AI always reveals first Amateur rival")
 click(button(game.ui.intro_panel,"JOURNEY"));await frames(3)
 check(game.state=="journey" and game.ui.journey_ids==[0],"Journey reveals only current rival")
 key(KEY_ESCAPE);await frames(3);check(game.state=="intro","Escape returns from journey")
 click(button(game.ui.intro_panel,"LET'S PLAY"));await frames(3)
 check(game.ui.profile_images[0].texture!=null and game.ui.profile_images[1].texture!=null,"Both player profile pictures appear")
 click(game.ui.pause_button);await frames(3)
 check(game.state=="paused" and game.ui.settings.visible,"Wooden pause menu opens")
 var enabled=game.music_enabled;click(game.ui.music_button);await frames(2);check(game.music_enabled!=enabled,"Music tile toggles lobby music")
 var effects=game.sound_enabled;click(game.ui.sound_button);await frames(2);check(game.sound_enabled!=effects,"Effects tile has an independent toggle")
 click(game.ui.journey_button);await frames(3);check(game.state=="journey","Pause offers the current journey")
 key(KEY_ESCAPE);await frames(3);check(game.state=="paused","Journey returns to Pause without resuming AI")
 click(button(game.ui.settings,"Resume"));await frames(3);check(game.state=="aim","Wooden Resume tile resumes play")
 game.sim.place(0,Vector2(-0.85,0.1));game.rules.ball_in_hand=false;game.rules.player=0
 var target=game.table.camera.unproject_position(Vector3(-0.2,game.table.BED+game.sim.radius,0.1))
 for pressed in [true,false]:
  var mouse=InputEventMouseButton.new();mouse.position=target;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=pressed;root.push_input(mouse)
 await frames(2);check(game.aim_locked and game.state=="aim","Real cloth click locks aim without firing")
 var meter=game.ui.get_global_transform()*Vector2(40,300)
 for pressed in [true,false]:
  var mouse=InputEventMouseButton.new();mouse.position=meter;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=pressed;root.push_input(mouse)
  await frames(2)
 check(game.state=="aim" and game.power>0.8,"Real meter drag and release adjusts power without firing")
 click(game.ui.play_button);await frames(2);check(game.state=="rolling","Explicit Shoot button launches ball")
 game.start_match(0)
 # Real player-one break and a subsequent AI turn use the same controllers.
 game.sim.place(0,Vector2(-0.85,0.1));game.rules.ball_in_hand=false;game.rules.player=1;game._invalidate_ai()
 var deadline=Time.get_ticks_msec()+15000
 while game.state=="aim" and Time.get_ticks_msec()<deadline:await process_frame
 check(game.state=="rolling" and game.sim.is_moving(),"The automatic Amateur opponent places and shoots")
 await game.prepare_to_close();game.queue_free();await process_frame
 print("FRONTEND INPUT: ",checks," checks, ",failures," failures");quit(0 if failures==0 else 1)
