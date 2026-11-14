extends RefCounted
## Local club rules. Referee-dependent tournament exceptions are documented in RULES.md.
const MODES := ["8-Ball Pool","9-Ball Pool","10-Ball Pool","Straight Pool","Blackball","Snooker","Six-Red Snooker","Carom Billiards","Three-Cushion","Practice"]
const NOTES := ["Solids vs stripes · call the black pocket","Lowest ball first · combinations allowed","Lowest first · called ball and pocket","Called shots · first to 25 points","Reds vs yellows · free shot after a foul","15 reds · alternate red and nominated colour","Six reds · a shorter snooker frame","Pocketless table · contact both object balls","Contact both balls after at least three cushions","Free play · no opponent or fouls"]
var mode = 0
var player = 0
var names = ["PLAYER 1","PLAYER 2"]
var scores = [0,0]
var groups = [-1,-1]
var winner = -1
var ball_in_hand = true
var baulk_only = false
var free_shot = false
var break_shot = true
var phase = "red"
var nominated = 7
var clearance = 2
var called_ball = -1
var called_pocket = -1
var target = 25
var message = "Place the cue ball, then break."
var history: Array[String] = []
var match_over = false
var consecutive_fouls = [0,0]

func configure(index: int, sim) -> void:
 mode=index; player=0; scores=[0,0]; groups=[-1,-1];winner=-1
 match_over=false;consecutive_fouls=[0,0]; ball_in_hand=true;baulk_only=false;free_shot=false;break_shot=true
 phase="red";nominated=7;clearance=2;called_ball=-1;called_pocket=-1;history.clear()
 sim.balls.clear();sim.shot.clear()
 sim.half_size=Vector2(1.27,0.635);sim.radius=0.0475;sim.pocket_radius=0.067;sim.pocketed_table=true;sim.friction=0.19
 if mode==4:
  sim.half_size=Vector2(0.915,0.4575);sim.radius=0.0342;sim.pocket_radius=0.055
 elif is_snooker():
  sim.half_size=Vector2(1.785,0.889);sim.radius=0.02625;sim.pocket_radius=0.055;sim.friction=0.16
 elif is_carom():
  sim.half_size=Vector2(1.42,0.71);sim.radius=0.03075;sim.pocketed_table=false;sim.friction=0.12
 if is_carom():
  sim.add_ball(0,Vector2(-0.71,0.18));sim.add_ball(16,Vector2(-0.71,-0.18));sim.add_ball(3,Vector2(0.71,0))
  ball_in_hand=false;target=10 if mode==7 else 5
 elif is_snooker():
  var reds =15 if mode==5 else 6
  var spots =colour_spots(sim)
  sim.add_ball(0,Vector2(-sim.half_size.x*0.70,0.12))
  for colour in range(2,8): sim.add_ball(colour,spots[colour])
  var rows =5 if reds==15 else 3
  var id =101
  for row in range(rows):
   for k in range(row+1):
    sim.add_ball(id,Vector2(sim.half_size.x*0.43+sim.radius*2.08+row*sim.radius*1.74,(k-row*0.5)*sim.radius*2.02));id+=1
  baulk_only=true
 else:
  sim.add_ball(0,Vector2(-sim.half_size.x*0.58,0))
  var ids: Array[int]=[]
  if mode==1: ids.assign([1,2,3,4,9,5,6,7,8])
  elif mode==2: ids.assign([1,2,3,4,10,5,6,7,8,9])
  else: ids.assign([1,9,2,10,8,3,11,4,12,5,6,13,14,7,15])
  var n =0
  var rows =4 if mode==2 else (5 if mode!=1 else 5)
  if mode==1:
   var widths =[1,2,3,2,1]
   for row in range(5):
    for k in range(widths[row]):
     sim.add_ball(ids[n],Vector2(sim.half_size.x*0.50+row*sim.radius*1.75,(k-(widths[row]-1)*0.5)*sim.radius*2.02));n+=1
  else:
   for row in range(rows):
    for k in range(row+1):
     if n>=ids.size(): break
     sim.add_ball(ids[n],Vector2(sim.half_size.x*0.50+row*sim.radius*1.75,(k-row*0.5)*sim.radius*2.02));n+=1
  if mode==3: target=25
 if not is_carom() and not is_snooker() and mode!=9: baulk_only=true
 if mode==9: message="Practice · place the white ball anywhere to begin."
 elif is_carom(): message="%s to play · contact both object balls." % names[player]
 else: message="%s · place the cue ball%s and break." % [names[player]," in the D" if is_snooker() else ""]
 history.append(message)

