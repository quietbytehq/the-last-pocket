extends Node3D
const Physics=preload("res://scripts/physics.gd")
const Rules=preload("res://scripts/rules.gd")
const Table=preload("res://scripts/table.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Board=preload("res://scripts/leaderboard.gd")
const AIPlanner=preload("res://scripts/ai.gd")
const Overlay=preload("res://scripts/overlay.gd")
var campaign=Campaign.new()
var leaderboard=Board.new()
var ai_mode=0
var ai_thread: Thread
var ai_generation=0
var thread_generation=0
var ai_delay=0.0
var ai_result: Dictionary={}
var music_tracks: Dictionary={}
var current_music=""
var pause_origin="aim"
const SAVE_SLOTS=10
var prewarm_frames=4
var sim=Physics.new()
var rules=Rules.new()
var table
var ui
var state: String="menu"
var power: float=0.45
var spin =Vector2.ZERO
var aim =Vector2.RIGHT
var aim_locked=false
var pocketed_by: Array=[[],[]]
var charging =false
var power_drag =false
var spin_drag =false
var charge_elapsed =0.0
var charge_origin =Vector2.ZERO
var before: Dictionary={}
var stationary_time =0.0
var high_quality =true
var sound_enabled =true
var music_enabled = true
var music_player: AudioStreamPlayer
var volume =0.65
var sfx: Dictionary={}
var active_voices: Array[AudioStreamPlayer]=[]
var pointer_position = Vector2.ZERO
var placements =Vector2.ZERO
var auto_capture =false
var frame_times: Array[float]=[]
var qa_mode := false
var quitting := false
var show_debug := false
var play_time =0.0

func _ready() -> void:
 qa_mode="--self-test" in OS.get_cmdline_user_args()
 Engine.max_fps=60
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 get_tree().auto_accept_quit=false
 get_tree().root.close_requested.connect(quit_game)
 pointer_position=get_viewport().get_mouse_position()
 DisplayServer.window_set_title("The Last Pocket")
 table=Table.new();add_child(table)
 var layer =CanvasLayer.new();layer.layer=1;add_child(layer)
 ui=Overlay.new();ui.game=self;layer.add_child(ui)
 if not qa_mode: _load_settings()
 _load_audio()
 ui.name_one.text=rules.names[0];ui.name_two.text=rules.names[1]
 rules.configure(0,sim);table.configure(sim,rules);ui.prime_ball_badges();ui.refresh_calls()
 get_viewport().size_changed.connect(func():table._position_camera();_apply_render_scale())
 _apply_render_scale()
 if not qa_mode and not get_meta("skip_title",false):state="title"
 _music_context()
 if qa_mode:
  var checker=load("res://scripts/runtime_check.gd").new()
  add_child(checker)

func start_match(mode: int) -> void:
 _invalidate_ai()
 if campaign.kind=="local":campaign.phase="playing";campaign.finished=false;campaign.last_won=false
 table.upgrade=campaign.tier() if campaign.kind!="local" else 0
 rules.configure(mode,sim);table.configure(sim,rules);ui.prime_ball_badges();_apply_render_scale()
 state="aim";aim_locked=false;pocketed_by=[[],[]];charging=false;spin=Vector2.ZERO;power=0.45;stationary_time=0
 ui.help_panel.visible=false;ui.refresh_calls()
 placements=sim.ball(rules.cue_id()).p
 # Do not leave a solid cue-ball model at the default position during placement.
 if rules.ball_in_hand:
  sim.ball(rules.cue_id()).active=false;sim.ball(rules.cue_id()).fall=1.0
 _play_sound("start")

func _physics_process(dt: float) -> void:
 if state!="rolling": return
 sim.step(dt)
 if not sim.is_moving():
  stationary_time+=dt
  if stationary_time>0.32 and not sim.pending_drop():
   for pot in sim.shot.get("potted",[]):
    if pot.id!=rules.cue_id():pocketed_by[rules.player].append(pot.id)
   for ledger in pocketed_by:
    while ledger.size()>512:ledger.pop_front()
   rules.resolve(sim,before);aim_locked=false;state="aim";stationary_time=0;spin=Vector2.ZERO;ui.refresh_calls()
   if rules.match_over:_match_finished()
   elif "FOUL" in rules.message:_play_sound("foul")
 else: stationary_time=0
 var events: Array=sim.collisions.duplicate();sim.collisions.clear()
 var handled =0
 for event in events:
  if handled>=4: break
  _play_sound(event.kind,clampf(event.speed/2.5,0.12,0.9),event.p.x/sim.half_size.x)
  handled+=1

func _process(dt: float) -> void:
 play_time+=dt
 _tick_ai(dt)
 if state!="menu" and state!="paused":
  frame_times.append(dt)
  if frame_times.size()>3600: frame_times.pop_front()
 if state in ["aim","intro","result"]:
  for b in sim.balls:
   if not b.active: b.fall=minf(1.0,b.fall+dt/Physics.DROP_DURATION)
 table.sync(dt)
 table.advance_guide_animation(dt if state=="aim" and human_turn() else 0.0)
 table.hide_prewarm()
 if prewarm_frames>0 and state in ["title","menu"]:
  # Compile cue and transparent guide shaders behind the opaque title art.
  table.update_aim(Vector2.RIGHT,0.45,true);table.prewarm_pocket_shader();prewarm_frames-=1
 elif state=="aim" and not rules.match_over and human_turn():
  var mouse =pointer_position
  var point: Vector2=table.screen_to_table(mouse)
  var b: Dictionary=sim.ball(rules.cue_id())
  if rules.ball_in_hand:
   placements=point.clamp(-sim.half_size+Vector2.ONE*sim.radius,sim.half_size-Vector2.ONE*sim.radius)
  elif not aim_locked and not charging and not power_drag and not spin_drag and (ui.get_global_transform().affine_inverse()*pointer_position).y>145 and (ui.get_global_transform().affine_inverse()*pointer_position).y<760 and absf(point.x)<=sim.half_size.x+0.04 and absf(point.y)<=sim.half_size.y+0.04:
   var direction: Vector2=point-b.p
   if direction.length()>sim.radius: aim=direction.normalized()
  if power_drag:
   power=clampf((680-(ui.get_global_transform().affine_inverse()*pointer_position).y)/466.0,0.03,1.0)
  if spin_drag: spin=(((ui.get_global_transform().affine_inverse()*pointer_position)-Vector2(1534,836))/30.0).limit_length(1.0)
  table.update_aim(aim,power,true,rules.ball_in_hand,placements)
 elif state=="aim" and not human_turn() and not ai_result.is_empty() and ai_result.has("aim"):
  table.update_aim(ai_result.aim,ai_result.power,true);table.guide.visible=false
 else:
  table.update_aim(aim,0,false)

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  pointer_position=event.position
 if state=="title":
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_M:toggle_sound()
   elif event.keycode==KEY_N:toggle_music()
  if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
   state="menu";ui.show_hub();_play_sound("ui_confirm");get_viewport().set_input_as_handled()
  return
 if not human_turn():return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
  if charging or power_drag or spin_drag:
   charging=false;power_drag=false;spin_drag=false
   get_viewport().set_input_as_handled()
 if event is InputEventKey and event.keycode==KEY_SPACE and not event.pressed and charging:
  charging=false;get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_M:toggle_sound();return
  if event.keycode==KEY_N:toggle_music();return
 if state=="saves":
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:ui.close_saves()
  return
 if state=="journey":
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:ui.close_journey()
  return
 if state in ["intro","result"]:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_ENTER:
    if state=="intro":begin_frame()
    else:result_primary()
   elif event.keycode==KEY_ESCAPE:open_menu()
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_F11:
   var fullscreen =DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN);return
  if event.keycode==KEY_ESCAPE:
   if ui.help_panel.visible: ui.help_panel.visible=false
   elif state=="menu":
    if ui.menu_page!="hub":ui.show_hub()
    else:state="title"
   else: toggle_pause()
   return
  if event.keycode==KEY_F3: show_debug=not show_debug;return
  if event.keycode==KEY_TAB: switch_camera();return
  if event.keycode==KEY_M: toggle_sound();return
  if event.keycode==KEY_H: ui.help_panel.visible=not ui.help_panel.visible;return
  if event.keycode==KEY_N: toggle_music();return
  if not human_turn():return
  if event.keycode==KEY_ENTER:
   if rules.match_over: start_match(rules.mode)
   else: strike()
   return
  if state=="aim" and event.keycode>=KEY_1 and event.keycode<=KEY_6:
   select_pocket(event.keycode-KEY_1);return
  if event.keycode==KEY_SPACE and state=="aim" and not rules.ball_in_hand:
   strike();return
 if event is InputEventKey and not event.pressed and event.keycode==KEY_SPACE and charging:
  charging=false;return
 if event is InputEventMouseButton:
  if not human_turn():return
  if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: power=clampf(power+0.05,0.03,1.0);return
  if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: power=clampf(power-0.05,0.03,1.0);return
  if state!="aim" or rules.match_over or ui.help_panel.visible: return
  var local: Vector2=ui.get_global_transform().affine_inverse()*event.position
  if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
   if local.distance_to(Vector2(1534,836))<65:spin=Vector2.ZERO
   else:aim_locked=false
   return
  if event.button_index!=MOUSE_BUTTON_LEFT: return
  if not event.pressed:
   spin_drag=false
   if charging or power_drag:
    charging=false;power_drag=false
   return
  if local.distance_to(Vector2(1534,836))<65:
   spin_drag=true;return
  if Rect2(20,200,60,490).has_point(local):
   power_drag=true;return
  if local.y<145 or local.y>760: return
  var p: Vector2=table.screen_to_table(event.position)
  if rules.ball_in_hand:
   if rules.is_placement_legal(p,sim):
    sim.place(rules.cue_id(),p);rules.ball_in_hand=false;rules.baulk_only=false
    rules.message="%s · aim, set power, then press SPACE to shoot" % rules.names[rules.player]
   else: rules.message="Choose a clear legal position%s" % (" inside the D" if rules.is_snooker() else " on the cloth")
   return
  if sim.pocketed_table:
   for k in range(sim.pockets().size()):
    if p.distance_to(sim.pockets()[k])<sim.pocket_radius*1.6: select_pocket(k);return
  if p.distance_to(sim.ball(rules.cue_id()).p)>sim.radius:
   aim=(p-sim.ball(rules.cue_id()).p).normalized();aim_locked=true

