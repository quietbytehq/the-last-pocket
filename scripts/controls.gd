extends RefCounted
# Input state belongs to the player device, never to a saved match.
var mode="mouse"
var keys={}
var axes={}
const DEADZONE=0.20
func clear():
 keys.clear();axes.clear()
func axis(index: int) -> float:
 var value=float(axes.get(index,0.0))
 return signf(value)*(absf(value)-DEADZONE)/(1.0-DEADZONE) if absf(value)>DEADZONE else 0.0
func held(positive: Array,negative: Array) -> float:
 var result=0.0
 for key in positive:
  if keys.get(key,false):result+=1.0;break
 for key in negative:
  if keys.get(key,false):result-=1.0;break
 return result
func tick(game,dt: float):
 if game.state!="aim" or not game.human_turn() or game.ui.help_panel.visible:return
 var fine=keys.get(KEY_SHIFT,false)
 var horizontal=held([KEY_RIGHT,KEY_D],[KEY_LEFT,KEY_A])
 var vertical=held([KEY_DOWN,KEY_S],[KEY_UP,KEY_W])
 var stick=Vector2(axis(JOY_AXIS_LEFT_X),axis(JOY_AXIS_LEFT_Y))
 if game.rules.ball_in_hand:
  var movement=Vector2(horizontal,vertical) if mode=="keyboard" else stick if mode=="gamepad" else Vector2.ZERO
  game.placements=(game.placements+movement.limit_length(1.0)*dt*(0.12 if fine else 0.75)).clamp(-game.sim.half_size+Vector2.ONE*game.sim.radius,game.sim.half_size-Vector2.ONE*game.sim.radius)
 else:
  if mode=="keyboard" and horizontal!=0:
   game.aim=game.aim.rotated(horizontal*dt*(0.22 if fine else 1.4));game.aim_locked=true
  if mode=="gamepad" and stick.length()>0.15:
   game.aim=stick.normalized();game.aim_locked=true
  if mode=="gamepad":
   horizontal=held([JOY_BUTTON_DPAD_RIGHT],[JOY_BUTTON_DPAD_LEFT])
   if horizontal!=0:game.aim=game.aim.rotated(horizontal*dt*0.22);game.aim_locked=true
 var power_delta=-vertical if mode=="keyboard" else axis(JOY_AXIS_TRIGGER_RIGHT)-axis(JOY_AXIS_TRIGGER_LEFT)+held([JOY_BUTTON_DPAD_UP],[JOY_BUTTON_DPAD_DOWN]) if mode=="gamepad" else 0.0
 game.power=clampf(game.power+power_delta*dt*0.45,0.03,1.0)
 if mode=="keyboard":
  game.spin=(game.spin+Vector2(held([KEY_L],[KEY_J]),held([KEY_K],[KEY_I]))*dt*0.8).limit_length(1.0)
 elif mode=="gamepad":
  var english=Vector2(axis(JOY_AXIS_RIGHT_X),axis(JOY_AXIS_RIGHT_Y))
  if english.length()>0.05:game.spin=english.limit_length(1.0)
func confirm(game):
 if game.rules.ball_in_hand:
  if game.rules.is_placement_legal(game.placements,game.sim):
   game.sim.place(game.rules.cue_id(),game.placements);game.rules.ball_in_hand=false;game.rules.baulk_only=false
   game.rules.message="Cue ball placed · aim, set power, then shoot."
  else:game.rules.message="Choose a clear legal cue-ball position."
 else:game.strike()
func cycle_ball(game):
 var choice=game.ui.call_choice
 if not choice.visible or choice.item_count==0:return
 var index=(choice.selected+1)%choice.item_count
 if choice.get_item_id(index)<0:index=(index+1)%choice.item_count
 choice.select(index);game.ui._call_selected(index)
func cycle_pocket(game,direction: int):
 game.select_pocket(posmod(game.rules.called_pocket+direction,6))
