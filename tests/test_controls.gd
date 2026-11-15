extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func key(game,code: Key,pressed: bool=true):
 var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;game._input(event)
func pad(game,button: int):
 for pressed in [true,false]:
  var event=InputEventJoypadButton.new();event.button_index=button;event.pressed=pressed;game._input(event)
func axis(game,index: int,value: float):
 var event=InputEventJoypadMotion.new();event.axis=index;event.axis_value=value;game._input(event)
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame;game.set_process(false);game.set_physics_process(false);game.sound_enabled=false
 game.start_local(0)
 var start=game.placements
 key(game,KEY_DOWN);game.controls.tick(game,0.1);key(game,KEY_DOWN,false)
 check(game.placements.y>start.y,"Keyboard moves placement without mouse")
 # A valid location behind the head string, away from the rack.
 game.placements=Vector2(-0.85,0.1);key(game,KEY_SPACE)
 check(not game.rules.ball_in_hand and game.state=="aim","Space places without also shooting")
 var angle=game.aim.angle();key(game,KEY_RIGHT);game.controls.tick(game,0.1);key(game,KEY_RIGHT,false)
 check(game.aim.angle()>angle and game.aim_locked,"Keyboard rotates aim")
 var power=game.power;key(game,KEY_UP);game.controls.tick(game,0.1);key(game,KEY_UP,false)
 check(game.power>power,"Keyboard increases power")
 key(game,KEY_I);game.controls.tick(game,0.1);key(game,KEY_I,false)
 check(game.spin.y<0,"Keyboard adjusts spin")
 key(game,KEY_R);check(game.spin==Vector2.ZERO,"Keyboard resets spin")
 key(game,KEY_E);check(game.rules.called_pocket==0,"Keyboard cycles pocket")
 key(game,KEY_SPACE);check(game.state=="rolling","Keyboard fires")
 game.start_local(0);game.placements=Vector2(-0.85,0.1);pad(game,JOY_BUTTON_A)
 check(not game.rules.ball_in_hand and game.state=="aim","Gamepad places without firing")
 var old_aim=game.aim
 axis(game,JOY_AXIS_LEFT_X,0.1);game.controls.tick(game,0.1)
 check(game.aim==old_aim,"Analog deadzone rejects drift")
 axis(game,JOY_AXIS_LEFT_X,0.7);axis(game,JOY_AXIS_LEFT_Y,-0.8);game.controls.tick(game,0.1)
 check(game.aim.x>0 and game.aim.y<0 and game.aim_locked,"Gamepad stick aims")
 power=game.power;axis(game,JOY_AXIS_TRIGGER_RIGHT,0.9);game.controls.tick(game,0.1)
 check(game.power>power,"Trigger raises power")
 axis(game,JOY_AXIS_RIGHT_X,-0.9);game.controls.tick(game,0.1)
 check(game.spin.x<0,"Right stick adjusts spin")
 pad(game,JOY_BUTTON_Y);check(game.spin==Vector2.ZERO,"Gamepad resets spin")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER);check(game.rules.called_pocket==0,"Bumper calls pocket")
 pad(game,JOY_BUTTON_START);check(game.state=="paused","Start pauses")
 power=game.power;angle=game.aim.angle();game.controls.tick(game,1.0)
 check(game.power==power and game.aim.angle()==angle,"Pause freezes held adjustments")
 pad(game,JOY_BUTTON_START);check(game.state=="aim","Start resumes")
 pad(game,JOY_BUTTON_A);check(game.state=="rolling","Gamepad fires")
 game.start_local(2);game.rules.ball_in_hand=false;game.rules.break_shot=false;game.ui.refresh_calls();game.ui.call_choice.visible=true
 pad(game,JOY_BUTTON_X);check(game.rules.called_ball>0,"Gamepad selects called ball")
 key(game,KEY_C);check(game.rules.called_ball>0,"Keyboard selects called ball")
 game.launch_tournament("ACE");game.begin_frame();game.rules.ball_in_hand=false;game.rules.player=1
 pad(game,JOY_BUTTON_A);check(game.state=="aim","Gamepad cannot shoot AI turn")
 key(game,KEY_SPACE);check(game.state=="aim","Keyboard cannot shoot AI turn")
 game.ai_mode=0;game.controls.keys[KEY_RIGHT]=true;game.controls.axes[JOY_AXIS_LEFT_X]=1.0
 game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(game.controls.keys.is_empty() and game.controls.axes.is_empty(),"Lost window focus clears held inputs")
 print("CONTROLS: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();game.queue_free();await process_frame;quit(0 if failures==0 else 1)