func needs_pocket_call() -> bool:
 return (rules.mode==0 and rules.groups[rules.player]>=0 and rules.remaining_group(sim,rules.groups[rules.player])==0) or (rules.mode in [2,3] and not rules.break_shot)

func shot_call_prompt() -> String:
 if rules.mode in [2,3] and not rules.break_shot and rules.called_ball<0:
  return "Select your called ball below, then choose a numbered pocket."
 if needs_pocket_call() and rules.called_pocket<0:
  return "8-ball: choose a pocket — click 1–6 on the table or press its number." if rules.mode==0 else "Choose a pocket — click 1–6 on the table or press its number."
 return ""

func select_pocket(index: int) -> void:
 if state!="aim" or not human_turn() or not sim.pocketed_table or index<0 or index>5:return
 rules.called_pocket=index
 rules.message="Pocket %d called · adjust your aim and power, then shoot." % (index+1)

func strike(from_ai: bool=false) -> void:
 if not from_ai and not human_turn():return
 if state!="aim" or rules.ball_in_hand or rules.match_over: return
 var requirement=shot_call_prompt()
 if not requirement.is_empty():
  rules.message=requirement;return
 if campaign.kind=="tournament" and rules.player==0:campaign.shots+=1
 before=rules.before_shot(sim)
 sim.begin_shot(rules.cue_id(),aim,0.35+power*5.1,Vector2(spin.x,-spin.y))
 state="rolling";charging=false;stationary_time=0
 _play_sound("cue",0.3+power*0.6,sim.ball(rules.cue_id()).p.x/sim.half_size.x)

