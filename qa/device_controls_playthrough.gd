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
func key(code: Key,pressed: bool):
 var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;viewport.push_input(event)
func pad(button: int):
 for pressed in [true,false]:
  var event=InputEventJoypadButton.new();event.device=0;event.button_index=button;event.pressed=pressed;viewport.push_input(event)
func axis(index: int,value: float):
 var event=InputEventJoypadMotion.new();event.device=0;event.axis=index;event.axis_value=value;viewport.push_input(event)
func click(point: Vector2,button: MouseButton=MOUSE_BUTTON_LEFT):
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=button;event.pressed=pressed;viewport.push_input(event)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 await frames(5);pad(JOY_BUTTON_A);await frames(4)
 check(game.state=="menu" and viewport.gui_get_focus_owner()!=null,"Gamepad starts title and focuses menu")
 pad(JOY_BUTTON_DPAD_DOWN);await frames(2)
 check(viewport.gui_get_focus_owner().text.contains("VERSUS AI"),"D-pad selects versus AI")
 pad(JOY_BUTTON_A);await frames(3)
 check(game.ui.menu_page=="ai","Gamepad activates menu")
 for i in range(12):
  var focused=viewport.gui_get_focus_owner()
  if focused is Button and focused.text.contains("START AMATEUR TOUR"):break
  pad(JOY_BUTTON_DPAD_LEFT if focused is Button and focused.text.contains("LOAD TOURNAMENT") else JOY_BUTTON_DPAD_DOWN);await frames(2)
 pad(JOY_BUTTON_A);await frames(4)
 check(game.state=="intro","Gamepad enters championship without mouse")
 pad(JOY_BUTTON_A);await frames(4)
 check(game.state=="aim" and game.rules.ball_in_hand,"Gamepad begins frame")
 game.set_physics_process(false);game.placements=Vector2(-0.85,0.1)
 pad(JOY_BUTTON_A);await frames(2)
 check(not game.rules.ball_in_hand and game.state=="aim","Pad A places cue ball")
 axis(JOY_AXIS_LEFT_X,0.8);axis(JOY_AXIS_LEFT_Y,-0.5);await frames(4)
 check(game.aim.y<0 and game.aim_locked,"Joypad events adjust live aim")
 var power=game.power;axis(JOY_AXIS_TRIGGER_RIGHT,1.0);await frames(5);axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
 check(game.power>power,"Joypad trigger adjusts live power")
 pad(JOY_BUTTON_A);await frames(2);check(game.state=="rolling","Pad A launches actual shot")
 pad(JOY_BUTTON_START);await frames(3)
 check(game.state=="paused" and viewport.gui_get_focus_owner().name=="ResumePlay","Controller Pause focuses Resume")
 pad(JOY_BUTTON_A);await frames(3);check(game.state=="rolling","Controller activates Resume")
 game.start_local(0);game.placements=Vector2(-0.85,0.1);key(KEY_SPACE,true);key(KEY_SPACE,false);await frames(2)
 check(not game.rules.ball_in_hand,"Keyboard places cue ball through input pipeline")
 var aim=game.aim;key(KEY_RIGHT,true);await frames(6);key(KEY_RIGHT,false)
 check(game.aim!=aim,"Held keyboard arrow changes aim")
 power=game.power;key(KEY_UP,true);await frames(5);key(KEY_UP,false)
 check(game.power>power,"Held keyboard arrow changes power")
 key(KEY_SPACE,true);key(KEY_SPACE,false);await frames(2);check(game.state=="rolling","Keyboard shoots through input pipeline")
 game.start_local(0);await frames(2)
 var point=game.table.camera.unproject_position(Vector3(-0.85,game.table.BED+game.sim.radius,0.1))
 click(point);await frames(2);check(not game.rules.ball_in_hand and game.state=="aim","Mouse places cue ball without shooting")
 point=game.table.camera.unproject_position(Vector3(0.3,game.table.BED+game.sim.radius,0.1))
 click(point);await frames(2);check(game.aim_locked and game.state=="aim","First cloth click locks aim")
 click(point,MOUSE_BUTTON_RIGHT);await frames(2);check(not game.aim_locked,"Right click unlocks")
 click(point);await frames(2);var locked=game.aim
 click(point);await frames(2);check(game.state=="rolling" and game.aim==locked,"Second cloth click fires locked direction")
 game.start_local(0);game.rules.ball_in_hand=false;game.pause_play();await frames(3)
 power=game.power;click(point,MOUSE_BUTTON_WHEEL_UP);await frames(2)
 check(game.power==power,"Wheel cannot change paused power")
 game.open_menu();game.state="title";await frames(2)
 key(KEY_SPACE,true);key(KEY_SPACE,false);await frames(3)
 check(game.state=="menu" and viewport.gui_get_focus_owner()!=null,"Keyboard starts title and focuses menu")
 key(KEY_DOWN,true);key(KEY_DOWN,false);await frames(2)
 check(viewport.gui_get_focus_owner().text.contains("VERSUS AI"),"Keyboard arrows navigate menu")
 key(KEY_ENTER,true);key(KEY_ENTER,false);await frames(3)
 check(game.ui.menu_page=="ai","Keyboard Enter activates menu")
 game.start_local(0);game.rules.ball_in_hand=false;game.ui.help_panel.visible=true;await frames(3)
 var event=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=true;game._unhandled_input(event)
 check(game.state=="aim","Help modal blocks unhandled shooting keys")
 viewport.get_texture().get_image().save_png("res://qa/device-controls-help.png")
 print("DEVICE INPUT: ",checks," checks, ",failures," failures; connected physical pads: ",Input.get_connected_joypads())
 await game.prepare_to_close();viewport.queue_free();await process_frame;quit(0 if failures==0 else 1)
