extends RefCounted
## Fair geometric planner. Runs on an isolated snapshot, never on live input.
const Physics=preload("res://scripts/physics.gd")
const Rules=preload("res://scripts/rules.gd")
static func snapshot(sim,rules) -> Dictionary:
 var data={"mode":rules.mode,"layout_version":sim.layout_version,"balls":sim.balls.duplicate(true),"rules":{}}
 for key in ["player","groups","break_shot","ball_in_hand","baulk_only","phase","clearance","free_shot"]:data.rules[key]=rules.get(key)
 return data
static func legal_targets(sim,rules) -> Array:
 var targets=[]
 for b in sim.balls:
  if not b.active or b.id==rules.cue_id():continue
  var legal=true
  if rules.mode in [0,4]:
   var group=rules.groups[rules.player]
   legal=b.id!=8 if group<0 else (b.id==8 if rules.remaining_group(sim,group)==0 else rules.group_of(b.id)==group)
  elif rules.mode in [1,2]:legal=b.id==rules.lowest(sim)
  elif rules.is_snooker():
   legal=b.id>=100 if rules.phase=="red" else (b.id==rules.clearance if rules.phase=="clearance" else b.id in [2,3,4,5,6,7])
  if legal:targets.append(b.id)
 return targets
static func clear_path(sim,a: Vector2,b: Vector2,ignored: Array) -> bool:
 var delta=b-a;var length=delta.length_squared()
 if length<0.000001:return false
 for ball in sim.balls:
  if not ball.active or ball.id in ignored:continue
  var t=clampf((ball.p-a).dot(delta)/length,0.0,1.0)
  if ball.p.distance_squared_to(a+delta*t)<pow(sim.radius*2.03,2):return false
 return true
static func _candidates(sim,rules,skill: float) -> Array:
 var cue=sim.ball(rules.cue_id());var choices=[]
 for id in legal_targets(sim,rules):
  var target=sim.ball(id)
  for pocket in range(6):
   var endpoint: Vector2=sim.pockets()[pocket]
   if not _entry_clear(sim,target.p,endpoint):continue
   var direction=(endpoint-target.p).normalized()
   var ghost: Vector2=target.p-direction*sim.radius*2.0
   if absf(ghost.x)>sim.half_size.x-sim.radius or absf(ghost.y)>sim.half_size.y-sim.radius:continue
   var incoming=(ghost-cue.p).normalized();var cut=incoming.dot(direction)
   if cut<0.16:continue
   if not clear_path(sim,cue.p,ghost,[cue.id,id]) or not clear_path(sim,target.p,endpoint,[cue.id,id]):continue
   var distance: float=cue.p.distance_to(ghost)
   var object_distance: float=target.p.distance_to(endpoint)
   var needed=sqrt(2*sim.friction*object_distance)*1.13+0.12
   var speed=sqrt(pow(needed/maxf(cut,0.2),2)+2*sim.friction*distance)
   if speed>5.4:continue
   var rating=cut*cut*7-distance*0.45-object_distance*0.6
   if rules.mode==0 and id==8:rating+=3
   choices.append({"aim":incoming,"power":clampf((speed-0.35)/5.1,0.10,0.95),"ball":id,"pocket":pocket,"rating":rating,"bank":false})
  # Better tiers also see one-cushion bank pots, not only straight shots.
  if skill<1.6:continue
  for pocket in range(6):
   var end: Vector2=sim.pockets()[pocket]
   for axis in range(2):
    for side in [-1,1]:
     var rail=(sim.half_size[axis]-sim.radius)*side
     var mirror=end;mirror[axis]=rail*2-end[axis]
     var ray=mirror-target.p
     if absf(ray[axis])<0.001:continue
     var t=(rail-target.p[axis])/ray[axis]
     if t<=0.05 or t>=0.95:continue
     var bounce: Vector2=target.p+ray*t
     var near_pocket=false
     for pp in sim.pockets():
      if bounce.distance_to(pp)<sim.pocket_radius*1.6:near_pocket=true
     if near_pocket:continue
     var direction=(bounce-target.p).normalized();var ghost: Vector2=target.p-direction*sim.radius*2
     var incoming=(ghost-cue.p).normalized();var cut=incoming.dot(direction)
     if cut<0.4:continue
     if absf(ghost.x)>sim.half_size.x-sim.radius or absf(ghost.y)>sim.half_size.y-sim.radius:continue
     if not clear_path(sim,cue.p,ghost,[cue.id,id]) or not clear_path(sim,target.p,bounce,[cue.id,id]) or not clear_path(sim,bounce,end,[cue.id,id]):continue
     var travel: float=target.p.distance_to(bounce)+bounce.distance_to(end)
     var needed=sqrt(2*sim.friction*travel)*1.45+0.16
     var speed=sqrt(pow(needed/cut,2)+2*sim.friction*cue.p.distance_to(ghost))
     if speed>5.4:continue
     choices.append({"aim":incoming,"power":clampf((speed-0.35)/5.1,0.15,0.98),"ball":id,"pocket":pocket,"rating":cut*cut*5-travel*0.7-4.0,"bank":true})
 return choices
