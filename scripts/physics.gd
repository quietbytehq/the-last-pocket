extends RefCounted
## Deterministic planar billiards simulation. Distances are metres, time seconds.
const DROP_DURATION := 0.76
const RESTITUTION := 0.96
const RAIL_RESTITUTION := 0.78
const STOP_SPEED := 0.009
var balls: Array[Dictionary] = []
var half_size = Vector2(1.27, 0.635)
var radius = 0.028575
var pocket_radius = 0.067
var pocketed_table = true
var friction = 0.19
var shot: Dictionary = {}
var elapsed = 0.0
var collisions: Array[Dictionary] = []

func pockets() -> Array[Vector2]:
 return [Vector2(-half_size.x,-half_size.y),Vector2(0,-half_size.y),Vector2(half_size.x,-half_size.y),Vector2(half_size.x,half_size.y),Vector2(0,half_size.y),Vector2(-half_size.x,half_size.y)]

func add_ball(id: int, p: Vector2) -> void:
 balls.append({"id":id,"p":p,"v":Vector2.ZERO,"q":Quaternion.IDENTITY,"spin":Vector2.ZERO,"active":true,"fall":0.0,"pocket":-1})

func ball(id: int) -> Dictionary:
 for b in balls:
  if b.id == id: return b
 return {}

func begin_shot(cue_id: int, direction: Vector2, speed: float, spin: Vector2) -> void:
 shot={"cue":cue_id,"first":-1,"potted":[],"rails":0,"rail_after_contact":false,"contacts":[],"cushions_at_second":0,"scratch":false}
 collisions.clear()
 var b = ball(cue_id)
 if b.is_empty(): return
 b.v=direction.normalized()*clampf(speed,0.1,6.0)
 b.spin=spin.clamp(Vector2(-1,-1),Vector2.ONE)
 elapsed=0.0

func is_moving() -> bool:
 for b in balls:
  if b.active and b.v.length_squared()>STOP_SPEED*STOP_SPEED: return true
 return false

func can_place(p: Vector2, ignore_id: int) -> bool:
 if absf(p.x)>half_size.x-radius or absf(p.y)>half_size.y-radius: return false
 for pocket in pockets():
  if pocketed_table and p.distance_to(pocket)<pocket_radius+radius*0.1: return false
 for b in balls:
  if b.active and b.id!=ignore_id and b.p.distance_to(p)<radius*2.02: return false
 return true

func place(id: int, p: Vector2) -> bool:
 if not can_place(p,id): return false
 var b = ball(id)
 if b.is_empty(): return false
 b.p=p; b.v=Vector2.ZERO; b.active=true; b.fall=0.0; b.pocket=-1
 return true

func respot(id: int, preferred: Vector2) -> void:
 var b = ball(id)
 if b.is_empty(): return
 b.active=false
 # Search along the centre line, then a grid. Never overlap another ball.
 for side in [1,-1]:
  for i in range(100):
   var p = preferred+Vector2(i*radius*0.55*side,0)
   if can_place(p,id):
    place(id,p); return
 for row in range(30):
  for col in range(60):
   var p = Vector2(-half_size.x+radius*2+col*radius*2.1,-half_size.y+radius*2+row*radius*2.1)
   if can_place(p,id):
    place(id,p); return

func step(delta: float) -> void:
 # Fixed 240 Hz substeps prevent a fast cue ball tunnelling through a rack.
 var count = maxi(1,ceili(delta*240.0))
 var dt = delta/count
 for sub in range(count): _substep(dt)
 elapsed+=delta

