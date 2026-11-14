extends SceneTree
const Physics=preload("res://scripts/physics.gd")
const Rules=preload("res://scripts/rules.gd")
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func play(sim,rules,first: int,id: int=-1,pocket: int=0,scratch: bool=false):
 var before=rules.before_shot(sim)
 var pots=[]
 if id>=0:
  pots.append({"id":id,"pocket":pocket});sim.ball(id).active=false
 sim.shot={"cue":rules.cue_id(),"first":first,"potted":pots,"scratch":scratch,"rail_after_contact":true,"rails":3,"contacts":[first],"cushions_at_second":3}
 rules.resolve(sim,before)
func run():
 var sim=Physics.new();var rules=Rules.new()
 for mode in [5,6]:
  rules.configure(mode,sim)
  var count=15 if mode==5 else 6
  for index in range(count):
   play(sim,rules,101+index,101+index)
   check(rules.phase=="colour","Every red requires a nominated colour")
   rules.nominated=7;play(sim,rules,7,7)
   check(sim.ball(7).active,"Black re-spots after every red-colour pair")
   check(rules.player==0 and rules.scores[0]==(index+1)*8,"Snooker break accumulates exactly")
  check(rules.phase=="clearance","Last red-colour pair starts ordered clearance")
  for colour in range(2,8):
   play(sim,rules,colour,colour)
   check(not sim.ball(colour).active,"Clearance colour stays down")
  check(rules.scores[0]==count*8+27,"147 / 75 maximum break")
  check(rules.match_over and rules.winner==0,"Perfect clearance ends the frame")
 for mode in [1,2]:
  rules.configure(mode,sim);rules.break_shot=false
  for index in range(3):
   rules.player=0;play(sim,rules,-1)
   check(rules.consecutive_fouls[0]==index+1,"Rotation-pool foul count increments")
  check(rules.winner==1,"Three consecutive fouls lose the rack")
  rules.configure(mode,sim);rules.break_shot=false;rules.consecutive_fouls=[2,0]
  play(sim,rules,1)
  check(rules.consecutive_fouls[0]==0,"A legal shot clears the foul sequence")
 rules.configure(5,sim);rules.phase="clearance";rules.clearance=7;rules.scores=[50,55]
 play(sim,rules,7,-1,0,true)
 check(rules.match_over and rules.winner==1 and rules.scores[1]==62,"Final-black foul ends an unequal frame")
 rules.configure(5,sim);rules.phase="clearance";rules.clearance=7;rules.scores=[62,55]
 play(sim,rules,7,-1,0,true)
 check(not rules.match_over and rules.scores==[62,62] and rules.ball_in_hand,"Final-black foul tie starts re-spotted black")
 rules.configure(5,sim);rules.phase="clearance";rules.clearance=7;rules.scores=[50,57]
 play(sim,rules,7,7)
 check(not rules.match_over and rules.clearance==7 and sim.ball(7).active and rules.ball_in_hand,"Potted final black can lead to a tied-frame decider")
 rules.configure(3,sim);rules.scores=[14,9]
 for b in sim.balls:
  if b.id>1:b.active=false
 rules._straight_rack(sim)
 check(rules._object_count(sim)==15 and rules.scores==[14,9],"Fourteen-ball re-rack preserves score and break ball")
 for a in sim.balls:
  for b in sim.balls:
   if a.id<b.id and a.active and b.active:check(a.p.distance_to(b.p)>=sim.radius*1.99,"Re-rack does not overlap balls")
 rules.configure(3,sim);rules.break_shot=false;rules.scores=[24,0];rules.called_ball=1;rules.called_pocket=2
 play(sim,rules,1,1,2)
 check(rules.match_over and rules.winner==0 and rules.scores[0]==25,"Straight pool target wins immediately")
 print("PASS" if failures==0 else "FAIL",": ",checks," extended rule checks, ",failures," failures")
 quit(0 if failures==0 else 1)
