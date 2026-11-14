extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 await process_frame
 game.set_process(false);game.set_physics_process(false);game.start_match(0)
 game.sim.place(0,Vector2(-0.9,0.25));game.rules.ball_in_hand=false
 game.ui._process(0)
 check(game.ui.play_button.visible,"Explicit shoot control is visible")
 var p=Vector2(-0.2,0.3)
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 event.position=game.table.camera.unproject_position(Vector3(p.x,game.table.BED+game.sim.radius,p.y))
 game._unhandled_input(event)
 check(game.aim_locked and game.state=="aim","Cloth click locks direction without firing")
 var locked=game.aim
 game.pointer_position=game.table.camera.unproject_position(Vector3(0,game.table.BED+game.sim.radius,-0.3));game._process(0.1)
 check(game.aim==locked,"Moving toward power controls preserves locked direction")
 game.power_drag=true;game.pointer_position=game.ui.get_global_transform()*Vector2(40,300);game._process(0.1)
 check(game.power>0.8,"Power meter can be adjusted independently")
 event.pressed=false;game._input(event)
 check(game.state=="aim" and not game.power_drag,"Releasing power meter does not fire")
 game.table.guide_cached=false;game.table.update_aim(Vector2.RIGHT,0.5,true)
 var dots=game.table.guide_dots
 check(dots.size()>8,"Guide contains individual dots")
 check(dots[0].alpha>dots[-1].alpha,"Guide fades toward distance")
 check(dots[0].spacing<dots[-1].spacing,"Dots are denser near cue ball")
 game.sim.ball(0).p=Vector2(game.sim.half_size.x-game.sim.radius-0.005,0.3)
 game.table.guide_cached=false;game.table.update_aim(Vector2.RIGHT,0.5,true)
 check(game.table.guide.mesh.get_surface_count()==1,"Very short guides near cushion remain valid")
 game.rules.groups=[0,1]
 check(game.ui.collection(0).ids==[1,2,3,4,5,6,7],"Player one shows own solid set")
 check(game.ui.collection(1).ids==[9,10,11,12,13,14,15],"Player two shows own striped set")
 game.sim.begin_shot(0,Vector2.RIGHT,0,Vector2.ZERO)
 var ball=game.sim.ball(1);ball.p=game.sim.pockets()[0]+Vector2(0.03,0.03)
 game.sim._pot(ball,0)
 check(game.sim.pending_drop(),"Pocket animation keeps shot alive")
 var start=ball.p
 ball.fall=0.3;game.table.sync(0)
 var node=game.table.ball_nodes[1]
 check(node.scale==Vector3.ONE,"Dropping ball retains full size")
 check(Vector2(node.position.x,node.position.z).distance_to(start)>0,"Ball rolls into mouth")
 var y=node.position.y;ball.fall=0.8;game.table.sync(0)
 check(node.position.y<y,"Ball accelerates downward into pocket")
 game.state="rolling";ball.fall=0;game.sim.ball(0).v=Vector2.ZERO
 for tick in range(120):game._physics_process(1.0/120.0)
 check(game.state=="aim" and 1 in game.pocketed_by[0],"Potted ball credited to shooter before turn transfers")
 check(not game.sim.pending_drop(),"Drop finishes before next shot")
 game._save_match();game.pocketed_by=[[],[]];game.resume_match()
 check(1 in game.pocketed_by[0],"Player ball record survives resume")
 game.rules.ball_in_hand=false;game.sim.place(0,Vector2(-0.9,0.25));game.state="aim"
 var key=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true;game._unhandled_input(key)
 check(game.state=="rolling","Space fires deliberate shot at selected power")
 check(FileAccess.get_sha256("res://assets/ui/icon.png")=="ddc5d5ad6ef0dc81e26e9db83e2339b3091ea7c3e288aaa98603c64f7e2e32a8","Chosen third icon is installed")
 print("PASS" if failures==0 else "FAIL",": ",checks," presentation checks, ",failures," failures")
 await game.prepare_to_close();quit(0 if failures==0 else 1)