static func _fallback(sim,rules) -> Dictionary:
 var cue=sim.ball(rules.cue_id());var best={};var best_distance=INF
 for id in legal_targets(sim,rules):
  var b=sim.ball(id);var distance: float=cue.p.distance_to(b.p)
  if distance<best_distance and clear_path(sim,cue.p,b.p,[cue.id,id]):
   best_distance=distance;best={"aim":(b.p-cue.p).normalized(),"power":0.52,"ball":id,"pocket":0,"rating":-10.0,"bank":false}
 if not best.is_empty():return best
 # One-rail kick contact when a direct line to the legal target is blocked.
 for id in legal_targets(sim,rules):
  var b=sim.ball(id)
  for axis in range(2):
   for side in [-1,1]:
    var rail=(sim.half_size[axis]-sim.radius)*side
    var mirror: Vector2=b.p;mirror[axis]=rail*2-b.p[axis]
    var ray=mirror-cue.p
    if absf(ray[axis])<0.001:continue
    var t=(rail-cue.p[axis])/ray[axis]
    if t<=0 or t>=1:continue
    var bounce: Vector2=cue.p+ray*t
    if clear_path(sim,cue.p,bounce,[cue.id,id]) and clear_path(sim,bounce,b.p,[cue.id,id]):
     return {"aim":ray.normalized(),"power":0.62,"ball":id,"pocket":0,"rating":-15.0,"bank":true}
 var targets=legal_targets(sim,rules)
 var target=sim.ball(targets[0]) if not targets.is_empty() else {"p":Vector2.ZERO,"id":-1}
 return {"aim":(target.p-cue.p).normalized() if target.p!=cue.p else Vector2.RIGHT,"power":0.5,"ball":target.id,"pocket":0,"rating":-20.0,"bank":false}
static func error_degrees(skill: float) -> float:
 var levels=[5.5,2.2,0.75,0.20,0.08]
 var tier=clampi(int(skill),0,3)
 return lerpf(levels[tier],levels[tier+1],clampf(skill-tier,0,1))
static func plan(data: Dictionary,skill: float,seed_value: int) -> Dictionary:
 var sim=Physics.new();var rules=Rules.new();rules.configure(int(data.mode),sim,int(data.get("layout_version",0)))
 for key in data.rules:rules.set(key,data.rules[key])
 sim.balls.assign(data.balls.duplicate(true))
 var rng=RandomNumberGenerator.new();rng.seed=seed_value
 var place=Vector2(INF,INF)
 if rules.ball_in_hand:
  var best=-INF
  for p in _placements(sim,rules):
   if not rules.is_placement_legal(p,sim):continue
   sim.place(rules.cue_id(),p)
   var choices=_candidates(sim,rules,0.0)
   var rating=-10.0
   for candidate in choices:rating=maxf(rating,candidate.rating)
   if rules.break_shot:rating=-p.distance_to(Vector2(-sim.half_size.x*0.75,0.06))
   if rating>best:best=rating;place=p
  if not place.is_finite():return {"error":"No legal cue position"}
  sim.place(rules.cue_id(),place)
 var shot: Dictionary
 if rules.is_carom():shot=_carom_plan(sim,rules,skill)
 elif rules.break_shot and not rules.is_snooker():
  var target=sim.ball(1);shot={"aim":(target.p-sim.ball(rules.cue_id()).p).normalized(),"power":0.84,"ball":1,"pocket":0,"rating":0.0,"bank":false}
 else:
  var choices=_candidates(sim,rules,skill)
  choices.sort_custom(func(a,b):return a.rating>b.rating)
  if skill>=1.0 and not choices.is_empty():
   choices=_refine(sim,rules,choices,skill)
  shot=choices[0] if not choices.is_empty() else _fallback(sim,rules)
 var error=deg_to_rad(error_degrees(skill))*rng.randfn(0.0,0.65)
 shot.aim=shot.aim.rotated(error).normalized()
 shot.power=clampf(shot.power*(1+rng.randf_range(-0.045,0.045)*(1-skill/5.0)),0.05,1.0)
 shot["place"]=place;shot["nominated"]=shot.ball if rules.is_snooker() and rules.phase=="colour" else rules.nominated
 return shot