func cue_id() -> int:
 return 16 if is_carom() and player==1 else 0
func is_snooker() -> bool: return mode==5 or mode==6
func is_carom() -> bool: return mode==7 or mode==8
func group_of(id: int) -> int:
 if id>=1 and id<=7: return 0
 if id>=9 and id<=15: return 1
 return -1
func remaining_group(sim,group: int) -> int:
 var count =0
 for b in sim.balls:
  if b.active and group_of(b.id)==group: count+=1
 return count
func remaining_reds(sim) -> int:
 var count =0
 for b in sim.balls:
  if b.active and b.id>=100: count+=1
 return count
func lowest(sim) -> int:
 var value =1000
 for b in sim.balls:
  if b.active and b.id>0: value=mini(value,b.id)
 return value if value!=1000 else -1
func colour_spots(sim) -> Dictionary:
 var h: Vector2=sim.half_size
 return {2:Vector2(-h.x*0.58,h.y*0.35),3:Vector2(-h.x*0.58,-h.y*0.35),4:Vector2(-h.x*0.58,0),5:Vector2.ZERO,6:Vector2(h.x*0.43,0),7:Vector2(h.x*0.81,0)}
func is_placement_legal(p: Vector2,sim) -> bool:
 if not sim.can_place(p,cue_id()): return false
 if is_snooker() and baulk_only:
  var centre =Vector2(-sim.half_size.x*0.58,0)
  return p.x<=centre.x and p.distance_to(centre)<=sim.half_size.y*0.35
 if mode==4 and baulk_only: return p.x< -sim.half_size.x*0.5
 if mode in [0,1,2,3] and baulk_only: return p.x< -sim.half_size.x*0.5
 return true

func legal_targets(sim) -> Array[int]:
 var out: Array[int]=[]
 if is_carom():
  for b in sim.balls:
   if b.active and b.id!=cue_id(): out.append(b.id)
 elif is_snooker():
  for b in sim.balls:
   if not b.active or b.id==0: continue
   if phase=="red" and b.id>=100: out.append(b.id)
   elif phase=="colour" and b.id==nominated: out.append(b.id)
   elif phase=="clearance" and b.id==clearance: out.append(b.id)
 elif mode==1 or mode==2:
  var l =lowest(sim)
  if l!=-1: out.append(l)
 elif mode==0 or mode==4:
  if groups[player]==-1:
   for b in sim.balls:
    if b.active and group_of(b.id)!=-1: out.append(b.id)
  elif remaining_group(sim,groups[player])==0: out.append(8)
  else:
   for b in sim.balls:
    if b.active and group_of(b.id)==groups[player]: out.append(b.id)
 else:
  for b in sim.balls:
   if b.active and b.id!=0: out.append(b.id)
 return out

func before_shot(sim) -> Dictionary:
 return {"targets":legal_targets(sim),"group_left":remaining_group(sim,groups[player]) if groups[player]>=0 else 99,"reds":remaining_reds(sim),"lowest":lowest(sim),"phase":phase,"free":free_shot}

