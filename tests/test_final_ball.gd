extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame;game.set_process(false);game.set_physics_process(false)
 game.launch_tournament("ACE");game.begin_frame();game.rules.ball_in_hand=false;game.rules.baulk_only=false;game.rules.break_shot=false;game.rules.groups=[0,1]
 for id in range(1,8):game.sim.ball(id).active=false;game.sim.ball(id).fall=1.0
 game.sim.place(0,Vector2(-0.7,0.3));game.sim.ball(8).p=Vector2(-0.2,-0.2)
 game.aim=(game.sim.ball(8).p-game.sim.ball(0).p).normalized();game.aim_locked=true;game.power=0.47
 game.strike();game.ui._process(0)
 check(game.state=="aim" and game.sim.ball(0).v==Vector2.ZERO,"Reproduces blocked final shot before pocket call")
 check("8-ball" in game.rules.message and "8-ball" in game.ui.shot_hint(),"Required call is visible in both message and footer")
 check(game.ui.play_button.text.begins_with("CHOOSE POCKET"),"Shoot control explains the missing selection")
 var shown=0
 for button in game.ui.pocket_buttons:
  if button.visible:shown+=1
 check(shown==6,"All six clickable pockets are shown for final ball")
 var aim=game.aim;var power=game.power
 game.ui.pocket_buttons[2].pressed.emit();game.ui._process(0)
 check(game.rules.called_pocket==2 and game.shot_call_prompt().is_empty(),"Clicking a numbered pocket satisfies rule")
 check(game.aim==aim and game.power==power and game.state=="aim","Calling pocket preserves aim and power without firing")
 check(game.ui.play_button.text=="SHOOT  [CLICK]","Shoot label returns after valid call")
 check("POCKET 3 CALLED" in game.ui.shot_hint(),"Selected pocket remains visible")
 game.save_slot(0);game.rules.called_pocket=-1
 check(game.load_slot(0) and game.rules.called_pocket==2,"Pocket selection survives saved-game resume")
 game.resume_play();game.ui.play_button.pressed.emit()
 check(game.state=="rolling" and game.sim.ball(0).v.length()>0,"Shoot button fires after pocket selection")
 for index in range(6):
  game.state="aim";game.rules.called_pocket=-1
  var key=InputEventKey.new();key.keycode=KEY_1+index;key.pressed=true;game._unhandled_input(key)
  check(game.rules.called_pocket==index,"Keyboard calls numbered pocket %d" % (index+1))
 game.state="paused";var old=game.rules.called_pocket;game.select_pocket(0)
 check(game.rules.called_pocket==old,"Pause prevents pocket selection")
 game.start_match(0);check(not game.needs_pocket_call(),"Ordinary open-table shots require no call")
 game.start_match(4);game.rules.groups=[0,1]
 for id in range(1,8):game.sim.ball(id).active=false
 check(not game.needs_pocket_call(),"Blackball keeps its no-call rule")
 for mode in [2,3]:
  game.start_match(mode);game.rules.break_shot=false;game.rules.ball_in_hand=false
  check(game.shot_call_prompt().begins_with("Select"),"Called-shot mode explains missing ball")
  game.rules.called_ball=1;check(game.needs_pocket_call() and not game.shot_call_prompt().is_empty(),"Called-shot mode explains missing pocket")
  game.select_pocket(1);check(game.shot_call_prompt().is_empty(),"Called ball plus pocket permits shot")
 print("FINAL BALL: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();quit(0 if failures==0 else 1)
