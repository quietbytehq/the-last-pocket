# The Last Pocket

A Linux cue-sports game with local two-player matches, AI rivals and a 48-frame comic-style championship.

![Actual Linux title screen](docs/title-screen.png)

[Gameplay preview](docs/current-build.png) · [Rival introduction](docs/rival-card.png) · [Manual saves](docs/manual-save-slots.png) · [Rival result](docs/rival-result.png)

## Play

Download the Linux archive from [GitHub Releases](https://github.com/quietbytehq/the-last-pocket/releases), extract it, then run `TheLastPocket/play.sh`. Godot is not required to play the exported build. The launcher selects native Wayland on Wayland desktops and otherwise uses the normal Linux display driver.

The game starts fullscreen with an illustrated title screen. Press any key, then choose **Local Versus** or **Versus AI**. Local Versus offers ten modes. Versus AI is the championship: new runs always start in Amateur, and rivals are revealed one at a time. For a local match, choose a game, enter two names and select **Play Match**. In Local Versus, both players share the mouse and keyboard. In Versus AI, you are player one. Tournament progress is saved only when you choose **Save tournament**. The separate save menu has ten slots with the player name and local date/time. Use **Load tournament** to open a chosen save; active frames load paused until you choose **Resume play**. There is no automatic progress saving.

## Championship

Four ranks — Amateur, Professional, Master and GOAT — each introduce twelve original comic-style opponents. Win frames to unlock upgraded tables and cues. Three retry diamonds allow rematches after a loss. Your journey shows only current and encountered rivals; future opponents stay hidden. Each rival has separate victory and defeat portraits and an individual line for each result. These lines are readable on screen; recorded voices are optional. The local top ten keep each player’s best tournament run. See [TOURNAMENT.md](TOURNAMENT.md) for scoring, progression and AI behaviour.

## Games

- 8-ball pool
- 9-ball pool
- 10-ball pool
- Straight pool, first to 25
- Blackball, with red/yellow sets
- Full 15-red snooker
- Six-red snooker
- Straight-rail carom, first to 10
- Three-cushion carom, first to 5
- Free practice

These are playable club-rule implementations. See [RULES.md](RULES.md) for the implemented rules and the tournament exceptions that are not simulated.

## Controls

| Action | Control |
| --- | --- |
| Aim | Move the mouse over the table; click the cloth to lock direction |
| Shoot | Press Space / Enter, or click Shoot |
| Unlock aim | Right click the table |
| Shot power | Mouse wheel; or drag the left power meter; releasing does not shoot |
| Cue spin | Drag the white spin control at the lower right |
| Reset spin | Right click the white spin control |
| Place cue ball | Left click a clear legal position when ball in hand |
| Called pocket | Keys 1–6, or click a numbered pocket marker. Required before the final 8-ball shot. |
| Called ball / nominated colour | Selector at the bottom |
| Help | H |
| Pause | Escape |
| Fullscreen/window | F11 |
| Effects on/off | M |
| Music on/off | N |
| FPS display | F3 |

For snooker, cue-ball placement is restricted to the D. A coral ring indicates an invalid placement; the cue ball stays white. Pool opening breaks start behind the head string.

## Graphics and performance

The revised pocketed tables use a detailed rendered club-table background based on the approved visual reference, combined with live 3D rolling balls, softbox highlights, contact shadows, cue and aiming guide. Pocket drops use a masked descent behind the pocket lip. Player ball sets have large glossy badges beside the names. The dotted aiming guide has a travelling highlight, fades with distance, and freezes when paused. The cue preview stays white; a separate ring indicates placement legality. The overhead view is fixed to preserve alignment. Pool ball/table proportions follow the larger balls in the reference. Carom currently retains the earlier 3D table layout.

Pocketed-table graphics render at the display's native resolution: edge smoothing in Performance, 4×MSAA in High. The earlier fallback carom scene uses reduced 3D resolution in Performance. Interface text remains native.

The frame limiter targets 60 fps. VSync is disabled because testing found a pacing problem in the laptop's Wayland session. See QA_REPORT.md for measurements and scope. Native Wayland on x86-64 Linux with OpenGL 3.3-compatible graphics was tested; other Linux machines and drivers need verification. ARM and Windows builds are not included.

## Audio

Four original stereo impact placeholders are included. The music design is calm hotel-lobby lounge music with separate loops per rank. The bundled stereo lounge track is included as music.mp3. Additional themes, final effects and voices remain optional exports. For the exported game, drop MP3 replacements into its `audio` folder and restart; no rebuild is needed. For source development, use `assets/audio`. OGG/WAV imports require rebuilding. MP3 takes priority over the bundled effects. See [AUDIO_BRIEF.md](AUDIO_BRIEF.md) for filenames, triggers and generation prompts. Effects pan subtly across the table.

## Development

Open `project.godot` with Godot 4.7.2. The project uses the Compatibility renderer. Scripts, rules, physics and scene construction are separate under `scripts/`.

```sh
godot --path .
godot --headless --path . --script tests/test_rules.gd
godot --headless --path . --script tests/test_extended_rules.gd
godot --headless --path . --script tests/test_integration.gd
godot --headless --path . --script tests/test_campaign.gd
godot --headless --path . --script tests/test_campaign_flow.gd
godot --headless --path . --script tests/test_ai.gd
godot --headless --path . --script tests/test_contact_accuracy.gd
```

The exported game has its own compiled smoke test (release executables do not accept editor `--script` commands):

```sh
./build/TheLastPocket/play.sh --audio-driver Dummy -- --self-test
```

For development tests, use an isolated `XDG_DATA_HOME` to keep test files separate from player data. `tools/build-linux.sh` exports and packages the Linux game using installed matching Godot export templates.

The game runs offline. It has no accounts, networking, telemetry or in-app purchases. AI planning runs locally on a background thread. Preferences, the local Top Ten and explicitly selected tournament saves are stored in Godot's `user://` directory. Unselected tournament progress is never saved. Legacy automatic match saves are ignored and left untouched.

## Licence and contact

Source code and original project visual/effect assets: [Apache-2.0](LICENSE). Fonts retain their original licences. Bundled music is distributed with permission for use within this game and is excluded from Apache-2.0. See [NOTICE](NOTICE), [LICENSES](LICENSES) and [ART_PROMPTS.md](ART_PROMPTS.md).

QuietByte · hello@quietbytehq.uk

## Snap packaging

Run `tools/build-snap.sh` with Snapcraft and an initialized LXD builder. The recipe uses core24, strict confinement, the GNOME graphics extension and audio-playback. Save data stays in the snap's per-user common data directory across refreshes.

The complete bundled game is listed as Proprietary in store metadata because the music is licensed for distribution within the game, without separate reuse rights. The source code remains Apache-2.0. Font and engine terms are in NOTICE.

To run the complete headless source suite: `tools/test.sh`. The script isolates test save/settings files from player data.