func open_menu() -> void:
 _invalidate_ai();_stop_spoken()
 state="menu";charging=false;power_drag=false;spin_drag=false;ui.help_panel.visible=false
 ui.show_hub();_music_context()
func pause_play() -> void:
 if state not in ["aim","rolling"]:return
 pause_origin=state;state="paused"
 charging=false;power_drag=false;spin_drag=false;ui.help_panel.visible=false

func resume_play() -> void:
 if state!="paused":return
 state=pause_origin if pause_origin in ["aim","rolling"] else "aim"
 ui.help_panel.visible=false

func toggle_pause() -> void:
 if state=="paused":resume_play()
 else:pause_play()

func switch_camera() -> void:
 table.elevated_view=not table.elevated_view;table._position_camera()
func _apply_render_scale() -> void:
 # Keep the interface native and limit only the 3D pixel workload.
 var width=maxf(get_viewport().get_visible_rect().size.x,1.0)
 get_viewport().scaling_3d_scale=1.0 if table.baked_table else minf(1.0,(1440.0 if high_quality else 1152.0)/width)
 table.edge_filter.visible=table.baked_table and not high_quality
 if table.baked_table:
  get_viewport().msaa_3d=Viewport.MSAA_4X if high_quality else Viewport.MSAA_DISABLED

func toggle_quality() -> void:
 high_quality=not high_quality
 _apply_render_scale()
 get_viewport().msaa_3d=Viewport.MSAA_4X if high_quality else Viewport.MSAA_DISABLED
 for child in table.get_children():
  if child is DirectionalLight3D: child.shadow_enabled=high_quality
 _save_settings()
