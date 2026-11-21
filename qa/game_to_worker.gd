extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.set_meta("skip_title",true);root.add_child(game)
 game.set_physics_process(false);game.set_process(false)
 game.online_endpoint="http://127.0.0.1:8793/api/submit"
 game.online_enabled=true;game.score_offer={"name":"GAMEQA","points":2000,"champion":false}
 game.finish_online_share("GAMEQA",false)
 var deadline=Time.get_ticks_msec()+6000
 while Time.get_ticks_msec()<deadline and not game.find_children("*","HTTPRequest",true,false).is_empty():await process_frame
 await game.prepare_to_close();game.queue_free();await process_frame;quit()