func resolve(sim,before: Dictionary) -> void:
 if sim.shot.is_empty(): return
 var s: Dictionary=sim.shot
 var pots: Array=s.potted
 var first: int=s.first
 var foul: bool=s.scratch or first==-1
 var why ="Cue ball potted" if s.scratch else ("No object ball contacted" if first==-1 else "")
 if first!=-1 and first not in before.targets and not free_shot:
  foul=true;why="Wrong ball hit first"
 if not is_snooker() and not is_carom() and not pots.size() and not s.rail_after_contact and first!=-1:
  foul=true;why="No cushion reached after contact"
 var keep =false
 if mode==9:
  if s.scratch: _hand(sim,false)
  for entry in pots:
   if entry.id!=0: scores[0]+=1
  if lowest(sim)==-1:
   var total=scores[0];configure(9,sim);scores[0]=total
  _announce("Practice · %d balls potted" % scores[0]);return
 if is_carom():
  var good: bool=s.contacts.size()>=2 and (mode==7 or s.cushions_at_second>=3)
  if good:
   scores[player]+=1;keep=true
   if scores[player]>=target: _win(player)
  if not match_over:
   if not keep: player=1-player
   _announce("%s · %s" % ["Carom! One point" if good else "No point",names[player]+" to play"])
  return
 if is_snooker():
  _snooker_resolve(sim,before,foul,why);return
 var pot_ids: Array[int]=[]
 for entry in pots: pot_ids.append(entry.id)
 if mode==0 or mode==4:
  if 8 in pot_ids:
   if break_shot:
    sim.respot(8,Vector2(sim.half_size.x*0.5,0))
   else:
    var pocket_ok =false
    for entry in pots:
     if entry.id==8: pocket_ok=(mode==4 or entry.pocket==called_pocket)
    _win(player if not foul and before.group_left==0 and pocket_ok else 1-player)
    return
  if groups[player]==-1 and not foul and not break_shot:
   for id in pot_ids:
    var g =group_of(id)
    if g>=0: groups[player]=g;groups[1-player]=1-g;break
  for id in pot_ids:
   if id==0: continue
   if groups[player]==-1 or group_of(id)==groups[player]: keep=true
   elif mode==4 and not free_shot and not break_shot: foul=true;why="Opponent's ball potted"
  if free_shot:
   keep=true;free_shot=false
  if foul:
   player=1-player
   _hand(sim,mode==4)
   free_shot=(mode==4)
   _announce("FOUL · %s · %s%s" % [why,names[player]," has a free shot" if free_shot else " has ball in hand"])
  else:
   if not keep: player=1-player
   _announce("%s to play%s" % [names[player]," · table open" if groups[player]==-1 else (" · solids" if groups[player]==0 else " · stripes")])
 elif mode==1 or mode==2:
  var final_ball =9 if mode==1 else 10
  var final_pot =false
  var called_pot =false
  for entry in pots:
   if entry.id==final_ball: final_pot=true
   if entry.id==called_ball and entry.pocket==called_pocket: called_pot=true
   if entry.id!=0: keep=true
  if mode==2: keep=called_pot
  if final_pot:
   if not foul and (mode==1 or (before.lowest==10 and called_ball==10 and called_pot and not break_shot)):
    _win(player);return
   sim.respot(final_ball,Vector2(sim.half_size.x*0.5,0))
  if foul:
   consecutive_fouls[player]+=1
   if consecutive_fouls[player]>=3:
    _win(1-player);message+=" · three consecutive fouls";return
   player=1-player;_hand(sim,false)
   _announce("FOUL · %s · %s has ball in hand" % [why,names[player]])
   if consecutive_fouls[1-player]==2: message+=" · WARNING: %s on two fouls" % names[1-player]
  else:
   consecutive_fouls[player]=0
   if not keep: player=1-player
   _announce("%s · lowest ball first" % names[player])
 elif mode==3:
  var called_pot =false
  for entry in pots:
   if entry.id==called_ball and entry.pocket==called_pocket: called_pot=true
  if foul:
   scores[player]-=1
   for id in pot_ids:
    if id>0: sim.respot(id,Vector2(sim.half_size.x*0.5,0))
   player=1-player
   if s.scratch: _hand(sim,true)
   _announce("FOUL · minus one point · %s to play" % names[player])
  elif called_pot:
   scores[player]+=pot_ids.size()
   if scores[player]>=target: _win(player);return
   _announce("%s · %d / %d" % [names[player],scores[player],target])
  else:
   for id in pot_ids:
    if id>0: sim.respot(id,Vector2(sim.half_size.x*0.5,0))
   player=1-player;_announce("%s · call a ball and pocket" % names[player])
  if _object_count(sim)<=1: _straight_rack(sim)
 break_shot=false;called_pocket=-1

