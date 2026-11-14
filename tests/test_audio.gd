extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 for name in ["cue","ball","rail","pocket"]:
  check(game.sfx.has(name),"Bundled impact loads: "+name)
  if game.sfx.has(name):
   check(game.sfx[name] is AudioStreamWAV and game.sfx[name].stereo,"Stereo WAV impact: "+name)
 check(game._audio_asset("missing_clip")==null,"Missing optional audio is allowed")
 check(game._external_mp3("user://not-present.mp3")==null,"Missing personal MP3 returns no stream")
 game.sound_enabled=true
 game._play_sound("ball",0.5,1.0)
 check(game.active_voices.size()==1,"Impact playback creates a voice")
 var bus=AudioServer.get_bus_index("BilliardsImpact0")
 check(bus>=0 and is_equal_approx(AudioServer.get_bus_effect(bus,0).pan,0.75),"Right-side impact is panned right")
 var count=game.active_voices.size();game.sound_enabled=false;game._play_sound("cue")
 check(game.active_voices.size()==count,"Muted effects do not create voices")
 var args=OS.get_cmdline_user_args()
 if args.is_empty():args=[ProjectSettings.globalize_path("res://assets/audio/music.mp3")]
 if not args.is_empty():
  var sample=game._external_mp3(args[0]);check(sample!=null and sample.get_length()>0,"Personal MP3 decodes without a Godot import")
  game.music_player.stream=sample
  if sample!=null: sample.loop=true;game.music_player.play()
  game.toggle_music();check(game.music_player.stream_paused==not game.music_enabled,"Music toggle pauses an imported MP3")
  sample=null
 game.sound_enabled=true;game._play_sound("ball",0.4)
 var retained_music=game.music_player.stream
 game.toggle_sound();check(game.active_voices.is_empty(),"SFX mute immediately stops active effects")
 check(game.music_player.stream==retained_music,"SFX mute keeps the music stream independent")
 retained_music=null
 await game.prepare_to_close()
 check(game.sfx.is_empty() and game.active_voices.is_empty(),"Shutdown releases effect and stream references")
 check(AudioServer.get_bus_index("BilliardsImpact0")==-1,"Shutdown removes owned panner buses")
 game.queue_free();await process_frame
 print("PASS" if failures==0 else "FAIL",": ",checks," audio checks, ",failures," failures")
 quit(0 if failures==0 else 1)