func toggle_sound() -> void:
 sound_enabled=not sound_enabled
 if not sound_enabled:
  for voice in active_voices:
   if is_instance_valid(voice):voice.stop();voice.queue_free()
  active_voices.clear()
 _save_settings()
func _external_mp3(path: String) -> AudioStreamMP3:
 if not FileAccess.file_exists(path): return null
 var bytes=FileAccess.get_file_as_bytes(path)
 if bytes.is_empty(): return null
 var stream=AudioStreamMP3.new();stream.data=bytes
 return stream if stream.get_length()>0 else null

func _audio_asset(name: String) -> AudioStream:
 # Personal MP3 exports can be dropped beside the executable without a rebuild.
 var external_dir=OS.get_executable_path().get_base_dir().path_join("audio")
 if OS.has_feature("editor"): external_dir=ProjectSettings.globalize_path("res://assets/audio")
 var personal=_external_mp3(external_dir.path_join(name+".mp3"))
 if personal!=null: return personal
 for ext in ["mp3","ogg","wav"]:
  var path="res://assets/audio/%s.%s" % [name,ext]
  if ResourceLoader.exists(path): return load(path) as AudioStream
 return null

func _load_audio() -> void:
 music_player=AudioStreamPlayer.new();add_child(music_player)
 for name in ["cue","ball","rail","pocket","start","win","ui_move","ui_confirm","ui_back","rival_reveal","foul","diamond_spend","stage_unlock","match_win","match_lose","new_record","tournament_win","voice_hero_start","voice_hero_win","voice_hero_lose","voice_continue"]:
  var stream=_audio_asset(name)
  if stream!=null: sfx[name]=stream
func _play_sound(name: String,gain: float=0.6,pan: float=0.0) -> void:
 if not sfx.has(name) and name.begins_with("voice_"):
  var clip=_audio_asset(name)
  if clip!=null:sfx[name]=clip
 if not sound_enabled or not sfx.has(name): return
 active_voices=active_voices.filter(func(v):return is_instance_valid(v))
 if active_voices.size()>=10: return
 var used=[]
 for old in active_voices: used.append(old.get_meta("slot",-1))
 var slot=0
 while slot in used: slot+=1
 var bus_name="BilliardsImpact"+str(slot)
 var bus=AudioServer.get_bus_index(bus_name)
 if bus<0:
  AudioServer.add_bus();bus=AudioServer.bus_count-1;AudioServer.set_bus_name(bus,bus_name);AudioServer.set_bus_send(bus,"Master");AudioServer.add_bus_effect(bus,AudioEffectPanner.new())
 var panner=AudioServer.get_bus_effect(bus,0) as AudioEffectPanner
 panner.pan=clampf(pan*0.75,-0.75,0.75)
 var voice =AudioStreamPlayer.new();voice.bus=bus_name;voice.set_meta("slot",slot);voice.set_meta("clip",name);add_child(voice);voice.stream=sfx[name];voice.volume_db=linear_to_db(maxf(0.001,gain*volume));voice.pitch_scale=randf_range(0.98,1.02) if name in ["ball","rail"] else 1.0
 # Keep stereo recordings, with subtle left/right placement across the table.
 voice.finished.connect(voice.queue_free);voice.play();active_voices.append(voice)
func _save_settings() -> void:
 if qa_mode: return
 var config =ConfigFile.new();config.set_value("display","high_quality",high_quality);config.set_value("audio","enabled",sound_enabled);config.set_value("audio","music",music_enabled);config.save("user://settings.cfg")
func _load_settings() -> void:
 high_quality=false
 var config =ConfigFile.new()
 if config.load("user://settings.cfg")==OK:
  high_quality=bool(config.get_value("display","high_quality",false));sound_enabled=bool(config.get_value("audio","enabled",true));music_enabled=bool(config.get_value("audio","music",true))
 if not high_quality:
  high_quality=true;toggle_quality()
func quit_game() -> void:
 if quitting: return
 quitting=true
 _save_settings()
 state="closing"
 await prepare_to_close()
 get_tree().quit()

func _stop_audio() -> void:
 if is_instance_valid(music_player):
  music_player.stop();music_player.stream=null
 for voice in active_voices:
  if is_instance_valid(voice):
   voice.stop();voice.stream=null
   if not voice.is_queued_for_deletion(): voice.queue_free()
 active_voices.clear();sfx.clear();music_tracks.clear()
 for index in range(AudioServer.bus_count-1,0,-1):
  if AudioServer.get_bus_name(index).begins_with("BilliardsImpact"):
   AudioServer.remove_bus(index)

func prepare_to_close() -> void:
 _join_ai()
 _stop_audio()
 # Allow the audio mixer to release playback references before engine teardown.
 await get_tree().create_timer(0.12).timeout