func _object_count(sim) -> int:
 var c =0
 for b in sim.balls:
  if b.active and b.id>0: c+=1
 return c
func _straight_rack(sim) -> void:
 var n =0
 for b in sim.balls:
  if b.id==0 or b.active: continue
  var row =0;var index =n+1
  while index>=row+1: index-=row+1;row+=1
  var p =Vector2(sim.half_size.x*0.4+row*sim.radius*1.76,(index-row*0.5)*sim.radius*2.03)
  sim.respot(b.id,p);n+=1
 _announce("Fourteen-ball re-rack · scores continue")

func _snooker_resolve(sim,before: Dictionary,foul: bool,why: String) -> void:
 var s: Dictionary=sim.shot
 var pots: Array=s.potted
 var expected: String=before.phase
 var penalty =4
 var earned =0
 for entry in pots:
  var id: int=entry.id
  if id==0: continue
  var legal =id in before.targets
  if not legal: foul=true;why="A ball not on was potted"
  penalty=maxi(penalty,id if id<100 else 1)
  if legal: earned+=1 if id>=100 else id
 if s.first>0 and s.first<100: penalty=maxi(penalty,s.first)
 if expected=="colour": penalty=maxi(penalty,nominated)
 if expected=="clearance": penalty=maxi(penalty,clearance)
 # Reds stay down even on a foul. Colours are re-spotted until the ordered clearance.
 for entry in pots:
  var id: int=entry.id
  if id>=2 and id<=7 and (foul or expected!="clearance"):
   sim.respot(id,colour_spots(sim)[id])
 if foul:
  scores[1-player]+=penalty;player=1-player
  if s.scratch: _hand(sim,true)
  if expected=="clearance" and clearance==7:
   if scores[0]!=scores[1]:
    _win(0 if scores[0]>scores[1] else 1);return
   sim.respot(7,colour_spots(sim)[7]);_hand(sim,true)
  phase="red" if remaining_reds(sim)>0 else "clearance"
  _announce("FOUL · %d to %s · %s" % [penalty,names[player],why])
 elif earned>0:
  scores[player]+=earned
  if expected=="red": phase="colour"
  elif expected=="colour": phase="red" if remaining_reds(sim)>0 else "clearance"
  else:
   clearance+=1
   if clearance>7:
    if scores[0]==scores[1]:
     clearance=7;sim.respot(7,colour_spots(sim)[7]);_hand(sim,true)
     _announce("Scores tied · re-spotted black")
    else: _win(0 if scores[0]>scores[1] else 1)
    return
  _announce("%s · +%d · %s on" % [names[player],earned,target_text(sim)])
 else:
  player=1-player
  if expected!="clearance": phase="red" if remaining_reds(sim)>0 else "clearance"
  _announce("%s · %s on" % [names[player],target_text(sim)])
 break_shot=false

func _hand(sim,restricted: bool) -> void:
 ball_in_hand=true;baulk_only=restricted
 var b: Dictionary=sim.ball(cue_id())
 if not b.is_empty(): b.active=false;b.fall=1.0;b.v=Vector2.ZERO
func _win(p: int) -> void:
 winner=p;match_over=true;ball_in_hand=false
 _announce("%s WINS" % names[p])
func _announce(text: String) -> void:
 message=text;history.append(text)
 if history.size()>20: history.pop_front()
func target_text(sim) -> String:
 if is_carom(): return "Both object balls" if mode==7 else "3 cushions + both balls"
 if is_snooker():
  if phase=="red": return "Red"
  var c =nominated if phase=="colour" else clearance
  return ["","","Yellow","Green","Brown","Blue","Pink","Black"][clampi(c,2,7)]
 if mode==1 or mode==2: return str(lowest(sim))
 if mode==3: return "Call ball + pocket"
 if mode==9: return "Free play"
 if groups[player]==-1: return "Open table"
 if remaining_group(sim,groups[player])==0: return "Black · call a pocket" if mode==0 else "Black"
 if mode==4: return "Reds" if groups[player]==0 else "Yellows"
 return "Solids 1–7" if groups[player]==0 else "Stripes 9–15"
