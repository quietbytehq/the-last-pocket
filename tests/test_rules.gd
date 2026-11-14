extends SceneTree
const Physics=preload("res://scripts/physics.gd")
const Rules=preload("res://scripts/rules.gd")
var checks=0
var failures=0
func check(condition: bool,label: String) -> void:
 checks+=1
 if not condition: failures+=1;push_error(label)
func _initialize(): call_deferred("run")
func shot(first: int,pots: Array=[],scratch: bool=false,rail: bool=true) -> Dictionary:
 return {"cue":0,"first":first,"potted":pots,"scratch":scratch,"rail_after_contact":rail,"rails":3,"contacts":[first],"cushions_at_second":3}
func apply_pots(sim,pots: Array):
 for p in pots:
  var b=sim.ball(p.id)
  if not b.is_empty(): b.active=false
func run():
 var sim=Physics.new();var rules=Rules.new()
 var counts=[16,10,11,16,16,22,13,3,3,16]
 for mode in range(10):
  rules.configure(mode,sim)
  check(sim.balls.size()==counts[mode],"Correct ball count in "+Rules.MODES[mode])
  var ids=[]
  for b in sim.balls:
   check(b.id not in ids,"Unique ball identifier")
   ids.append(b.id)
   check(absf(b.p.x)<sim.half_size.x and absf(b.p.y)<sim.half_size.y,"Rack inside cloth")
   for other in sim.balls:
    if other.id>b.id: check(b.p.distance_to(other.p)>sim.radius*1.99,"Rack balls do not overlap: %s %d %d" % [Rules.MODES[mode],b.id,other.id])
  check(sim.pocketed_table==not rules.is_carom(),"Correct pocketless configuration")
  check(rules.cue_id()==0,"First player cue")
  if rules.is_carom():
   rules.player=1;check(rules.cue_id()==16,"Second carom player uses yellow")
  if rules.is_snooker():
   check(not rules.is_placement_legal(Vector2.ZERO,sim),"Snooker cue cannot be placed outside D")
   var legal=Vector2(-sim.half_size.x*0.58-sim.half_size.y*0.2,0)
   check(rules.is_placement_legal(legal,sim),"Legal D position")
 # Pool ball-in-hand placement and no overlaps.
 rules.configure(0,sim)
 check(not sim.can_place(sim.ball(1).p,0),"Cannot place cue on object ball")
 check(not sim.can_place(Vector2(5,5),0),"Cannot place outside table")
 check(sim.can_place(Vector2(-0.5,0.2),0),"Clear legal placement")
 # Momentum transfer, no spurious energy creation.
 sim.balls.clear();sim.friction=0;sim.add_ball(0,Vector2(-0.2,0));sim.add_ball(1,Vector2(0,0));sim.begin_shot(0,Vector2.RIGHT,2,Vector2.ZERO)
 for i in range(40): sim.step(1.0/240.0)
 check(sim.shot.first==1,"First contact recorded")
 check(sim.ball(1).v.x>1.8,"Cue transfers momentum")
 check(sim.ball(0).v.length_squared()+sim.ball(1).v.length_squared()<=4.001,"Collision does not create energy")
 # Fast break cannot tunnel through a head-on object.
 sim.balls.clear();sim.add_ball(0,Vector2(-0.15,0));sim.add_ball(1,Vector2(0,0));sim.begin_shot(0,Vector2.RIGHT,6,Vector2.ZERO)
 sim.step(1.0/30.0)
 check(sim.shot.first==1,"Fast shot collision at 30 Hz outer frame")
 # Rails, friction, pockets and respotting.
 sim.balls.clear();sim.add_ball(0,Vector2(1.20,0.3));sim.begin_shot(0,Vector2.RIGHT,2,Vector2.ZERO)
 for i in range(20):sim.step(1.0/240.0)
 check(sim.ball(0).v.x<0 and sim.shot.rails>0,"Rail rebound recorded")
 sim.friction=0.2
 for i in range(3000):sim.step(1.0/240.0)
 check(not sim.is_moving(),"Rolling friction settles a shot")
 sim.balls.clear();sim.add_ball(0,Vector2(0,sim.half_size.y-0.11));sim.begin_shot(0,Vector2.DOWN,0.7,Vector2.ZERO)
 for i in range(90):sim.step(1.0/240.0)
 check(not sim.ball(0).active and sim.shot.scratch,"Cue scratch into side pocket")
 sim.add_ball(1,Vector2(0.6,0));sim.add_ball(9,Vector2(-0.3,0));sim.ball(9).active=false;sim.respot(9,Vector2(0.6,0))
 check(sim.ball(9).active and sim.ball(9).p.distance_to(sim.ball(1).p)>sim.radius*1.99,"Respot avoids occupied spot")
 # 8-ball open table, legal group assignment, misses, fouls and win/loss.
 rules.configure(0,sim);rules.break_shot=false;rules.ball_in_hand=false
 var before=rules.before_shot(sim);var pots=[{"id":1,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(rules.groups==[0,1] and rules.player==0,"Legal solid assigns groups and retains turn")
 before=rules.before_shot(sim);sim.shot=shot(2);rules.resolve(sim,before);check(rules.player==1,"Miss switches player")
 before=rules.before_shot(sim);sim.shot=shot(2);rules.resolve(sim,before)
 check(rules.player==0 and rules.ball_in_hand,"Wrong first ball gives opponent ball in hand")
 # Scratching remains a foul even when an opponent's ball is pocketed.
 rules.player=0;rules.ball_in_hand=false;before=rules.before_shot(sim);pots=[{"id":0,"pocket":0},{"id":9,"pocket":1}];apply_pots(sim,pots);sim.shot=shot(2,pots,true);rules.resolve(sim,before)
 check(rules.player==1 and rules.ball_in_hand,"Opponent pot cannot erase a scratch")
 rules.configure(0,sim);rules.break_shot=false;before=rules.before_shot(sim);pots=[{"id":8,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(rules.winner==1,"Early black loses frame")
 rules.configure(0,sim);rules.break_shot=false;rules.groups=[0,1]
 for b in sim.balls:
  if b.id>=1 and b.id<=7:b.active=false
 rules.called_pocket=2;before=rules.before_shot(sim);pots=[{"id":8,"pocket":2}];apply_pots(sim,pots);sim.shot=shot(8,pots);rules.resolve(sim,before)
 check(rules.winner==0,"Called legal black wins")
 rules.configure(0,sim);before=rules.before_shot(sim);pots=[{"id":8,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(not rules.match_over and sim.ball(8).active,"Black on break is spotted")
 # 9-ball combinations and illegal nine respot.
 rules.configure(1,sim);before=rules.before_shot(sim);pots=[{"id":9,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(rules.winner==0,"Legal nine combination wins")
 rules.configure(1,sim);before=rules.before_shot(sim);apply_pots(sim,pots);sim.shot=shot(9,pots);rules.resolve(sim,before)
 check(not rules.match_over and sim.ball(9).active and rules.player==1,"Illegal nine respotted and foul awarded")
 # Called ten only wins as the final ball, not an early combination.
 rules.configure(2,sim);rules.break_shot=false;rules.called_ball=10;rules.called_pocket=0;before=rules.before_shot(sim);pots=[{"id":10,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(not rules.match_over and sim.ball(10).active,"Early ten spotted")
 rules.configure(2,sim);rules.break_shot=false
 for b in sim.balls:
  if b.id>0 and b.id!=10:b.active=false
 rules.called_ball=10;rules.called_pocket=1;before=rules.before_shot(sim);pots=[{"id":10,"pocket":1}];apply_pots(sim,pots);sim.shot=shot(10,pots);rules.resolve(sim,before)
 check(rules.winner==0,"Called final ten wins")
 # Straight pool scores called pots, penalizes fouls and re-racks.
 rules.configure(3,sim);rules.break_shot=false;rules.called_ball=1;rules.called_pocket=0;before=rules.before_shot(sim);pots=[{"id":1,"pocket":0},{"id":2,"pocket":1}];apply_pots(sim,pots);sim.shot=shot(1,pots);rules.resolve(sim,before)
 check(rules.scores[0]==2 and rules.player==0,"Called straight-pool shot scores all pots")
 before=rules.before_shot(sim);sim.shot=shot(-1);rules.resolve(sim,before);check(rules.scores[0]==1 and rules.player==1,"Straight-pool foul costs one")
 # Blackball foul gives a free shot.
 rules.configure(4,sim);rules.break_shot=false;rules.groups=[0,1];before=rules.before_shot(sim);sim.shot=shot(9);rules.resolve(sim,before)
 check(rules.player==1 and rules.free_shot and rules.ball_in_hand,"Blackball foul gives free shot and baulk placement")
 # Snooker red, colour, respot, foul points and ordered clearance.
 rules.configure(6,sim);rules.ball_in_hand=false;before=rules.before_shot(sim);pots=[{"id":101,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(101,pots);rules.resolve(sim,before)
 check(rules.scores[0]==1 and rules.phase=="colour","Snooker red scores one and requires colour")
 rules.nominated=7;before=rules.before_shot(sim);pots=[{"id":7,"pocket":1}];apply_pots(sim,pots);sim.shot=shot(7,pots);rules.resolve(sim,before)
 check(rules.scores[0]==8 and rules.phase=="red" and sim.ball(7).active,"Black scores seven and is re-spotted")
 before=rules.before_shot(sim);sim.shot=shot(7);rules.resolve(sim,before)
 check(rules.scores[1]==7 and rules.player==1,"Wrong first snooker black awards seven")
 for b in sim.balls:
  if b.id>=100:b.active=false
 rules.phase="clearance";rules.clearance=2;before=rules.before_shot(sim);pots=[{"id":2,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(2,pots);rules.resolve(sim,before)
 check(rules.clearance==3 and not sim.ball(2).active,"Colour clearance removes yellow and advances to green")
 rules.clearance=7;rules.scores=[10,15];rules.player=0;before=rules.before_shot(sim);pots=[{"id":7,"pocket":0}];apply_pots(sim,pots);sim.shot=shot(7,pots);rules.resolve(sim,before)
 check(rules.match_over and rules.winner==0,"Final black determines score winner")
 # Carom success and three-cushion timing.
 for mode in [7,8]:
  rules.configure(mode,sim);before=rules.before_shot(sim);sim.shot=shot(3);sim.shot.contacts=[3,16];sim.shot.cushions_at_second=3;rules.resolve(sim,before)
  check(rules.scores[0]==1 and rules.player==0,"Valid carom retains player")
 rules.configure(8,sim);before=rules.before_shot(sim);sim.shot=shot(3);sim.shot.contacts=[3,16];sim.shot.cushions_at_second=2;rules.resolve(sim,before)
 check(rules.scores[0]==0 and rules.player==1,"Two cushions insufficient for three-cushion")
 # Endurance: break every pool/snooker rack, allow it to settle, validate finite state.
 for mode in range(7):
  rules.configure(mode,sim);sim.begin_shot(0,Vector2.RIGHT,5.4,Vector2(0.3,-0.4))
  for tick in range(2400):
   sim.step(1.0/120.0)
   if tick%30==0:
    for b in sim.balls:
     check(b.p.is_finite() and b.v.is_finite(),"Finite ball state under break")
     if b.active:check(absf(b.p.x)<sim.half_size.x+0.03 and absf(b.p.y)<sim.half_size.y+0.03,"No ball escapes table")
  check(not sim.is_moving(),"Break settles in "+Rules.MODES[mode])
 print("PASS" if failures==0 else "FAIL",": ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