func _exit_tree() -> void:
 _join_ai()
 _stop_audio()

func toggle_music() -> void:
 music_enabled=not music_enabled
 if is_instance_valid(music_player): music_player.stream_paused=not music_enabled
 _save_settings()

const SAVED_RULE_FIELDS=["mode","player","names","scores","groups","winner","ball_in_hand","baulk_only","free_shot","break_shot","phase","nominated","clearance","called_ball","called_pocket","target","message","match_over","consecutive_fouls"]
func slot_path(index: int) -> String:
 return "user://saves/tournament-%02d.save" % (index+1)

func _save_digest(payload: PackedByteArray) -> PackedByteArray:
 var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(payload);return hash.finish()

func _read_slot(index: int) -> Dictionary:
 if index<0 or index>=SAVE_SLOTS:return {}
 var file=FileAccess.open(slot_path(index),FileAccess.READ)
 if file==null or file.get_length()<40 or file.get_length()>262144:return {}
 if file.get_buffer(4).get_string_from_ascii()!="TLP5":return {}
 var checksum=file.get_buffer(32)
 var payload=file.get_buffer(file.get_length()-36)
 if _save_digest(payload)!=checksum:return {}
 var value=bytes_to_var(payload)
 return value if value is Dictionary else {}

func list_save_slots() -> Array:
 var slots=[]
 for index in range(SAVE_SLOTS):
  var exists=FileAccess.file_exists(slot_path(index))
  var data=_read_slot(index) if exists else {}
  var valid=exists and _valid_save(data) and data.get("version",0)==5
  slots.append({"index":index,"empty":not exists,"valid":valid,"player":data.get("saved_by","") if valid else "","timestamp":data.get("saved_at_local","") if valid else "","offset":data.get("utc_offset_minutes",0) if valid else 0,"frame":data.session.rival_index+1 if valid else 0,"tier":data.session.rival_index/12 if valid else 0})
 return slots

func snapshot_match() -> Dictionary:
 var phase=ui.save_return if state=="saves" else state
 if phase=="paused":phase=pause_origin
 if campaign.kind!="tournament" or phase not in ["aim","rolling","intro","result"]:return {}
 var data={"version":5,"saved_by":campaign.human_name,"saved_at_utc":int(Time.get_unix_time_from_system()),"saved_at_local":Time.get_datetime_string_from_system(false,true),"utc_offset_minutes":int(Time.get_time_zone_from_system().bias),"pocketed_by":pocketed_by.duplicate(true),"session":campaign.snapshot(),"ui_state":phase,"rules":{},"balls":sim.balls.duplicate(true),"aim":aim,"aim_locked":aim_locked,"power":power,"spin":spin,"placement":placements,"stationary_time":stationary_time,"physics_elapsed":sim.elapsed,"shot":sim.shot.duplicate(true),"before":before.duplicate(true)}
 for key in SAVED_RULE_FIELDS:data.rules[key]=rules.get(key).duplicate(true) if rules.get(key) is Array else rules.get(key)
 return data

func save_slot(index: int,overwrite: bool=false) -> Dictionary:
 if qa_mode:return {"ok":false,"message":"Saving is disabled during automated checks."}
 if index<0 or index>=SAVE_SLOTS:return {"ok":false,"message":"Choose one of the ten save slots."}
 if FileAccess.file_exists(slot_path(index)) and not overwrite:return {"ok":false,"confirm":true,"message":"Click this slot again to confirm replacement."}
 var data=snapshot_match()
 if data.is_empty() or not _valid_save(data):return {"ok":false,"message":"Only an active AI tournament can be saved."}
 var folder=ProjectSettings.globalize_path("user://saves")
 if DirAccess.make_dir_recursive_absolute(folder)!=OK:return {"ok":false,"message":"The save folder could not be created."}
 var file=FileAccess.open(slot_path(index)+".tmp",FileAccess.WRITE)
 if file==null:return {"ok":false,"message":"The save could not be written."}
 var payload=var_to_bytes(data)
 file.store_buffer("TLP5".to_ascii_buffer());file.store_buffer(_save_digest(payload));file.store_buffer(payload);file.flush();file.close()
 var status=DirAccess.rename_absolute(ProjectSettings.globalize_path(slot_path(index)+".tmp"),ProjectSettings.globalize_path(slot_path(index)))
 if status!=OK:return {"ok":false,"message":"The existing save was kept; replacement failed."}
 return {"ok":true,"message":"Saved to slot %02d · %s" % [index+1,data.saved_at_local]}