func _substep(dt: float) -> void:
 for b in balls:
  if not b.active:
   b.fall=minf(1.0,b.fall+dt/DROP_DURATION)
   continue
  var old: Vector2=b.p
  b.p+=b.v*dt
  var displacement: Vector2=b.p-old
  if displacement.length_squared()>0.000000001:
   var axis =Vector3(displacement.y,0,-displacement.x).normalized()
   b.q=Quaternion(axis,displacement.length()/radius)*b.q
   b.q=b.q.normalized()
  var speed: float=b.v.length()
  if speed>0:
   b.v=b.v.move_toward(Vector2.ZERO,friction*dt)
   if b.v.length()<STOP_SPEED: b.v=Vector2.ZERO
  # Gentle swerve / spin decay; draw and follow transfer on object contact.
  if speed>0.1 and absf(b.spin.x)>0.01:
   b.v=b.v.rotated(b.spin.x*dt*0.006)
  b.spin=b.spin.move_toward(Vector2.ZERO,dt*0.12)
  if pocketed_table:
   var pp =pockets()
   for k in range(pp.size()):
    var segment: Vector2=b.p-old
    var closest: Vector2=old+segment*clampf((pp[k]-old).dot(segment)/maxf(segment.length_squared(),0.00000001),0.0,1.0)
    if closest.distance_to(pp[k])<pocket_radius-radius*0.22:
     _pot(b,k); break
  if b.active: _rail(b)
 for i in range(balls.size()):
  var a: Dictionary=balls[i]
  if not a.active: continue
  for j in range(i+1,balls.size()):
   var b: Dictionary=balls[j]
   if not b.active: continue
   var d: Vector2=b.p-a.p
   var dist =d.length()
   if dist>=radius*2.0: continue
   # Recover the contact instant inside this substep. Using the overlapped
   # end-position normal introduces an artificial cut-angle error at speed.
   var back=0.0
   var relative: Vector2=a.v-b.v
   var speed_squared=relative.length_squared()
   if speed_squared>0.000001 and (d+relative*dt).length_squared()>=pow(radius*2,2):
    var linear=2*d.dot(relative)
    var discriminant=linear*linear-4*speed_squared*(d.length_squared()-pow(radius*2,2))
    if discriminant>=0:
     back=clampf((-linear+sqrt(discriminant))/(2*speed_squared),0.0,dt)
     a.p-=a.v*back;b.p-=b.v*back;d=b.p-a.p;dist=d.length()
   var n =d/dist if dist>0.00001 else Vector2.RIGHT
   var penetration =radius*2.0-dist
   a.p-=n*penetration*0.5; b.p+=n*penetration*0.5
   var closing: float=(a.v-b.v).dot(n)
   if closing<=0:
    a.p+=a.v*back;b.p+=b.v*back
    continue
   var impulse =closing*(1.0+RESTITUTION)*0.5
   a.v-=n*impulse; b.v+=n*impulse
   if not shot.is_empty():
    var cue_id: int=shot.cue
    if a.id==cue_id or b.id==cue_id:
     var other: int=b.id if a.id==cue_id else a.id
     if shot.first==-1: shot.first=other
     if other not in shot.contacts:
      shot.contacts.append(other)
      if shot.contacts.size()==2: shot.cushions_at_second=shot.rails
     var cue: Dictionary=a if a.id==cue_id else b
     var dir =n if a.id==cue_id else -n
     cue.v+=dir*cue.spin.y*minf(impulse,2.0)*0.35
     cue.spin.y*=0.65
   a.p+=a.v*back;b.p+=b.v*back
   if closing>0.06: collisions.append({"kind":"ball","speed":closing,"p":(a.p+b.p)*0.5})

 if pocketed_table:
  for b in balls:
   if b.active:_rail(b)

func pending_drop() -> bool:
 for b in balls:
  if not b.active and b.pocket>=0 and b.fall<1.0:return true
 return false

func _pot(b: Dictionary, pocket: int) -> void:
 if not b.active:return
 b.active=false; b.v=Vector2.ZERO; b.pocket=pocket; b.fall=0.0
 if not shot.is_empty():
  shot.potted.append({"id":b.id,"pocket":pocket})
  if b.id==shot.cue: shot.scratch=true
 collisions.append({"kind":"pocket","speed":0.8,"p":b.p})

func _rail(b: Dictionary) -> void:
 for axis in range(2):
  var bound: float=half_size[axis]-radius
  if absf(b.p[axis])<=bound: continue
  var mouth =false
  if pocketed_table:
   # Side and corner mouths remain open to the pocket catchment.
   for p in pockets():
    if b.p.distance_to(p)<pocket_radius+radius*0.75:
     # A ball crossing the open mouth must enter the pocket, never the room.
     if absf(b.p.x)>=half_size.x or absf(b.p.y)>=half_size.y:
      _pot(b,pockets().find(p));return
     mouth=true;break
  if mouth: continue
  var outward: float=signf(b.p[axis])
  b.p[axis]=outward*bound
  if b.v[axis]*outward<=0: continue
  var impact: float=absf(b.v[axis])
  b.v[axis]=-b.v[axis]*RAIL_RESTITUTION
  b.v[1-axis]+=b.spin.x*impact*0.10
  b.spin.x*=0.75
  if not shot.is_empty() and b.id==shot.cue: shot.rails+=1
  if not shot.is_empty() and shot.first!=-1: shot.rail_after_contact=true
  if impact>0.06: collisions.append({"kind":"rail","speed":impact,"p":b.p})
