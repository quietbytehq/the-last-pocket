extends SceneTree
const Physics=preload("res://scripts/physics.gd")
const Rules=preload("res://scripts/rules.gd")
const AI=preload("res://scripts/ai.gd")
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var sim=Physics.new();var rules=Rules.new();rules.configure(0,sim);rules.player=1;rules.break_shot=false;rules.ball_in_hand=false
 for b in sim.balls:b.active=b.id in [0,1]
 sim.ball(0).p=Vector2(-0.6,0.15);sim.ball(1).p=Vector2(0.25,-0.1)
 var data=AI.snapshot(sim,rules);var shot=AI.plan(data,3.9,100)
 check(shot.aim.is_finite() and is_equal_approx(shot.aim.length(),1.0),"Finite normalized AI aim")
 check(shot.ball==1 and shot.pocket>=0 and shot.pocket<6,"Calls a legal target and pocket")
 sim.begin_shot(0,shot.aim,0.35+shot.power*5.1,Vector2.ZERO)
 for i in range(1800):
  sim.step(1.0/120.0)
  if not sim.is_moving():break
 check(sim.shot.first==1 and sim.shot.potted.any(func(pot):return pot.id==1),"Expert geometric shot actually pots under game physics")
 var rookie_pots=0;var expert_pots=0
 for level in [0.0,3.9]:
  for trial in range(24):
   rules.configure(0,sim);rules.player=1;rules.break_shot=false;rules.ball_in_hand=false
   for b in sim.balls:b.active=b.id in [0,1]
   sim.ball(0).p=Vector2(-0.65,0.26-trial%4*0.12);sim.ball(1).p=Vector2(0.25+(trial%3)*0.13,-0.23+(trial%5)*0.1)
   shot=AI.plan(AI.snapshot(sim,rules),level,trial+70)
   sim.begin_shot(0,shot.aim,0.35+shot.power*5.1,Vector2.ZERO)
   for i in range(1800):
    sim.step(1.0/120.0)
    if not sim.is_moving():break
   if sim.shot.potted.any(func(pot):return pot.id==1):
    if level<1:rookie_pots+=1
    else:expert_pots+=1
 check(expert_pots>rookie_pots,"Higher rank improves real pot success, rather than changing a label")
 for mode in range(9):
  rules.configure(mode,sim);rules.player=1
  if not rules.is_carom():sim.ball(rules.cue_id()).active=false
  shot=AI.plan(AI.snapshot(sim,rules),0.0,43)
  check(not shot.has("error") and shot.aim.is_finite(),"AI can plan mode %d" % mode)
  if shot.has("error"):continue
  if rules.ball_in_hand:check(rules.is_placement_legal(shot.place,sim),"AI cue placement respects the mode's restrictions")
  check(shot.ball in AI.legal_targets(sim,rules),"AI targets a legal ball")
 print("AI: ",checks," checks, ",failures," failures; rookie pots ",rookie_pots,"/24; expert ",expert_pots,"/24")
 quit(0 if failures==0 else 1)