func load_slot(index: int) -> bool:
 var data=_read_slot(index)
 if data.get("version",0)!=5 or not _valid_save(data):return false
 _invalidate_ai();_join_ai();_stop_spoken();campaign.restore(data.session);ai_mode=int(data.rules.mode)
 table.upgrade=campaign.tier();rules.configure(data.rules.mode,sim)
 for key in SAVED_RULE_FIELDS:rules.set(key,data.rules[key])
 sim.balls.assign(data.balls);sim.shot=data.shot.duplicate(true);sim.elapsed=float(data.physics_elapsed);sim.collisions.clear()
 before=data.before.duplicate(true);stationary_time=float(data.stationary_time)
 table.configure(sim,rules);_apply_render_scale();ui.refresh_calls()
 pocketed_by=data.pocketed_by.duplicate(true);aim_locked=data.aim_locked
 aim=data.aim.normalized();power=float(data.power);spin=data.spin;placements=data.placement
 charging=false;power_drag=false;spin_drag=false;ui.help_panel.visible=false;ui.pending_slot=-1
 state=data.ui_state
 if state in ["aim","rolling"]:pause_origin=state;state="paused"
 elif state=="intro":ui.show_intro()
 elif state=="result":ui.show_result()
 _music_context()
 return true

func _valid_pair(value,kind: int) -> bool:
 return value is Array and value.size()==2 and typeof(value[0])==kind and typeof(value[1])==kind

func _load_player_names(value) -> void:
 if _valid_pair(value,TYPE_STRING):
  if value[0].length()>0 and value[0].length()<=18 and value[1].length()>0 and value[1].length()<=18:
   rules.names=value

func _valid_save(data) -> bool:
 if not data is Dictionary or data.get("version",0)!=5: return false
 if not campaign.valid(data.get("session")) or data.get("ui_state","") not in ["aim","rolling","intro","result"]:return false
 var saved=data.get("rules")
 if not saved is Dictionary or not data.get("balls") is Array: return false
 var mode=saved.get("mode",-1)
 if not mode is int or mode<0 or mode>=rules.MODES.size(): return false
 if saved.get("player",-1) not in [0,1] or saved.get("winner",-2) not in [-1,0,1]: return false
 if not _valid_pair(saved.get("names"),TYPE_STRING): return false
 for name in saved.names:
  if name.length()==0 or name.length()>18: return false
 if not _valid_pair(saved.get("scores"),TYPE_INT) or not _valid_pair(saved.get("groups"),TYPE_INT): return false
 if not _valid_pair(saved.get("consecutive_fouls"),TYPE_INT): return false
 for score in saved.scores:
  if absi(score)>100000: return false
 for group in saved.groups:
  if group not in [-1,0,1]: return false
 for count in saved.consecutive_fouls:
  if count<0 or count>3: return false
 for flag in ["ball_in_hand","baulk_only","free_shot","break_shot","match_over"]:
  if not saved.get(flag) is bool: return false
 if saved.get("phase","") not in ["red","colour","clearance"]: return false
 for field in ["nominated","clearance","called_ball","called_pocket","target"]:
  if not saved.get(field) is int: return false
 if saved.nominated<2 or saved.nominated>7 or saved.clearance<2 or saved.clearance>8: return false
 if saved.called_ball< -1 or saved.called_ball>115 or saved.called_pocket< -1 or saved.called_pocket>5: return false
 if saved.target<1 or saved.target>1000 or not saved.get("message") is String or saved.message.length()>500: return false
 var expected_sim=Physics.new();var expected_rules=Rules.new();expected_rules.configure(mode,expected_sim)
 if data.balls.size()!=expected_sim.balls.size(): return false
 var ids=[]
 for b in data.balls:
  if not b is Dictionary or not b.get("id") is int: return false
  if b.id in ids or expected_sim.ball(b.id).is_empty(): return false
  ids.append(b.id)
  if not b.get("p") is Vector2 or not b.get("v") is Vector2 or not b.get("spin") is Vector2 or not b.get("q") is Quaternion: return false
  if not b.p.is_finite() or not b.v.is_finite() or not b.spin.is_finite() or not b.q.is_finite(): return false
  if not b.q.is_normalized() or b.v.length()>(12.0 if data.get("version")==5 and data.ui_state=="rolling" else 0.05): return false
  if not b.get("active") is bool or not b.get("pocket") is int: return false
  if b.pocket< -1 or b.pocket>5 or not (b.get("fall") is float or b.get("fall") is int): return false
  if not is_finite(b.fall) or b.fall<0 or b.fall>1: return false
  if absf(b.p.x)>expected_sim.half_size.x+0.2 or absf(b.p.y)>expected_sim.half_size.y+0.2: return false
 if not data.get("aim") is Vector2 or not data.aim.is_finite() or data.aim.length()<0.5: return false
 if data.has("pocketed_by"):
  if not data.pocketed_by is Array or data.pocketed_by.size()!=2:return false
  for ledger in data.pocketed_by:
   if not ledger is Array or ledger.size()>512:return false
   for id in ledger:
    if not id is int or id<1 or id>115:return false
 if not (data.get("power") is float or data.get("power") is int): return false
 if not is_finite(data.power) or data.power<0 or data.power>1:return false
 return _valid_manual_snapshot(data)