static func _carom_plan(sim,rules,skill: float) -> Dictionary:
 var cue=sim.ball(rules.cue_id());var targets=legal_targets(sim,rules)
 var count=16+int(skill*18)
 var best={"aim":(sim.ball(targets[0]).p-cue.p).normalized(),"power":0.65,"ball":targets[0],"pocket":-1,"rating":-1000.0,"bank":false}
 for i in range(count):
  var candidate=Physics.new();var copy_rules=Rules.new();copy_rules.configure(rules.mode,candidate,sim.layout_version);candidate.balls.assign(sim.balls.duplicate(true))
  var angle=TAU*i/count
  var aim=Vector2(cos(angle),sin(angle));var power=0.5+float(i%3)*0.2
  candidate.begin_shot(rules.cue_id(),aim,0.35+power*5.1,Vector2.ZERO)
  for step in range(75):
   candidate.step(1.0/30.0)
   if candidate.shot.contacts.size()>=2:break
  var contacts: Array=candidate.shot.contacts
  var scored=contacts.size()>=2 and (rules.mode==7 or candidate.shot.cushions_at_second>=3)
  var rating=1000.0 if scored else contacts.size()*10.0+minf(3,candidate.shot.rails)*0.5
  if rating>best.rating:best={"aim":aim,"power":power,"ball":targets[0],"pocket":-1,"rating":rating,"bank":false}
  if scored:break
 return best

static func _placements(sim,rules) -> Array[Vector2]:
 var points: Array[Vector2]=[]
 for x in range(10):
  for y in range(6):points.append(Vector2(lerpf(-sim.half_size.x+sim.radius*2,sim.half_size.x-sim.radius*2,x/9.0),lerpf(-sim.half_size.y+sim.radius*2,sim.half_size.y-sim.radius*2,y/5.0)))
 if rules.is_snooker() and rules.baulk_only:
  var center=Vector2(-sim.half_size.x*0.58,0)
  for radius in [0.3,0.6,0.85]:
   for i in range(9):
    var angle=-PI/2+PI*i/8.0
    points.append(center+Vector2(-cos(angle),sin(angle))*sim.half_size.y*0.35*radius)
 return points
static func _entry_clear(sim,start: Vector2,end: Vector2) -> bool:
 var ray=end-start
 for axis in range(2):
  if absf(ray[axis])<0.001:continue
  var rail=(sim.half_size[axis]-sim.radius)*signf(end[axis])
  if absf(end[axis])<sim.half_size[axis]*0.5:continue
  var t=(rail-start[axis])/ray[axis]
  if t>0 and t<1:
   if (start+ray*t).distance_to(end)>(sim.pocket_radius+sim.radius*0.75)*0.94:return false
 return true

static func _refine(sim,rules,choices: Array,skill: float) -> Array:
 var refined=[]
 for original in choices.slice(0,3):
  var best=original.duplicate();var best_score=-INF
  var offsets=[-0.75,0.0,0.75] if skill<2.5 else [-1.0,-0.5,0.0,0.5,1.0]
  for offset in offsets:
   # Only these two balls lie on the already obstruction-checked paths.
   # Running the actual collision solver catches finite-step cut-angle error.
   var test=Physics.new()
   test.half_size=sim.half_size;test.radius=sim.radius;test.pocket_radius=sim.pocket_radius;test.friction=sim.friction
   test.balls.assign([sim.ball(rules.cue_id()).duplicate(true),sim.ball(original.ball).duplicate(true)])
   var direction=original.aim.rotated(deg_to_rad(offset))
   test.begin_shot(rules.cue_id(),direction,0.35+original.power*5.1,Vector2.ZERO)
   var closest=INF
   var endpoint: Vector2=sim.pockets()[original.pocket]
   for frame in range(480):
    test.step(1.0/60.0)
    closest=minf(closest,test.ball(original.ball).p.distance_to(endpoint))
    if not test.is_moving():break
   var potted=false
   for pot in test.shot.potted:
    if pot.id==original.ball and pot.pocket==original.pocket:potted=true
   var rating=original.rating+(100 if potted else -closest*8)-(200 if test.shot.scratch else 0)
   if rating>best_score:
    best_score=rating;best=original.duplicate();best.aim=direction;best.rating=rating
  refined.append(best)
 refined.sort_custom(func(a,b):return a.rating>b.rating)
 return refined
