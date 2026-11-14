# Club rules used by this build

This build supports ten selectable modes with their own layouts, targets, turn rules and scoring. It is intended for recreational play on one computer; it does not claim tournament-referee certification.

## Shared mechanics

Balls collide and roll on a planar cloth surface. A shot ends only after the active balls have stopped. Fouls include a scratch, failure to contact an object ball and, where relevant, contacting the wrong ball first. Pool also requires a pot or a cushion contact after the first object-ball contact. A foul hands the turn to the opponent.

Aiming, shot power, simplified draw/follow and side spin are supported. Jump shots, masse, cue-tip miscues and airborne/off-table ball physics are not simulated.

## Pool

**8-ball:** the table remains open after the break. A legal post-break pot assigns solids and stripes. The player continues after a legal pot of their group. The eight must be played after the group is cleared and must enter the called pocket. An early eight, wrong called pocket or foul on the winning eight loses the frame. An eight on the break is re-spotted. An opponent's incidental pot is permitted when first contact was legal. Ordinary shots other than the eight do not require a call in this club variant.

**9-ball:** hit the lowest active numbered ball first. A legally potted nine, including a combination, wins. An illegal nine is re-spotted. Three consecutive fouls by one player lose the rack. A legal shot clears that player's foul sequence.

**10-ball:** hit the lowest active ball first. After the opening break, select a called ball and pocket. A called pot retains the turn; uncalled pots pass the turn. The ten is re-spotted when potted early. Winning requires a called, legal ten when it is the last object ball. Three consecutive fouls lose the rack.

**Straight pool:** call a ball and pocket. A successful called shot scores all object balls pocketed on that stroke. A foul costs one point. Uncalled pots are re-spotted. Fourteen balls are re-racked when one object ball remains; the score continues. The target is 25 points. Occupied re-rack positions use the common non-overlapping spotting search.

**Blackball:** seven reds versus seven yellows, followed by the black. Groups are assigned by a legal post-break pot. A foul gives the opponent ball in hand in baulk and a free shot, followed by their regular visit. The free shot permits first contact with an opponent ball. Potting the black before clearing one's group loses. On a regular shot, potting an opponent's colour is a foul.

### Pool tournament options not implemented

- Push-outs and accept/return-shot choices.
- Special opening-break acceptance, re-rack and multi-ball-cushion requirements; this build uses the common post-contact cushion/pot requirement.
- Called safeties, tournament race formats and shot clocks.
- Straight-pool three-foul additional penalties and the full interference-dependent re-rack placement procedure.
- Alternative national blackball/world-rules variants.

## Snooker

The full game begins with 15 reds; the shorter game begins with six. Reds score one. Colours score yellow 2, green 3, brown 4, blue 5, pink 6 and black 7.

Alternate a red with a nominated colour. Colours are re-spotted during the red-colour phase; reds remain down. After the final red and following colour, clear yellow through black in order. Multiple legal reds on one stroke score individually. Fouls award at least four points to the opponent, increasing to the value of a higher involved ball. Re-spotting searches for an unoccupied position.

The final black decides the frame. A final-black foul also ends the frame when scores are unequal. A tied frame uses a re-spotted black with cue ball in hand in the D.

Referee-dependent free balls, foul-and-miss/replacement decisions, asking an opponent to play again, touching-ball declarations and specialist tournament exceptions are not implemented. The receiving player takes the position left after a foul, with placement in the D following a scratch. These omissions are significant for competitive snooker; use this build for recreational play.

## Carom

The table has no pockets. Player one uses the white cue ball; player two uses yellow. The third ball is red. Contact both other balls to score one and continue. Straight-rail carom has a target of 10 points. Three-cushion requires the cue ball to contact at least three cushions before its first contact with the second distinct object ball; its target is 5 points. No point passes the turn.

Balkline restrictions and specialised international competition formats are not implemented.

## Practice

Free potting with one player and no foul penalties. The counter continues through cleared racks. Scratches permit cue-ball placement.

## Reference organisations

The normal sequences and scoring were checked against the organisations below. The software's simplified club variants are described above rather than presented as complete implementations of their official rulebooks.

- World Pool-Billiard Association: https://wpapool.com/rules/
- World Professional Billiards and Snooker Association: https://wpbsa.com/rules/
- Union Mondiale de Billard: https://www.umb-carom.org/sport/rules
