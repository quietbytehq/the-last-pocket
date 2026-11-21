class_name PocketOnline
extends RefCounted
const SITE="lastpocket.quietbytehq.uk"
const URL="https://lastpocket.quietbytehq.uk/api/submit"
const MIN_SCORE=1000
const MAX_SCORE=1000000
static func qualifying(points: int) -> bool:return points>=MIN_SCORE and points<=MAX_SCORE and points%50==0
static func clean_name(raw: String) -> String:
 var name=""
 for character in raw.to_upper():
  if character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ._-":name+=character
 return name.strip_edges().left(12)
static func payload(player: String,points: int,champion: bool) -> Dictionary:
 return {"name":clean_name(player),"score":points,"mode":"champion_all_48" if champion else "championship","version":str(ProjectSettings.get_setting("application/config/version",""))}
static func submit(host: Node,player: String,points: int,champion: bool,endpoint: String=URL):
 if not qualifying(points):return
 var request=HTTPRequest.new();request.timeout=5.0;request.use_threads=true;host.add_child(request)
 request.request_completed.connect(func(_result,_code,_headers,_body):request.queue_free())
 if request.request(endpoint,PackedStringArray(["Content-Type: application/json"]),HTTPClient.METHOD_POST,JSON.stringify(payload(player,points,champion)))!=OK:request.queue_free()