func _valid_manual_snapshot(data: Dictionary) -> bool:
 if data.session.kind!="tournament" or data.rules.mode!=0:return false
 if data.get("saved_by")!=data.session.human_name or data.saved_by!=data.rules.names[0]:return false
 if not data.get("saved_at_utc") is int or data.saved_at_utc<=0:return false
 if not data.get("saved_at_local") is String or data.saved_at_local.length()!=19:return false
 var date_pattern=RegEx.new();date_pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$")
 if date_pattern.search(data.saved_at_local)==null:return false
 if not data.get("utc_offset_minutes") is int or absi(data.utc_offset_minutes)>840:return false
 if not data.get("aim_locked") is bool or not data.get("spin") is Vector2 or not data.spin.is_finite() or data.spin.length()>1.5:return false
 if not data.get("placement") is Vector2 or not data.placement.is_finite():return false
 for key in ["physics_elapsed","stationary_time"]:
  if not (data.get(key) is float or data.get(key) is int) or not is_finite(data[key]) or data[key]<0 or data[key]>7200:return false
 if not data.get("pocketed_by") is Array or not data.get("before") is Dictionary or not data.get("shot") is Dictionary:return false
 if data.ui_state=="rolling":
  if data.rules.match_over or data.session.phase!="playing":return false
  var shot=data.shot;var prior=data.before
  if shot.get("cue",-1)!=0 or not shot.get("first") is int or shot.first< -1 or shot.first>15:return false
  for key in ["rails","cushions_at_second"]:
   if not shot.get(key) is int or shot[key]<0 or shot[key]>10000:return false
  for key in ["scratch","rail_after_contact"]:
   if not shot.get(key) is bool:return false
  if not shot.get("potted") is Array or shot.potted.size()>16:return false
  var seen=[]
  for pot in shot.potted:
   if not pot is Dictionary or not pot.get("id") is int or pot.id<0 or pot.id>15 or pot.id in seen:return false
   if not pot.get("pocket") is int or pot.pocket<0 or pot.pocket>5:return false
   seen.append(pot.id)
  for key in ["targets","contacts"]:
   var values=prior.get(key) if key=="targets" else shot.get(key)
   if not values is Array or values.size()>16:return false
   for id in values:
    if not id is int or id<0 or id>15:return false
  for key in ["group_left","reds","lowest"]:
   if not prior.get(key) is int or prior[key]< -1 or prior[key]>115:return false
  if prior.get("phase","") not in ["red","colour","clearance"] or not prior.get("free") is bool:return false
 elif data.ui_state=="aim":
  if data.rules.match_over or data.session.phase!="playing":return false
 elif data.ui_state=="intro":
  if data.rules.match_over or data.session.phase!="intro":return false
 elif data.ui_state=="result":
  if not data.rules.match_over or data.session.phase!="result":return false
 return true

func human_turn() -> bool:
 return not (campaign.kind in ["ai","tournament"] and rules.player==1)
func start_local(mode: int):
 _close_previous_run()
 campaign.kind="local";campaign.phase="playing";campaign.finished=false
 start_match(mode);_music_context()
func launch_tournament(player_name: String):
 _close_previous_run()
 ai_mode=0;campaign.start_tournament(player_name);_start_ai_frame()
func _start_ai_frame(voice_delay: float=0.35):
 rules.names=[campaign.human_name,campaign.rival().name]
 start_match(0 if campaign.kind=="tournament" else ai_mode)
 # Alternate opening breaks across the roster. Human remains player one.
 rules.player=campaign.rival_index%2
 rules.message="%s breaks." % rules.names[rules.player]
 state="intro";campaign.phase="intro";ui.show_intro();_music_context()
 _play_sound("rival_reveal");_reveal_voice(campaign.rival().voice,voice_delay,ai_generation)
func begin_frame():
 if state!="intro":return
 state="aim";campaign.phase="playing";_stop_spoken();_play_sound("ui_confirm");_play_sound("voice_hero_start",0.8);_music_context()
