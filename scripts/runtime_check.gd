extends Node
var failures=0
var checks=0
var presented=false
var rendered_frames=0
func draw_frame():
 if not presented:RenderingServer.force_draw(false)
func check(value: bool,label: String):
 checks+=1
 if not value: failures+=1;push_error(label)
func _ready():call_deferred("run")
func sample(frames: int) -> Dictionary:
 for i in range(60):
  await get_tree().process_frame
  draw_frame()
 var drawn_before=rendered_frames
 var draw_usec=0;var wait_usec=0
 var times: Array[float]=[];var last=Time.get_ticks_usec()
 for i in range(frames):
  var before_wait=Time.get_ticks_usec()
  await get_tree().process_frame
  var before_draw=Time.get_ticks_usec();wait_usec+=before_draw-before_wait
  draw_frame()
  draw_usec+=Time.get_ticks_usec()-before_draw
  var now=Time.get_ticks_usec();times.append((now-last)/1000.0);last=now
 var total=0.0
 for value in times:total+=value
 times.sort()
 return {"rendered_frames":rendered_frames-drawn_before,"average_force_draw_ms":draw_usec/1000.0/frames,"average_frame_wait_ms":wait_usec/1000.0/frames,"fps":frames*1000.0/total,"p95_ms":times[int(frames*0.95)],"p99_ms":times[int(frames*0.99)],"worst_ms":times.back(),"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)}
func run():
 print("PACKAGED QA: entering controller")
 var game=get_parent()
 game.sound_enabled=false
 if "--qa-high" not in OS.get_cmdline_user_args():game.toggle_quality()
 if "--qa-uncapped" in OS.get_cmdline_user_args():Engine.max_fps=0
 print("PACKAGED QA: main scene ready")
 check(game.state=="menu","Packaged game opens menu")
 check(game.sfx.size()>=4,"Embedded impact sounds load")
 check(game.ui.bold!=null,"Embedded UI font loads")
 check(game.music_player.stream!=null and game.music_player.stream.get_length()>60,"Supplied lobby music is embedded and decodes")
 check(game.ui.ai_page.find_children("*","OptionButton",true,false).is_empty(),"AI entry has no skill or opponent selectors")
 check(game.campaign.roster.size()==48,"All 48 rivals are embedded")
 check(game.list_save_slots().size()==10,"Exactly ten manual tournament slots are available")
 check(game.ui.slot_buttons.size()==10,"Separate save menu has ten slot controls")
 check(game.ui.settings.get_node("ResumePlay")!=null,"Pause includes explicit Resume play control")
 var result_lines={}
 for rival in game.campaign.roster:
  for outcome in ["win","loss"]:result_lines[rival.get("result_"+outcome+"_quote","")]=true
 check(result_lines.size()==96 and not result_lines.has(""),"All 96 individual result lines are embedded")
 for tier in range(4):
  for outcome in ["win","loss"]:check(ResourceLoader.exists("res://assets/characters/results/tier_%d_%s.png" % [tier,outcome]),"Rival outcome atlas %d %s is embedded" % [tier,outcome])
 check(ResourceLoader.exists("res://assets/characters/title_hero.png"),"Comic title hero is embedded")
 check(ResourceLoader.exists("res://assets/characters/title_group.png"),"Group title portrait is embedded")
 check(ResourceLoader.exists("res://assets/characters/champion_trophy.png"),"Champion trophy scene is embedded")
 for tier in range(4):check(ResourceLoader.exists("res://assets/characters/tier_%d.png" % tier),"Rival portrait atlas %d is embedded" % tier)
 for tier in range(1,4):check(ResourceLoader.exists("res://assets/table/tier_%d.png" % tier),"Upgraded table %d is embedded" % tier)
 # An offscreen viewport ensures the GPU is exercised even if the desktop
 # compositor suspends an occluded test window. The player path is unchanged.
 presented="--qa-presented" in OS.get_cmdline_user_args()
 var viewport: Viewport=game.get_viewport()
 if presented:
  DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
  DisplayServer.window_move_to_foreground()
 else:
  var offscreen=SubViewport.new();offscreen.size=DisplayServer.window_get_size()
  offscreen.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  offscreen.own_world_3d=true;offscreen.msaa_3d=viewport.msaa_3d
  offscreen.scaling_3d_scale=viewport.scaling_3d_scale
  get_tree().root.add_child(offscreen);game.reparent(offscreen);viewport=offscreen
  game.table.camera.current=true;game.table._position_camera()
  RenderingServer.render_loop_enabled=false
 RenderingServer.frame_post_draw.connect(func():rendered_frames+=1)

 var qa_dir=OS.get_environment("QB_QA_DIR")
 game.state="title"
 for i in range(3):await get_tree().process_frame;draw_frame()
 if qa_dir!="":viewport.get_texture().get_image().save_png(qa_dir.path_join("packaged-title.png"))
 game.ui.show_hub()
 for mode in range(10):
  print("PACKAGED QA: loading mode ",mode)
  game.start_match(mode)
  check(game.table.ball_nodes.size()==game.sim.balls.size(),"Packaged mode actors %d" % mode)
  check(not game.sim.balls.is_empty(),"Packaged mode has balls %d" % mode)
  await get_tree().process_frame
 game.start_match(0);game.rules.ball_in_hand=false;game.sim.place(0,Vector2(-0.82,0.025));game.aim=Vector2.RIGHT;game.power=0.85;game.strike()
 print("PACKAGED QA: sampling pool")
 var pool=await sample(600)
 check(pool.draw_calls>0 and pool.rendered_frames>=590,"Pool benchmark performed real GPU draws")
 check(pool.fps>=59.0,"Packaged pool meets 60 fps target on development laptop")
 game.ui.help_panel.visible=false
 draw_frame()
 if qa_dir!="":viewport.get_texture().get_image().save_png(qa_dir.path_join("packaged-pool.png"))
 game.start_match(5);game.rules.ball_in_hand=false;game.sim.place(0,Vector2(-1.27,0));game.aim=Vector2.RIGHT;game.power=0.8;game.strike()
 print("PACKAGED QA: sampling snooker")
 var snooker=await sample(360)
 check(snooker.draw_calls>0 and snooker.rendered_frames>=350,"Snooker benchmark performed real GPU draws")
 check(snooker.fps>=59.0,"Packaged snooker meets 60 fps target on development laptop")
 if qa_dir!="":
  draw_frame();viewport.get_texture().get_image().save_png(qa_dir.path_join("packaged-snooker.png"))
 game.launch_tournament("QA PLAYER");game.campaign.rival_index=47;game.campaign.wins=47;game._start_ai_frame();game.begin_frame()
 print("PACKAGED QA: sampling GOAT AI match")
 var versus_ai=await sample(360)
 check(versus_ai.draw_calls>0 and versus_ai.rendered_frames>=350,"GOAT AI match performed real GPU draws")
 check(versus_ai.fps>=59.0,"Native-resolution GOAT AI match meets the average 60 fps target")
 check(not game.sim.shot.is_empty(),"Compiled AI planner placed and struck its break")
 if qa_dir!="":
  draw_frame();viewport.get_texture().get_image().save_png(qa_dir.path_join("packaged-goat-ai.png"))
  var file=FileAccess.open(qa_dir.path_join("packaged-performance.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify({"measurement":"Normal presented window" if presented else "Forced offscreen GPU render; frame_limit and render_scale recorded separately",
   "quality":"High" if game.high_quality else "Performance","frame_limit":Engine.max_fps,"render_scale":viewport.scaling_3d_scale,"renderer":RenderingServer.get_video_adapter_name(),"resolution":DisplayServer.window_get_size(),"pool":pool,"snooker":snooker,"versus_ai":versus_ai,"checks":checks,"failures":failures},"\t"));file.close()
 print("PACKAGED BUILD: ","PASS" if failures==0 else "FAIL"," · ",checks," checks · pool ",pool.fps," fps · snooker ",snooker.fps," fps · AI ",versus_ai.fps," fps")
 await game.prepare_to_close()
 get_tree().quit(0 if failures==0 else 1)
