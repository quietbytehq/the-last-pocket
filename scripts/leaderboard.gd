extends RefCounted
const PATH="user://top_ten.json"
var entries: Array=[]
func _init():load_board()
func load_board():
 entries.clear()
 if not FileAccess.file_exists(PATH):return
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 if not parsed is Dictionary or parsed.get("version",0)!=1 or not parsed.get("entries") is Array:return
 for row in parsed.entries:
  if not row is Dictionary or not row.get("name") is String:continue
  if row.name.strip_edges().is_empty() or row.name.length()>18:continue
  if not (row.get("points") is int or row.get("points") is float) or not is_finite(row.points) or row.points<0 or row.points>1000000:continue
  if not (row.get("wins") is int or row.get("wins") is float) or row.wins<0 or row.wins>48:continue
  var duplicate=false
  for old in entries:
   if old.name.to_lower()==row.name.to_lower():duplicate=true
  if not duplicate:entries.append({"name":row.name,"points":int(row.points),"wins":int(row.wins)})
 _sort()
func _sort():
 entries.sort_custom(func(a,b):return a.points>b.points if a.points!=b.points else a.wins>b.wins)
 entries=entries.slice(0,10)
func record(player_name: String,points: int,wins: int) -> bool:
 if points<0 or points>1000000 or wins<0 or wins>48:return false
 var name=preload("res://scripts/campaign.gd").clean_name(player_name)
 for index in range(entries.size()-1,-1,-1):
  if entries[index].name.to_lower()==name.to_lower():
   if entries[index].points>=points:return false
   entries.remove_at(index)
 var previous_best=entries[0].points if not entries.is_empty() else -1
 entries.append({"name":name,"points":points,"wins":wins});_sort()
 var file=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if file!=null:
  file.store_string(JSON.stringify({"version":1,"entries":entries},"\t"));file.close()
  DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
 return points>previous_best
