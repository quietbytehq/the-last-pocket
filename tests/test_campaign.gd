extends SceneTree
var checks=0
var failures=0
func check(value: bool,label: String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var Campaign=load("res://scripts/campaign.gd");var Board=load("res://scripts/leaderboard.gd")
 var career=Campaign.new();check(career.roster.size()==48,"48 original rivals")
 var names=[];var quotes=[]
 for tier in range(4):
  for slot in range(12):
   var r=career.roster[tier*12+slot]
   check(int(r.tier)==tier and int(r.slot)==slot,"Twelve rivals per tier in stable order")
   check(r.name not in names and r.quote not in quotes,"Individual name and taunt")
   names.append(r.name);quotes.append(r.quote)
 career.start_tournament("  ACE  ");check(career.human_name=="ACE" and career.diamonds==3,"New run grants exactly three diamonds")
 var previous_skill=-1.0;var previous_score=0
 for i in range(48):
  check(career.rival_index==i and career.skill()>previous_skill,"Rival difficulty progresses monotonically")
  previous_skill=career.skill();career.phase="playing";career.shots=8
  career.finish_frame(true)
  check(career.wins==i+1 and career.points>previous_score and career.diamonds==3,"Victory scores once and retains diamonds")
  previous_score=career.points;career.finish_frame(true)
  check(career.points==previous_score,"Result cannot score twice")
  check(career.valid(career.snapshot()),"Every tournament boundary serializes consistently")
  if i<47:check(career.advance(),"Progress to the next rival")
 check(career.finished and career.wins==48 and not career.advance(),"48th rival completes the championship")
 var champion_points=career.points
 career.start_tournament("RETRY");career.phase="playing"
 for i in range(3):
  career.finish_frame(false)
  check(not career.advance(),"A loss cannot advance")
  check(career.spend_continue() and career.diamonds==2-i,"Each continue spends one diamond")
  check(not career.spend_continue(),"One result cannot spend twice")
  career.phase="playing"
 career.finish_frame(false)
 check(career.finished and not career.spend_continue() and career.diamonds==0,"Fourth loss ends a three-continue run")
 var restored=Campaign.new();check(restored.restore(career.snapshot()),"Run state round-trips")
 var bad=career.snapshot();bad.diamonds=-1;check(not restored.restore(bad),"Invalid diamond count rejected")
 bad=career.snapshot();bad.wins=48;check(not restored.valid(bad),"Impossible run progress rejected")
 var board=Board.new();board.entries=[]
 for i in range(15):board.record("Player %02d" % i,1000+i*100,i)
 check(board.entries.size()==10 and board.entries[0].points==2400 and board.entries[9].points==1500,"Leaderboard retains sorted top ten")
 board.record("PLAYER 14",2500,15)
 check(board.entries.size()==10 and board.entries[0].points==2500,"Name comparison ignores case and keeps the personal best")
 board.record("Player 14",20,0);check(board.entries[0].points==2500,"Lower replay does not replace a record")
 var loaded=Board.new();check(loaded.entries==board.entries,"Top ten survives a reload")
 board.record("Champion",champion_points,48);check(board.entries[0].wins==48,"Champion record stores all 48 wins")
 print("CAMPAIGN: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
