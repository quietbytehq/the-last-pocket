extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():
 var P=load("res://scripts/physics.gd")
 for cut in [0.0,0.2,0.4,0.6]:
  for speed in [0.8,2.0,4.0]:
   var sim=P.new();sim.friction=0;sim.pocketed_table=false;sim.radius=0.0475
   var normal=Vector2(cos(cut),sin(cut));var target=Vector2(0.2,0)
   var ghost=target-normal*sim.radius*2
   sim.add_ball(0,ghost-Vector2(0.3,0));sim.add_ball(1,target)
   sim.begin_shot(0,Vector2.RIGHT,speed,Vector2.ZERO)
   for tick in range(200):
    sim.step(1.0/240)
    if sim.shot.first==1:break
   check(sim.shot.first==1,"Cut shot contacts at multiple speeds")
   var actual: Vector2=sim.ball(1).v.normalized()
   check(absf(actual.angle_to(normal))<deg_to_rad(0.05),"Contact-time normal preserves geometric cut angle")
   var momentum: Vector2=sim.ball(0).v+sim.ball(1).v
   check(momentum.distance_to(Vector2(speed,0))<0.0001,"Collision conserves linear momentum")
   check(sim.ball(0).v.length_squared()+sim.ball(1).v.length_squared()<=speed*speed+0.001,"Collision does not add kinetic energy")
 print("CONTACT: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