func _match_finished():
 _invalidate_ai();campaign.finish_frame(rules.winner==0);state="result"
 if campaign.kind=="tournament" and campaign.finished:_record_run()
 ui.show_result();_music_context()
 _play_sound("match_win" if rules.winner==0 else "match_lose")
 if rules.winner==0 and not sfx.has("match_win"):_play_sound("win")
 var result_clip=campaign.rival().voice+("_loss" if rules.winner==0 else "_win") if campaign.kind=="tournament" else ""
 if not result_clip.is_empty() and _audio_asset(result_clip)!=null:_play_sound(result_clip,0.8)
 else:_play_sound("voice_hero_win" if rules.winner==0 else "voice_hero_lose",0.8)
 if campaign.kind=="tournament" and campaign.finished and campaign.wins==48:_play_sound("tournament_win")
func result_primary():
 if state!="result":return
 if campaign.kind=="tournament":
  if campaign.finished:open_menu();ui.show_board();return
  if campaign.last_won:
   var promoted=campaign.wins%12==0
   if campaign.advance():
    if promoted:_play_sound("stage_unlock")
    _start_ai_frame()
  elif campaign.spend_continue():
   _play_sound("diamond_spend");_play_sound("voice_continue",0.8);_start_ai_frame(3.0)
 else:
  if campaign.kind=="ai":campaign.phase="intro";_start_ai_frame()
  else:start_local(rules.mode)
func end_tournament():
 var was_tournament=campaign.kind=="tournament"
 if campaign.kind=="tournament" and not campaign.finished:
  campaign.abandon();_record_run()
 open_menu()
 if was_tournament:ui.show_board()
func _record_run():
 if campaign.recorded or campaign.kind!="tournament":return
 campaign.recorded=true
 if not qa_mode:
  if leaderboard.record(campaign.human_name,campaign.points,campaign.wins):_play_sound("new_record")
func _invalidate_ai():
 ai_generation+=1;ai_delay=0;ai_result.clear()
func _join_ai():
 if ai_thread!=null and ai_thread.is_started():ai_thread.wait_to_finish()
 ai_thread=null;ai_result.clear()
func _tick_ai(dt: float):
 if ai_thread!=null and ai_thread.is_started() and not ai_thread.is_alive():
  var result=ai_thread.wait_to_finish();ai_thread=null
  if thread_generation==ai_generation and result is Dictionary:ai_result=result
 if state!="aim" or human_turn() or rules.match_over:return
 ai_delay+=dt
 if not ai_result.is_empty() and ai_delay>0.85:
  var result=ai_result.duplicate();ai_result.clear()
  if result.has("error"):
   # A blocked placement is a visible foul, never an illegal teleport.
   rules.message="No legal AI placement. Returning to game selection.";open_menu();return
  if rules.ball_in_hand:
   if not rules.is_placement_legal(result.place,sim):_invalidate_ai();return
   sim.place(rules.cue_id(),result.place);rules.ball_in_hand=false;rules.baulk_only=false
  aim=result.aim;power=result.power;spin=Vector2.ZERO
  rules.called_ball=int(result.ball);rules.called_pocket=int(result.pocket);rules.nominated=int(result.nominated)
  strike(true);ai_delay=0
 elif ai_thread==null and ai_result.is_empty() and ai_delay>0.35:
  var data=AIPlanner.snapshot(sim,rules)
  thread_generation=ai_generation;ai_thread=Thread.new()
  var status=ai_thread.start(AIPlanner.plan.bind(data,campaign.skill(),randi()))
  if status!=OK:ai_thread=null;rules.message="AI planner could not start.";open_menu()
func _music_context():
 if not is_instance_valid(music_player):return
 var track="music_title" if state in ["title","menu"] else "music_"+Campaign.TIERS[campaign.tier()].to_lower()
 if current_music==track:return
 current_music=track
 if not music_tracks.has(track):music_tracks[track]=_audio_asset(track)
 var stream=music_tracks[track]
 if stream==null:stream=_audio_asset("music")
 music_player.stop();music_player.stream=stream
 if stream!=null:
  if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:stream.loop=true
  music_player.volume_db=-22;music_player.play();music_player.stream_paused=not music_enabled

func _stop_spoken():
 for voice in active_voices:
  if is_instance_valid(voice) and str(voice.get_meta("clip","")).begins_with("voice_"):voice.stop();voice.queue_free()
func _reveal_voice(clip: String,delay: float,generation: int):
 await get_tree().create_timer(delay).timeout
 if state=="intro" and generation==ai_generation:_play_sound(clip,0.8)

func _close_previous_run():
 if campaign.kind=="tournament" and not campaign.recorded and not campaign.finished and campaign.points>0:
  campaign.abandon();_record_run()
