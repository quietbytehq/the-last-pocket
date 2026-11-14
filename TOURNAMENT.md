# The championship tour

The title screen leads to **Local Versus** (two humans sharing this computer) or **Versus AI**. Local Versus keeps all ten cue-sport choices. Versus AI is exclusively the 8-ball championship. New runs begin in Amateur, with no skill or rival selector. Practice remains a local free-play option.

## Four clubs, 48 rivals

| Rank | Rivals | Table and accessories |
| --- | --- | --- |
| Amateur | 01–12 | Green cloth, club oak and a house maple cue |
| Professional | 13–24 | Teal cloth, polished walnut/chrome and a Carbon Pro cue |
| Master | 25–36 | Burgundy cloth, mahogany/brass and a Rosewood Master cue |
| GOAT | 37–48 | Sapphire cloth, ebony/engraved gold and an Onyx Elite cue |

Each rank has twelve distinct original comic-style rivals. Every rival has a portrait, a personality and an individual teasing introduction. The portrait card is shown before a frame starts. Names and spoken lines are listed in `docs/RIVAL_VOICE_LINES.csv`.

One 8-ball frame is played against each rival. Win to advance. Opening breaks alternate between the human and the AI across the roster. The human always remains player one. Completing twelve rivals unlocks the next club, table finish and cue. Complete all 48 to become champion.

## Three continue diamonds

A new championship grants exactly three diamonds. Losing opens a result card: spend one diamond to replay that rival, or end the run. Wins do not spend diamonds. Diamonds do not regenerate between clubs. After three spent diamonds, another loss ends the run. Local matches have ordinary rematches and do not consume tournament diamonds.

Pause and return to the menu keep the latest settled position available through Resume. A shot in flight resumes from the previously saved settled position. Introductions, results, points and spent continues are saved too. The earlier prototype's save format is not loaded into this version.

## Points and the top ten

A victory awards 1,000 points plus 500 per rank above Amateur, plus 50 for every human shot under 18. Completing all 48 rivals adds 1,000 per unused diamond. Losing a frame grants no points. A run is recorded when completed, when all continues are exhausted, or when explicitly ended from its result card. Starting a different match or a fresh tournament also records the points already earned on an unfinished run.

The top ten are stored on this PC. Each player name keeps its highest championship score; replaying with a lower score does not replace it. Equal scores are ordered by frames won. There are no online accounts or leaderboards.

## AI behaviour

The AI uses the same collision solver, placement restrictions, legal-target rules, friction and pocket geometry as the human. Planning uses a separate snapshot in a background thread; human input cannot shoot on the AI's turn, and Pause prevents it from executing a shot.

Aim error reduces as rivals progress. Better ranks examine bank shots and check promising plans with the actual two-ball collision solver. Blocked paths, cushion jaws, called balls/pockets, nominated colours and ball-in-hand restrictions are considered. Carom uses sampled trajectories with increasing search depth. The AI does not read future player inputs or change ball physics to make a shot succeed. It can miss, foul and lose; GOAT is a fictional arcade rank, not a guarantee of perfect play.

The underlying game still uses the recreational club rules described in RULES.md.

## Audio

Gameplay music is designed as calm, upscale hotel-lobby lounge music with subtle rank variations. The supplied stereo lobby track is included as music.mp3; optional alternate themes, effects and voices are listed in AUDIO_BRIEF.md. Music and effects have independent icons, Pause switches and N / M shortcuts. Missing optional voices leave readable dialogue on screen.

## Your journey, without spoilers

Open **Your journey** from a rival introduction or the wooden Pause menu. The AI entry page also offers **Your journey** for a saved championship. The view shows the current rival and everyone already encountered, with portraits, rank, defeated/current status and repeat attempts. Future rival names, portraits and descriptions are not created in this view. A win does not reveal the next rival until you advance. Only reached ranks appear in the rank path.

Version 4 saves preserve encounter history. Earlier version 3 tournament saves still restore their known victories and current rival; unrecorded historical losses are not invented. The former single-frame AI saves are not accepted into the new sequential championship. The brand changed to The Last Pocket while the existing save location was retained.
