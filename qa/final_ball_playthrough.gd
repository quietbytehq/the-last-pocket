extends SceneTree
var viewport: SubViewport
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1;print("PASS · " if value else "FAIL · ",label)
 if not value:failures+=1
func _initialize():call_deferred("run")
func frames(count: int):
 for i in range(count):await process_frame;RenderingServer.force_draw(false)
func click(button: Button):
 var point=button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;viewport.push_input(event)
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.start_match(0);game.rules.ball_in_hand=false;game.rules.baulk_only=false;game.rules.break_shot=false;game.rules.groups=[0,1];game.rules.names=["ACE","BENNY BANKS"]
 for ball in game.sim.balls:
  if ball.id not in [0,8,11,13]:ball.active=false;ball.fall=1.0
 game.sim.place(0,Vector2(-0.7,0.3));game.sim.ball(8).p=Vector2(-0.2,-0.2);game.sim.ball(11).p=Vector2(-0.3,0.5);game.sim.ball(13).p=Vector2(-1.1,0.2)
 game.aim=(game.sim.ball(8).p-game.sim.ball(0).p).normalized();game.aim_locked=true;game.power=0.45
 viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport);game.reparent(viewport);game.table.camera.current=true;game.table._position_camera()
 await frames(8)
 check(game.ui.play_button.text.begins_with("CHOOSE POCKET"),"Final-ball control explains missing call before clicking")
 click(game.ui.play_button);await frames(3)
 check(game.state=="aim" and "8-ball" in game.rules.message,"Attempted uncalled shot gives explicit feedback")
 viewport.get_texture().get_image().save_png("res://qa/final-ball-prompt.png")
 var aim=game.aim;var power=game.power
 click(game.ui.pocket_buttons[2]);await frames(3)
 check(game.rules.called_pocket==2,"Actual mouse click selects pocket 3")
 check(game.aim==aim and game.power==power,"Pocket selection preserves locked aim and power")
 check(game.ui.play_button.text=="SHOOT  [SPACE]","Shot becomes ready after pocket call")
 viewport.get_texture().get_image().save_png("res://qa/final-ball-called.png")
 click(game.ui.play_button);await frames(3)
 check(game.state=="rolling" and game.sim.ball(0).v.length()>0,"Actual Shoot click launches the final-ball shot")
 print("FINAL BALL INPUT: ",checks," checks, ",failures," failures")
 await game.prepare_to_close();viewport.queue_free();await process_frame;quit(0 if failures==0 else 1)
