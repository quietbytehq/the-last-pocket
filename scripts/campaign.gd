extends RefCounted
const TIERS=["Amateur","Professional","Master","GOAT"]
const EQUIPMENT=["House maple · club oak","Carbon Pro · polished walnut","Rosewood Master · mahogany & brass","Onyx Elite · ebony & engraved gold"]
var roster: Array=[]
var kind="local"
var rival_index=0
var quick_tier=0
var diamonds=3
var points=0
var wins=0
var shots=0
var human_name="PLAYER 1"
var last_won=false
var finished=false
var recorded=false
var phase="playing"
var run_id=""
var losses: Array=[]
func _init():
 losses.resize(48);losses.fill(0)
 var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/rivals.json"))
 if parsed is Array:roster=parsed
func tier() -> int:return clampi(rival_index/12 if kind=="tournament" else quick_tier,0,3)
func rival() -> Dictionary:return roster[clampi(rival_index,0,47)]
func skill() -> float:return tier()+float(rival_index%12)/12.0
func start_tournament(player_name: String):
 losses.resize(48);losses.fill(0)
 kind="tournament";rival_index=0;quick_tier=0;diamonds=3;points=0;wins=0;shots=0
 human_name=clean_name(player_name);last_won=false;finished=false;recorded=false;phase="intro"
 run_id=str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec())
func finish_frame(won: bool):
 if phase=="result" or finished:return
 last_won=won;phase="result"
 if kind!="tournament":return
 if won:
  points+=1000+tier()*500+maxi(0,18-shots)*50
  wins+=1
  if wins==48:
   points+=diamonds*1000;finished=true
 else:
  losses[rival_index]+=1
  if diamonds==0:finished=true
func advance() -> bool:
 if kind!="tournament" or not last_won or finished or phase!="result":return false
 rival_index+=1;shots=0;phase="intro";last_won=false
 return true
func spend_continue() -> bool:
 if kind!="tournament" or last_won or finished or phase!="result" or diamonds<=0:return false
 diamonds-=1;shots=0;phase="intro"
 return true
func abandon():finished=true;phase="result"
static func clean_name(value: String) -> String:
 var name=value.strip_edges().replace("\n","").replace("\r","").left(18)
 return name if not name.is_empty() else "PLAYER 1"
func snapshot() -> Dictionary:
 var data={}
 for key in ["kind","rival_index","quick_tier","diamonds","points","wins","shots","human_name","last_won","finished","recorded","phase","run_id","losses"]:data[key]=get(key).duplicate() if get(key) is Array else get(key)
 return data
func valid(data) -> bool:
 if not data is Dictionary:return false
 if data.get("kind","") not in ["local","tournament"]:return false
 for key in ["rival_index","quick_tier","diamonds","points","wins","shots"]:
  if not data.get(key) is int:return false
 if data.rival_index<0 or data.rival_index>47 or data.quick_tier<0 or data.quick_tier>3:return false
 if data.diamonds<0 or data.diamonds>3 or data.points<0 or data.points>1000000 or data.wins<0 or data.wins>48 or data.shots<0 or data.shots>10000:return false
 for key in ["last_won","finished","recorded"]:
  if not data.get(key) is bool:return false
 if not data.get("human_name") is String or data.human_name.length()<1 or data.human_name.length()>18:return false
 if not data.get("run_id") is String or data.run_id.length()>100:return false
 if data.get("phase","") not in ["intro","playing","result"]:return false
 if data.has("losses"):
  if not data.losses is Array or data.losses.size()!=48:return false
  for count in data.losses:
   if not count is int or count<0 or count>4:return false
 if data.kind=="tournament":
  if data.wins!=data.rival_index+(1 if data.last_won else 0):return false
  if data.wins==48 and not data.finished:return false
 return true
func restore(data) -> bool:
 if not valid(data):return false
 losses.resize(48);losses.fill(0)
 for key in data:
  if key in snapshot():set(key,data[key])
 return true

func revealed_rivals() -> Array:
 var seen=[]
 if kind!="tournament":return seen
 for index in range(rival_index+1):
  var entry=roster[index].duplicate()
  entry["defeated"]=index<wins
  entry["losses"]=losses[index]
  entry["status"]="Defeated" if index<wins else ("Last played" if finished else "Current rival")
  seen.append(entry)
 return seen
